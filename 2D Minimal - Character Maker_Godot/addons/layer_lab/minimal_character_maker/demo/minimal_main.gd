extends Node2D

## Godot reconstruction of the 2D Minimal-CharacterMaker `DemoScene.unity` scene.
## Coordinates use the Unity Canvas 1920x1080 top-left pixel origin and extracted layout values.

const TMP_OUTLINE_SMALL := 4
const TMP_OUTLINE_STANDARD := 12
const TMP_OUTLINE_LARGE := 12
const PRESET_SLOT_COUNT := 10
const HIDDEN_ALPHA := 0.3
const FAVORITE_SLOT_COUNT := 20
const FAVORITES_PATH := "user://minimal_character_maker_favorite_colors.json"
const SAVED_SCENE_DIRECTORY := "res://layer_lab_generated/minimal_character_maker"
const BUTTON_FEEDBACK_HOVER_SCALE := 1.025
const BUTTON_FEEDBACK_PRESSED_SCALE := 0.94
const BUTTON_FEEDBACK_HOVER_TINT := Color(1.08, 1.08, 1.08, 1.0)
const BUTTON_FEEDBACK_PRESSED_TINT := Color(0.70, 0.84, 1.0, 1.0)
const BUTTON_FEEDBACK_HOVER_DURATION := 0.08
const BUTTON_FEEDBACK_RELEASE_DURATION := 0.14
const BUTTON_FEEDBACK_MARKER := &"layer_lab_button_feedback"
const BUTTON_FEEDBACK_BASE_SCALE := &"layer_lab_button_feedback_base_scale"
const BUTTON_FEEDBACK_BASE_MODULATE := &"layer_lab_button_feedback_base_modulate"
const BUTTON_FEEDBACK_HOVERED := &"layer_lab_button_feedback_hovered"
const BUTTON_FEEDBACK_POINTER_DOWN := &"layer_lab_button_feedback_pointer_down"
const BUTTON_FEEDBACK_TWEEN := &"layer_lab_button_feedback_tween"
const CHARACTER_SCENE := "res://addons/layer_lab/minimal_character_maker/character/minimal_character.tscn"
const MinimalCharacter := preload("res://addons/layer_lab/minimal_character_maker/runtime/minimal_character.gd")
const FONT_PATH := "res://addons/layer_lab/minimal_character_maker/demo/fonts/art_maker_ui_bitmap_64.fnt"
const OUTLINE_FONT_PATH := "res://addons/layer_lab/minimal_character_maker/demo/fonts/art_maker_ui_bitmap_outline_64.fnt"
const UI_ROOT := "res://addons/layer_lab/minimal_character_maker/demo/assets/ui/"
# Unity: Main Camera (1.57, 0.85), orthographic size 5, 108 px/unit, character instance scale 2.0872.
const PIXELS_PER_UNIT := 108.0
const CHARACTER_SCREEN_POSITION := Vector2(790.44, 631.8)
const CHARACTER_SCALE := 2.0872 * 1.08
const MAP_SCREEN_POSITION := Vector2(952.44, 544.32)
const PATH_DISCORD := "https://discord.gg/qCsVSHHcY7"
const PATH_FACEBOOK := "https://www.facebook.com/layerlab"
const PATH_YOUTUBE := "https://www.youtube.com/@LayerlabGameAssets"
const UI_CATEGORY_ORDER := ["Hair", "Eye", "Beard", "Skin", "Helmet", "Chest", "HandRight", "HandLeft"]
const SLOT_POSITIONS := {
	"Hair": Vector2(1314.97, 206.02), "Eye": Vector2(1418.97, 206.02), "Beard": Vector2(1522.97, 206.02), "Skin": Vector2(1314.97, 312.02),
	"Helmet": Vector2(1314.97, 463.22), "Chest": Vector2(1418.97, 463.22), "HandRight": Vector2(1522.97, 463.22), "HandLeft": Vector2(1314.97, 569.22),
}
const SLOT_ICON_RECTS := {
	"Hair": Rect2(14.5, 26.5, 67, 45), "Eye": Rect2(18.5, 28.5, 59, 41), "Beard": Rect2(13, 34, 70, 30), "Skin": Rect2(15.5, 24, 65, 50),
	"Helmet": Rect2(20, 21.5, 56, 55), "Chest": Rect2(14, 23.5, 68, 51), "HandRight": Rect2(21, 23, 54, 52), "HandLeft": Rect2(20.5, 21.5, 55, 55),
}
const LIST_TITLES := {"HandRight": "HAND RIGHT", "HandLeft": "HAND LEFT"}
const COLOR_PRESETS_1 := ["222121", "592E2F", "604535", "8C7A74", "8C7A74", "C7A275", "F3B840", "FCFDED", "E57130", "99220E", "E33C77", "EF9ECE", "875BF1", "3252AC", "84B9F1", "3A7A5E"]
const COLOR_PRESETS_2 := ["FAC9AC", "EAA888", "DBA77B", "BF8670", "D77762", "B5805F", "A57860", "B46941", "744D45", "67403B", "93B26A", "A4C9DA"]

var font: FontFile
var outline_font: FontFile
var character: MinimalCharacter
var ui_root: Control
var background: Sprite2D
var presets: Array = []
var preset_index := 0
var selected_category := ""
var focused_category := ""
var last_visible_type := {}
var active_list_type := ""
var slot_views := {}
var list_cells: Array = []
var list_select_frame: TextureRect
var list_reset_button: TextureButton
var list_title: Label
var list_grid: GridContainer
var list_scroll: ScrollContainer
var list_background: ColorRect
var color_picker: Control
var picker_target := "Hair"
var picker_hue := 0.0
var picker_saturation := 0.0
var picker_value := 1.0
var saturation_value_area: ColorRect
var saturation_value_pointer: TextureRect
var hue_pointer: TextureRect
var hue_hit_area: Control
var preview_color: ColorRect
var hex_input: LineEdit
var favorite_colors: Array = []
var favorite_focus := -1
var favorite_views: Array = []
var preset_number: Label
var animation_buttons: Array = []
var focus_frame: NinePatchRect
var select_frame: NinePatchRect
var arrow_previous: Control
var arrow_next: Control
var save_button: Button
var dragging_saturation := false
var dragging_hue := false
var audit_category := ""
var audit_random := false
var audit_preset := -1
var audit_skin_color := ""
var audit_button_feedback := false


func _ready() -> void:
	_parse_arguments()
	font = load(FONT_PATH) as FontFile
	outline_font = load(OUTLINE_FONT_PATH) as FontFile
	RenderingServer.set_default_clear_color(Color(0.15, 0.15, 0.15))
	if has_node("UI/Canvas"):
		_bind_serialized_scene()
		_connect_serialized_ui()
	else:
		_build_world()
		_build_ui()
	character.initialize()
	presets = MinimalCharacter.load_presets()
	_load_favorites()
	_connect_character()
	_apply_preset(0)
	if audit_skin_color.length() == 6 and audit_skin_color.is_valid_html_color():
		character.set_color("Skin", Color.html(audit_skin_color))
	if audit_random:
		_randomize_character()
	if audit_preset >= 0:
		_apply_preset(audit_preset)
	_select_category(audit_category if audit_category != "" else "Hair")
	_play_animation("Idle")
	_refresh_all()
	_register_button_feedback_tree(ui_root)
	if audit_button_feedback:
		_on_button_feedback_down(save_button)


func _parse_arguments() -> void:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--audit-category="):
			audit_category = argument.trim_prefix("--audit-category=")
		elif argument == "--audit-random":
			audit_random = true
		elif argument.begins_with("--audit-preset="):
			audit_preset = int(argument.trim_prefix("--audit-preset="))
		elif argument.begins_with("--audit-skin-color="):
			audit_skin_color = argument.trim_prefix("--audit-skin-color=").trim_prefix("#")
		elif argument == "--audit-button-feedback":
			audit_button_feedback = true


## Resets machine-local state before the editor-visible preview is serialized by the project builder.
func _prepare_serialized_preview() -> void:
	favorite_colors.resize(FAVORITE_SLOT_COUNT)
	favorite_colors.fill(null)
	favorite_focus = -1
	_refresh_favorites()
	_apply_preset(0)
	if selected_category != "Hair":
		selected_category = ""
		_select_category("Hair")
	_play_animation("Idle")
	_refresh_all()
	_clear_button_feedback_for_serialization()


