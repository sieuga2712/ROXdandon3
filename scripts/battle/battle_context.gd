class_name BattleContext
extends RefCounted

## Shared state of one battle: clock, seeded RNG, units and the event log
## that BattleView (and tests) read.

var time := 0.0
var rng := RandomNumberGenerator.new()
var units: Array[UnitState] = []
var events: Array[Dictionary] = []


func _init(seed_value: int = 0) -> void:
	rng.seed = seed_value


func emit(type: StringName, data: Dictionary = {}) -> void:
	data["type"] = type
	data["time"] = time
	events.append(data)


func alive_units() -> Array[UnitState]:
	var out: Array[UnitState] = []
	out.assign(units.filter(func(u: UnitState) -> bool: return u.alive))
	return out


func find(unit_id: String) -> UnitState:
	for u in units:
		if u.id == unit_id:
			return u
	return null
