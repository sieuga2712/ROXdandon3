class_name UnitFactory
extends RefCounted

## Turns data (+ profile) into UnitState for BattleSim.

## x of each row at battle start. Row 0 = front. Players stand left of 0, enemies right.
const ROW_X := [60.0, 140.0, 220.0]


## [param member]: a preset member {class_id, row, passives, actives, ultimate}.
static func hero(profile: Profile, member: Dictionary) -> UnitState:
	var c := GameDB.class_data(member.class_id)
	var stats := Stats.new(c.base_stats)
	var equipment: Dictionary = profile.data.classes[member.class_id].equipment
	for slot in equipment:
		var uid: String = equipment[slot]
		var item_stats := profile.item_stats(uid)
		for stat in item_stats:
			stats.add_modifier(stat, item_stats[stat], Stats.Mode.FLAT, "item:%s" % uid)
	var u := UnitState.new(String(member.class_id), UnitState.Team.PLAYER, stats)
	u.class_id = String(member.class_id)
	u.row = int(member.row)
	u.x = -ROW_X[u.row]
	u.move_speed = c.move_speed
	u.attack_range = c.attack_range
	u.attack_type = c.attack_type
	u.mana_max = c.mana_max
	u.mana_per_attack = c.mana_per_attack
	u.mana_per_hit_taken = c.mana_per_hit_taken
	u.auto_ultimate = profile.data.classes[member.class_id].get("auto_ultimate", true)
	for skill_id in member.get("passives", []):
		u.passives.append(_resolve(profile, u.class_id, skill_id))
	for skill_id in member.get("actives", []):
		u.actives.append(_resolve(profile, u.class_id, skill_id))
	if member.get("ultimate", "") != "":
		u.ultimate = _resolve(profile, u.class_id, member.ultimate)
	return u


## Hero without a profile: class base stats + default loadout, level 1. Used by tests and balance runs.
static func hero_bare(class_id: String, row: int) -> UnitState:
	var c := GameDB.class_data(class_id)
	var u := UnitState.new(class_id, UnitState.Team.PLAYER, Stats.new(c.base_stats))
	u.class_id = class_id
	u.row = row
	u.x = -ROW_X[row]
	u.move_speed = c.move_speed
	u.attack_range = c.attack_range
	u.attack_type = c.attack_type
	u.mana_max = c.mana_max
	u.mana_per_attack = c.mana_per_attack
	u.mana_per_hit_taken = c.mana_per_hit_taken
	for skill_id in c.default_passives:
		u.passives.append(GameDB.skill(skill_id).resolve(1))
	for skill_id in c.default_actives:
		u.actives.append(GameDB.skill(skill_id).resolve(1))
	if c.default_ultimate != &"":
		u.ultimate = GameDB.skill(c.default_ultimate).resolve(1)
	return u


static func monster(monster_id: String, unit_id: String, row: int, front_x: float) -> UnitState:
	var m := GameDB.monster(monster_id)
	var u := UnitState.new(unit_id, UnitState.Team.ENEMY, Stats.new(m.base_stats))
	u.class_id = monster_id
	u.is_monster = true
	u.row = row
	u.x = front_x + ROW_X[row] - ROW_X[0]
	u.move_speed = m.move_speed
	u.attack_range = m.attack_range
	u.attack_type = m.attack_type
	u.is_boss = m.is_boss
	u.break_max = m.break_max
	u.break_value = m.break_max
	u.break_lock = m.break_lock
	for skill_id in m.skills:
		u.actives.append(GameDB.skill(skill_id).resolve(1))
	return u


static func _resolve(profile: Profile, class_id: String, skill_id: String) -> Dictionary:
	return GameDB.skill(skill_id).resolve(profile.skill_level(class_id, skill_id))