## Binds the editor-visible node hierarchy stored in `main.tscn`.
## Dynamic list cells are rebuilt from the installed catalog during `_refresh_list()`.
func _bind_serialized_scene() -> void:
	background = get_node("Map") as Sprite2D
	character = get_node("Character") as MinimalCharacter
	ui_root = get_node("UI/Canvas") as Control
	slot_views.clear()
	for ui_category: String in UI_CATEGORY_ORDER:
		var cell := ui_root.get_node("Slot%s" % ui_category) as Control
		slot_views[ui_category] = {
			"cell": cell,
			"background": cell.get_node("Select"),
			"icon": cell.get_node("Icon"),
			"item": cell.get_node("Item"),
			"eye": cell.get_node("VisibilityButton"),
		}
	arrow_previous = ui_root.get_node("ArrowPrevious") as Control
	arrow_next = ui_root.get_node("ArrowNext") as Control
	focus_frame = ui_root.get_node("FocusFrame") as NinePatchRect
	select_frame = ui_root.get_node("SelectFrame") as NinePatchRect
	preset_number = ui_root.get_node("PresetNumber") as Label
	save_button = ui_root.get_node("ButtonSaveCharacter") as Button
	list_title = ui_root.get_node("ListTitle") as Label
	list_background = ui_root.get_node("ListBackground") as ColorRect
	list_scroll = ui_root.get_node("ListScroll") as ScrollContainer
	list_grid = ui_root.get_node("ListScroll/ListMargin/ListGrid") as GridContainer
	list_reset_button = ui_root.find_child("ListReset", true, false) as TextureButton
	list_select_frame = ui_root.find_child("ListSelectFrame", true, false) as TextureRect
	color_picker = ui_root.get_node("ColorPicker") as Control
	saturation_value_area = color_picker.get_node("SaturationValue") as ColorRect
	saturation_value_pointer = color_picker.get_node("SaturationValue/SaturationValuePointer") as TextureRect
	hue_pointer = color_picker.get_node("HuePointer") as TextureRect
	hue_hit_area = color_picker.get_node("HueHitArea") as Control
	preview_color = color_picker.get_node("PreviewColor") as ColorRect
	hex_input = color_picker.get_node("HexInput") as LineEdit
	favorite_views.clear()
	for index in FAVORITE_SLOT_COUNT:
		favorite_views.append({
			"swatch": color_picker.get_node("FavoriteColor%d" % index),
			"focus": color_picker.get_node("FavoriteFocus%d" % index),
		})
	animation_buttons.clear()
	for index in 16:
		animation_buttons.append(ui_root.get_node("AnimationButton%d" % index))


func _connect_once(signal_value: Signal, callable: Callable) -> void:
	if not signal_value.is_connected(callable):
		signal_value.connect(callable)


func _open_link(url: String) -> void:
	OS.shell_open(url)


func _focus_selected_category() -> void:
	if focused_category == "" and selected_category != "":
		_focus_category(selected_category)


func _copy_current_hex() -> void:
	DisplayServer.clipboard_set(hex_input.text)


func _apply_previous_preset() -> void:
	_apply_preset(posmod(preset_index - 1, PRESET_SLOT_COUNT))


func _apply_next_preset() -> void:
	_apply_preset(posmod(preset_index + 1, PRESET_SLOT_COUNT))


## Runtime signal connections are intentionally restored from named serialized nodes.
## This keeps the scene editable without persisting editor-generated callables in the file.
func _connect_serialized_ui() -> void:
	for link: Array in [["Discord", PATH_DISCORD], ["Facebook", PATH_FACEBOOK], ["YouTube", PATH_YOUTUBE]]:
		_connect_once((ui_root.get_node("Button%s" % link[0]) as TextureButton).pressed, _open_link.bind(link[1]))
	for ui_category: String in UI_CATEGORY_ORDER:
		var cell := slot_views[ui_category].cell as Control
		var select := cell.get_node("Select") as TextureButton
		var visibility := cell.get_node("VisibilityButton") as TextureButton
		_connect_once(select.pressed, _select_category.bind(ui_category))
		_connect_once(select.mouse_entered, _focus_category.bind(ui_category))
		_connect_once(select.mouse_exited, _unfocus_category.bind(ui_category))
		_connect_once(visibility.pressed, _toggle_slot_visibility.bind(ui_category))
		_connect_once(visibility.mouse_entered, _focus_category.bind(ui_category))
	_connect_once((arrow_previous.get_node("HitArea") as Button).pressed, _step_focused_category.bind(-1))
	_connect_once((arrow_next.get_node("HitArea") as Button).pressed, _step_focused_category.bind(1))
	_connect_once((arrow_previous.get_node("HitArea") as Button).mouse_entered, _focus_selected_category)
	_connect_once((arrow_next.get_node("HitArea") as Button).mouse_entered, _focus_selected_category)
	_connect_once((ui_root.get_node("PresetPrevious") as TextureButton).pressed, _apply_previous_preset)
	_connect_once((ui_root.get_node("PresetNext") as TextureButton).pressed, _apply_next_preset)
	_connect_once((ui_root.get_node("ButtonRandom") as TextureButton).pressed, _randomize_character)
	_connect_once(save_button.pressed, _save_character_scene)
	_connect_once(list_reset_button.pressed, _reset_list_category)
	_connect_once(saturation_value_area.gui_input, _saturation_value_input)
	_connect_once(hue_hit_area.gui_input, _hue_input)
	_connect_once(hex_input.text_submitted, _hex_submitted)
	_connect_once((color_picker.get_node("ButtonCopy") as TextureButton).pressed, _copy_current_hex)
	_connect_once((color_picker.get_node("ButtonAdd") as TextureButton).pressed, _add_favorite)
	_connect_once((color_picker.get_node("ButtonDelete") as TextureButton).pressed, _delete_favorite)
	for index in COLOR_PRESETS_1.size():
		_connect_once((color_picker.get_node("ColorPreset%d" % index) as Button).pressed, _set_picker_color.bind(Color(COLOR_PRESETS_1[index]), true))
	for index in COLOR_PRESETS_2.size():
		_connect_once((color_picker.get_node("ColorPreset%d" % (16 + index)) as Button).pressed, _set_picker_color.bind(Color(COLOR_PRESETS_2[index]), true))
	for index in FAVORITE_SLOT_COUNT:
		_connect_once((color_picker.get_node("FavoriteSlot%d" % index) as Button).gui_input, _favorite_input.bind(index))
	for index in animation_buttons.size():
		var button := animation_buttons[index] as Button
		_connect_once(button.pressed, _play_animation.bind(button.text))


func _build_world() -> void:
	# Unity map: sample_map.png, 1920x1080, PPU 100, position (1.5, 0.81), sortingOrder -1.
	background = Sprite2D.new()
	background.name = "Map"
	background.texture = load("res://addons/layer_lab/minimal_character_maker/demo/assets/map/sample_map.png")
	background.position = MAP_SCREEN_POSITION
	background.scale = Vector2.ONE * (PIXELS_PER_UNIT / 100.0)
	background.z_index = -1
	add_child(background)
	character = (load(CHARACTER_SCENE) as PackedScene).instantiate() as MinimalCharacter
	character.name = "Character"
	character.default_animation = &""
	character.position = CHARACTER_SCREEN_POSITION
	character.scale = Vector2.ONE * CHARACTER_SCALE
	add_child(character)


func _build_ui() -> void:
	var layer := CanvasLayer.new()
	layer.name = "UI"
	add_child(layer)
	ui_root = Control.new()
	ui_root.name = "Canvas"
	ui_root.size = Vector2(1920, 1080)
	ui_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(ui_root)
	_build_title()
	_build_parts_panel()
	_build_list_panel()
	_build_animation_control()


func _build_title() -> void:
	var title := _unity_label("2D MINIMAL", Vector2(33.46, 18.05), Vector2(296.48, 47.33), 36, HORIZONTAL_ALIGNMENT_LEFT, TMP_OUTLINE_LARGE)
	title.name = "TextTitle"
	title.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	ui_root.add_child(title)
	# Unity Text_Sub: 21.5 px uppercase, #EFC15F. Godot uses the nearest integer size, 22 px.
	var subtitle := _unity_label("CHARACTER MAKER", Vector2(33.46, 62.63), Vector2(296.48, 33.34), 22, HORIZONTAL_ALIGNMENT_LEFT, TMP_OUTLINE_STANDARD)
	subtitle.name = "TextSub"
	subtitle.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	subtitle.add_theme_color_override("font_color", Color("EFC15F"))
	ui_root.add_child(subtitle)
	# Unity ButtonLink has four 48x48 entries. The Unity link is intentionally omitted.
	var links := [["Discord", "sns_discord.png", 1685.99, PATH_DISCORD], ["Facebook", "sns_facebook.png", 1739.99, PATH_FACEBOOK], ["YouTube", "sns_youtube.png", 1793.99, PATH_YOUTUBE]]
	for link: Array in links:
		var button := _texture_button(UI_ROOT + link[1], Vector2(link[2], 25.07), Vector2(48, 48))
		button.name = "Button%s" % link[0]
		button.tooltip_text = "Open the Layer Lab %s page." % link[0]
		button.pressed.connect(func() -> void: OS.shell_open(link[3]))
		ui_root.add_child(button)


