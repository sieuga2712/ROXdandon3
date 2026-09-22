@tool
class_name LayerLabMinimalCharacter
extends Node2D

## Layer Lab 2D Minimal Character Maker runtime.
##
## Mirrors the Unity [code]PartsManager[/code] behaviour on top of the converted
## [Sprite2D] rig: equipping, unequipping and hiding parts, colour targets,
## helmet-hair and arrow synchronisation, randomisation, presets and animation
## playback through the child [AnimationPlayer].

## Emitted after a part index changes. [param index] is -1 when the part is unequipped.
signal parts_changed(type_name: String, index: int)
## Emitted after a part visibility changes.
signal parts_visibility_changed(type_name: String, is_visible: bool)
## Emitted after a colour target changes.
signal color_changed(target: String, color: Color)
## Emitted when an animation event key fires (Unity AnimationEvent function name and string parameter).
signal animation_event(function_name: String, string_parameter: String)
## Emitted after [method play_animation] switches the current animation.
signal animation_changed(animation_name: String)

const CATALOG_PATH := "res://addons/layer_lab/minimal_character_maker/character/catalog.json"
const PRESETS_PATH := "res://addons/layer_lab/minimal_character_maker/character/presets.json"
const PARTS_PACK_DIRECTORY := "res://addons/layer_lab"
const PARTS_PACK_PREFIX := "minimal_character_parts_pack_"
const CONFIGURATION_VERSION := 1
const HAND_RIGHT_TYPES := ["Sword", "Axe", "Bow", "Wand", "Staff", "Spear", "Blunt", "Crossbow"]
const HAND_LEFT_TYPES := ["Shield", "SubItem"]
const COLOR_TARGETS := ["Skin", "Hair", "Eye", "Beard"]

static var _catalog_cache: Dictionary = {}
static var _presets_cache: Array = []
static var _texture_cache: Dictionary = {}

## Saved character configuration (schema version, parts, visibility, colours, animation).
## Applied automatically after [method initialize] when not empty.
@export_storage var configuration: Dictionary = {}
## Animation played after initialisation when [member configuration] does not specify one.
@export var default_animation: StringName = &"Idle"

var catalog: Dictionary = {}
## Current sprite index per parts type. -1 means the part is unequipped.
var active_indices: Dictionary = {}
## Visibility flag per parts type.
var visibility: Dictionary = {}
## Colour per colour target (Skin, Hair, Eye, Beard).
var colors: Dictionary = {}

var _initial_pose: Dictionary = {}
var _current_animation: StringName = &""
var _initialized := false


static func load_catalog() -> Dictionary:
	if _catalog_cache.is_empty():
		var base_catalog := _read_json(CATALOG_PATH)
		if not base_catalog.is_empty():
			_catalog_cache = base_catalog.duplicate(true)
			_merge_installed_parts_packs(_catalog_cache)
	return _catalog_cache


static func _merge_installed_parts_packs(base_catalog: Dictionary) -> void:
	var directory := DirAccess.open(PARTS_PACK_DIRECTORY)
	if directory == null:
		return
	var catalog_paths := PackedStringArray()
	directory.list_dir_begin()
	var folder_name := directory.get_next()
	while not folder_name.is_empty():
		if directory.current_is_dir() and folder_name.begins_with(PARTS_PACK_PREFIX):
			var catalog_path := PARTS_PACK_DIRECTORY.path_join(folder_name).path_join("catalog.json")
			if FileAccess.file_exists(catalog_path):
				catalog_paths.append(catalog_path)
		folder_name = directory.get_next()
	directory.list_dir_end()
	catalog_paths.sort()
	for catalog_path in catalog_paths:
		var parts_pack := _read_json(catalog_path)
		if parts_pack.is_empty():
			continue
		if String(parts_pack.get("requires_product", "")) != String(base_catalog.get("product_id", "")):
			push_warning("Layer Lab Minimal Character Maker: incompatible parts pack %s" % catalog_path)
			continue
		_merge_parts_pack(base_catalog, parts_pack)


