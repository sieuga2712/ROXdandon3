class_name BattleView
extends Node2D

## Plays a BattleSim on screen (docs/khung-ky-thuat.md, section 3).
## The sim decides everything; this script only turns its events into
## animations, numbers and bars.
##
## Opened from the hub with BattleView.request, or run directly (F6) to fight 1-3.

const CharacterScene := preload("res://addons/layer_lab/minimal_character_maker/character/minimal_character.tscn")
const HUB_SCENE := "res://scenes/hub/hub.tscn"
const HAND_TYPES := ["Sword", "Axe", "Bow", "Wand", "Staff", "Spear", "Blunt", "Crossbow", "Shield", "SubItem"]

const PIXELS_PER_UNIT := 1.5
const GROUND_Y := 420.0
const ROW_SPREAD_Y := 42.0
const UNIT_SCALE := 1.3
## Real seconds an attack/skill animation keeps the unit from going back to Idle/Walk.
const ACTION_LOCK := 0.55

## Set by the hub before changing scene: {"stage_id": "1_3"}.
static var request: Dictionary = {}

var profile: Profile
var stage: StageData
var sim: BattleSim
var speed := 1.0
var _accumulator := 0.0
var _event_cursor := 0
var _camera_x := 0.0
var _visuals: Dictionary = {}
var _ult_buttons: Dictionary = {}
var _boss_id := ""
var _result_shown := false

@onready var world: Node2D = $World
@onready var stage_label: Label = %StageLabel
@onready var wave_label: Label = %WaveLabel
@onready var speed_button: Button = %SpeedButton
@onready var back_button: Button = %BackButton
@onready var boss_panel: Control = %BossPanel
@onready var boss_name: Label = %BossName
@onready var boss_hp: ProgressBar = %BossHp
@onready var boss_break: ProgressBar = %BossBreak
@onready var boss_cast: Label = %BossCast
@onready var ult_bar: HBoxContainer = %UltBar
@onready var message: Label = %Message
@onready var result_panel: PanelContainer = %ResultPanel
@onready var result_label: Label = %ResultLabel
@onready var retry_button: Button = %RetryButton
@onready var hub_button: Button = %HubButton


func _ready() -> void:
	GameDB.ensure_loaded()
	profile = SaveService.load_or_create(int(Time.get_unix_time_from_system()))
	stage = GameDB.stage(request.get("stage_id", "1_3"))
	stage_label.text = stage.display_name
	speed_button.pressed.connect(_cycle_speed)
	back_button.pressed.connect(_go_hub)
	hub_button.pressed.connect(_go_hub)
	retry_button.pressed.connect(func(): get_tree().reload_current_scene())
	result_panel.hide()
	boss_panel.hide()
	_style_bar(boss_hp, Color(0.85, 0.25, 0.25))
	_style_bar(boss_break, Color(1.0, 0.8, 0.2))

	var members: Array = profile.active_preset().members
	var errors := StageRules.validate(stage.rules, members)
	if errors.size() > 0:
		message.text = "Đội hình không hợp lệ cho màn này:\n" + "\n".join(errors)
		return
	var heroes: Array[UnitState] = []
	for m in members:
		heroes.append(UnitFactory.hero(profile, m))
	sim = BattleSim.new(stage, heroes, randi())
	for u in sim.ctx.units:
		_spawn_visual(u)
	for h in heroes:
		_add_ult_button(h)
	_camera_x = _target_camera_x()
	_consume_events()


func _process(delta: float) -> void:
	if sim == null:
		return
	_accumulator += delta * speed
	while _accumulator >= BattleSim.TICK and sim.result == BattleSim.Result.RUNNING:
		_accumulator -= BattleSim.TICK
		sim.step()
		_consume_events()
	_update_visuals(delta)
	_update_hud()


# --- events -> visuals ---------------------------------------------------------------