func _build_parts_panel() -> void:
	var panel := _nine_patch(UI_ROOT + "parts_panel_bg.png", Vector2(1292.75, 160.71), Vector2(348.78, 801.08), 86, 144, 60, 87)
	panel.name = "PanelParts"
	ui_root.add_child(panel)
	var body_label := _unity_label("BODY", Vector2(1314.47, 178.42), Vector2(120.3, 20.77), 16, HORIZONTAL_ALIGNMENT_LEFT, TMP_OUTLINE_STANDARD)
	body_label.name = "TextBody"
	ui_root.add_child(body_label)
	var equip_label := _unity_label("EQUIP", Vector2(1314.47, 433.62), Vector2(120.3, 20.77), 16, HORIZONTAL_ALIGNMENT_LEFT, TMP_OUTLINE_STANDARD)
	equip_label.name = "TextEquip"
	ui_root.add_child(equip_label)
	for ui_category in UI_CATEGORY_ORDER:
		_build_slot(ui_category)
	# ActionUI: hover arrows and focus/select frames use the extracted Unity rectangles.
	arrow_previous = _slot_arrow("parts_slot_icon_arrow_left.png", Vector2(0.19, 38.5), Vector2(14, 21), -1)
	arrow_next = _slot_arrow("parts_slot_icon_arrow_right.png", Vector2(87.99, 38.5), Vector2(15, 21), 1)
	ui_root.add_child(arrow_previous)
	ui_root.add_child(arrow_next)
	focus_frame = _nine_patch(UI_ROOT + "parts_slot_item_select_frame.png", Vector2.ZERO, Vector2(91.19, 91.67), 21, 26, 21, 26)
	focus_frame.name = "FocusFrame"
	focus_frame.visible = false
	ui_root.add_child(focus_frame)
	select_frame = _nine_patch(UI_ROOT + "parts_slot_item_select_frame.png", Vector2.ZERO, Vector2(91.19, 91.67), 21, 26, 21, 26)
	select_frame.name = "SelectFrame"
	select_frame.modulate = Color("B7FF87")
	select_frame.visible = false
	ui_root.add_child(select_frame)
	# Preset title, previous button, number, and next button.
	var preset_label := _unity_label("PRESET", Vector2(1316.65, 787.92), Vector2(120.3, 25.6), 16, HORIZONTAL_ALIGNMENT_LEFT, TMP_OUTLINE_STANDARD)
	preset_label.name = "TextPreset"
	ui_root.add_child(preset_label)
	var preset_previous := _texture_button(UI_ROOT + "preset_previous.png", Vector2(1314.94, 821.72), Vector2(43, 45))
	preset_previous.name = "PresetPrevious"
	preset_previous.tooltip_text = "Apply the previous preset slot."
	preset_previous.pressed.connect(func() -> void: _apply_preset(posmod(preset_index - 1, PRESET_SLOT_COUNT)))
	ui_root.add_child(preset_previous)
	var preset_background := TextureRect.new()
	preset_background.name = "PresetMiddle"
	preset_background.texture = load(UI_ROOT + "preset_bg.png")
	preset_background.position = Vector2(1357.94, 824.53)
	preset_background.size = Vector2(217.4, 39.38)
	preset_background.stretch_mode = TextureRect.STRETCH_SCALE
	preset_background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	preset_background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui_root.add_child(preset_background)
	preset_number = _unity_label("01", Vector2(1366.64, 833.49), Vector2(200, 21.46), 15, HORIZONTAL_ALIGNMENT_CENTER, TMP_OUTLINE_SMALL)
	preset_number.name = "PresetNumber"
	ui_root.add_child(preset_number)
	var preset_next := _texture_button(UI_ROOT + "preset_next.png", Vector2(1575.34, 821.72), Vector2(43, 45))
	preset_next.name = "PresetNext"
	preset_next.tooltip_text = "Apply the next preset slot."
	preset_next.pressed.connect(func() -> void: _apply_preset(posmod(preset_index + 1, PRESET_SLOT_COUNT)))
	ui_root.add_child(preset_next)
	var random_button := _texture_button(UI_ROOT + "button_dice_white.png", Vector2(1311.85, 897.65), Vector2(40, 46.24))
	random_button.name = "ButtonRandom"
	random_button.tooltip_text = "Randomize every part and the skin, hair and beard colors."
	random_button.pressed.connect(_randomize_character)
	ui_root.add_child(random_button)
	# Replace the Unity-only Save Prefab and Asset Store pair with one 254.47 px Save Character button.
	save_button = _textured_text_button(UI_ROOT + "button_small_blue.png", "Save Character", Vector2(1373.21, 897.65), Vector2(254.47, 46.24), 16, 16, 24, 17, 21)
	save_button.name = "ButtonSaveCharacter"
	save_button.tooltip_text = "Save the current character as a reusable scene with a 512x512 preview (Godot editor only)."
	save_button.disabled = not OS.has_feature("editor")
	save_button.pressed.connect(_save_character_scene)
	ui_root.add_child(save_button)


func _build_slot(ui_category: String) -> void:
	var origin: Vector2 = SLOT_POSITIONS[ui_category]
	var cell := Control.new()
	cell.name = "Slot%s" % ui_category
	cell.position = origin
	cell.size = Vector2(96, 98)
	cell.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui_root.add_child(cell)
	var background_button := _texture_button(UI_ROOT + "parts_slot_bg_empty.png", Vector2.ZERO, Vector2(96, 98))
	background_button.name = "Select"
	background_button.tooltip_text = "Open the %s part list." % _category_title(ui_category).to_lower()
	background_button.pressed.connect(_select_category.bind(ui_category))
	background_button.mouse_entered.connect(_focus_category.bind(ui_category))
	background_button.mouse_exited.connect(_unfocus_category.bind(ui_category))
	cell.add_child(background_button)
	var icon := TextureRect.new()
	icon.name = "Icon"
	icon.texture = load(UI_ROOT + "icon_%s.png" % _snake(ui_category))
	var icon_rect: Rect2 = SLOT_ICON_RECTS[ui_category]
	icon.position = icon_rect.position
	icon.size = icon_rect.size
	icon.stretch_mode = TextureRect.STRETCH_SCALE
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cell.add_child(icon)
	# Item: center the 128x128 thumbnail at 0.7 scale, producing 89.6 px.
	var item := TextureRect.new()
	item.name = "Item"
	item.position = Vector2((96 - 89.6) * 0.5, (98 - 89.6) * 0.5)
	item.size = Vector2(89.6, 89.6)
	item.stretch_mode = TextureRect.STRETCH_SCALE
	item.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	item.mouse_filter = Control.MOUSE_FILTER_IGNORE
	item.visible = false
	cell.add_child(item)
	var eye := _texture_button(UI_ROOT + "parts_slot_activeself_on.png", Vector2(68.8, 5.4), Vector2(23, 18))
	eye.name = "VisibilityButton"
	eye.tooltip_text = "Hide or show the %s part." % _category_title(ui_category).to_lower()
	eye.pressed.connect(_toggle_slot_visibility.bind(ui_category))
	eye.mouse_entered.connect(_focus_category.bind(ui_category))
	cell.add_child(eye)
	slot_views[ui_category] = {"cell": cell, "background": background_button, "icon": icon, "item": item, "eye": eye}


func _slot_arrow(texture_name: String, offset: Vector2, size: Vector2, direction: int) -> Control:
	var holder := Control.new()
	holder.name = "ArrowPrevious" if direction < 0 else "ArrowNext"
	holder.size = Vector2(18.6, 44.05)
	holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	holder.set_meta("cell_offset", offset - Vector2(2.3, 8.58))
	holder.visible = false
	var button := Button.new()
	button.name = "HitArea"
	button.flat = true
	button.size = Vector2(18.6, 44.05)
	button.tooltip_text = "Select the previous part." if direction < 0 else "Select the next part."
	button.focus_mode = Control.FOCUS_NONE
	for state in ["normal", "hover", "pressed", "focus"]:
		button.add_theme_stylebox_override(state, StyleBoxEmpty.new())
	button.pressed.connect(_step_focused_category.bind(direction))
	button.mouse_entered.connect(func() -> void: if focused_category == "" and selected_category != "": _focus_category(selected_category))
	holder.add_child(button)
	var icon := TextureRect.new()
	icon.name = "Icon"
	icon.texture = load(UI_ROOT + texture_name)
	icon.position = Vector2(2.3, 8.58)
	icon.size = size
	icon.stretch_mode = TextureRect.STRETCH_SCALE
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	holder.add_child(icon)
	return holder


