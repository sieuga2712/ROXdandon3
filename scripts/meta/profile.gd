class_name Profile
extends RefCounted

## Everything the save file holds (docs/khung-ky-thuat.md, section 9).
## Only ids and levels are stored; numbers always come from data.

const SAVE_VERSION := 1
const PRESET_SIZE := 4
const PASSIVE_SLOTS := 2
const ACTIVE_SLOTS := 2

var data: Dictionary = {}


static func create_new(now_unix: int) -> Profile:
	GameDB.ensure_loaded()
	var p := Profile.new()
	p.data = {
		"save_version": SAVE_VERSION,
		"classes": {},
		"inventory": {},
		"next_uid": 1,
		"skill_levels_shared": {},
		"skill_levels_class": {},
		"presets": [],
		"active_preset": 0,
		"progress": {"cleared": [], "highest": ""},
		"idle_last_claim": now_unix,
		"daily": {"date": "", "used": {}},
		"wallet": {"gold": 0},
		"gems": {},
		"materials": {},
		"ledger": {},
	}
	var starter_items := {
		"knight": ["sword_wood", "armor_balanced_iron", "helm_balanced_iron", "ring_power"],
		"warrior": ["sword_wood", "armor_balanced_iron", "helm_balanced_iron", "ring_power"],
		"archer": ["bow_wood", "armor_light_leather", "helm_light_leather", "ring_power"],
		"priest": ["wand_wood", "armor_magic_robe", "helm_magic_hood", "amulet_life"],
		"mage": ["staff_wood", "armor_magic_robe", "helm_magic_hood", "amulet_life"],
	}
	for class_id: String in GameDB.classes:
		p.data.classes[class_id] = {"unlocked": true, "appearance": {}, "equipment": {}, "auto_ultimate": true}
		for base_id in starter_items.get(class_id, []):
			if GameDB.item(base_id):
				p.equip(class_id, p.add_item(base_id))
	var default_team := [["knight", 0], ["warrior", 0], ["priest", 1], ["archer", 2]]
	var members: Array = []
	for pair in default_team:
		if GameDB.class_data(pair[0]):
			members.append(p.default_member(pair[0], pair[1]))
	p.data.presets = [{"name": "Đội 1", "members": members}]
	return p


func default_member(class_id: String, row: int) -> Dictionary:
	var c := GameDB.class_data(class_id)
	return {
		"class_id": class_id, "row": row,
		"passives": Array(c.default_passives), "actives": Array(c.default_actives),
		"ultimate": String(c.default_ultimate),
	}


# --- currencies ----------------------------------------------------------------

## Currencies: "gold", "gem_0".."gem_9", or any material id. Every change is logged per reason.
func amount(key: String) -> float:
	if key == "gold":
		return data.wallet.gold
	if key.begins_with("gem_"):
		return data.gems.get(key, 0)
	return data.materials.get(key, 0)


func add(key: String, value: float, reason: String) -> void:
	if key == "gold":
		data.wallet.gold += value
	elif key.begins_with("gem_"):
		data.gems[key] = data.gems.get(key, 0) + value
	else:
		data.materials[key] = data.materials.get(key, 0) + value
	var ledger_key := "%s:%s" % [key, reason]
	data.ledger[ledger_key] = data.ledger.get(ledger_key, 0) + value


func spend(key: String, value: float, reason: String) -> bool:
	if amount(key) < value:
		return false
	add(key, -value, reason)
	return true


func add_rewards(rewards: Dictionary, reason: String, multiplier: float = 1.0) -> void:
	for key in rewards:
		add(key, floorf(rewards[key] * multiplier), reason)


# --- items -------------------------------------------------------------------

func add_item(base_id: String) -> String:
	var uid := "it%d" % data.next_uid
	data.next_uid += 1
	data.inventory[uid] = {"base": base_id, "level": 0}
	return uid


func item_level(uid: String) -> int:
	return data.inventory[uid].level


func item_base(uid: String) -> ItemData:
	return GameDB.item(data.inventory[uid].base)