static func _merge_parts_pack(base_catalog: Dictionary, parts_pack: Dictionary) -> void:
	var base_types: Dictionary = base_catalog.get("types", {})
	var pack_types: Dictionary = parts_pack.get("types", {})
	for type_name: String in pack_types:
		if not base_types.has(type_name):
			push_warning("Layer Lab Minimal Character Maker: unknown parts type %s" % type_name)
			continue
		var target: Dictionary = base_types[type_name]
		var base_sprite_count := int(target.get("sprite_count", 0))
		var target_renderers: Array = target.get("renderers", [])
		for extension_renderer: Dictionary in (pack_types[type_name] as Dictionary).get("renderers", []):
			var renderer_node := String(extension_renderer.get("node", ""))
			for renderer_index in target_renderers.size():
				var target_renderer: Dictionary = target_renderers[renderer_index]
				if String(target_renderer.get("node", "")) != renderer_node:
					continue
				var textures: Array = target_renderer.get("textures", [])
				textures.append_array((extension_renderer.get("textures", []) as Array).duplicate(true))
				target_renderer["textures"] = textures
				target_renderers[renderer_index] = target_renderer
				break
		var thumbnails: Array = target.get("thumbnails", [])
		# Expansion indices start immediately after the base sprite count. Normalize the
		# base thumbnail span first so unresolved legacy entries cannot shift those indices.
		thumbnails.resize(base_sprite_count)
		thumbnails.append_array(((pack_types[type_name] as Dictionary).get("thumbnails", []) as Array).duplicate(true))
		target["renderers"] = target_renderers
		target["thumbnails"] = thumbnails
		var sprite_count := 0
		for renderer: Dictionary in target_renderers:
			sprite_count = maxi(sprite_count, (renderer.get("textures", []) as Array).size())
		target["sprite_count"] = sprite_count
		base_types[type_name] = target
	base_catalog["types"] = base_types
	var installed: Array = base_catalog.get("installed_parts_packs", [])
	installed.append(String(parts_pack.get("product_id", "")))
	base_catalog["installed_parts_packs"] = installed


static func load_presets() -> Array:
	if _presets_cache.is_empty():
		var parsed := _read_json(PRESETS_PATH)
		_presets_cache = parsed.get("items", [])
	return _presets_cache


static func _read_json(path: String) -> Dictionary:
	var resource := load(path)
	if resource is JSON and (resource as JSON).data is Dictionary:
		return (resource as JSON).data
	if FileAccess.file_exists(path):
		var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
		if parsed is Dictionary:
			return parsed
	push_error("Layer Lab Minimal Character Maker: cannot read %s" % path)
	return {}


static func _load_texture(path: String) -> Texture2D:
	if path.is_empty():
		return null
	if not _texture_cache.has(path):
		_texture_cache[path] = load(path) as Texture2D
	return _texture_cache[path]


func _ready() -> void:
	if Engine.is_editor_hint():
		return
	# Do not revert parts that were already configured in code through initialize() before entering the tree.
	if not _initialized:
		initialize()
	if not configuration.is_empty():
		apply_configuration(configuration)
	elif not String(default_animation).is_empty():
		play_animation(default_animation)


## Rebuilds the catalog state and applies the Unity [code]PartsManager.Init()[/code] defaults.
func initialize() -> void:
	catalog = load_catalog()
	if catalog.is_empty():
		return
	if _initial_pose.is_empty():
		_capture_initial_pose(self)
	active_indices.clear()
	visibility.clear()
	colors.clear()
	for type_name: String in catalog.type_order:
		if not catalog.types.has(type_name):
			continue
		active_indices[type_name] = 0
		visibility[type_name] = true
	for ui_category: String in catalog.ui_categories:
		var members: Array = catalog.ui_categories[ui_category]
		if members.size() <= 1:
			continue
		for index in range(1, members.size()):
			if visibility.has(members[index]):
				visibility[members[index]] = false
	if visibility.has("Arrow"):
		visibility["Arrow"] = false
	if visibility.has("HelmetHair"):
		visibility["HelmetHair"] = false
	for target in COLOR_TARGETS:
		colors[target] = Color.WHITE
	for type_name: String in active_indices:
		var category: Dictionary = catalog.types[type_name]
		_apply_sprites(category, 0)
		if category.can_toggle:
			_set_renderers_visible(category, visibility[type_name])
	for target in COLOR_TARGETS:
		_apply_color(target, colors[target])
	_sync_helmet_hair_visibility(false)
	_initialized = true