func _build_list_panel() -> void:
	var panel := _nine_patch(UI_ROOT + "parts_panel_bg_default.png", Vector2(1641.53, 160.71), Vector2(278.47, 801.23), 9, 9, 3, 9)
	panel.name = "PanelPartsList"
	panel.modulate = Color("2F333F")
	ui_root.add_child(panel)
	list_title = _unity_label("HAIR", Vector2(1657.39, 176.6), Vector2(235.35, 21.66), 16, HORIZONTAL_ALIGNMENT_LEFT, TMP_OUTLINE_STANDARD)
	list_title.name = "ListTitle"
	ui_root.add_child(list_title)
	list_background = ColorRect.new()
	list_background.name = "ListBackground"
	list_background.color = Color("232630")
	list_background.position = Vector2(1642.56, 211.28)
	list_background.size = Vector2(276.41, 466.66)
	list_background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui_root.add_child(list_background)
	list_scroll = ScrollContainer.new()
	list_scroll.name = "ListScroll"
	list_scroll.position = Vector2(1642.56, 211.28)
	list_scroll.size = Vector2(276.41, 466.66)
	list_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	list_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_NEVER
	ui_root.add_child(list_scroll)
	var margin := MarginContainer.new()
	margin.name = "ListMargin"
	margin.add_theme_constant_override("margin_left", int(1653.97 - 1642.56))
	margin.add_theme_constant_override("margin_top", 20)
	margin.add_theme_constant_override("margin_bottom", 20)
	margin.add_theme_constant_override("margin_right", 0)
	list_scroll.add_child(margin)
	list_grid = GridContainer.new()
	list_grid.name = "ListGrid"
	list_grid.columns = 3
	list_grid.add_theme_constant_override("h_separation", 10)
	list_grid.add_theme_constant_override("v_separation", 10)
	margin.add_child(list_grid)
	list_reset_button = _texture_button(UI_ROOT + "button_reset.png", Vector2.ZERO, Vector2(80, 80))
	list_reset_button.name = "ListReset"
	list_reset_button.custom_minimum_size = Vector2(80, 80)
	list_reset_button.tooltip_text = "Unequip this part."
	list_reset_button.pressed.connect(_reset_list_category)
	list_select_frame = TextureRect.new()
	list_select_frame.name = "ListSelectFrame"
	list_select_frame.texture = load(UI_ROOT + "parts_list_select.png")
	list_select_frame.size = Vector2(78, 78)
	list_select_frame.stretch_mode = TextureRect.STRETCH_SCALE
	list_select_frame.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	list_select_frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	list_select_frame.visible = false
	_build_color_picker()


func _build_color_picker() -> void:
	color_picker = Control.new()
	color_picker.name = "ColorPicker"
	color_picker.position = Vector2(1642.17, 687.94)
	color_picker.size = Vector2(277.19, 269.75)
	color_picker.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui_root.add_child(color_picker)
	var shadow := ColorRect.new()
	shadow.name = "PickerShadow"
	shadow.color = Color(0, 0, 0, 0.5)
	shadow.position = Vector2(1653.47 - 1642.17 + 2, 2)
	shadow.size = Vector2(153.79, 153.8)
	shadow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	color_picker.add_child(shadow)
	saturation_value_area = ColorRect.new()
	saturation_value_area.name = "SaturationValue"
	saturation_value_area.position = Vector2(1653.47 - 1642.17, 0)
	saturation_value_area.size = Vector2(153.79, 153.8)
	var shader := Shader.new()
	shader.code = "shader_type canvas_item;\nuniform float hue = 0.0;\nvec3 hsv2rgb(vec3 c) {\n\tvec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);\n\tvec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);\n\treturn c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);\n}\nvoid fragment() {\n\tCOLOR = vec4(hsv2rgb(vec3(hue, UV.x, 1.0 - UV.y)), 1.0);\n}\n"
	var material := ShaderMaterial.new()
	material.shader = shader
	saturation_value_area.material = material
	saturation_value_area.gui_input.connect(_saturation_value_input)
	color_picker.add_child(saturation_value_area)
	saturation_value_pointer = TextureRect.new()
	saturation_value_pointer.name = "SaturationValuePointer"
	saturation_value_pointer.texture = load(UI_ROOT + "picker_pointer.png")
	saturation_value_pointer.size = Vector2(11, 11)
	saturation_value_pointer.stretch_mode = TextureRect.STRETCH_SCALE
	saturation_value_pointer.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	saturation_value_pointer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	saturation_value_area.add_child(saturation_value_pointer)
	# Hue: preserve the Unity 6x154 visual bar and use a centered transparent 24 px input area.
	var hue_bar := TextureRect.new()
	hue_bar.name = "HueBar"
	hue_bar.texture = load(UI_ROOT + "picker_color_bar.png")
	hue_bar.position = Vector2(1816.26 - 1642.17, 0)
	hue_bar.size = Vector2(6, 154)
	hue_bar.stretch_mode = TextureRect.STRETCH_SCALE
	hue_bar.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	hue_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	color_picker.add_child(hue_bar)
	hue_hit_area = Control.new()
	hue_hit_area.name = "HueHitArea"
	hue_hit_area.position = Vector2(1816.26 - 1642.17 + 3 - 12, 0)
	hue_hit_area.size = Vector2(24, 154)
	hue_hit_area.gui_input.connect(_hue_input)
	color_picker.add_child(hue_hit_area)
	hue_pointer = TextureRect.new()
	hue_pointer.name = "HuePointer"
	hue_pointer.texture = load(UI_ROOT + "picker_slider_pointer.png")
	hue_pointer.size = Vector2(14, 14)
	hue_pointer.stretch_mode = TextureRect.STRETCH_SCALE
	hue_pointer.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	hue_pointer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	color_picker.add_child(hue_pointer)
	# Color presets: 4x4 plus 4x3, 18x18 cells, 2 px spacing.
	for index in COLOR_PRESETS_1.size():
		color_picker.add_child(_color_preset_button(Color(COLOR_PRESETS_1[index]), Vector2(1832.56 + 20 * (index % 4), 688.74 + 20 * (index / 4)) - color_picker.position, index))
	for index in COLOR_PRESETS_2.size():
		color_picker.add_child(_color_preset_button(Color(COLOR_PRESETS_2[index]), Vector2(1832.56 + 20 * (index % 4), 782.52 + 20 * (index / 4)) - color_picker.position, 16 + index))
	# Favorites row: preview, HEX input, copy, add, delete, and 10x2 slots at 22x22.
	preview_color = ColorRect.new()
	preview_color.name = "PreviewColor"
	preview_color.position = Vector2(1658.28, 859.64) - color_picker.position
	preview_color.size = Vector2(25.82, 25.82)
	preview_color.mouse_filter = Control.MOUSE_FILTER_IGNORE
	color_picker.add_child(preview_color)
	var input_background := _nine_patch(UI_ROOT + "picker_favorite_inputfield_bg.png", Vector2(1691.27, 859.46) - color_picker.position, Vector2(83.02, 26), 4, 4, 5, 5)
	input_background.name = "HexBackground"
	color_picker.add_child(input_background)
	hex_input = LineEdit.new()
	hex_input.name = "HexInput"
	hex_input.position = input_background.position
	hex_input.size = input_background.size
	hex_input.alignment = HORIZONTAL_ALIGNMENT_CENTER
	hex_input.max_length = 7
	hex_input.add_theme_font_override("font", font)
	hex_input.add_theme_font_size_override("font_size", 11)
	hex_input.add_theme_color_override("font_color", Color("B0B0B0"))
	hex_input.add_theme_color_override("font_placeholder_color", Color(0.196, 0.196, 0.196, 0.5))
	hex_input.placeholder_text = "Enter text..."
	hex_input.tooltip_text = "Type a #RRGGBB color and press Enter."
	for state in ["normal", "focus", "read_only"]:
		hex_input.add_theme_stylebox_override(state, StyleBoxEmpty.new())
	hex_input.text_submitted.connect(_hex_submitted)
	color_picker.add_child(hex_input)
	_center_within_unity_rect(hex_input, input_background.position, input_background.size)
	var copy_button := _texture_button(UI_ROOT + "picker_favorite_button_copy.png", Vector2(1760.76, 857.46) - color_picker.position, Vector2(54, 30))
	copy_button.name = "ButtonCopy"
	copy_button.tooltip_text = "Copy the current color hex code to the clipboard."
	copy_button.pressed.connect(func() -> void: DisplayServer.clipboard_set(hex_input.text))
	color_picker.add_child(copy_button)
	var add_button := _texture_button(UI_ROOT + "picker_favorite_button_coloradd.png", Vector2(1849.76, 860.46) - color_picker.position, Vector2(24, 24))
	add_button.name = "ButtonAdd"
	add_button.tooltip_text = "Save the current color to the selected favorite slot."
	add_button.pressed.connect(_add_favorite)
	color_picker.add_child(add_button)
	var delete_button := _texture_button(UI_ROOT + "picker_favorite_button_colordelete.png", Vector2(1884.16, 859.64) - color_picker.position, Vector2(22, 24))
	delete_button.name = "ButtonDelete"
	delete_button.tooltip_text = "Delete the selected favorite color."
	delete_button.pressed.connect(_delete_favorite)
	color_picker.add_child(delete_button)
	for index in FAVORITE_SLOT_COUNT:
		var origin := Vector2(1656.86 + 25 * (index % 10), 897.36 + 25 * (index / 10)) - color_picker.position
		var empty := _nine_patch(UI_ROOT + "picker_favorite_slot_empty.png", origin, Vector2(22, 22), 4, 4, 5, 5)
		empty.name = "FavoriteEmpty%d" % index
		color_picker.add_child(empty)
		var swatch := ColorRect.new()
		swatch.name = "FavoriteColor%d" % index
		swatch.position = origin
		swatch.size = Vector2(22, 22)
		swatch.mouse_filter = Control.MOUSE_FILTER_IGNORE
		swatch.visible = false
		color_picker.add_child(swatch)
		var focus := _nine_patch(UI_ROOT + "picker_favorite_focus.png", origin, Vector2(22, 22), 4, 4, 5, 5)
		focus.name = "FavoriteFocus%d" % index
		focus.visible = false
		color_picker.add_child(focus)
		var button := Button.new()
		button.name = "FavoriteSlot%d" % index
		button.position = origin
		button.size = Vector2(22, 22)
		button.flat = true
		button.focus_mode = Control.FOCUS_NONE
		button.tooltip_text = "Select this favorite color, click again to apply, right-click to delete."
		for state in ["normal", "hover", "pressed", "focus"]:
			button.add_theme_stylebox_override(state, StyleBoxEmpty.new())
		button.gui_input.connect(_favorite_input.bind(index))
		color_picker.add_child(button)
		favorite_views.append({"swatch": swatch, "focus": focus})