func _consume_events() -> void:
	var moved := {}
	while _event_cursor < sim.ctx.events.size():
		var ev: Dictionary = sim.ctx.events[_event_cursor]
		_event_cursor += 1
		match ev.type:
			&"wave":
				wave_label.text = "Đợt %d/%d" % [ev.index + 1, ev.count]
				for unit_id in ev.units:
					var u := sim.ctx.find(unit_id)
					if not _visuals.has(unit_id):
						_spawn_visual(u)
			&"move":
				moved[ev.source] = true
			&"attack":
				_play_action(ev.source, &"Attack")
			&"skill_cast":
				var anim: StringName = ev.get("animation", &"Attack")
				var u := sim.ctx.find(ev.source)
				# Passives with "always" fire at the start; no animation for those.
				if ev.source in _visuals and sim.ctx.time > 0.0 and (u == null or not _is_always_passive(u, ev.skill)):
					_play_action(ev.source, anim)
					var skill := GameDB.skill(ev.skill)
					if skill and skill.kind != SkillData.Kind.PASSIVE:
						_float_text(ev.source, skill.display_name, Color(1, 0.95, 0.6), -70.0)
			&"damage":
				_float_text(ev.target, str(roundi(ev.amount)), Color(1, 0.85, 0.3) if ev.crit else Color.WHITE, -50.0, 1.3 if ev.crit else 1.0)
			&"heal":
				if ev.amount >= 1.0:
					_float_text(ev.target, "+%d" % roundi(ev.amount), Color(0.5, 1, 0.5), -50.0)
			&"immune":
				_float_text(ev.target, "Miễn", Color(0.7, 0.8, 1), -50.0)
			&"shield":
				_float_text(ev.target, "Khiên", Color(0.6, 0.85, 1), -60.0)
			&"cast_start":
				var skill := GameDB.skill(ev.skill)
				_float_text(ev.source, "Đang niệm: %s" % (skill.display_name if skill else ev.skill), Color(1, 0.5, 0.4), -90.0, 1.2)
			&"break":
				_float_text(ev.target, "PHÁ THANH!", Color(1, 0.9, 0.2), -100.0, 1.6)
				_play_action(ev.target, &"Stun", 1.0)
			&"status_add":
				if ev.status == "stun":
					_play_action(ev.target, &"Stun", ev.duration)
			&"death":
				_play_death(ev.target)
			&"battle_end":
				_show_result(ev.result == "win")
	for unit_id in _visuals:
		var v: Dictionary = _visuals[unit_id]
		if v.dead or Time.get_ticks_msec() / 1000.0 < v.busy_until:
			continue
		_play(v, &"Walk" if moved.has(unit_id) else &"Idle")


func _is_always_passive(u: UnitState, skill_id: StringName) -> bool:
	for p in u.passives:
		if p.id == skill_id and p.when == SkillData.When.ALWAYS:
			return true
	return false


# --- unit visuals --------------------------------------------------------------------

func _spawn_visual(u: UnitState) -> void:
	var holder := Node2D.new()
	holder.name = u.id.replace("#", "_")
	world.add_child(holder)
	var rig: Node2D
	if u.is_monster:
		rig = GameDB.monster(u.class_id).scene.instantiate()
		holder.add_child(rig)
		rig.set_facing_left(true)
	else:
		rig = CharacterScene.instantiate()
		holder.add_child(rig)
		_dress_hero(rig, GameDB.class_data(u.class_id))
	rig.scale = Vector2.ONE * UNIT_SCALE * (1.25 if u.is_boss else 1.0)
	var hp_bar := _make_bar(Color(0.85, 0.25, 0.25), 56.0)
	hp_bar.position = Vector2(-28, 10)
	holder.add_child(hp_bar)
	var mana_bar: ProgressBar = null
	if not u.is_monster:
		mana_bar = _make_bar(Color(0.3, 0.55, 1.0), 56.0, 4.0)
		mana_bar.position = Vector2(-28, 18)
		holder.add_child(mana_bar)
	_visuals[u.id] = {
		"unit": u, "holder": holder, "rig": rig, "hp": hp_bar, "mana": mana_bar,
		"anim": &"", "busy_until": 0.0, "dead": false,
	}
	holder.position = _screen_pos(u)
	if u.is_boss:
		_boss_id = u.id
	_play(_visuals[u.id], &"Idle")


