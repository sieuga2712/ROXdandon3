extends Control

const SPINE_RUNTIME_URL := "https://esotericsoftware.com/spine-godot"
const DEMOS := [
    {
        "name": "Minimal Character Maker",
        "scene": "res://addons/layer_lab/minimal_character_maker/demo/main.tscn",
        "requires_spine": false,
    },
    {
        "name": "Casual Character Maker",
        "scene": "res://addons/layer_lab/art_maker/casual/demo/main.tscn",
        "requires_spine": true,
    },
    {
        "name": "Fantasy Character Maker",
        "scene": "res://addons/layer_lab/art_maker/fantasy/demo/main.tscn",
        "requires_spine": true,
    },
]

var _content: VBoxContainer


func _ready() -> void:
    _build_interface()
    var installed := _find_installed_demos()
    if installed.size() == 1 and _can_open(installed[0], false):
        _open_demo.call_deferred(installed[0])
        return
    _show_picker(installed)


func _build_interface() -> void:
    var background := ColorRect.new()
    background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    background.color = Color("202735")
    background.mouse_filter = Control.MOUSE_FILTER_IGNORE
    add_child(background)

    var center := CenterContainer.new()
    center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    add_child(center)

    var panel := PanelContainer.new()
    panel.custom_minimum_size = Vector2(680, 360)
    center.add_child(panel)

    _content = VBoxContainer.new()
    _content.add_theme_constant_override("separation", 18)
    panel.add_child(_content)

    var title := Label.new()
    title.text = "Layer Lab Character Maker Demos"
    title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    title.add_theme_font_size_override("font_size", 30)
    _content.add_child(title)


func _find_installed_demos() -> Array[Dictionary]:
    var installed: Array[Dictionary] = []
    for demo: Dictionary in DEMOS:
        if ResourceLoader.exists(String(demo.scene)):
            installed.append(demo)
    return installed


func _show_picker(installed: Array[Dictionary]) -> void:
    if installed.is_empty():
        _add_message("No Character Maker demo was found under res://addons/layer_lab/.")
        return
    _add_message("Select an installed product demo.")
    for demo: Dictionary in installed:
        var button := Button.new()
        button.text = String(demo.name)
        button.custom_minimum_size = Vector2(520, 52)
        button.pressed.connect(_on_demo_pressed.bind(demo))
        _content.add_child(button)
    if installed.any(func(demo: Dictionary) -> bool: return bool(demo.requires_spine)) and not ClassDB.class_exists("SpineSprite"):
        _show_spine_notice()


func _on_demo_pressed(demo: Dictionary) -> void:
    if _can_open(demo, true):
        _open_demo(demo)


func _can_open(demo: Dictionary, show_notice: bool) -> bool:
    if not bool(demo.requires_spine) or ClassDB.class_exists("SpineSprite"):
        return true
    if show_notice:
        _show_spine_notice()
    return false


func _show_spine_notice() -> void:
    if _content.get_node_or_null("SpineRuntimeNotice") != null:
        return
    var notice := Label.new()
    notice.name = "SpineRuntimeNotice"
    notice.text = "Casual and Fantasy require Spine 4.3 for Godot 4.7.1.
Install the official bin folder at res://bin/, then reopen this project."
    notice.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    notice.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    _content.add_child(notice)
    var download := Button.new()
    download.name = "DownloadSpineRuntime"
    download.text = "Open Spine Runtime Download"
    download.pressed.connect(func() -> void: OS.shell_open(SPINE_RUNTIME_URL))
    _content.add_child(download)


func _add_message(message: String) -> void:
    var label := Label.new()
    label.text = message
    label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    _content.add_child(label)


func _open_demo(demo: Dictionary) -> void:
    var error := get_tree().change_scene_to_file(String(demo.scene))
    if error != OK:
        _add_message("Unable to open %s (error %d)." % [String(demo.name), error])