func _color_preset_button(color: Color, position: Vector2, index: int) -> Button:
	var button := Button.new()
	button.name = "ColorPreset%d" % index
	button.position = position
	button.size = Vector2(18, 18)
	button.focus_mode = Control.FOCUS_NONE
	button.tooltip_text = "Apply preset color #%s." % color.to_html(false).to_upper()
	var style := StyleBoxFlat.new()
	style.bg_color = color
	for state in ["normal", "hover", "pressed", "focus"]:
		button.add_theme_stylebox_override(state, style)
	button.pressed.connect(func() -> void: _set_picker_color(color, true))
	return button


func _build_animation_control() -> void:
	var title := _unity_label("ANIMATION", Vector2(109.11, 405.77), Vector2(131.04, 30.46), 18, HORIZONTAL_ALIGNMENT_CENTER, TMP_OUTLINE_STANDARD)
	title.name = "TextAnimation"
	ui_root.add_child(title)
	var names := character.get_animation_names()
	for index in names.size():
		var name := String(names[index])
		var button := _textured_text_button(UI_ROOT + "button_animaiton_n.png", name, Vector2(30.73 + 145.8 * (index % 2), 445.7 + 44.09 * (index / 2)), Vector2(140, 38), 15, 5, 5, 5, 0)
		button.name = "AnimationButton%d" % index
		button.tooltip_text = "Play the %s animation." % name
		button.pressed.connect(_play_animation.bind(name))
		ui_root.add_child(button)
		animation_buttons.append(button)


# ---------------------------------------------------------------- State synchronization

func _connect_character() -> void:
	character.parts_changed.connect(func(_type_name: String, _index: int) -> void: _refresh_slots(); _refresh_list_selection())
	character.parts_visibility_changed.connect(func(_type_name: String, _visible: bool) -> void: _refresh_slots(); _refresh_list_selection())
	character.color_changed.connect(func(target: String, color: Color) -> void:
		_refresh_slots()
		_refresh_list_tint()
		if target == picker_target and not _applying_picker:
			# Mirror external color changes while preserving HSV state for picker-originated changes.
			_sync_picker_from_color(color))


func _refresh_all() -> void:
	_refresh_slots()
	_refresh_list()
	_refresh_preset_number()
	_refresh_animation_buttons()


func _category_title(ui_category: String) -> String:
	return LIST_TITLES.get(ui_category, ui_category.to_upper())


func _snake(value: String) -> String:
	var result := ""
	for index in value.length():
		var letter := value[index]
		if index > 0 and letter == letter.to_upper() and letter != letter.to_lower():
			result += "_"
		result += letter.to_lower()
	return result


func _sub_types(ui_category: String) -> Array:
	return character.get_ui_categories().get(ui_category, [])


func _is_group(ui_category: String) -> bool:
	return _sub_types(ui_category).size() > 1


## Returns the first visible subtype in a group, or the first subtype when all are hidden.
func _active_type_for_slot(ui_category: String) -> String:
	var members := _sub_types(ui_category)
	if members.is_empty():
		return ""
	if not _is_group(ui_category):
		return members[0]
	for member: String in members:
		if character.is_parts_visible(member):
			return member
	return members[0]


func _refresh_slots() -> void:
	for ui_category: String in slot_views:
		_refresh_slot(ui_category)
	if selected_category != "":
		select_frame.position = SLOT_POSITIONS[selected_category] + Vector2(2.405, 3.165)
		select_frame.visible = true


## Refreshes empty, equipped-hidden, and equipped-visible slot states to match Unity.
func _refresh_slot(ui_category: String) -> void:
	var view: Dictionary = slot_views[ui_category]
	var members := _sub_types(ui_category)
	var display_type := ""
	var hidden := false
	if _is_group(ui_category):
		for member: String in members:
			if character.is_equipped(member) and character.is_parts_visible(member):
				display_type = member
				break
		if display_type == "":
			for member: String in members:
				if character.is_equipped(member):
					display_type = String(last_visible_type.get(ui_category, members[0]))
					hidden = true
					break
	else:
		var member: String = members[0]
		if character.is_equipped(member):
			display_type = member
			hidden = not character.is_parts_visible(member)
	var background := view.background as TextureButton
	var icon := view.icon as TextureRect
	var item := view.item as TextureRect
	var eye := view.eye as TextureButton
	if display_type == "":
		background.texture_normal = load(UI_ROOT + "parts_slot_bg_empty.png")
		icon.visible = true
		item.visible = false
	else:
		background.texture_normal = load(UI_ROOT + ("parts_slot_bg_hide.png" if hidden else "parts_slot_bg_select.png"))
		icon.visible = false
		var thumbnail := character.get_thumbnail(display_type, maxi(character.get_active_index(display_type), 0))
		item.texture = thumbnail
		item.visible = thumbnail != null
		var tint := Color.WHITE
		if not _is_group(ui_category) and character.can_change_color(display_type):
			tint = character.get_color(character.get_color_target(display_type))
		tint.a = HIDDEN_ALPHA if hidden else 1.0
		item.modulate = tint
	var toggleable := false
	for member: String in members:
		toggleable = toggleable or character.can_toggle(member)
	eye.visible = toggleable and ui_category != "Skin" and ui_category != "Eye" and display_type != ""
	eye.texture_normal = load(UI_ROOT + ("parts_slot_activeself_off.png" if hidden else "parts_slot_activeself_on.png"))


func _select_category(ui_category: String) -> void:
	if ui_category == selected_category or not slot_views.has(ui_category):
		return
	selected_category = ui_category
	select_frame.position = SLOT_POSITIONS[ui_category] + Vector2(2.405, 3.165)
	select_frame.visible = true
	_refresh_list()


func _focus_category(ui_category: String) -> void:
	focused_category = ui_category
	focus_frame.position = SLOT_POSITIONS[ui_category] + Vector2(2.405, 3.165)
	focus_frame.visible = true
	var navigable := false
	for member: String in _sub_types(ui_category):
		navigable = navigable or character.get_parts_count(member) > 1
	arrow_previous.visible = navigable
	arrow_next.visible = navigable
	arrow_previous.position = SLOT_POSITIONS[ui_category] + arrow_previous.get_meta("cell_offset")
	arrow_next.position = SLOT_POSITIONS[ui_category] + arrow_next.get_meta("cell_offset")


func _unfocus_category(ui_category: String) -> void:
	if focused_category != ui_category:
		return
	var mouse := ui_root.get_local_mouse_position()
	var cell_rect := Rect2(SLOT_POSITIONS[ui_category] - Vector2(2.3, 0), Vector2(96 + 4.6, 98))
	if cell_rect.has_point(mouse):
		return
	focused_category = ""
	focus_frame.visible = false
	arrow_previous.visible = false
	arrow_next.visible = false