func _dress_hero(rig: Node2D, c: ClassData) -> void:
	rig.randomize_all()
	for t in HAND_TYPES:
		rig.unequip_parts(t)
	rig.equip_parts(c.weapon_part, 0)
	if c.offhand_part != "":
		rig.equip_parts(c.offhand_part, 0)


func _screen_pos(u: UnitState) -> Vector2:
	# Units on the same team and row stand a little apart vertically so they don't overlap.
	var slot := 0
	for other in sim.ctx.units:
		if other == u:
			break
		if other.team == u.team and other.row == u.row:
			slot += 1
	var y := GROUND_Y + (slot % 3) * ROW_SPREAD_Y - ROW_SPREAD_Y + u.row * 6.0
	return Vector2(576.0 + (u.x - _camera_x) * PIXELS_PER_UNIT, y)


func _update_visuals(delta: float) -> void:
	_camera_x = lerpf(_camera_x, _target_camera_x(), clampf(delta * 2.0, 0.0, 1.0))
	for unit_id in _visuals:
		var v: Dictionary = _visuals[unit_id]
		var u: UnitState = v.unit
		var target := _screen_pos(u)
		v.holder.position = v.holder.position.lerp(target, clampf(delta * 12.0, 0.0, 1.0))
		v.holder.z_index = int(v.holder.position.y)
		v.hp.value = 100.0 * u.hp / u.max_hp()
		v.hp.visible = not v.dead
		if v.mana:
			v.mana.value = 100.0 * u.mana / u.mana_max
			v.mana.visible = not v.dead


func _target_camera_x() -> float:
	var front_hero := -INF
	var front_enemy := INF
	for u in sim.ctx.units:
		if not u.alive:
			continue
		if u.team == UnitState.Team.PLAYER:
			front_hero = maxf(front_hero, u.x)
		else:
			front_enemy = minf(front_enemy, u.x)
	if front_hero == -INF:
		return _camera_x
	if front_enemy == INF:
		return front_hero
	return (front_hero + front_enemy) * 0.5


func _play(v: Dictionary, anim: StringName, speed_scale: float = 1.0) -> void:
	if v.anim == anim:
		return
	if v.rig.has_animation(anim):
		v.rig.play_animation(anim, speed_scale * speed)
		v.anim = anim


func _play_action(unit_id: String, anim: StringName, lock: float = ACTION_LOCK) -> void:
	if not _visuals.has(unit_id):
		return
	var v: Dictionary = _visuals[unit_id]
	if v.dead:
		return
	if not v.rig.has_animation(anim):
		anim = &"Attack"
	v.anim = &""
	_play(v, anim)
	v.busy_until = Time.get_ticks_msec() / 1000.0 + lock / speed


func _play_death(unit_id: String) -> void:
	if not _visuals.has(unit_id):
		return
	var v: Dictionary = _visuals[unit_id]
	v.dead = true
	v.anim = &""
	_play(v, &"Dead1")
	var fade := create_tween()
	fade.tween_interval(1.4 / speed)
	fade.tween_property(v.holder, "modulate:a", 0.0, 0.5 / speed)
	if _ult_buttons.has(unit_id):
		_ult_buttons[unit_id].button.disabled = true


func _make_bar(color: Color, width: float, height: float = 6.0) -> ProgressBar:
	var bar := ProgressBar.new()
	bar.custom_minimum_size = Vector2(width, height)
	bar.size = Vector2(width, height)
	bar.show_percentage = false
	_style_bar(bar, color)
	bar.z_index = 1000
	return bar


func _style_bar(bar: ProgressBar, color: Color) -> void:
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color(0, 0, 0, 0.55)
	var fill := StyleBoxFlat.new()
	fill.bg_color = color
	bar.add_theme_stylebox_override("background", bg)
	bar.add_theme_stylebox_override("fill", fill)


