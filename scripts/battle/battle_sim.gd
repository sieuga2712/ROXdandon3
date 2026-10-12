class_name BattleSim
extends RefCounted

## Fixed-tick battle simulation (docs/khung-ky-thuat.md, section 6).
## Knows nothing about Nodes: BattleView and BalanceRunner read ctx.events.

enum Result { RUNNING, WIN, LOSE }

const TICK := 0.1
## Max battle length when the stage sets no time limit.
const DEFAULT_MAX_TIME := 180.0
## Distance in front of the furthest hero where a new wave spawns.
const WAVE_SPAWN_GAP := 320.0

var ctx: BattleContext
var stage: StageData
var result := Result.RUNNING
var wave_index := -1
var max_time := DEFAULT_MAX_TIME
var _next_unit_number := 1


func _init(p_stage: StageData, heroes: Array[UnitState], seed_value: int = 0) -> void:
	stage = p_stage
	ctx = BattleContext.new(seed_value)
	for h in heroes:
		ctx.units.append(h)
	var limit := StageRules.time_limit(stage.rules)
	if limit > 0.0:
		max_time = limit
	for h in heroes:
		_prepare(h)
	for h in heroes:
		_apply_always_passives(h)
	# Team HP passives raise max HP; start the battle at full health.
	for h in heroes:
		h.hp = h.max_hp()
	_spawn_next_wave()
	ctx.emit(&"battle_start", {"stage": stage.id})


## Player presses an ultimate button (only matters when auto is off).
func cast_ultimate(unit_id: String) -> void:
	var u := ctx.find(unit_id)
	if u and u.alive:
		u.ultimate_requested = true


func run_to_end() -> Result:
	while result == Result.RUNNING:
		step()
	return result


func step() -> void:
	if result != Result.RUNNING:
		return
	ctx.time += TICK
	for u in ctx.units.duplicate():
		if u.alive:
			_process(u)
	_check_end()


# --- per-unit turn (section 6.2) -----------------------------------------------

func _process(u: UnitState) -> void:
	u.expire(ctx.time)
	u.add_mana(u.stats.get_value("mana_regen") * TICK)
	_check_low_hp(u)
	if u.has_status("stun"):
		return
	if u.is_casting():
		if ctx.time >= u.casting.finish_at:
			var skill: Dictionary = u.casting.skill
			u.casting = {}
			_execute(u, skill)
		return
	var target := Targeting.default_target(u, ctx)
	if target == null:
		return
	var dist := absf(target.x - u.x)
	# 3. Ultimate: off cooldown, enough mana, auto on (or button pressed).
	if not u.is_monster and u.ultimate_ready(ctx.time) and (u.auto_ultimate or u.ultimate_requested) \
			and _in_cast_range(u.ultimate, dist):
		u.mana -= u.ultimate.mana_cost
		u.ultimate.ready_at = ctx.time + u.ultimate.cooldown
		u.ultimate_requested = false
		_use(u, u.ultimate)
		return
	# 4. Cooldown skills.
	for s in u.actives:
		if ctx.time >= s.ready_at and _in_cast_range(s, dist):
			s.ready_at = ctx.time + s.cooldown
			_use(u, s)
			return
	# 5. Basic attack / 6. move.
	if dist <= u.attack_range:
		if ctx.time >= u.next_attack_at:
			_basic_attack(u, target)
			u.next_attack_at = ctx.time + 1.0 / maxf(u.current_atsp(), 0.01)
	else:
		_move_towards(u, target)


func _use(u: UnitState, skill: Dictionary) -> void:
	if skill.cast_time > 0.0:
		u.casting = {"skill": skill, "finish_at": ctx.time + skill.cast_time}
		if u.break_max > 0.0 and ctx.time >= u.break_locked_until:
			u.break_value = u.break_max
		ctx.emit(&"cast_start", {"source": u.id, "skill": skill.id, "duration": skill.cast_time})
		return
	_execute(u, skill)


func _execute(u: UnitState, skill: Dictionary) -> void:
	var targets := Targeting.select(skill.target, u, ctx, skill.target_count, skill.radius)
	if targets.is_empty():
		return
	Effects.apply_skill(skill, u, targets, ctx)
	_after_damage_checks()


