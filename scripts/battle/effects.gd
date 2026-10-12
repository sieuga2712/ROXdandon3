class_name Effects
extends RefCounted

## Applies skill effects (docs/khung-ky-thuat.md, sections 4.5, 5.3 and 6.3).
##
## An effect is a Dictionary with a "type" key plus that type's parameters.
## Add "on": "self" to an effect to apply it to the caster once instead of to
## every target (e.g. Khiêu khích: taunt the enemies, reduce damage on self).
## Add "target": "<selector>" (+ optional "target_count", "radius") to pick that
## effect's own targets (e.g. Tu sĩ: hit the enemy, heal the lowest-HP ally).

const CC_TYPES: PackedStringArray = ["stun", "slow", "taunt", "knockback"]
const DEBUFF_STATUSES: PackedStringArray = ["stun", "slow", "taunt"]

## K in damage × K / (K + def). Starting value, tune with the data.
static var defense_k := 100.0
## Stun a boss gets when its break bar breaks. Ignores cc_resist.
static var break_stun := 1.0


static func apply_skill(skill: Dictionary, caster: UnitState, targets: Array[UnitState], ctx: BattleContext) -> void:
	ctx.emit(&"skill_cast", {
		"source": caster.id, "skill": skill.id, "animation": skill.get("animation", &"Attack"),
		"targets": targets.map(func(t: UnitState) -> String: return t.id),
	})
	var own_target_effects: Array[Dictionary] = []
	for e: Dictionary in skill.effects:
		if e.get("on", "") == "self" or e.has("target"):
			own_target_effects.append(e)
	for target in targets:
		if not target.alive:
			continue
		var cc_on_boss := false
		for e: Dictionary in skill.effects:
			if e.get("on", "") == "self" or e.has("target"):
				continue
			if target.is_boss and e.type in CC_TYPES:
				# Bosses ignore crowd control; it only damages the break bar.
				cc_on_boss = true
				continue
			apply_effect(e, caster, target, ctx, skill.id)
		if cc_on_boss:
			hit_break_bar(target, skill.get("break_power", 0.0), ctx)
	for e in own_target_effects:
		var own_targets: Array[UnitState] = [caster]
		if e.has("target"):
			own_targets = Targeting.select(StringName(e.target), caster, ctx, e.get("target_count", 1), e.get("radius", 0.0))
		for t in own_targets:
			if t.alive and not (t.is_boss and e.type in CC_TYPES):
				apply_effect(e, caster, t, ctx, skill.id)


static func apply_effect(e: Dictionary, caster: UnitState, target: UnitState, ctx: BattleContext, source_skill: StringName = &"") -> void:
	match e.type:
		"damage":
			deal_damage(caster, target, e.get("scale", 1.0), e.get("damage_type", "physical"),
					e.get("hits", 1), e.get("force_crit", false), ctx)
		"heal":
			var basis := _basis_value(e.get("basis", "max_hp"), caster, target)
			heal(target, e.get("scale", 0.0) * basis, ctx, caster.id)
		"shield":
			var amount: float = e.get("scale", 0.0) * _basis_value(e.get("basis", "caster_max_hp"), caster, target)
			target.shields.append({"amount": amount, "expires_at": ctx.time + e.get("duration", 0.0)})
			ctx.emit(&"shield", {"source": caster.id, "target": target.id, "amount": amount})
		"modify_stat":
			var mode := Stats.Mode.PERCENT if e.get("mode", "flat") == "percent" else Stats.Mode.FLAT
			var stack := Stats.StackRule.HIGHEST if e.get("stack_rule", "stack") == "highest" else Stats.StackRule.STACK
			var mod_id := target.stats.add_modifier(e.stat, e.value, mode, "%s:%s" % [caster.id, source_skill], stack)
			var duration: float = e.get("duration", 0.0)
			if duration > 0.0:
				target.timed_mods.append({"mod_id": mod_id, "expires_at": ctx.time + duration})
			ctx.emit(&"status_add", {"source": caster.id, "target": target.id, "status": "stat:%s" % e.stat, "duration": duration})
		"stun":
			var stun_for := _cc_duration(e.get("duration", 0.0), target)
			target.statuses["stun"] = {"expires_at": ctx.time + stun_for}
			if target.is_casting():
				target.casting = {}
				ctx.emit(&"cast_interrupted", {"target": target.id})
			ctx.emit(&"status_add", {"source": caster.id, "target": target.id, "status": "stun", "duration": stun_for})
		"slow":
			var slow_for := _cc_duration(e.get("duration", 0.0), target)
			target.statuses["slow"] = {"value": e.get("value", 0.0), "expires_at": ctx.time + slow_for}
			ctx.emit(&"status_add", {"source": caster.id, "target": target.id, "status": "slow", "duration": slow_for})
		"taunt":
			var taunt_for := _cc_duration(e.get("duration", 0.0), target)
			target.statuses["taunt"] = {"source_id": caster.id, "expires_at": ctx.time + taunt_for}
			ctx.emit(&"status_add", {"source": caster.id, "target": target.id, "status": "taunt", "duration": taunt_for})
		"knockback":
			var direction := signf(target.x - caster.x)
			if direction == 0.0:
				direction = 1.0 if target.team == UnitState.Team.ENEMY else -1.0
			target.x += direction * e.get("distance", 0.0)
			ctx.emit(&"knockback", {"source": caster.id, "target": target.id, "x": target.x})
		"cleanse":
			var removed := 0
			for status in DEBUFF_STATUSES:
				if removed >= e.get("count", 1):
					break
				if target.statuses.erase(status):
					removed += 1
			ctx.emit(&"cleanse", {"source": caster.id, "target": target.id, "removed": removed})
		"undying":
			target.statuses["undying"] = {"expires_at": ctx.time + e.get("duration", 0.0)}
			ctx.emit(&"status_add", {"source": caster.id, "target": target.id, "status": "undying", "duration": e.get("duration", 0.0)})
		"extra_attacks":
			target.pending_extra_attacks += e.get("count", 0)
		_:
			push_error("Unknown effect type: %s" % e.type)


