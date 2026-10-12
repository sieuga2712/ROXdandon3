class_name StageRules
extends RefCounted

## Stage requirements (docs/khung-ky-thuat.md, section 8.1). Each rule is a
## Dictionary with a "type". validate() runs when the team is picked,
## apply() runs when the battle starts. New rule = one more match branch.
##
##   ban_class            {"classes": ["mage"]}
##   require_class_count  {"classes": ["mage", "priest"], "count": 1}
##   ban_row              {"row": 0}
##   max_team_size        {"count": 3}
##   enemy_immune         {"damage_type": "physical"}
##   enemy_modifier       {"stat": "def", "value": 2.0, "mode": "percent"}
##   team_modifier        {"stat": "lifesteal", "value": -0.5, "mode": "percent"}
##   time_limit           {"seconds": 60}


## [param members]: preset members ({class_id, row, ...}). Returns the broken rules, in Vietnamese.
static func validate(rules: Array[Dictionary], members: Array) -> PackedStringArray:
	var errors := PackedStringArray()
	for r in rules:
		match r.type:
			"ban_class":
				for m in members:
					if r.classes.has(m.class_id):
						errors.append("Màn này cấm %s" % _class_name(m.class_id))
			"require_class_count":
				var n := 0
				for m in members:
					if r.classes.has(m.class_id):
						n += 1
				if n < r.count:
					errors.append("Cần ít nhất %d trong: %s" % [r.count, ", ".join(r.classes.map(func(c): return _class_name(c)))])
			"ban_row":
				for m in members:
					if int(m.row) == int(r.row):
						errors.append("Màn này cấm xếp người ở hàng %s" % ["đầu", "giữa", "cuối"][int(r.row)])
						break
			"max_team_size":
				if members.size() > r.count:
					errors.append("Màn này chỉ cho %d người" % r.count)
	return errors


static func apply(rules: Array[Dictionary], ctx: BattleContext) -> void:
	for r in rules:
		match r.type:
			"enemy_immune":
				for u in ctx.units:
					if u.team == UnitState.Team.ENEMY:
						u.immune_types.append(r.damage_type)
			"enemy_modifier", "team_modifier":
				var team := UnitState.Team.ENEMY if r.type == "enemy_modifier" else UnitState.Team.PLAYER
				var mode := Stats.Mode.PERCENT if r.get("mode", "flat") == "percent" else Stats.Mode.FLAT
				for u in ctx.units:
					if u.team == team:
						u.stats.add_modifier(r.stat, r.value, mode, "stage_rule")
						u.hp = u.max_hp()


## Seconds, or 0 when the stage has no time limit.
static func time_limit(rules: Array[Dictionary]) -> float:
	for r in rules:
		if r.type == "time_limit":
			return r.seconds
	return 0.0


## Plain-language description of a rule for the stage list.
static func describe(r: Dictionary) -> String:
	match r.type:
		"ban_class":
			return "Cấm: %s" % ", ".join(r.classes.map(func(c): return _class_name(c)))
		"require_class_count":
			return "Cần ≥ %d: %s" % [r.count, ", ".join(r.classes.map(func(c): return _class_name(c)))]
		"ban_row":
			return "Cấm hàng %s" % ["đầu", "giữa", "cuối"][int(r.row)]
		"max_team_size":
			return "Tối đa %d người" % r.count
		"enemy_immune":
			return "Quái miễn sát thương %s" % ("vật lý" if r.damage_type == "physical" else "phép")
		"enemy_modifier":
			return "Quái %s %+d%%" % [r.stat, roundi(r.value * 100)] if r.get("mode") == "percent" else "Quái %s %+d" % [r.stat, r.value]
		"team_modifier":
			return "Đội mình %s %+d%%" % [r.stat, roundi(r.value * 100)] if r.get("mode") == "percent" else "Đội mình %s %+d" % [r.stat, r.value]
		"time_limit":
			return "Giới hạn %d giây" % r.seconds
	return r.type


static func _class_name(class_id) -> String:
	var c := GameDB.class_data(class_id)
	return c.display_name if c else String(class_id)
