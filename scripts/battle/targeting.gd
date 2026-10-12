class_name Targeting
extends RefCounted

## Target selectors (docs/khung-ky-thuat.md, section 4.4). The field is a single
## lane, so every distance is measured on x only.

const SELECTORS: PackedStringArray = [
	"self", "current_target", "nearest_enemy", "random_enemy", "all_enemies",
	"enemies_near_self", "enemies_near_target", "highest_hp_enemy",
	"lowest_hp_ally", "all_allies",
]


## Returns the units hit by [param selector]. [param count] 0 = no limit.
static func select(selector: StringName, caster: UnitState, ctx: BattleContext,
		count: int = 1, radius: float = 0.0) -> Array[UnitState]:
	var enemies := _alive(ctx, caster, true)
	var allies := _alive(ctx, caster, false)
	var out: Array[UnitState] = []
	match selector:
		&"self":
			out.append(caster)
		&"current_target", &"nearest_enemy":
			var t := default_target(caster, ctx)
			if t:
				out.append(t)
		&"random_enemy":
			var pool := enemies.duplicate()
			while pool.size() > 0 and (count <= 0 or out.size() < count):
				out.append(pool.pop_at(ctx.rng.randi_range(0, pool.size() - 1)))
			return out
		&"all_enemies":
			out = enemies
		&"enemies_near_self":
			out = _within(enemies, caster.x, radius)
		&"enemies_near_target":
			var center := default_target(caster, ctx)
			if center:
				out = _within(enemies, center.x, radius)
		&"highest_hp_enemy":
			enemies.sort_custom(func(a: UnitState, b: UnitState) -> bool: return a.hp > b.hp)
			out = enemies
		&"lowest_hp_ally":
			allies.sort_custom(func(a: UnitState, b: UnitState) -> bool: return a.hp_ratio() < b.hp_ratio())
			out = allies
		&"all_allies":
			out = allies
		_:
			push_error("Unknown target selector: %s" % selector)
	if count > 0 and out.size() > count:
		out.resize(count)
	return out


## Who a unit attacks: the taunter if taunted, otherwise the nearest enemy.
static func default_target(caster: UnitState, ctx: BattleContext) -> UnitState:
	if caster.has_status("taunt"):
		var taunter := ctx.find(caster.statuses.taunt.source_id)
		if taunter and taunter.alive:
			return taunter
	var best: UnitState = null
	var best_dist := INF
	for u in _alive(ctx, caster, true):
		var d := absf(u.x - caster.x)
		if d < best_dist:
			best = u
			best_dist = d
	return best


static func _alive(ctx: BattleContext, caster: UnitState, enemies: bool) -> Array[UnitState]:
	var out: Array[UnitState] = []
	for u in ctx.units:
		if u.alive and u.is_enemy_of(caster) == enemies:
			out.append(u)
	return out


static func _within(units: Array[UnitState], center_x: float, radius: float) -> Array[UnitState]:
	var out: Array[UnitState] = []
	for u in units:
		if absf(u.x - center_x) <= radius:
			out.append(u)
	return out