## Damage formula (section 5.3). Returns the total damage dealt, shields included.
static func deal_damage(attacker: UnitState, target: UnitState, scale: float, damage_type: String,
		hits: int, force_crit: bool, ctx: BattleContext) -> float:
	if target.immune_types.has(damage_type):
		ctx.emit(&"immune", {"source": attacker.id, "target": target.id})
		return 0.0
	var magic := damage_type == "magic"
	var attack := attacker.stats.get_value("matk" if magic else "atk")
	var defense := maxf(target.stats.get_value("mdef" if magic else "def"), 0.0)
	var total := 0.0
	for i in hits:
		if not target.alive:
			break
		var amount := attack * scale
		var crit := force_crit or ctx.rng.randf() < attacker.stats.get_value("crit")
		if crit:
			amount *= attacker.stats.get_value("crit_dmg")
		amount *= defense_k / (defense_k + defense)
		amount *= target.stats.get_value("damage_taken")
		take_damage(target, amount, ctx, attacker.id, crit)
		total += amount
		var lifesteal := attacker.stats.get_value("lifesteal")
		if lifesteal > 0.0:
			heal(attacker, amount * lifesteal, ctx, attacker.id)
	return total


## Shields absorb first; undying keeps HP at 1 or more.
static func take_damage(target: UnitState, amount: float, ctx: BattleContext, source_id: String = "", crit: bool = false) -> void:
	var remaining := amount
	for s in target.shields:
		var absorbed := minf(s.amount, remaining)
		s.amount -= absorbed
		remaining -= absorbed
		if remaining <= 0.0:
			break
	target.hp -= remaining
	if target.has_status("undying"):
		target.hp = maxf(target.hp, 1.0)
	ctx.emit(&"damage", {
		"source": source_id, "target": target.id, "amount": amount,
		"absorbed": amount - remaining, "crit": crit, "hp": target.hp,
	})
	if target.hp <= 0.0 and target.alive:
		target.hp = 0.0
		target.alive = false
		target.casting = {}
		ctx.emit(&"death", {"target": target.id, "source": source_id})


static func heal(target: UnitState, amount: float, ctx: BattleContext, source_id: String = "") -> void:
	if not target.alive or amount <= 0.0:
		return
	var before := target.hp
	target.hp = minf(target.max_hp(), target.hp + amount)
	ctx.emit(&"heal", {"source": source_id, "target": target.id, "amount": target.hp - before})


## Break bar (section 6.3): only a casting boss, only crowd-control skills, not while locked.
static func hit_break_bar(boss: UnitState, power: float, ctx: BattleContext) -> void:
	if power <= 0.0 or boss.break_max <= 0.0 or not boss.is_casting():
		return
	if ctx.time < boss.break_locked_until:
		return
	boss.break_value = maxf(boss.break_value - power, 0.0)
	ctx.emit(&"break_damage", {"target": boss.id, "value": boss.break_value, "max": boss.break_max})
	if boss.break_value > 0.0:
		return
	boss.casting = {}
	boss.statuses["stun"] = {"expires_at": ctx.time + break_stun}
	boss.break_locked_until = ctx.time + break_stun + boss.break_lock
	boss.break_value = boss.break_max
	ctx.emit(&"break", {"target": boss.id, "stun": break_stun})


static func _cc_duration(duration: float, target: UnitState) -> float:
	return duration * (1.0 - target.stats.get_value("cc_resist"))


static func _basis_value(basis: String, caster: UnitState, target: UnitState) -> float:
	match basis:
		"max_hp", "target_max_hp":
			return target.max_hp()
		"caster_max_hp":
			return caster.max_hp()
		"atk":
			return caster.stats.get_value("atk")
		"matk":
			return caster.stats.get_value("matk")
	push_error("Unknown basis: %s" % basis)
	return 0.0