## Stats of an owned item after enhance: base × (1 + bonus × level), linear (decision 19).
func item_stats(uid: String) -> Dictionary:
	var base := item_base(uid)
	var level := item_level(uid)
	var out := {}
	for stat in base.stats:
		var mult := 1.0
		if not GameDB.config.enhance_excluded_stats.has(stat):
			mult += GameDB.config.enhance_bonus * level
		out[stat] = base.stats[stat] * mult
	return out


## Who wears [param uid], or "" if nobody.
func item_owner(uid: String) -> String:
	for class_id in data.classes:
		if data.classes[class_id].equipment.values().has(uid):
			return class_id
	return ""


func can_equip(class_id: String, uid: String) -> bool:
	var c := GameDB.class_data(class_id)
	return c != null and data.inventory.has(uid) and c.can_wear(item_base(uid).equip_tag)


## Puts [param uid] on [param class_id], taking it off whoever had it.
func equip(class_id: String, uid: String) -> bool:
	if not can_equip(class_id, uid):
		return false
	var previous_owner := item_owner(uid)
	if previous_owner != "":
		data.classes[previous_owner].equipment.erase(item_base(uid).slot)
	data.classes[class_id].equipment[item_base(uid).slot] = uid
	return true


func unequip(class_id: String, slot: String) -> void:
	data.classes[class_id].equipment.erase(slot)


# --- skills ------------------------------------------------------------------

## Shared skills level per account, class skills per class (decision 15).
func skill_level(class_id: String, skill_id: String) -> int:
	var s := GameDB.skill(skill_id)
	if s == null:
		return 1
	if s.is_shared():
		return data.skill_levels_shared.get(skill_id, 1)
	return data.skill_levels_class.get(class_id, {}).get(skill_id, 1)


func set_skill_level(class_id: String, skill_id: String, level: int) -> void:
	var s := GameDB.skill(skill_id)
	if s.is_shared():
		data.skill_levels_shared[skill_id] = level
	else:
		if not data.skill_levels_class.has(class_id):
			data.skill_levels_class[class_id] = {}
		data.skill_levels_class[class_id][skill_id] = level


## Checks a preset member's skills fit their slots and class (section 4.7).
func validate_member(member: Dictionary) -> PackedStringArray:
	var errors := PackedStringArray()
	var class_id: String = member.class_id
	var slots := {"passives": [SkillData.Kind.PASSIVE, PASSIVE_SLOTS], "actives": [SkillData.Kind.COOLDOWN, ACTIVE_SLOTS]}
	for key in slots:
		var ids: Array = member.get(key, [])
		if ids.size() > slots[key][1]:
			errors.append("%s: quá %d skill ở ô %s" % [class_id, slots[key][1], key])
		var seen := {}
		for skill_id in ids:
			var s := GameDB.skill(skill_id)
			if s == null:
				errors.append("%s: không có skill %s" % [class_id, skill_id])
			elif s.kind != slots[key][0]:
				errors.append("%s: %s sai loại ô" % [class_id, skill_id])
			elif not s.can_equip(class_id):
				errors.append("%s: không lắp được %s" % [class_id, skill_id])
			if seen.has(skill_id):
				errors.append("%s: lắp trùng %s" % [class_id, skill_id])
			seen[skill_id] = true
	var ult: String = member.get("ultimate", "")
	if ult != "":
		var u := GameDB.skill(ult)
		if u == null or u.kind != SkillData.Kind.ULTIMATE or not u.can_equip(class_id):
			errors.append("%s: chiêu cuối %s không hợp lệ" % [class_id, ult])
	return errors


func active_preset() -> Dictionary:
	return data.presets[data.active_preset]


# --- progress ----------------------------------------------------------------

func mark_cleared(stage: StageData) -> void:
	if stage.is_daily or data.progress.cleared.has(String(stage.id)):
		return
	data.progress.cleared.append(String(stage.id))
	var order := GameDB.main_stages()
	var best := -1
	for i in order.size():
		if data.progress.cleared.has(String(order[i].id)):
			best = i
	data.progress.highest = String(order[best].id) if best >= 0 else ""


func is_cleared(stage_id: String) -> bool:
	return data.progress.cleared.has(stage_id)