func get_all_parts_types() -> PackedStringArray:
	var result := PackedStringArray()
	for type_name: String in catalog.get("type_order", []):
		if catalog.types.has(type_name):
			result.append(type_name)
	return result


func get_ui_categories() -> Dictionary:
	return catalog.get("ui_categories", {})


func get_display_name(type_name: String) -> String:
	return String(_category(type_name).get("display_name", type_name))


func can_toggle(type_name: String) -> bool:
	return bool(_category(type_name).get("can_toggle", false))


func can_change_color(type_name: String) -> bool:
	return bool(_category(type_name).get("can_change_color", false))


func get_color_target(type_name: String) -> String:
	return String(_category(type_name).get("color_target", "Skin"))


## Number of selectable sprites. Falls back to the thumbnail count like Unity when a category has no sprites.
func get_parts_count(type_name: String) -> int:
	var category := _category(type_name)
	if category.is_empty():
		return 0
	var count := int(category.sprite_count)
	return count if count > 0 else (category.thumbnails as Array).size()


func get_active_index(type_name: String) -> int:
	return int(active_indices.get(type_name, 0))


func is_parts_visible(type_name: String) -> bool:
	return bool(visibility.get(type_name, false))


func is_equipped(type_name: String) -> bool:
	return active_indices.has(type_name) and int(active_indices[type_name]) >= 0


## Thumbnail resource path for the parts list UI. Empty when Unity also has no thumbnail for that index.
func get_thumbnail_path(type_name: String, index: int) -> String:
	var category := _category(type_name)
	if category.is_empty():
		return ""
	var thumbnails: Array = category.thumbnails
	if not thumbnails.is_empty():
		if index < 0 or index >= thumbnails.size():
			return ""
		return String((thumbnails[index] as Dictionary).get("path", ""))
	var renderers: Array = category.renderers
	if renderers.is_empty():
		return ""
	var textures: Array = (renderers[0] as Dictionary).textures
	if index < 0 or index >= textures.size():
		return ""
	return String((textures[index] as Dictionary).get("path", ""))


func get_thumbnail(type_name: String, index: int) -> Texture2D:
	return _load_texture(get_thumbnail_path(type_name, index))


## Equips [param index] (clamped to the valid range) and restores visibility when the part was unequipped.
func equip_parts(type_name: String, index: int) -> void:
	var category := _category(type_name)
	if category.is_empty():
		return
	var count := get_parts_count(type_name)
	if count == 0:
		return
	index = clampi(index, 0, count - 1)
	active_indices[type_name] = index
	_apply_sprites(category, index)
	if category.can_toggle and visibility.has(type_name) and not visibility[type_name]:
		visibility[type_name] = true
		_set_renderers_visible(category, true)
		parts_visibility_changed.emit(type_name, true)
	parts_changed.emit(type_name, index)
	if type_name in HAND_RIGHT_TYPES:
		_sync_arrow_visibility()
	if type_name == "Hair":
		var helmet_hair := _category("HelmetHair")
		if not helmet_hair.is_empty() and index < int(helmet_hair.sprite_count):
			active_indices["HelmetHair"] = index
			_apply_sprites(helmet_hair, index)
	if type_name == "Helmet":
		_sync_helmet_hair_visibility()


## Unequips a toggleable part (index -1, hidden).
func unequip_parts(type_name: String) -> void:
	var category := _category(type_name)
	if category.is_empty() or not category.can_toggle:
		return
	active_indices[type_name] = -1
	visibility[type_name] = false
	_set_renderers_visible(category, false)
	parts_changed.emit(type_name, -1)
	parts_visibility_changed.emit(type_name, false)
	if type_name == "Bow" or type_name == "Crossbow":
		_sync_arrow_visibility()
	if type_name == "Helmet":
		_sync_helmet_hair_visibility()


