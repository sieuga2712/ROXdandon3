extends Control

## Main menu between battles: stages, daily dungeons, team preset, equipment,
## inventory and idle rewards. UI is rebuilt from the profile after every change.

const BATTLE_SCENE := "res://scenes/battle/battle_view.tscn"
const ROW_NAMES := ["Hàng đầu", "Hàng giữa", "Hàng cuối"]
const SLOT_NAMES := {"weapon": "Vũ khí", "armor": "Áo", "helmet": "Mũ", "accessory": "Phụ kiện"}
## Temporary shop so items can be tested before drops exist.
const SHOP_PRICE := 1500

var profile: Profile
var rng := RandomNumberGenerator.new()
var _equip_class := "knight"

@onready var gold_label: Label = %GoldLabel
@onready var idle_button: Button = %IdleButton
@onready var toast: Label = %Toast
@onready var stages_box: VBoxContainer = %StagesBox
@onready var daily_box: VBoxContainer = %DailyBox
@onready var team_box: VBoxContainer = %TeamBox
@onready var equip_box: VBoxContainer = %EquipBox
@onready var bag_box: VBoxContainer = %BagBox


func _ready() -> void:
	GameDB.ensure_loaded()
	rng.randomize()
	profile = SaveService.load_or_create(_now())
	idle_button.pressed.connect(_claim_idle)
	_refresh()


func _process(_delta: float) -> void:
	var preview := IdleAndDaily.idle_preview(profile, _now())
	idle_button.text = "Treo máy %.1fh: %s" % [preview.hours, _rewards_text(preview.rewards)] if preview.rewards.size() > 0 else "Treo máy: chưa có gì"
	idle_button.disabled = preview.rewards.is_empty()


func _now() -> int:
	return int(Time.get_unix_time_from_system())


func _save_and_refresh(note: String = "") -> void:
	SaveService.save(profile)
	if note != "":
		toast.text = note
	# Deferred: the button that triggered this is rebuilt by _refresh().
	_refresh.call_deferred()


func _refresh() -> void:
	gold_label.text = "Vàng: %d   %s" % [profile.amount("gold"), _gems_text()]
	_build_stages()
	_build_daily()
	_build_team()
	_build_equipment()
	_build_bag()


# --- stages ----------------------------------------------------------------------------

func _build_stages() -> void:
	_clear(stages_box)
	var stages := GameDB.main_stages()
	for i in stages.size():
		var s := stages[i]
		var unlocked := i == 0 or profile.is_cleared(String(s.id)) or profile.is_cleared(String(stages[i - 1].id))
		var text := "%s %s" % ["✓" if profile.is_cleared(String(s.id)) else ("•" if unlocked else "[khóa]"), s.display_name]
		stages_box.add_child(_stage_row(s, text, unlocked, ""))


func _build_daily() -> void:
	_clear(daily_box)
	daily_box.add_child(_label("Hôm nay mở:", 18))
	for s in IdleAndDaily.todays_dungeons(_now()):
		var left := IdleAndDaily.attempts_left(profile, String(s.id), _now())
		daily_box.add_child(_stage_row(s, "%s (còn %d lượt)" % [s.display_name, left], left > 0, "Hết lượt hôm nay" if left <= 0 else ""))


func _stage_row(s: StageData, title: String, enabled: bool, why_disabled: String) -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 16)
	var info := VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.add_child(_label(title, 18))
	var details := PackedStringArray()
	for r in s.rules:
		details.append(StageRules.describe(r))
	details.append("Thưởng: " + _rewards_text(s.rewards))
	info.add_child(_label("  " + " · ".join(details), 14, Color(0.8, 0.8, 0.8), true))
	var errors := StageRules.validate(s.rules, profile.active_preset().members)
	if errors.size() > 0:
		info.add_child(_label("  Đội hiện tại không hợp lệ: " + "; ".join(errors), 14, Color(1, 0.6, 0.5), true))
	row.add_child(info)
	var go := Button.new()
	go.text = "Đánh"
	go.custom_minimum_size = Vector2(90, 40)
	go.disabled = not enabled or errors.size() > 0
	go.tooltip_text = why_disabled
	go.pressed.connect(func():
		BattleView.request = {"stage_id": String(s.id)}
		get_tree().change_scene_to_file(BATTLE_SCENE))
	row.add_child(go)
	return row


# --- team preset (section 4.7) -------------------------------------------------------------

