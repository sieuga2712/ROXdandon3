class_name ClassData
extends Resource

## One playable class. One class = one character (docs/khung-ky-thuat.md, decision 10).

@export var id: StringName
@export var display_name: String
## Base values for Stats.NAMES at level 1.
@export var base_stats: Dictionary = {}

@export_group("Fixed attributes")
@export var move_speed := 100.0
@export var attack_range := 60.0
## "physical" or "magic": what the basic attack deals.
@export var attack_type := "physical"
@export var mana_max := 100.0
@export var mana_per_attack := 5.0
@export var mana_per_hit_taken := 3.0

@export_group("Equipment")
## Item equip_tags this class may wear (section 7.1).
@export var equip_tags: PackedStringArray = []
## Layer Lab part types shown in hand, e.g. "Bow", "Sword" + "Shield".
@export var weapon_part := "Sword"
@export var offhand_part := ""

@export_group("Skills")
## Loadout of a new profile: 2 passives, 2 cooldown skills, 1 ultimate.
@export var default_passives: PackedStringArray = []
@export var default_actives: PackedStringArray = []
@export var default_ultimate: StringName


func can_wear(tag: String) -> bool:
	return equip_tags.has(tag)