## Previous/next targets the hovered slot, falling back to the selected slot.
func _step_focused_category(direction: int) -> void:
	var ui_category := focused_category if focused_category != "" else selected_category
	if ui_category == "":
		return
	if not _is_group(ui_category):
		var type_name: String = _sub_types(ui_category)[0]
		if direction > 0:
			character.next_parts(type_name)
		else:
			character.prev_parts(type_name)
		return
	_navigate_group(ui_category, direction)


## Flattens subtype and index pairs so grouped navigation wraps across type boundaries.
func _navigate_group(ui_category: String, direction: int) -> void:
	var entries: Array = []
	for member: String in _sub_types(ui_category):
		for index in character.get_parts_count(member):
			entries.append([member, index])
	if entries.is_empty():
		return
	var current_type := _active_type_for_slot(ui_category)
	var current_index := character.get_active_index(current_type)
	var position := 0
	for entry_index in entries.size():
		if entries[entry_index][0] == current_type and entries[entry_index][1] == current_index:
			position = entry_index
			break
	var next: Array = entries[posmod(position + direction, entries.size())]
	var next_type: String = next[0]
	if next_type != current_type:
		character.toggle_parts(current_type, false)
		character.toggle_parts(next_type, true)
		last_visible_type[ui_category] = next_type
	character.equip_parts(next_type, int(next[1]))


## The eye button toggles a single type or restores the last visible subtype of a group.
func _toggle_slot_visibility(ui_category: String) -> void:
	var members := _sub_types(ui_category)
	if not _is_group(ui_category):
		var member: String = members[0]
		if character.can_toggle(member):
			character.toggle_parts(member, not character.is_parts_visible(member))
		return
	var any_visible := false
	for member: String in members:
		if character.is_parts_visible(member) and character.can_toggle(member):
			any_visible = true
	if any_visible:
		for member: String in members:
			if character.is_parts_visible(member) and character.can_toggle(member):
				character.toggle_parts(member, false)
				last_visible_type[ui_category] = member
	elif last_visible_type.has(ui_category):
		character.toggle_parts(String(last_visible_type[ui_category]), true)


# ---------------------------------------------------------------- Parts list

func _refresh_list() -> void:
	for child in list_grid.get_children():
		list_grid.remove_child(child)
		if child != list_reset_button and child != list_select_frame:
			child.queue_free()
	if list_select_frame.get_parent() != null:
		list_select_frame.get_parent().remove_child(list_select_frame)
	list_cells.clear()
	if selected_category == "":
		return
	list_title.text = _category_title(selected_category)
	var members := _sub_types(selected_category)
	var group := _is_group(selected_category)
	var show_reset := false
	for member: String in members:
		show_reset = show_reset or character.can_toggle(member)
	if show_reset:
		list_grid.add_child(list_reset_button)
	for member: String in members:
		for index in character.get_parts_count(member):
			list_grid.add_child(_list_cell(member, index))
	if not group:
		active_list_type = members[0]
	var color_enabled := not group and character.can_change_color(members[0])
	color_picker.visible = color_enabled
	var list_height := 466.66 if color_enabled else 746.41
	list_background.size = Vector2(276.41, list_height)
	list_scroll.size = Vector2(276.41, list_height)
	if color_enabled:
		picker_target = character.get_color_target(members[0])
		_sync_picker_from_color(character.get_color(picker_target))
	_refresh_list_tint()
	_refresh_list_selection()


func _list_cell(type_name: String, index: int) -> Control:
	var cell := Button.new()
	cell.name = "ListCell_%s_%d" % [type_name, index]
	cell.custom_minimum_size = Vector2(80, 80)
	cell.focus_mode = Control.FOCUS_NONE
	cell.tooltip_text = "Equip %s %d." % [character.get_display_name(type_name), index + 1]
	for state in ["normal", "hover", "pressed", "focus"]:
		cell.add_theme_stylebox_override(state, StyleBoxEmpty.new())
	cell.pressed.connect(_select_list_cell.bind(type_name, index))
	var image := TextureRect.new()
	image.name = "Image"
	image.position = Vector2(1.6, 1.6)
	image.size = Vector2(76.8, 76.8)
	image.stretch_mode = TextureRect.STRETCH_SCALE
	image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	image.texture = character.get_thumbnail(type_name, index)
	image.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cell.add_child(image)
	list_cells.append({"cell": cell, "image": image, "type": type_name, "index": index})
	_register_button_feedback(cell)
	return cell


## Selecting a grouped slot shows only that subtype; selecting a single slot equips and reveals it.
func _select_list_cell(type_name: String, index: int) -> void:
	if _is_group(selected_category):
		for member: String in _sub_types(selected_category):
			if member == type_name:
				character.toggle_parts(member, true)
			elif character.can_toggle(member):
				character.toggle_parts(member, false)
		active_list_type = type_name
		last_visible_type[selected_category] = type_name
	elif not character.is_parts_visible(type_name) and character.can_toggle(type_name):
		character.toggle_parts(type_name, true)
	character.equip_parts(type_name, index)


func _reset_list_category() -> void:
	if selected_category == "":
		return
	for member: String in _sub_types(selected_category):
		character.unequip_parts(member)


func _refresh_list_tint() -> void:
	if selected_category == "" or _is_group(selected_category):
		for entry: Dictionary in list_cells:
			(entry.image as TextureRect).modulate = Color.WHITE
		return
	var member: String = _sub_types(selected_category)[0]
	var tint := character.get_color(character.get_color_target(member)) if character.can_change_color(member) else Color.WHITE
	for entry: Dictionary in list_cells:
		(entry.image as TextureRect).modulate = tint


## Updates the selection frame from the visible grouped subtype or equipped single index.
func _refresh_list_selection() -> void:
	if list_select_frame.get_parent() != null:
		list_select_frame.get_parent().remove_child(list_select_frame)
	list_select_frame.visible = false
	if selected_category == "":
		return
	var target_type := ""
	if _is_group(selected_category):
		for member: String in _sub_types(selected_category):
			if character.is_equipped(member) and (character.is_parts_visible(member) or member == active_list_type):
				target_type = member
				break
	else:
		var member: String = _sub_types(selected_category)[0]
		if character.is_equipped(member):
			target_type = member
	if target_type == "":
		return
	var target_index := character.get_active_index(target_type)
	for entry: Dictionary in list_cells:
		if entry.type == target_type and int(entry.index) == target_index:
			var cell := entry.cell as Control
			cell.add_child(list_select_frame)
			cell.move_child(list_select_frame, 0)
			list_select_frame.position = Vector2(1, 1)
			list_select_frame.visible = true
			return


# ---------------------------------------------------------------- Color picker

func _sync_picker_from_color(color: Color) -> void:
	picker_hue = color.h
	picker_saturation = color.s
	picker_value = color.v
	_refresh_picker_visuals(color)


func _refresh_picker_visuals(color: Color) -> void:
	(saturation_value_area.material as ShaderMaterial).set_shader_parameter("hue", picker_hue)
	saturation_value_pointer.position = Vector2(picker_saturation * 153.79 - 5.5, (1.0 - picker_value) * 153.8 - 5.5)
	hue_pointer.position = Vector2(1816.26 - 1642.17 + 3 - 7, (1.0 - picker_hue) * 154 - 7)
	preview_color.color = color
	if not hex_input.has_focus():
		hex_input.text = "#" + color.to_html(false).to_upper()


var _applying_picker := false


func _set_picker_color(color: Color, from_preset := false) -> void:
	color.a = 1.0
	_applying_picker = true
	character.set_color(picker_target, color)
	_applying_picker = false
	if from_preset:
		_sync_picker_from_color(color)
	else:
		_refresh_picker_visuals(color)


func _apply_picker_hsv() -> void:
	_set_picker_color(Color.from_hsv(picker_hue, picker_saturation, picker_value))


