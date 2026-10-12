class_name MonsterData
extends Resource

## One monster type. Monsters only use basic attacks and cooldown skills (decision 7).

@export var id: StringName
@export var display_name: String
@export var base_stats: Dictionary = {}
@export var move_speed := 70.0
@export var attack_range := 50.0
@export var attack_type := "physical"
## Cooldown skills (SkillData ids). Boss skills with cast_time are the ones the break bar can stop.
@export var skills: PackedStringArray = []
## Rig scene from scenes/monsters/.
@export var scene: PackedScene

@export_group("Boss")
@export var is_boss := false
## 0 = no break bar.
@export var break_max := 0.0
@export var break_lock := 4.0