## Shows or hides a toggleable part without changing its index.
func toggle_parts(type_name: String, is_visible: bool) -> void:
	var category := _category(type_name)
	if category.is_empty() or not category.can_toggle:
		return
	visibility[type_name] = is_visible
	_set_renderers_visible(category, is_visible)
	parts_visibility_changed.emit(type_name, is_visible)
	if type_name in HAND_RIGHT_TYPES:
		_sync_arrow_visibility()
	if type_name == "Helmet" or type_name == "Hair":
		_sync_helmet_hair_visibility()


func next_parts(type_name: String) -> void:
	var count := get_parts_count(type_name)
	if count == 0:
		return
	equip_parts(type_name, posmod(get_active_index(type_name) + 1, count))


func prev_parts(type_name: String) -> void:
	var count := get_parts_count(type_name)
	if count == 0:
		return
	equip_parts(type_name, posmod(get_active_index(type_name) - 1, count))


func get_color(target: String) -> Color:
	return colors.get(target, Color.WHITE)


func set_color(target: String, color: Color) -> void:
	if target not in COLOR_TARGETS:
		push_warning("Unknown colour target: %s" % target)
		return
	colors[target] = color
	_apply_color(target, color)
	color_changed.emit(target, color)


## Re-runs [method initialize] and re-emits every change signal so UI listeners resynchronise.
func reset_all() -> void:
	initialize()
	for type_name: String in active_indices:
		parts_changed.emit(type_name, int(active_indices[type_name]))
		parts_visibility_changed.emit(type_name, bool(visibility[type_name]))
	for target: String in colors:
		color_changed.emit(target, colors[target])


## Unity [code]RandomizeAll[/code]: one random weapon per hand group, 50% chance to drop beard/helmet, random colours.
func randomize_all() -> void:
	var group_picks := {}
	for ui_category: String in catalog.ui_categories:
		var members: Array = catalog.ui_categories[ui_category]
		if members.size() <= 1:
			continue
		var candidates: Array = []
		for member: String in members:
			if get_parts_count(member) > 0:
				candidates.append(member)
		if not candidates.is_empty():
			group_picks[ui_category] = candidates[randi_range(0, candidates.size() - 1)]
	for type_name: String in get_all_parts_types():
		if type_name == "HelmetHair" or type_name == "Arrow":
			continue
		var count := get_parts_count(type_name)
		if count == 0:
			continue
		if type_name == "Beard" or type_name == "Helmet":
			if randf() < 0.5:
				unequip_parts(type_name)
				continue
			if visibility.has(type_name) and not visibility[type_name]:
				toggle_parts(type_name, true)
		if type_name in HAND_RIGHT_TYPES:
			var picked_right: bool = group_picks.get("HandRight", "") == type_name
			toggle_parts(type_name, picked_right)
			if picked_right:
				equip_parts(type_name, randi_range(0, count - 1))
			continue
		if type_name in HAND_LEFT_TYPES:
			var picked_left: bool = group_picks.get("HandLeft", "") == type_name
			toggle_parts(type_name, picked_left)
			if picked_left:
				equip_parts(type_name, randi_range(0, count - 1))
			continue
		equip_parts(type_name, randi_range(0, count - 1))
	randomize_colors()


## Random Skin, Hair and Beard colours (hue 0-1, saturation 0.4-1, value 0.5-1), like Unity.
func randomize_colors() -> void:
	for target in COLOR_TARGETS:
		if target == "Eye":
			continue
		set_color(target, Color.from_hsv(randf(), randf_range(0.4, 1.0), randf_range(0.5, 1.0)))


func copy_from(other: LayerLabMinimalCharacter) -> void:
	if other == null:
		return
	for type_name: String in other.active_indices:
		equip_parts(type_name, int(other.active_indices[type_name]))
	for type_name: String in other.visibility:
		toggle_parts(type_name, bool(other.visibility[type_name]))
	for target: String in other.colors:
		set_color(target, other.colors[target])