func _saturation_value_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and (event as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT:
		dragging_saturation = (event as InputEventMouseButton).pressed
		if dragging_saturation:
			_update_saturation_value((event as InputEventMouseButton).position)
	elif event is InputEventMouseMotion and dragging_saturation:
		_update_saturation_value((event as InputEventMouseMotion).position)


func _update_saturation_value(local: Vector2) -> void:
	picker_saturation = clampf(local.x / 153.79, 0.0, 1.0)
	picker_value = clampf(1.0 - local.y / 153.8, 0.0, 1.0)
	_apply_picker_hsv()


func _hue_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and (event as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT:
		dragging_hue = (event as InputEventMouseButton).pressed
		if dragging_hue:
			_update_hue((event as InputEventMouseButton).position)
	elif event is InputEventMouseMotion and dragging_hue:
		_update_hue((event as InputEventMouseMotion).position)


func _update_hue(local: Vector2) -> void:
	picker_hue = clampf(1.0 - local.y / 154.0, 0.0, 0.9999)
	_apply_picker_hsv()


func _hex_submitted(text_value: String) -> void:
	var cleaned := text_value.strip_edges().trim_prefix("#")
	if cleaned.is_valid_html_color() and cleaned.length() == 6:
		_set_picker_color(Color.html(cleaned))
	else:
		_sync_picker_from_color(character.get_color(picker_target))


func _favorite_input(event: InputEvent, index: int) -> void:
	if not event is InputEventMouseButton or not (event as InputEventMouseButton).pressed:
		return
	var button := event as InputEventMouseButton
	if button.button_index == MOUSE_BUTTON_RIGHT:
		if index < favorite_colors.size() and favorite_colors[index] != null:
			favorite_colors[index] = null
			_save_favorites()
			_refresh_favorites()
		return
	if button.button_index != MOUSE_BUTTON_LEFT:
		return
	if favorite_focus == index and favorite_colors[index] != null:
		_set_picker_color(favorite_colors[index])
	favorite_focus = index
	_refresh_favorites()


func _add_favorite() -> void:
	var slot := favorite_focus
	if slot < 0:
		slot = favorite_colors.find(null)
	if slot < 0:
		return
	favorite_colors[slot] = character.get_color(picker_target)
	favorite_focus = slot
	_save_favorites()
	_refresh_favorites()


func _delete_favorite() -> void:
	if favorite_focus < 0:
		return
	favorite_colors[favorite_focus] = null
	_save_favorites()
	_refresh_favorites()


func _refresh_favorites() -> void:
	for index in FAVORITE_SLOT_COUNT:
		var view: Dictionary = favorite_views[index]
		var color = favorite_colors[index]
		(view.swatch as ColorRect).visible = color != null
		if color != null:
			(view.swatch as ColorRect).color = color
		(view.focus as Control).visible = favorite_focus == index


func _load_favorites() -> void:
	favorite_colors.resize(FAVORITE_SLOT_COUNT)
	favorite_colors.fill(null)
	if FileAccess.file_exists(FAVORITES_PATH):
		var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(FAVORITES_PATH))
		if parsed is Array:
			for index in mini(FAVORITE_SLOT_COUNT, (parsed as Array).size()):
				var value = parsed[index]
				favorite_colors[index] = Color.html(String(value)) if value is String and String(value).is_valid_html_color() else null
	_refresh_favorites()


func _save_favorites() -> void:
	var values: Array = []
	for color in favorite_colors:
		values.append(null if color == null else "#" + (color as Color).to_html(false))
	var file := FileAccess.open(FAVORITES_PATH, FileAccess.WRITE)
	if file != null:
		file.store_string(JSON.stringify(values))


# ---------------------------------------------------------------- Presets, randomization, saving, and animation

func _apply_preset(index: int) -> void:
	preset_index = posmod(index, PRESET_SLOT_COUNT)
	if preset_index < presets.size():
		var item: Dictionary = presets[preset_index]
		if not bool(item.get("is_empty", true)):
			character.apply_preset(item)
	_refresh_preset_number()
	_refresh_slots()
	_refresh_list()


func _refresh_preset_number() -> void:
	preset_number.text = "%02d" % (preset_index + 1)


## Matches Unity DemoControl.RandomizeCharacter, including randomized Skin, Hair, and Beard colors.
## The picker target retains the last randomized color as in the original ColorPicker.SetColor flow.
func _randomize_character() -> void:
	character.randomize_all()
	var last_color := Color.WHITE
	for target in ["Skin", "Hair", "Beard"]:
		last_color = Color.from_hsv(randf(), randf_range(0.4, 1.0), randf_range(0.5, 1.0))
		character.set_color(target, last_color)
	if color_picker.visible:
		character.set_color(picker_target, last_color)
	_refresh_list()


func _play_animation(name: String) -> void:
	character.play_animation(StringName(name))
	_refresh_animation_buttons()


func _refresh_animation_buttons() -> void:
	var names := character.get_animation_names()
	for index in animation_buttons.size():
		var button := animation_buttons[index] as Button
		var selected := index < names.size() and String(names[index]) == character.get_current_animation()
		_apply_button_texture(button, UI_ROOT + ("button_animation_f.png" if selected else "button_animaiton_n.png"), 5, 0 if selected else 5, 5, 0)


# ---------------------------------------------------------------- Button feedback

func _register_button_feedback_tree(target: Node) -> void:
	for child in target.find_children("*", "BaseButton", true, false):
		_register_button_feedback(child as BaseButton)


func _register_button_feedback(button: BaseButton) -> void:
	if button == null:
		return
	if not button.has_meta(BUTTON_FEEDBACK_MARKER):
		button.set_meta(BUTTON_FEEDBACK_MARKER, true)
		button.set_meta(BUTTON_FEEDBACK_BASE_SCALE, button.scale)
		button.set_meta(BUTTON_FEEDBACK_BASE_MODULATE, button.modulate)
		button.set_meta(BUTTON_FEEDBACK_HOVERED, false)
		button.set_meta(BUTTON_FEEDBACK_POINTER_DOWN, false)
	button.pivot_offset = button.size * 0.5
	_connect_once(button.button_down, _on_button_feedback_down.bind(button))
	_connect_once(button.button_up, _on_button_feedback_up.bind(button))
	_connect_once(button.mouse_entered, _on_button_feedback_mouse_entered.bind(button))
	_connect_once(button.mouse_exited, _on_button_feedback_mouse_exited.bind(button))


func _capture_button_feedback_base(button: BaseButton) -> void:
	button.set_meta(BUTTON_FEEDBACK_BASE_SCALE, button.scale)
	button.set_meta(BUTTON_FEEDBACK_BASE_MODULATE, button.modulate)
	button.pivot_offset = button.size * 0.5


func _on_button_feedback_mouse_entered(button: BaseButton) -> void:
	if button.disabled:
		return
	button.set_meta(BUTTON_FEEDBACK_HOVERED, true)
	if not bool(button.get_meta(BUTTON_FEEDBACK_POINTER_DOWN, false)):
		_capture_button_feedback_base(button)
		_tween_button_feedback(
			button,
			(button.get_meta(BUTTON_FEEDBACK_BASE_SCALE, Vector2.ONE) as Vector2) * BUTTON_FEEDBACK_HOVER_SCALE,
			(button.get_meta(BUTTON_FEEDBACK_BASE_MODULATE, Color.WHITE) as Color) * BUTTON_FEEDBACK_HOVER_TINT,
			BUTTON_FEEDBACK_HOVER_DURATION
		)


func _on_button_feedback_mouse_exited(button: BaseButton) -> void:
	button.set_meta(BUTTON_FEEDBACK_HOVERED, false)
	if bool(button.get_meta(BUTTON_FEEDBACK_POINTER_DOWN, false)):
		return
	_tween_button_feedback(
		button,
		button.get_meta(BUTTON_FEEDBACK_BASE_SCALE, Vector2.ONE) as Vector2,
		button.get_meta(BUTTON_FEEDBACK_BASE_MODULATE, Color.WHITE) as Color,
		BUTTON_FEEDBACK_HOVER_DURATION
	)


func _on_button_feedback_down(button: BaseButton) -> void:
	if button.disabled:
		return
	if not bool(button.get_meta(BUTTON_FEEDBACK_HOVERED, false)):
		_capture_button_feedback_base(button)
	_kill_button_feedback_tween(button)
	button.set_meta(BUTTON_FEEDBACK_POINTER_DOWN, true)
	button.pivot_offset = button.size * 0.5
	button.scale = (button.get_meta(BUTTON_FEEDBACK_BASE_SCALE, Vector2.ONE) as Vector2) * BUTTON_FEEDBACK_PRESSED_SCALE
	button.modulate = (button.get_meta(BUTTON_FEEDBACK_BASE_MODULATE, Color.WHITE) as Color) * BUTTON_FEEDBACK_PRESSED_TINT


func _on_button_feedback_up(button: BaseButton) -> void:
	if button.disabled:
		return
	button.set_meta(BUTTON_FEEDBACK_POINTER_DOWN, false)
	var hovered := bool(button.get_meta(BUTTON_FEEDBACK_HOVERED, false))
	var base_scale := button.get_meta(BUTTON_FEEDBACK_BASE_SCALE, Vector2.ONE) as Vector2
	var base_modulate := button.get_meta(BUTTON_FEEDBACK_BASE_MODULATE, Color.WHITE) as Color
	_tween_button_feedback(
		button,
		base_scale * BUTTON_FEEDBACK_HOVER_SCALE if hovered else base_scale,
		base_modulate * BUTTON_FEEDBACK_HOVER_TINT if hovered else base_modulate,
		BUTTON_FEEDBACK_RELEASE_DURATION
	)


func _tween_button_feedback(button: BaseButton, target_scale: Vector2, target_modulate: Color, duration: float) -> void:
	if not is_instance_valid(button):
		return
	_kill_button_feedback_tween(button)
	var tween := create_tween().set_parallel(true)
	tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(button, "scale", target_scale, duration)
	tween.tween_property(button, "modulate", target_modulate, duration)
	button.set_meta(BUTTON_FEEDBACK_TWEEN, tween)


func _kill_button_feedback_tween(button: BaseButton) -> void:
	if not button.has_meta(BUTTON_FEEDBACK_TWEEN):
		return
	var current: Variant = button.get_meta(BUTTON_FEEDBACK_TWEEN)
	if current is Tween and (current as Tween).is_valid():
		(current as Tween).kill()
	button.remove_meta(BUTTON_FEEDBACK_TWEEN)


func _clear_button_feedback_for_serialization() -> void:
	for found in ui_root.find_children("*", "BaseButton", true, false):
		var button := found as BaseButton
		_kill_button_feedback_tween(button)
		button.scale = button.get_meta(BUTTON_FEEDBACK_BASE_SCALE, button.scale) as Vector2
		button.modulate = button.get_meta(BUTTON_FEEDBACK_BASE_MODULATE, button.modulate) as Color
		for key in [BUTTON_FEEDBACK_MARKER, BUTTON_FEEDBACK_BASE_SCALE, BUTTON_FEEDBACK_BASE_MODULATE, BUTTON_FEEDBACK_HOVERED, BUTTON_FEEDBACK_POINTER_DOWN]:
			if button.has_meta(key):
				button.remove_meta(key)


func _save_character_scene() -> void:
	if not OS.has_feature("editor"):
		return
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(SAVED_SCENE_DIRECTORY))
	var base_name := "character_%s" % Time.get_datetime_string_from_system(false, true).replace(":", "-")
	var scene_path := SAVED_SCENE_DIRECTORY.path_join(base_name + ".tscn")
	var preview_path := SAVED_SCENE_DIRECTORY.path_join(base_name + ".png")
	var suffix := 2
	while FileAccess.file_exists(scene_path) or FileAccess.file_exists(preview_path):
		scene_path = SAVED_SCENE_DIRECTORY.path_join("%s_%d.tscn" % [base_name, suffix])
		preview_path = SAVED_SCENE_DIRECTORY.path_join("%s_%d.png" % [base_name, suffix])
		suffix += 1
	var saved := (load(CHARACTER_SCENE) as PackedScene).instantiate() as MinimalCharacter
	saved.name = base_name.to_pascal_case()
	saved.configuration = character.get_configuration()
	var packed := PackedScene.new()
	if packed.pack(saved) != OK or ResourceSaver.save(packed, scene_path) != OK:
		push_error("Failed to save the character scene: %s" % scene_path)
		saved.free()
		return
	saved.free()
	_save_preview(preview_path)
	save_button.tooltip_text = "Saved %s" % scene_path.get_file()


