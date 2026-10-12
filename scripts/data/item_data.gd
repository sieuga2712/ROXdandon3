class_name ItemData
extends Resource

## Base item. Each owned copy lives in the profile inventory with its own
## enhance level (docs/khung-ky-thuat.md, section 7).

const SLOTS: PackedStringArray = ["weapon", "armor", "helmet", "accessory"]

@export var id: StringName
@export var display_name: String
## One of SLOTS.
@export var slot := "weapon"
## Who can wear it, e.g. "sword", "bow", "armor_balanced", "accessory".
@export var equip_tag := "sword"
## Stat name -> value at enhance level 0.
@export var stats: Dictionary = {}