func _basic_attack(u: UnitState, target: UnitState) -> void:
	ctx.emit(&"attack", {"source": u.id, "target": target.id})
	_hit(u, target)
	u.add_mana(u.mana_per_attack)
	for p in u.passives:
		if p.when == SkillData.When.ON_ATTACK and ctx.rng.randf() < p.chance:
			_execute(u, p)
	while u.pending_extra_attacks > 0 and target.alive:
		u.pending_extra_attacks -= 1
		ctx.emit(&"attack", {"source": u.id, "target": target.id, "extra": true})
		_hit(u, target)
	u.pending_extra_attacks = 0


func _hit(u: UnitState, target: UnitState) -> void:
	Effects.deal_damage(u, target, 1.0, u.attack_type, 1, false, ctx)
	if target.alive:
		target.add_mana(target.mana_per_hit_taken)
		for p in target.passives:
			if p.when == SkillData.When.ON_HIT_TAKEN and ctx.rng.randf() < p.chance:
				_execute(target, p)
	_after_damage_checks()


func _move_towards(u: UnitState, target: UnitState) -> void:
	var direction := signf(target.x - u.x)
	var new_x := u.x + direction * u.current_move_speed() * TICK
	# Stop exactly at attack range instead of walking through the target.
	if absf(target.x - new_x) < u.attack_range:
		new_x = target.x - direction * u.attack_range
	if not is_equal_approx(new_x, u.x):
		u.x = new_x
		ctx.emit(&"move", {"source": u.id, "x": u.x})


func _in_cast_range(skill: Dictionary, dist: float) -> bool:
	return skill.cast_range <= 0.0 or dist <= skill.cast_range


# --- passives --------------------------------------------------------------------

func _apply_always_passives(u: UnitState) -> void:
	for p in u.passives:
		if p.when == SkillData.When.ALWAYS:
			_execute(u, p)


func _check_low_hp(u: UnitState) -> void:
	for p in u.passives:
		if p.when == SkillData.When.ON_LOW_HP and not u.low_hp_fired.has(p.id) and u.hp_ratio() < p.threshold:
			u.low_hp_fired[p.id] = true
			_execute(u, p)


func _after_damage_checks() -> void:
	for u in ctx.units:
		if u.alive:
			_check_low_hp(u)


# --- waves and end ---------------------------------------------------------------

func _prepare(u: UnitState) -> void:
	for s in u.actives:
		s["ready_at"] = ctx.time + s.start_cooldown
	if not u.ultimate.is_empty():
		u.ultimate["ready_at"] = ctx.time + u.ultimate.start_cooldown


func _spawn_next_wave() -> void:
	wave_index += 1
	var front_x := 0.0
	for u in ctx.alive_units():
		if u.team == UnitState.Team.PLAYER:
			front_x = maxf(front_x, u.x)
	front_x += WAVE_SPAWN_GAP
	var spawned: Array[UnitState] = []
	for entry: Dictionary in stage.waves[wave_index].monsters:
		var unit_id := "%s#%d" % [entry.id, _next_unit_number]
		_next_unit_number += 1
		var m := UnitFactory.monster(entry.id, unit_id, int(entry.get("row", 0)), front_x)
		_prepare(m)
		ctx.units.append(m)
		spawned.append(m)
	# Stage rules (immunities, stat changes) must also cover monsters of later waves.
	var wave_ctx := BattleContext.new()
	wave_ctx.units = spawned
	StageRules.apply(_rules_where(func(r: Dictionary) -> bool: return r.type.begins_with("enemy_")), wave_ctx)
	if wave_index == 0:
		var team_ctx := BattleContext.new()
		for u in ctx.units:
			if u.team == UnitState.Team.PLAYER:
				team_ctx.units.append(u)
		StageRules.apply(_rules_where(func(r: Dictionary) -> bool: return r.type == "team_modifier"), team_ctx)
	ctx.emit(&"wave", {"index": wave_index, "count": stage.waves.size(), "units": spawned.map(func(u: UnitState) -> String: return u.id)})


func _rules_where(predicate: Callable) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	out.assign(stage.rules.filter(predicate))
	return out


func _check_end() -> void:
	var heroes_alive := false
	var enemies_alive := false
	for u in ctx.units:
		if not u.alive:
			continue
		if u.team == UnitState.Team.PLAYER:
			heroes_alive = true
		else:
			enemies_alive = true
	if not heroes_alive:
		_finish(Result.LOSE)
	elif not enemies_alive:
		if wave_index + 1 < stage.waves.size():
			_spawn_next_wave()
		else:
			_finish(Result.WIN)
	elif ctx.time >= max_time:
		_finish(Result.LOSE)


func _finish(r: Result) -> void:
	result = r
	ctx.emit(&"battle_end", {"result": "win" if r == Result.WIN else "lose"})