## Applies a Unity preset item ({"is_empty", "parts", "colors", "visibility"}), skipping auto-synced parts.
func apply_preset(item: Dictionary) -> void:
	if item.is_empty() or bool(item.get("is_empty", false)):
		return
	for entry: Dictionary in item.get("parts", []):
		var type_name := String(entry.type)
		if int(entry.index) < 0:
			unequip_parts(type_name)
		else:
			equip_parts(type_name, int(entry.index))
	for entry: Dictionary in item.get("colors", []):
		var channels: Array = entry.color
		set_color(String(entry.target), Color(channels[0], channels[1], channels[2], channels[3]))
	for entry: Dictionary in item.get("visibility", []):
		var type_name := String(entry.type)
		if type_name == "Arrow" or type_name == "HelmetHair":
			continue
		toggle_parts(type_name, bool(entry.visible))
	_sync_arrow_visibility()
	_sync_helmet_hair_visibility()


func to_preset() -> Dictionary:
	var parts: Array = []
	for type_name: String in active_indices:
		parts.append({"type": type_name, "index": int(active_indices[type_name])})
	var color_entries: Array = []
	for target: String in colors:
		var color: Color = colors[target]
		color_entries.append({"target": target, "color": [color.r, color.g, color.b, color.a]})
	var visibility_entries: Array = []
	for type_name: String in visibility:
		visibility_entries.append({"type": type_name, "visible": bool(visibility[type_name])})
	return {"is_empty": false, "parts": parts, "colors": color_entries, "visibility": visibility_entries}


## Serialisable configuration for saved scenes.
func get_configuration() -> Dictionary:
	var preset := to_preset()
	return {
		"version": CONFIGURATION_VERSION,
		"parts": preset.parts,
		"colors": preset.colors,
		"visibility": preset.visibility,
		"animation": String(_current_animation),
	}


func apply_configuration(config: Dictionary) -> bool:
	if config.is_empty():
		push_error("Character configuration is empty.")
		return false
	var version := int(config.get("version", CONFIGURATION_VERSION))
	if version > CONFIGURATION_VERSION:
		push_error("Unsupported character configuration version: %d" % version)
		return false
	if not _initialized:
		initialize()
	apply_preset({"is_empty": false, "parts": config.get("parts", []), "colors": config.get("colors", []), "visibility": config.get("visibility", [])})
	var animation_name := String(config.get("animation", ""))
	if animation_name.is_empty():
		animation_name = String(default_animation)
	if not animation_name.is_empty():
		play_animation(StringName(animation_name))
	return true


func get_animation_player() -> AnimationPlayer:
	return get_node_or_null("AnimationPlayer") as AnimationPlayer


## Animation names in the Unity Animator controller order.
func get_animation_names() -> PackedStringArray:
	var player := get_animation_player()
	var result := PackedStringArray()
	if player == null:
		return result
	var available := player.get_animation_list()
	for animation_name: String in catalog.get("animations", []):
		if animation_name in available:
			result.append(animation_name)
	for animation_name in available:
		if animation_name not in result:
			result.append(animation_name)
	return result


func has_animation(animation_name: StringName) -> bool:
	var player := get_animation_player()
	return player != null and player.has_animation(animation_name)


func get_current_animation() -> String:
	return String(_current_animation)


## Restores the setup pose (Unity Animator "Write Defaults") and plays [param animation_name].
func play_animation(animation_name: StringName, speed: float = 1.0) -> bool:
	var player := get_animation_player()
	if player == null or not player.has_animation(animation_name):
		return false
	reset_pose()
	player.play(animation_name, -1.0, speed)
	_current_animation = animation_name
	animation_changed.emit(String(animation_name))
	return true


func stop_animation(reset_to_setup_pose: bool = true) -> void:
	var player := get_animation_player()
	if player != null:
		player.stop()
	if reset_to_setup_pose:
		reset_pose()


## Restores transform and alpha values captured from the converted prefab pose.
func reset_pose() -> void:
	if _initial_pose.is_empty():
		_capture_initial_pose(self)
	for node: Node in _initial_pose:
		if not is_instance_valid(node):
			continue
		var state: Dictionary = _initial_pose[node]
		var item := node as Node2D
		item.position = state.position
		item.rotation = state.rotation
		item.scale = state.scale
		if item is Sprite2D:
			var modulate_value: Color = item.modulate
			modulate_value.a = state.alpha
			item.modulate = modulate_value