func _build_team() -> void:
	_clear(team_box)
	var preset := profile.active_preset()
	team_box.add_child(_label("Preset: %s — mỗi người 2 nội tại, 2 hồi chiêu, 1 chiêu cuối" % preset.name, 18))
	var class_ids: Array = GameDB.classes.keys()
	for i in preset.members.size():
		var m: Dictionary = preset.members[i]
		var box := VBoxContainer.new()
		var line := HBoxContainer.new()
		line.add_child(_label("%d." % (i + 1), 16))
		var class_pick := _option(class_ids.map(func(c): return GameDB.class_data(c).display_name), class_ids.find(m.class_id))
		class_pick.item_selected.connect(func(idx: int): _change_member_class(i, class_ids[idx]))
		line.add_child(class_pick)
		var row_pick := _option(ROW_NAMES, int(m.row))
		row_pick.item_selected.connect(func(idx: int):
			m.row = idx
			_save_and_refresh())
		line.add_child(row_pick)
		box.add_child(line)
		var skills_line := HBoxContainer.new()
		for slot in [["passives", 0, SkillData.Kind.PASSIVE], ["passives", 1, SkillData.Kind.PASSIVE],
				["actives", 0, SkillData.Kind.COOLDOWN], ["actives", 1, SkillData.Kind.COOLDOWN]]:
			skills_line.add_child(_skill_picker(m, slot[0], slot[1], slot[2]))
		skills_line.add_child(_skill_picker(m, "ultimate", -1, SkillData.Kind.ULTIMATE))
		box.add_child(skills_line)
		var errors := profile.validate_member(m)
		if errors.size() > 0:
			box.add_child(_label("  " + "; ".join(errors), 14, Color(1, 0.6, 0.5), true))
		team_box.add_child(box)
		team_box.add_child(HSeparator.new())


func _change_member_class(index: int, class_id: String) -> void:
	var members: Array = profile.active_preset().members
	for j in members.size():
		if j != index and members[j].class_id == class_id:
			toast.text = "%s đã có trong đội" % GameDB.class_data(class_id).display_name
			_refresh.call_deferred()
			return
	members[index] = profile.default_member(class_id, int(members[index].row))
	_save_and_refresh()


func _skill_picker(m: Dictionary, key: String, index: int, kind: SkillData.Kind) -> OptionButton:
	var ids: Array = [""]
	var names: Array = ["(trống)"]
	for s: SkillData in GameDB.skills.values():
		if s.kind == kind and s.can_equip(m.class_id) and not s.class_tags.has("monster"):
			ids.append(String(s.id))
			names.append(s.display_name + (" [chung]" if s.is_shared() else ""))
	var current := ""
	if key == "ultimate":
		current = m.get("ultimate", "")
	elif index < m[key].size():
		current = m[key][index]
	var pick := _option(names, maxi(ids.find(current), 0))
	pick.item_selected.connect(func(idx: int):
		if key == "ultimate":
			m.ultimate = ids[idx]
		else:
			var list: Array = m[key]
			while list.size() <= index:
				list.append("")
			list[index] = ids[idx]
			m[key] = list.filter(func(x): return x != "")
		_save_and_refresh())
	return pick


# --- equipment (section 7) ------------------------------------------------------------------

