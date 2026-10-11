class_name Monster
extends Node2D

## Monster rig that reuses the Layer Lab character animations
## (scenes/monsters/monster_animations.tres, filtered from
## addons/layer_lab/minimal_character_maker/character/animations.tres).
##
## The animation tracks drive the pivot nodes (Body, Body/Head, HandRight/Sword,
## HandLeft/Shield, Shadow, Dead/...) with the character's absolute positions,
## so never move those pivots. Line each monster up by moving/rotating the
## "Art" Sprite2D children instead.

## Emitted by method tracks in the clips, e.g. "OnAttackHit" in Attack.
signal animation_event(function_name: String, string_parameter: String)

@export var default_animation: StringName = &"Idle"

var _initial_pose: Dictionary = {}

@onready var animation_player: AnimationPlayer = $AnimationPlayer


func _ready() -> void:
	_capture_initial_pose(self)
	if not String(default_animation).is_empty():
		play_animation(default_animation)


func get_animation_names() -> PackedStringArray:
	return animation_player.get_animation_list()


func has_animation(animation_name: StringName) -> bool:
	return animation_player.has_animation(animation_name)


## Restores the setup pose first, like the character runtime, so clips that
## fade parts out (Dead1-3) do not leak into the next clip.
func play_animation(animation_name: StringName, speed: float = 1.0) -> bool:
	if not animation_player.has_animation(animation_name):
		return false
	reset_pose()
	animation_player.play(animation_name, -1.0, speed)
	return true


func reset_pose() -> void:
	for item: Node2D in _initial_pose:
		if not is_instance_valid(item):
			continue
		var state: Dictionary = _initial_pose[item]
		item.position = state.position
		item.rotation = state.rotation
		item.scale = state.scale
		item.modulate.a = state.alpha


func set_facing_left(facing_left: bool) -> void:
	var magnitude := absf(scale.x)
	scale.x = -magnitude if facing_left else magnitude


func _on_animation_event(function_name: String, string_parameter: String = "") -> void:
	animation_event.emit(function_name, string_parameter)


func _capture_initial_pose(node: Node) -> void:
	for child in node.get_children():
		if child is Node2D:
			var item := child as Node2D
			_initial_pose[item] = {
				"position": item.position,
				"rotation": item.rotation,
				"scale": item.scale,
				"alpha": item.modulate.a,
			}
		_capture_initial_pose(child)