func _float_text(unit_id: String, text: String, color: Color, offset_y: float, size_scale: float = 1.0) -> void:
	if not _visuals.has(unit_id):
		return
	var v: Dictionary = _visuals[unit_id]
	var label := Label.new()
	label.text = text
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_outline_color", Color.BLACK)
	label.add_theme_constant_override("outline_size", 6)
	label.add_theme_font_size_override("font_size", roundi(18 * size_scale))
	label.z_index = 2000
	label.position = v.holder.position + Vector2(randf_range(-20, 10), offset_y)
	world.add_child(label)
	var tween := create_tween()
	tween.tween_property(label, "position:y", label.position.y - 40.0, 0.9 / speed)
	tween.parallel().tween_property(label, "modulate:a", 0.0, 0.9 / speed).set_delay(0.3 / speed)
	tween.tween_callback(label.queue_free)


# --- HUD -------------------------------------------------------------------------------

func _add_ult_button(u: UnitState) -> void:
	if u.ultimate.is_empty():
		return
	var box := VBoxContainer.new()
	var button := Button.new()
	button.custom_minimum_size = Vector2(150, 48)
	button.focus_mode = Control.FOCUS_NONE
	var skill := GameDB.skill(u.ultimate.id)
	button.text = "%s\n%s" % [GameDB.class_data(u.class_id).display_name, skill.display_name]
	button.pressed.connect(func(): sim.cast_ultimate(u.id))
	var auto := CheckBox.new()
	auto.text = "Tự động"
	auto.button_pressed = u.auto_ultimate
	auto.focus_mode = Control.FOCUS_NONE
	auto.toggled.connect(func(on: bool):
		u.auto_ultimate = on
		profile.data.classes[u.class_id].auto_ultimate = on
		SaveService.save(profile))
	box.add_child(button)
	box.add_child(auto)
	ult_bar.add_child(box)
	_ult_buttons[u.id] = {"button": button, "unit": u}


func _update_hud() -> void:
	for unit_id in _ult_buttons:
		var entry: Dictionary = _ult_buttons[unit_id]
		var u: UnitState = entry.unit
		var can_cast := u.alive and u.ultimate_ready(sim.ctx.time)
		entry.button.disabled = not can_cast
		entry.button.modulate = Color.WHITE if can_cast else Color(0.75, 0.75, 0.75)
	var boss := sim.ctx.find(_boss_id) if _boss_id != "" else null
	boss_panel.visible = boss != null and boss.alive
	if boss_panel.visible:
		boss_name.text = GameDB.monster(boss.class_id).display_name
		boss_hp.value = 100.0 * boss.hp / boss.max_hp()
		boss_break.value = 100.0 * boss.break_value / boss.break_max
		boss_break.modulate = Color(1, 1, 1, 1.0 if boss.is_casting() and sim.ctx.time >= boss.break_locked_until else 0.35)
		if boss.is_casting():
			boss_cast.text = "Đang niệm %s: %.1fs — dùng skill khống chế để phá thanh!" % [
				GameDB.skill(boss.casting.skill.id).display_name, boss.casting.finish_at - sim.ctx.time]
		else:
			boss_cast.text = ""


func _cycle_speed() -> void:
	speed = {1.0: 2.0, 2.0: 4.0, 4.0: 1.0}[speed]
	speed_button.text = "x%d" % speed


func _show_result(win: bool) -> void:
	if _result_shown:
		return
	_result_shown = true
	var lines := PackedStringArray()
	if win:
		lines.append("THẮNG! (%.1f giây)" % sim.ctx.time)
		var now := int(Time.get_unix_time_from_system())
		if stage.is_daily:
			IdleAndDaily.use_attempt(profile, String(stage.id), now)
		else:
			profile.mark_cleared(stage)
		profile.add_rewards(stage.rewards, "stage:%s" % stage.id)
		for key in stage.rewards:
			lines.append("+%d %s" % [stage.rewards[key], GameDB.currency_name(key)])
		SaveService.save(profile)
	else:
		lines.append("THUA" if sim.ctx.time < sim.max_time else "HẾT GIỜ")
	result_label.text = "\n".join(lines)
	result_panel.show()


func _go_hub() -> void:
	if ResourceLoader.exists(HUB_SCENE):
		get_tree().change_scene_to_file(HUB_SCENE)