func _build_equipment() -> void:
	_clear(equip_box)
	var class_ids: Array = GameDB.classes.keys()
	var top := HBoxContainer.new()
	top.add_child(_label("Nhân vật:", 16))
	var pick := _option(class_ids.map(func(c): return GameDB.class_data(c).display_name), class_ids.find(_equip_class))
	pick.item_selected.connect(func(idx: int):
		_equip_class = class_ids[idx]
		_refresh.call_deferred())
	top.add_child(pick)
	equip_box.add_child(top)
	var equipment: Dictionary = profile.data.classes[_equip_class].equipment
	for slot in ItemData.SLOTS:
		equip_box.add_child(HSeparator.new())
		var uid: String = equipment.get(slot, "")
		equip_box.add_child(_label("%s: %s" % [SLOT_NAMES[slot], _item_text(uid) if uid != "" else "(trống)"], 17))
		var actions := HBoxContainer.new()
		actions.add_theme_constant_override("separation", 8)
		if uid != "":
			var cost := Enhance.cost_for(profile.item_level(uid) + 1)
			var up := Button.new()
			up.text = "Cường hóa +1 (%d %s, %d vàng, %d%%)" % [cost.gem_count, GameDB.currency_name(Enhance.gem_key(int(cost.gem_tier))), cost.gold_cost, roundi(cost.success_rate * 100)] if not cost.is_empty() else "Đã tối đa"
			up.disabled = cost.is_empty()
			up.pressed.connect(func():
				var r := Enhance.enhance(profile, uid, rng)
				_save_and_refresh({"ok": "Cường hóa thành công!", "fail": "Thất bại, mất nguyên liệu", "not_enough": "Không đủ đá hoặc vàng", "max": "Đã tối đa"}.get(r, r)))
			actions.add_child(up)
		# Other items for this slot this class can wear.
		var others: Array = []
		for other_uid in profile.data.inventory:
			if other_uid != uid and profile.item_base(other_uid).slot == slot and profile.can_equip(_equip_class, other_uid):
				others.append(other_uid)
		if others.size() > 0:
			var choose := _option(others.map(func(o): return _item_text(o) + _owner_note(o)), 0)
			actions.add_child(choose)
			var wear := Button.new()
			wear.text = "Mặc"
			wear.pressed.connect(func():
				profile.equip(_equip_class, others[choose.selected])
				_save_and_refresh("Đã đổi đồ"))
			actions.add_child(wear)
			if uid != "" and profile.item_level(uid) > 0:
				var move := Button.new()
				var quote := Enhance.transfer_quote(profile, uid)
				move.text = "Chuyển cấp sang món đã chọn (%d vàng)" % quote.gold
				move.pressed.connect(func():
					var r := Enhance.transfer(profile, uid, others[choose.selected])
					_save_and_refresh({"ok": "Đã chuyển cấp cường hóa", "not_enough": "Không đủ vàng"}.get(r, r)))
				actions.add_child(move)
		equip_box.add_child(actions)
	equip_box.add_child(HSeparator.new())
	equip_box.add_child(_label("Cửa hàng tạm (để thử đổi đồ, %d vàng/món):" % SHOP_PRICE, 16))
	var shop := HFlowContainer.new()
	for item: ItemData in GameDB.items.values():
		if not GameDB.class_data(_equip_class).can_wear(item.equip_tag):
			continue
		var buy := Button.new()
		buy.text = "Mua %s" % item.display_name
		buy.pressed.connect(func():
			if profile.spend("gold", SHOP_PRICE, "shop"):
				profile.add_item(String(item.id))
				_save_and_refresh("Đã mua %s" % item.display_name)
			else:
				toast.text = "Không đủ vàng")
		shop.add_child(buy)
	equip_box.add_child(shop)


func _item_text(uid: String) -> String:
	var base := profile.item_base(uid)
	var stats := profile.item_stats(uid)
	var parts := PackedStringArray()
	for stat in stats:
		var v: float = stats[stat]
		parts.append("%s %s" % [stat, ("%.0f%%" % (v * 100)) if v < 1.0 else ("%.0f" % v)])
	return "%s +%d (%s)" % [base.display_name, profile.item_level(uid), ", ".join(parts)]


func _owner_note(uid: String) -> String:
	var owner := profile.item_owner(uid)
	return " — đang ở %s" % GameDB.class_data(owner).display_name if owner != "" else ""


# --- bag ------------------------------------------------------------------------------------

func _build_bag() -> void:
	_clear(bag_box)
	bag_box.add_child(_label("Vàng: %d" % profile.amount("gold"), 18))
	for tier in 10:
		var key := Enhance.gem_key(tier)
		var line := HBoxContainer.new()
		line.add_child(_label("%s: %d" % [GameDB.currency_name(key), profile.amount(key)], 16))
		if tier < 9:
			var merge := Button.new()
			merge.text = "Ghép 3 → 1 bậc trên"
			merge.disabled = profile.amount(key) < 3
			merge.pressed.connect(func():
				var n := Enhance.merge_gems(profile, tier, 1)
				_save_and_refresh("Đã ghép" if n > 0 else "Không đủ đá hoặc vàng"))
			line.add_child(merge)
		bag_box.add_child(line)


# --- idle -----------------------------------------------------------------------------------

func _claim_idle() -> void:
	var got := IdleAndDaily.claim_idle(profile, _now())
	_save_and_refresh("Nhận treo máy: " + _rewards_text(got.rewards))


# --- helpers --------------------------------------------------------------------------------

func _rewards_text(rewards: Dictionary) -> String:
	var parts := PackedStringArray()
	for key in rewards:
		parts.append("%d %s" % [rewards[key], GameDB.currency_name(key)])
	return ", ".join(parts)


func _gems_text() -> String:
	var parts := PackedStringArray()
	for tier in 10:
		var n := profile.amount(Enhance.gem_key(tier))
		if n > 0:
			parts.append("%s: %d" % [GameDB.currency_name(Enhance.gem_key(tier)), n])
	return "  ".join(parts)


func _label(text: String, size: int = 16, color: Color = Color.WHITE, wrap: bool = false) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	if wrap:
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return l


func _option(names: Array, selected: int) -> OptionButton:
	var o := OptionButton.new()
	for n in names:
		o.add_item(n)
	o.selected = selected
	return o


func _clear(box: Node) -> void:
	for c in box.get_children():
		box.remove_child(c)
		c.queue_free()
