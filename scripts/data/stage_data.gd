class_name StageData
extends Resource

## A stage or a daily dungeon (docs/khung-ky-thuat.md, section 8).

@export var id: StringName
@export var display_name: String
@export var chapter := 1
## True for daily dungeons; they do not count for idle progress.
@export var is_daily := false
## Each wave: {"monsters": [{"id": "slime_green", "row": 0}, ...]}. Row 0 = front.
@export var waves: Array[Dictionary] = []
## Stage requirements, see StageRules.
@export var rules: Array[Dictionary] = []
## Clear reward: {"gold": 100, "gem_0": 2, ...}.
@export var rewards: Dictionary = {}
## Idle reward per hour once this is the highest cleared stage.
@export var idle_rate: Dictionary = {}
