extends Node2D

## Minimal example: instance the converted character, apply a Unity preset,
## change parts and colours from code, and cycle animations with the keyboard.

@onready var character: LayerLabMinimalCharacter = $MinimalCharacter
var _animation_index := 0


func _ready() -> void:
	character.position = get_viewport_rect().size * Vector2(0.5, 0.6)
	# Unity DemoScene: instance scale 2.0872 at 108 px/unit (1080p) → 2.254 screen px per texture px.
	character.scale = Vector2.ONE * 2.0872 * 1.08
	var presets := LayerLabMinimalCharacter.load_presets()
	if not presets.is_empty():
		character.apply_preset(presets[0])
	character.equip_parts("Helmet", 3)
	character.set_color("Hair", Color("7DE8A7"))
	character.animation_event.connect(func(function_name: String, _parameter: String) -> void: print("Animation event: %s" % function_name))
	character.play_animation(&"Idle")


func _unhandled_input(event: InputEvent) -> void:
	if not event is InputEventKey or not (event as InputEventKey).pressed:
		return
	var key := event as InputEventKey
	var names := character.get_animation_names()
	match key.keycode:
		KEY_SPACE:
			_animation_index = posmod(_animation_index + 1, names.size())
			character.play_animation(StringName(names[_animation_index]))
		KEY_R:
			character.randomize_all()
		KEY_H:
			character.toggle_parts("Helmet", not character.is_parts_visible("Helmet"))
		KEY_F:
			character.set_facing_left(character.scale.x > 0.0)
