class_name GameConfig
extends Resource

## Global numbers that are not tied to one class/skill/item. data/config.tres.

@export_group("Battle")
## K in damage × K / (K + def).
@export var defense_k := 100.0
## Stun on a boss when its break bar breaks.
@export var break_stun := 1.0
## Stat caps: stat -> [min, max]. Overrides Stats.caps.
@export var stat_caps: Dictionary = {}

@export_group("Enhance")
## Each enhance level adds this share of the item's base stats (linear).
@export var enhance_bonus := 0.05
## Stats that enhance does not scale. Empty = everything scales (decision 19).
@export var enhance_excluded_stats: PackedStringArray = []

@export_group("Idle and daily")
@export var idle_max_hours := 12.0
@export var daily_attempts := 3
## Weekday (0 = Sunday, like Time.get_datetime_dict_from_unix_time) -> daily stage ids.
@export var daily_schedule: Dictionary = {}


func apply_to_battle() -> void:
	Effects.defense_k = defense_k
	Effects.break_stun = break_stun
	for stat in stat_caps:
		Stats.caps[stat] = stat_caps[stat]
