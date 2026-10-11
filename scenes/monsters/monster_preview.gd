extends Node2D

## Test bench for monster rigs: lines up every slime variant and plays the
## same clip on all of them. Run this scene with F6.

const MONSTER_SCENES := [
	preload("res://scenes/monsters/slime/slime_green.tscn"),
	preload("res://scenes/monsters/slime/slime_king_green.tscn"),
	preload("res://scenes/monsters/slime/slime_stone_green.tscn"),
	preload("res://scenes/monsters/slime/slime_orange.tscn"),
	preload("res://scenes/monsters/slime/slime_king_orange.tscn"),
	preload("res://scenes/monsters/slime/slime_stone_orange.tscn"),
]

const ANIM_LABELS_VI := {
	"Idle": "Đứng yên",
	"Walk": "Đi bộ",
	"Run": "Chạy",
	"Attack": "Tấn công",
	"Double Attack": "Đánh 2 lần",
	"Jump": "Nhảy",
	"Stun": "Choáng",
	"Victory": "Thắng",
	"Dead1": "Chết 1",
	"Dead2": "Chết 2",
	"Dead3": "Chết 3",
}

var monsters: Array[Monster] = []
var facing_left := false

@onready var anim_flow: HFlowContainer = %AnimFlow
@onready var event_label: Label = %EventLabel


func _ready() -> void:
	var spacing := 160.0
	var start_x := 576.0 - spacing * (MONSTER_SCENES.size() - 1) * 0.5
	for i in MONSTER_SCENES.size():
		var monster := MONSTER_SCENES[i].instantiate() as Monster
		monster.position = Vector2(start_x + spacing * i, 430)
		monster.scale = Vector2.ONE * 1.6
		monster.animation_event.connect(_on_animation_event.bind(monster))
		add_child(monster)
		monsters.append(monster)

	for anim_name: String in ANIM_LABELS_VI:
		var btn := Button.new()
		btn.text = ANIM_LABELS_VI[anim_name]
		btn.focus_mode = Control.FOCUS_NONE
		btn.pressed.connect(_play_all.bind(StringName(anim_name)))
		anim_flow.add_child(btn)

	var flip := Button.new()
	flip.text = "Quay mặt"
	flip.focus_mode = Control.FOCUS_NONE
	flip.pressed.connect(_toggle_facing)
	anim_flow.add_child(flip)


func _play_all(anim_name: StringName) -> void:
	event_label.text = ""
	for monster in monsters:
		monster.play_animation(anim_name)


func _toggle_facing() -> void:
	facing_left = not facing_left
	for monster in monsters:
		monster.set_facing_left(facing_left)


func _on_animation_event(function_name: String, _string_parameter: String, monster: Monster) -> void:
	event_label.text = "%s: %s" % [monster.name, function_name]
