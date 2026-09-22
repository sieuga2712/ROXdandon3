extends Control

## Simple character creation screen built on the Layer Lab
## `LayerLabMinimalCharacter` runtime (addons/layer_lab/minimal_character_maker).
## Shows a live preview and lets the player equip parts and pick colors.

const CharacterScene := preload("res://addons/layer_lab/minimal_character_maker/character/minimal_character.tscn")

# Types kept out of the manual tab list: Arrow and HelmetHair are synchronized
# automatically by the runtime (bow/crossbow, hair+helmet) and are not meant
# to be picked directly (see docs/API.md).
const HIDDEN_TYPES := ["Arrow", "HelmetHair"]

const TYPE_LABELS_VI := {
	"Eye": "Mắt",
	"Hair": "Tóc",
	"Helmet": "Mũ",
	"Beard": "Râu",
	"Chest": "Giáp",
	"Sword": "Kiếm",
	"Axe": "Rìu",
	"Bow": "Cung",
	"Shield": "Khiên",
	"Wand": "Đũa phép",
	"Staff": "Trượng",
	"Spear": "Giáo",
	"Blunt": "Chùy",
	"Crossbow": "Nỏ",
	"SubItem": "Phụ kiện",
	"Skin": "Da",
}

# A handful of the 16 available clips (see docs/API.md) so the preview stays compact.
const ANIM_PICKS := ["Idle", "Walk", "Run", "Attack", "Skill", "Dance"]
const ANIM_LABELS_VI := {
	"Idle": "Đứng yên",
	"Walk": "Đi bộ",
	"Run": "Chạy",
	"Attack": "Tấn công",
	"Skill": "Kỹ năng",
	"Dance": "Nhảy múa",
}

@onready var category_box: VBoxContainer = %CategoryBox
@onready var item_grid: GridContainer = %ItemGrid
@onready var preview_holder: Control = %PreviewHolder
@onready var color_box: VBoxContainer = %ColorBox
@onready var anim_flow: HFlowContainer = %AnimFlow
@onready var name_edit: LineEdit = %NameEdit
@onready var create_button: Button = %CreateButton
@onready var random_button: Button = %RandomButton
@onready var result_label: Label = %ResultLabel

var character: LayerLabMinimalCharacter
var current_category: String = ""
var item_buttons: Array = []


func _ready() -> void:
	character = CharacterScene.instantiate() as LayerLabMinimalCharacter
	preview_holder.add_child(character)
	character.parts_changed.connect(func(_type, _index): _refresh_selection_highlight())
	character.parts_visibility_changed.connect(func(_type, _is_visible): _refresh_selection_highlight())

	_build_category_buttons()
	_build_color_pickers()
	_build_animation_buttons()
	create_button.pressed.connect(_on_create_pressed)
	random_button.pressed.connect(_on_random_pressed)

	var types := character.get_all_parts_types()
	for type_name in types:
		if type_name not in HIDDEN_TYPES:
			_select_category(type_name)
			break

	# Position/scale the preview after the panel has its final layout size.
	call_deferred("_layout_preview")


func _layout_preview() -> void:
	var area := preview_holder.size
	character.position = Vector2(area.x * 0.5, area.y * 0.9)
	character.scale = Vector2.ONE * clampf(area.y / 170.0, 0.8, 2.2)


func _build_category_buttons() -> void:
	for type_name in character.get_all_parts_types():
		if type_name in HIDDEN_TYPES:
			continue
		var btn := Button.new()
		btn.text = TYPE_LABELS_VI.get(type_name, character.get_display_name(type_name))
		btn.toggle_mode = true
		btn.focus_mode = Control.FOCUS_NONE
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.set_meta("type_name", type_name)
		btn.pressed.connect(_select_category.bind(type_name))
		category_box.add_child(btn)


func _build_color_pickers() -> void:
	for target in ["Skin", "Hair", "Beard"]:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 8)

		var label := Label.new()
		label.text = target
		label.custom_minimum_size = Vector2(60, 0)
		row.add_child(label)

		var picker := ColorPickerButton.new()
		picker.custom_minimum_size = Vector2(48, 28)
		picker.color = character.get_color(target)
		picker.color_changed.connect(func(color: Color): character.set_color(target, color))
		row.add_child(picker)

		color_box.add_child(row)


func _build_animation_buttons() -> void:
	for anim_name in ANIM_PICKS:
		if not character.has_animation(StringName(anim_name)):
			continue
		var btn := Button.new()
		btn.text = ANIM_LABELS_VI.get(anim_name, anim_name)
		btn.focus_mode = Control.FOCUS_NONE
		btn.pressed.connect(func(): character.play_animation(StringName(anim_name)))
		anim_flow.add_child(btn)


func _select_category(type_name: String) -> void:
	current_category = type_name
	for btn in category_box.get_children():
		btn.set_pressed_no_signal(String(btn.get_meta("type_name")) == type_name)
	_populate_grid(type_name)


func _populate_grid(type_name: String) -> void:
	for child in item_grid.get_children():
		child.queue_free()
	item_buttons.clear()

	if character.can_toggle(type_name):
		var none_btn := _make_item_button(type_name, -1, null)
		item_grid.add_child(none_btn)
		item_buttons.append(none_btn)

	var count := character.get_parts_count(type_name)
	for index in range(count):
		var thumb := character.get_thumbnail(type_name, index)
		var btn := _make_item_button(type_name, index, thumb)
		item_grid.add_child(btn)
		item_buttons.append(btn)

	_refresh_selection_highlight()


func _make_item_button(type_name: String, index: int, thumb: Texture2D) -> Button:
	var btn := Button.new()
	btn.custom_minimum_size = Vector2(72, 72)
	btn.toggle_mode = true
	btn.focus_mode = Control.FOCUS_NONE
	btn.expand_icon = true
	btn.set_meta("index", index)
	if thumb:
		btn.icon = thumb
	else:
		btn.text = "Bỏ"
		btn.tooltip_text = "Không trang bị"
	btn.toggled.connect(_on_item_toggled.bind(type_name, index))
	return btn


func _on_item_toggled(is_on: bool, type_name: String, index: int) -> void:
	if not is_on:
		_refresh_selection_highlight()
		return
	if index < 0:
		character.unequip_parts(type_name)
	else:
		# Hide other members of the same exclusive group (HandRight / HandLeft)
		# before equipping so only one weapon / off-hand item is visible.
		var ui_categories: Dictionary = character.get_ui_categories()
		for ui_category in ui_categories:
			var members: Array = ui_categories[ui_category]
			if type_name in members and members.size() > 1:
				for member in members:
					if member != type_name and character.is_parts_visible(member):
						character.toggle_parts(member, false)
		character.equip_parts(type_name, index)
	_refresh_selection_highlight()


func _refresh_selection_highlight() -> void:
	var equipped_index := character.get_active_index(current_category)
	var is_visible := character.is_parts_visible(current_category)
	for btn in item_buttons:
		var idx: int = btn.get_meta("index")
		if idx < 0:
			btn.set_pressed_no_signal(not is_visible)
		else:
			btn.set_pressed_no_signal(is_visible and idx == equipped_index)


func _on_random_pressed() -> void:
	character.randomize_all()
	_populate_grid(current_category)
	for row in color_box.get_children():
		var picker := row.get_child(1) as ColorPickerButton
		var target: String = (row.get_child(0) as Label).text
		picker.color = character.get_color(target)


func _on_create_pressed() -> void:
	var char_name := name_edit.text.strip_edges()
	if char_name.is_empty():
		char_name = "Nhân vật"
	result_label.text = "Đã tạo \"%s\"." % char_name