func set_facing_left(facing_left: bool) -> void:
	var magnitude := absf(scale.x)
	scale.x = -magnitude if facing_left else magnitude


func _on_animation_event(function_name: String, string_parameter: String = "") -> void:
	animation_event.emit(function_name, string_parameter)


func _category(type_name: String) -> Dictionary:
	var types: Dictionary = catalog.get("types", {})
	return types.get(type_name, {})


func _renderer_node(path: String) -> Sprite2D:
	return get_node_or_null(NodePath(path)) as Sprite2D


func _apply_sprites(category: Dictionary, index: int) -> void:
	for renderer: Dictionary in category.renderers:
		var textures: Array = renderer.textures
		if textures.is_empty():
			continue
		var sprite := _renderer_node(String(renderer.node))
		if sprite == null:
			continue
		# Static decoration renderers (Bow_Line_Up etc.) hold one sprite and clamp to index 0 like Unity.
		var use_index := 0 if index < 0 else (index if index < textures.size() else 0)
		var entry: Dictionary = textures[use_index]
		sprite.texture = _load_texture(String(entry.path))
		var offset_values: Array = entry.get("offset", [0.0, 0.0])
		sprite.offset = Vector2(float(offset_values[0]), float(offset_values[1]))


func _set_renderers_visible(category: Dictionary, is_visible: bool) -> void:
	for renderer: Dictionary in category.renderers:
		var sprite := _renderer_node(String(renderer.node))
		if sprite != null:
			sprite.visible = is_visible


func _apply_color(target: String, color: Color) -> void:
	var color_renderers: Dictionary = catalog.get("color_renderers", {})
	for path: String in color_renderers.get(target, []):
		var sprite := _renderer_node(path)
		if sprite != null:
			# SpriteRenderer colors are independent in Unity. Godot `modulate` cascades to
			# child CanvasItems, so part RGB must use `self_modulate` to keep Skin from
			# tinting Head children such as Eye, Hair and Beard.
			var self_modulate_value := color
			self_modulate_value.a = sprite.self_modulate.a
			sprite.self_modulate = self_modulate_value


func _sync_arrow_visibility() -> void:
	var arrow := _category("Arrow")
	if arrow.is_empty():
		return
	var bow_visible := bool(visibility.get("Bow", false))
	var crossbow_visible := bool(visibility.get("Crossbow", false))
	for renderer: Dictionary in arrow.renderers:
		var sprite := _renderer_node(String(renderer.node))
		if sprite == null:
			continue
		sprite.visible = crossbow_visible if sprite.name == "Bolt" else bow_visible
	var show_any := bow_visible or crossbow_visible
	visibility["Arrow"] = show_any
	parts_visibility_changed.emit("Arrow", show_any)


func _sync_helmet_hair_visibility(emit: bool = true) -> void:
	var helmet_hair := _category("HelmetHair")
	var hair := _category("Hair")
	if helmet_hair.is_empty() or hair.is_empty():
		return
	var hair_wanted := bool(visibility.get("Hair", false))
	var helmet_visible := bool(visibility.get("Helmet", false))
	if hair_wanted and helmet_visible:
		_set_renderers_visible(hair, false)
		_set_renderers_visible(helmet_hair, true)
		visibility["HelmetHair"] = true
	elif hair_wanted:
		_set_renderers_visible(hair, true)
		_set_renderers_visible(helmet_hair, false)
		visibility["HelmetHair"] = false
	else:
		_set_renderers_visible(hair, false)
		_set_renderers_visible(helmet_hair, false)
		visibility["HelmetHair"] = false
	if emit:
		parts_visibility_changed.emit("HelmetHair", bool(visibility["HelmetHair"]))


func _capture_initial_pose(node: Node) -> void:
	for child in node.get_children():
		if child is Node2D and not child is AnimationPlayer:
			var item := child as Node2D
			var state := {
				"position": item.position,
				"rotation": item.rotation,
				"scale": item.scale,
				"alpha": item.modulate.a,
			}
			_initial_pose[item] = state
		_capture_initial_pose(child)
