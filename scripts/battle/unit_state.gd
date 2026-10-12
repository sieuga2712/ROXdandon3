class_name UnitState
extends RefCounted

## One hero or monster inside BattleSim. Pure data, no Node.

enum Team { PLAYER, ENEMY }

var id: String
var team: Team
var class_id: String
var row := 0
var x := 0.0
var move_speed := 100.0
var attack_range := 50.0
var is_boss := false

var stats: Stats
var hp := 1.0
var mana := 0.0
var mana_max := 100.0
var alive := true

## [{amount, expires_at}], used up oldest first.
var shields: Array[Dictionary] = []
## name -> {expires_at, ...}. Names: stun, slow, taunt, undying.
var statuses: Dictionary = {}
## [{mod_id, expires_at}] for buffs/debuffs from skills.
var timed_mods: Array[Dictionary] = []
var pending_extra_attacks := 0

## Break bar (boss only, section 6.3). break_max = 0 means no bar.
var break_max := 0.0
var break_value := 0.0
var break_lock := 3.0
var break_locked_until := -1.0

## Skill being cast: {} when idle, else {"skill": Dictionary, "finish_at": float}.
var casting: Dictionary = {}

## --- Set up by UnitFactory, driven by BattleSim ---
var is_monster := false
var attack_type := "physical"
var mana_per_attack := 0.0
var mana_per_hit_taken := 0.0
## Damage types this unit takes no damage from (stage rule enemy_immune).
var immune_types: PackedStringArray = []
## Resolved skill Dictionaries (SkillData.resolve). Cooldown/ultimate ones get a "ready_at" key.
var passives: Array[Dictionary] = []
var actives: Array[Dictionary] = []
var ultimate: Dictionary = {}
var auto_ultimate := true
var ultimate_requested := false
var next_attack_at := 0.0
var low_hp_fired: Dictionary = {}


func _init(p_id: String, p_team: Team, p_stats: Stats) -> void:
	id = p_id
	team = p_team
	stats = p_stats
	hp = max_hp()


func max_hp() -> float:
	return stats.get_value("hp")


func hp_ratio() -> float:
	return hp / max_hp()


func is_enemy_of(other: UnitState) -> bool:
	return team != other.team


func has_status(name: String) -> bool:
	return statuses.has(name)


func is_casting() -> bool:
	return not casting.is_empty()


## Attack speed and move speed after slow.
func current_atsp() -> float:
	return stats.get_value("atsp") * (1.0 - _slow_value())


func current_move_speed() -> float:
	return move_speed * (1.0 - _slow_value())


func ultimate_ready(now: float) -> bool:
	return not ultimate.is_empty() and now >= ultimate.ready_at and mana >= ultimate.mana_cost


func add_mana(amount: float) -> void:
	if not is_monster:
		mana = clampf(mana + amount, 0.0, mana_max)


func total_shield() -> float:
	var total := 0.0
	for s in shields:
		total += s.amount
	return total


## Removes expired statuses, shields and timed modifiers.
func expire(now: float) -> void:
	for key in statuses.keys():
		if statuses[key].expires_at <= now:
			statuses.erase(key)
	shields.assign(shields.filter(func(s: Dictionary) -> bool: return s.expires_at > now and s.amount > 0.0))
	var kept: Array[Dictionary] = []
	for m in timed_mods:
		if m.expires_at <= now:
			stats.remove_modifier(m.mod_id)
		else:
			kept.append(m)
	timed_mods = kept
	hp = minf(hp, max_hp())


func _slow_value() -> float:
	if statuses.has("slow"):
		return clampf(statuses.slow.value, 0.0, 0.9)
	return 0.0
