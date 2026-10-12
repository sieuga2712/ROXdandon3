class_name SkillData
extends Resource

## One skill in the shared skill pool (docs/khung-ky-thuat.md, section 4).
## Skills are data only: behaviour comes from `target` + `effects`.

enum Kind { PASSIVE, COOLDOWN, ULTIMATE }
enum When { ALWAYS, ON_ATTACK, ON_HIT_TAKEN, ON_LOW_HP }

@export var id: StringName
@export var display_name: String
@export var kind: Kind = Kind.COOLDOWN
## Empty = shared skill (any class, level counted per account).
@export var class_tags: PackedStringArray = []

@export_group("Trigger")
@export var when: When = When.ALWAYS
@export var chance := 0.0
@export var threshold := 0.3
@export var cooldown := 0.0
@export var start_cooldown := 0.0
@export var mana_cost := 0.0
@export var cast_time := 0.0
@export var cast_range := 0.0

@export_group("Targeting")
## One of Targeting.SELECTORS.
@export var target: StringName = &"nearest_enemy"
## 0 = all matching units.
@export var target_count := 1
@export var radius := 0.0

@export_group("Effects")
## Each entry: {"type": "damage", "scale": 1.2, ...}. See Effects for the keys.
@export var effects: Array[Dictionary] = []
## Damage dealt to a casting boss's break bar per target hit. Only crowd-control skills set this.
@export var break_power := 0.0
@export var animation: StringName = &"Attack"

@export_group("Levels")
## Per-level overrides, index 0 = level 1. Top-level keys override the fields above;
## an "effects" array overrides the effect at the same index key by key.
@export var levels: Array[Dictionary] = []


func can_equip(class_id: String) -> bool:
	return class_tags.is_empty() or class_tags.has(class_id)


func is_shared() -> bool:
	return class_tags.is_empty()


## Returns every number of this skill at [param level] (1-based) as a plain Dictionary.
func resolve(level: int = 1) -> Dictionary:
	var out := {
		"id": id, "kind": kind, "when": when, "chance": chance, "threshold": threshold,
		"cooldown": cooldown, "start_cooldown": start_cooldown, "mana_cost": mana_cost,
		"cast_time": cast_time, "cast_range": cast_range, "target": target,
		"target_count": target_count, "radius": radius, "break_power": break_power,
		"animation": animation,
	}
	var resolved_effects: Array[Dictionary] = []
	for e in effects:
		resolved_effects.append(e.duplicate())
	if levels.size() > 0:
		var override: Dictionary = levels[clampi(level - 1, 0, levels.size() - 1)]
		for key in override:
			if key == "effects":
				var effect_overrides: Array = override[key]
				for i in mini(effect_overrides.size(), resolved_effects.size()):
					resolved_effects[i].merge(effect_overrides[i], true)
			else:
				out[key] = override[key]
	out["effects"] = resolved_effects
	return out