## Unity CharacterPrefabSaver: 512x512, orthographic size 3, centered on active renderer bounds.
func _save_preview(preview_path: String) -> void:
	var viewport := SubViewport.new()
	viewport.size = Vector2i(512, 512)
	viewport.transparent_bg = true
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(viewport)
	var preview := (load(CHARACTER_SCENE) as PackedScene).instantiate() as MinimalCharacter
	preview.default_animation = &""
	preview.scale = Vector2.ONE * 2.0872 * (512.0 / 6.0 / 100.0)
	viewport.add_child(preview)
	preview.initialize()
	preview.apply_preset(character.to_preset())
	preview.play_animation(&"Idle")
	preview.get_animation_player().advance(0.0)
	var bounds := _visible_bounds(preview)
	preview.position = Vector2(256, 256) - bounds.get_center()
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	var image := viewport.get_texture().get_image()
	image.save_png(ProjectSettings.globalize_path(preview_path))
	viewport.queue_free()


func _visible_bounds(node: Node2D) -> Rect2:
	var result := Rect2()
	var first := true
	for child in node.find_children("*", "Sprite2D", true, false):
		var sprite := child as Sprite2D
		if not sprite.is_visible_in_tree() or sprite.texture == null:
			continue
		var rect := sprite.get_rect()
		var transform := node.get_global_transform().affine_inverse() * sprite.get_global_transform()
		var global_rect := transform * rect
		if first:
			result = global_rect
			first = false
		else:
			result = result.merge(global_rect)
	return result


# ---------------------------------------------------------------- UI helpers

func _unity_label(text_value: String, label_position: Vector2, label_size: Vector2, font_size: int, alignment := HORIZONTAL_ALIGNMENT_CENTER, outline_size := TMP_OUTLINE_SMALL) -> Label:
	var label := Label.new()
	label.text = text_value
	label.position = label_position
	label.size = label_size
	label.horizontal_alignment = alignment
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_override("font", font)
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", Color.WHITE)
	_apply_tmp_outline(label, outline_size)
	_center_within_unity_rect(label, label_position, label_size)
	return label


## Keeps the optical center aligned when a Godot control minimum height exceeds the Unity rectangle.
func _center_within_unity_rect(control: Control, unity_position: Vector2, unity_size: Vector2) -> void:
	control.update_minimum_size()
	var minimum := control.get_combined_minimum_size()
	minimum = Vector2(maxf(minimum.x, control.size.x), maxf(minimum.y, control.size.y))
	if minimum.y > unity_size.y:
		control.position.y = unity_position.y - (minimum.y - unity_size.y) * 0.5
	if minimum.x > unity_size.x:
		control.position.x = unity_position.x - (minimum.x - unity_size.x) * 0.5


func _apply_tmp_outline(control: Control, outline_size: int) -> void:
	# Uses pre-baked bitmap glyphs and outlines without distributing the source vector font.
	control.add_theme_font_override("font", outline_font)
	control.add_theme_color_override("font_outline_color", Color.BLACK)
	control.add_theme_constant_override("outline_size", outline_size)
	control.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.85))
	control.add_theme_constant_override("shadow_offset_x", 0)
	control.add_theme_constant_override("shadow_offset_y", 1)
	control.add_theme_constant_override("shadow_outline_size", 1)


func _texture_button(path: String, button_position: Vector2, button_size: Vector2) -> TextureButton:
	var button := TextureButton.new()
	button.position = button_position
	button.size = button_size
	button.ignore_texture_size = true
	button.stretch_mode = TextureButton.STRETCH_SCALE
	button.texture_normal = load(path)
	return button


func _textured_text_button(path: String, text_value: String, button_position: Vector2, button_size: Vector2, font_size: int, left: int, top: int, right: int, bottom: int) -> Button:
	var button := Button.new()
	button.position = button_position
	button.size = button_size
	button.text = text_value
	button.focus_mode = Control.FOCUS_NONE
	button.add_theme_font_override("font", font)
	button.add_theme_font_size_override("font_size", font_size)
	button.add_theme_color_override("font_color", Color.WHITE)
	button.add_theme_color_override("font_hover_color", Color.WHITE)
	button.add_theme_color_override("font_pressed_color", Color.WHITE)
	button.add_theme_color_override("font_disabled_color", Color(1, 1, 1, 0.5))
	_apply_tmp_outline(button, TMP_OUTLINE_STANDARD)
	_apply_button_texture(button, path, left, top, right, bottom)
	return button


func _apply_button_texture(button: Button, path: String, left: int, top: int, right: int, bottom: int) -> void:
	var texture := load(path) as Texture2D
	for state in ["normal", "hover", "pressed", "focus", "disabled"]:
		var style := StyleBoxTexture.new()
		style.texture = texture
		style.texture_margin_left = left
		style.texture_margin_top = top
		style.texture_margin_right = right
		style.texture_margin_bottom = bottom
		# Unity centers text in the full button rectangle, so 9-slice margins are not layout padding.
		style.content_margin_left = 0
		style.content_margin_top = 0
		style.content_margin_right = 0
		style.content_margin_bottom = 0
		button.add_theme_stylebox_override(state, style)


func _nine_patch(path: String, patch_position: Vector2, patch_size: Vector2, left: int, top: int, right: int, bottom: int) -> NinePatchRect:
	var patch := NinePatchRect.new()
	patch.position = patch_position
	patch.size = patch_size
	patch.texture = load(path)
	patch.patch_margin_left = left
	patch.patch_margin_top = top
	patch.patch_margin_right = right
	patch.patch_margin_bottom = bottom
	patch.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return patch
