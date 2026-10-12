class_name Stats
extends RefCounted

## Stat block of one unit (docs/khung-ky-thuat.md, section 5).
##
## Final value = (base + sum of flat) * (1 + sum of percent), then clamped to
## the stat's cap. Every source (class base, item, passive, in-battle buff)
## pushes a modifier; nothing writes the final values directly.

const NAMES: PackedStringArray = [
	"atk", "matk", "hp", "def", "mdef", "atsp", "crit", "crit_dmg",
	"cc_resist", "mana_regen", "lifesteal", "damage_taken",
]

const DEFAULTS := {
	"atk": 0.0, "matk": 0.0, "hp": 1.0, "def": 0.0, "mdef": 0.0,
	"atsp": 1.0, "crit": 0.0, "crit_dmg": 1.5, "cc_resist": 0.0,
	"mana_regen": 0.0, "lifesteal": 0.0, "damage_taken": 1.0,
}

## [min, max] per stat. Values are starting points; tune them with the rest of the data.
static var caps := {
	"hp": [1.0, INF],
	"atsp": [0.1, 5.0],
	"crit": [0.0, 1.0],
	"crit_dmg": [1.0, 10.0],
	"cc_resist": [0.0, 0.6],
	"lifesteal": [0.0, 1.0],
	"damage_taken": [0.1, 5.0],
}

enum Mode { FLAT, PERCENT }
enum StackRule { STACK, HIGHEST }

var _base: Dictionary = DEFAULTS.duplicate()
var _modifiers: Array[Dictionary] = []
var _next_id := 1


func _init(base: Dictionary = {}) -> void:
	for key in base:
		set_base(key, base[key])


func set_base(stat: String, value: float) -> void:
	assert(stat in NAMES, "Unknown stat: %s" % stat)
	_base[stat] = value


func get_base(stat: String) -> float:
	return _base.get(stat, 0.0)


## Returns the modifier id, used to remove it later.
func add_modifier(stat: String, value: float, mode: Mode = Mode.FLAT,
		source_id: String = "", stack_rule: StackRule = StackRule.STACK) -> int:
	assert(stat in NAMES, "Unknown stat: %s" % stat)
	var id := _next_id
	_next_id += 1
	_modifiers.append({
		"id": id, "stat": stat, "value": value, "mode": mode,
		"source_id": source_id, "stack_rule": stack_rule,
	})
	return id


func remove_modifier(id: int) -> void:
	for i in _modifiers.size():
		if _modifiers[i].id == id:
			_modifiers.remove_at(i)
			return


func remove_source(source_id: String) -> void:
	_modifiers.assign(_modifiers.filter(func(m: Dictionary) -> bool: return m.source_id != source_id))


func get_value(stat: String) -> float:
	var flat := 0.0
	var percent := 0.0
	# HIGHEST modifiers only count the largest value per (source, mode).
	var highest := {}
	for m in _modifiers:
		if m.stat != stat:
			continue
		if m.stack_rule == StackRule.HIGHEST:
			var key := "%s|%d" % [m.source_id, m.mode]
			if not highest.has(key) or m.value > highest[key].value:
				highest[key] = m
			continue
		if m.mode == Mode.FLAT:
			flat += m.value
		else:
			percent += m.value
	for m in highest.values():
		if m.mode == Mode.FLAT:
			flat += m.value
		else:
			percent += m.value
	var value: float = (get_base(stat) + flat) * (1.0 + percent)
	if caps.has(stat):
		value = clampf(value, caps[stat][0], caps[stat][1])
	return value
