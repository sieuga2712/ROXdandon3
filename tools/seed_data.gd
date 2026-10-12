extends SceneTree

## Writes the starting data set into res://data (classes, skills, monsters,
## items, stages, config, economy CSVs). Every number is a placeholder to tune.
##
## Run once: Godot_console.exe --headless --path . -s res://tools/seed_data.gd
## WARNING: running it again overwrites edits made to those files in the editor.
## After the first run, edit the .tres/.csv files directly.

const OUT := "res://data"


func _initialize() -> void:
	for sub in ["classes", "skills", "monsters", "items", "stages", "economy"]:
		DirAccess.make_dir_recursive_absolute("%s/%s" % [OUT, sub])
	_skills()
	_classes()
	_monsters()
	_items()
	_stages()
	_config()
	_economy()
	print("Seeded data into %s" % OUT)
	quit()


func _save(res: Resource, sub: String) -> void:
	var path := "%s/%s/%s.tres" % [OUT, sub, res.id]
	var err := ResourceSaver.save(res, path)
	if err != OK:
		printerr("Cannot save %s (%d)" % [path, err])


# --- skills -----------------------------------------------------------------------

func _skill(id: String, name: String, kind: SkillData.Kind, tags: Array, fields: Dictionary, effects: Array) -> void:
	var s := SkillData.new()
	s.id = id
	s.display_name = name
	s.kind = kind
	s.class_tags = PackedStringArray(tags)
	for key in fields:
		s.set(key, fields[key])
	var typed: Array[Dictionary] = []
	for e in effects:
		typed.append(e)
	s.effects = typed
	_save(s, "skills")


func _skills() -> void:
	var P := SkillData.Kind.PASSIVE
	var C := SkillData.Kind.COOLDOWN
	var U := SkillData.Kind.ULTIMATE
	var ALWAYS := SkillData.When.ALWAYS
	var ON_ATTACK := SkillData.When.ON_ATTACK
	var ult := {"cooldown": 20.0, "start_cooldown": 5.0, "mana_cost": 100.0, "animation": &"Skill"}

	# Cung thủ
	_skill("archer_team_haste", "Tăng tốc đánh (team)", P, ["archer"], {"when": ALWAYS, "target": &"all_allies", "target_count": 0},
		[{"type": "modify_stat", "stat": "atsp", "value": 0.10, "mode": "percent"}])
	_skill("archer_quick_draw", "Tăng tốc đánh bất chợt", P, ["archer"], {"when": ON_ATTACK, "chance": 0.15, "target": &"self"},
		[{"type": "modify_stat", "stat": "atsp", "value": 0.30, "mode": "percent", "duration": 3.0, "stack_rule": "highest"}])
	_skill("archer_arrow_rain", "Mưa tên", C, ["archer"], {"cooldown": 8.0, "start_cooldown": 2.0, "target": &"random_enemy", "target_count": 5},
		[{"type": "damage", "scale": 0.6}])
	_skill("archer_piercing_shot", "Tên xuyên tim", U, ["archer"], ult.merged({"target": &"highest_hp_enemy"}, true),
		[{"type": "damage", "scale": 4.0, "force_crit": true}])

	# Chiến binh
	_skill("warrior_team_might", "Tăng sát thương (team)", P, ["warrior"], {"when": ALWAYS, "target": &"all_allies", "target_count": 0},
		[{"type": "modify_stat", "stat": "atk", "value": 0.08, "mode": "percent"},
		 {"type": "modify_stat", "stat": "matk", "value": 0.08, "mode": "percent"}])
	_skill("warrior_bloodlust", "Hút máu, 3 đòn liên tiếp", P, ["warrior"], {"when": ON_ATTACK, "chance": 0.12, "target": &"self"},
		[{"type": "modify_stat", "stat": "lifesteal", "value": 0.2, "duration": 3.0, "stack_rule": "highest"},
		 {"type": "extra_attacks", "count": 2}])
	_skill("warrior_whirlwind", "Chém xoáy", C, ["warrior"], {"cooldown": 10.0, "start_cooldown": 3.0, "target": &"enemies_near_self", "target_count": 0, "radius": 120.0},
		[{"type": "damage", "scale": 1.2},
		 {"type": "modify_stat", "stat": "lifesteal", "value": 0.15, "duration": 3.0, "on": "self"}])
	_skill("warrior_rage", "Cuồng nộ", U, ["warrior"], ult.merged({"target": &"self"}, true),
		[{"type": "modify_stat", "stat": "atk", "value": 0.5, "mode": "percent", "duration": 8.0}])

	# Tu sĩ
	_skill("priest_team_vitality", "Tăng HP (team)", P, ["priest"], {"when": ALWAYS, "target": &"all_allies", "target_count": 0},
		[{"type": "modify_stat", "stat": "hp", "value": 0.10, "mode": "percent"}])
	_skill("priest_smite", "Sát thương 2 lần + hồi máu", P, ["priest"], {"when": ON_ATTACK, "chance": 0.2, "target": &"current_target"},
		[{"type": "damage", "scale": 0.5, "damage_type": "magic", "hits": 2},
		 {"type": "heal", "scale": 0.08, "basis": "max_hp", "target": "lowest_hp_ally"}])
	_skill("priest_purify", "Ánh sáng thanh tẩy", C, ["priest"], {"cooldown": 12.0, "start_cooldown": 4.0, "target": &"all_allies", "target_count": 0},
		[{"type": "heal", "scale": 0.15, "basis": "max_hp"}, {"type": "cleanse", "count": 1}])
	_skill("priest_blessing", "Phước lành", U, ["priest"], ult.merged({"cooldown": 25.0, "target": &"all_allies", "target_count": 0}, true),
		[{"type": "heal", "scale": 0.4, "basis": "max_hp"}, {"type": "undying", "duration": 3.0}])

	# Hiệp sĩ
	_skill("knight_team_guard", "Tăng giáp (team)", P, ["knight"], {"when": ALWAYS, "target": &"all_allies", "target_count": 0},
		[{"type": "modify_stat", "stat": "def", "value": 0.10, "mode": "percent"}])
	_skill("knight_barrier", "Tạo giáp ảo", P, ["knight"], {"when": ON_ATTACK, "chance": 0.15, "target": &"self"},
		[{"type": "shield", "scale": 0.08, "basis": "caster_max_hp", "duration": 4.0}])
	_skill("knight_taunt", "Khiêu khích", C, ["knight"], {"cooldown": 10.0, "start_cooldown": 2.0, "target": &"enemies_near_self", "target_count": 0, "radius": 150.0, "break_power": 40.0},
		[{"type": "taunt", "duration": 4.0},
		 {"type": "modify_stat", "stat": "damage_taken", "value": -0.3, "duration": 4.0, "on": "self"}])
	_skill("knight_fortress", "Thành trì", U, ["knight"], ult.merged({"cooldown": 22.0, "target": &"all_allies", "target_count": 0}, true),
		[{"type": "shield", "scale": 0.2, "basis": "caster_max_hp", "duration": 6.0}])

	# Pháp sư
	_skill("mage_team_focus", "Tăng hồi mana (team)", P, ["mage"], {"when": ALWAYS, "target": &"all_allies", "target_count": 0},
		[{"type": "modify_stat", "stat": "mana_regen", "value": 1.0}])
	_skill("mage_arcane_burst", "Sát thương AoE", P, ["mage"], {"when": ON_ATTACK, "chance": 0.15, "target": &"enemies_near_target", "target_count": 0, "radius": 80.0},
		[{"type": "damage", "scale": 0.4, "damage_type": "magic"}])
	_skill("mage_frost", "Băng giá", C, ["mage"], {"cooldown": 9.0, "start_cooldown": 3.0, "target": &"enemies_near_target", "target_count": 0, "radius": 100.0, "break_power": 30.0},
		[{"type": "damage", "scale": 1.0, "damage_type": "magic"}, {"type": "slow", "value": 0.3, "duration": 3.0}])
	_skill("mage_meteor", "Thiên thạch", U, ["mage"], ult.merged({"target": &"enemies_near_target", "target_count": 0, "radius": 120.0, "break_power": 60.0}, true),
		[{"type": "damage", "scale": 3.5, "damage_type": "magic"}, {"type": "stun", "duration": 2.0}])

	# Kho chung (class nào cũng lắp được)
	_skill("shared_stun_strike", "Đòn choáng", C, [], {"cooldown": 12.0, "start_cooldown": 4.0, "target": &"current_target", "break_power": 35.0},
		[{"type": "damage", "scale": 0.8}, {"type": "stun", "duration": 1.0}])
	_skill("shared_second_wind", "Hồi sức", P, [], {"when": SkillData.When.ON_LOW_HP, "threshold": 0.3, "target": &"self"},
		[{"type": "heal", "scale": 0.25, "basis": "max_hp"}])

	# Quái
	_skill("slime_bash", "Húc", C, ["monster"], {"cooldown": 6.0, "start_cooldown": 3.0, "target": &"current_target"},
		[{"type": "damage", "scale": 1.3}])
	_skill("stone_throw", "Ném đá", C, ["monster"], {"cooldown": 7.0, "start_cooldown": 2.0, "target": &"current_target"},
		[{"type": "damage", "scale": 1.5}])
	_skill("slime_king_quake", "Động đất", C, ["monster"], {"cooldown": 12.0, "start_cooldown": 6.0, "cast_time": 2.5, "target": &"all_enemies", "target_count": 0},
		[{"type": "damage", "scale": 2.2}])


# --- classes ----------------------------------------------------------------------

func _class(id: String, name: String, stats: Dictionary, attrs: Dictionary, tags: Array, prefix: String) -> void:
	var c := ClassData.new()
	c.id = id
	c.display_name = name
	c.base_stats = stats
	for key in attrs:
		c.set(key, attrs[key])
	c.equip_tags = PackedStringArray(tags)
	var passives: Array = []
	var actives: Array = []
	var ultimate := &""
	for skill_path in DirAccess.get_files_at(OUT + "/skills"):
		var s: SkillData = load("%s/skills/%s" % [OUT, skill_path])
		if not String(s.id).begins_with(prefix + "_"):
			continue
		match s.kind:
			SkillData.Kind.PASSIVE:
				passives.append(String(s.id))
			SkillData.Kind.COOLDOWN:
				actives.append(String(s.id))
			SkillData.Kind.ULTIMATE:
				ultimate = s.id
	c.default_passives = PackedStringArray(passives)
	c.default_actives = PackedStringArray(actives)
	c.default_ultimate = ultimate
	_save(c, "classes")


func _classes() -> void:
	var common := {"crit": 0.05, "mana_regen": 1.0}
	_class("knight", "Hiệp sĩ", common.merged({"hp": 1800.0, "atk": 80.0, "matk": 20.0, "def": 60.0, "mdef": 40.0, "atsp": 0.8}, true),
		{"move_speed": 90.0, "attack_range": 60.0, "weapon_part": "Sword", "offhand_part": "Shield"},
		["sword", "armor_balanced", "accessory"], "knight")
	_class("warrior", "Chiến binh", common.merged({"hp": 1400.0, "atk": 115.0, "matk": 20.0, "def": 40.0, "mdef": 25.0, "atsp": 1.0, "crit": 0.08}, true),
		{"move_speed": 100.0, "attack_range": 60.0, "weapon_part": "Sword"},
		["sword", "armor_balanced", "accessory"], "warrior")
	_class("archer", "Cung thủ", common.merged({"hp": 900.0, "atk": 105.0, "matk": 20.0, "def": 20.0, "mdef": 20.0, "atsp": 1.3, "crit": 0.15}, true),
		{"move_speed": 100.0, "attack_range": 300.0, "weapon_part": "Bow"},
		["bow", "armor_light", "accessory"], "archer")
	_class("priest", "Tu sĩ", common.merged({"hp": 1000.0, "atk": 40.0, "matk": 85.0, "def": 22.0, "mdef": 50.0, "atsp": 0.9}, true),
		{"move_speed": 95.0, "attack_range": 260.0, "attack_type": "magic", "weapon_part": "Wand"},
		["wand", "armor_magic", "accessory"], "priest")
	_class("mage", "Pháp sư", common.merged({"hp": 850.0, "atk": 30.0, "matk": 125.0, "def": 15.0, "mdef": 45.0, "atsp": 0.8}, true),
		{"move_speed": 95.0, "attack_range": 280.0, "attack_type": "magic", "weapon_part": "Staff"},
		["staff", "armor_magic", "accessory"], "mage")


# --- monsters ---------------------------------------------------------------------

func _monster(id: String, name: String, stats: Dictionary, attrs: Dictionary, skills: Array) -> void:
	var m := MonsterData.new()
	m.id = id
	m.display_name = name
	m.base_stats = stats
	for key in attrs:
		m.set(key, attrs[key])
	m.skills = PackedStringArray(skills)
	m.scene = load("res://scenes/monsters/slime/%s.tscn" % id)
	_save(m, "monsters")


func _monsters() -> void:
	_monster("slime_green", "Slime xanh", {"hp": 700.0, "atk": 45.0, "def": 15.0, "mdef": 10.0, "atsp": 0.8},
		{"move_speed": 60.0, "attack_range": 55.0}, ["slime_bash"])
	_monster("slime_orange", "Slime cam", {"hp": 950.0, "atk": 58.0, "def": 20.0, "mdef": 14.0, "atsp": 0.85},
		{"move_speed": 65.0, "attack_range": 55.0}, ["slime_bash"])
	_monster("slime_stone_green", "Slime đá xanh", {"hp": 550.0, "atk": 55.0, "def": 40.0, "mdef": 10.0, "atsp": 0.7},
		{"move_speed": 55.0, "attack_range": 220.0}, ["stone_throw"])
	_monster("slime_stone_orange", "Slime đá cam", {"hp": 750.0, "atk": 70.0, "def": 50.0, "mdef": 14.0, "atsp": 0.75},
		{"move_speed": 55.0, "attack_range": 220.0}, ["stone_throw"])
	_monster("slime_king_green", "Vua slime xanh", {"hp": 9000.0, "atk": 85.0, "def": 45.0, "mdef": 30.0, "atsp": 0.7},
		{"move_speed": 50.0, "attack_range": 70.0, "is_boss": true, "break_max": 100.0, "break_lock": 4.0}, ["slime_bash", "slime_king_quake"])
	_monster("slime_king_orange", "Vua slime cam", {"hp": 14000.0, "atk": 110.0, "def": 60.0, "mdef": 40.0, "atsp": 0.75},
		{"move_speed": 50.0, "attack_range": 70.0, "is_boss": true, "break_max": 140.0, "break_lock": 4.0}, ["slime_bash", "slime_king_quake"])


# --- items ------------------------------------------------------------------------

func _item(id: String, name: String, slot: String, tag: String, stats: Dictionary) -> void:
	var it := ItemData.new()
	it.id = id
	it.display_name = name
	it.slot = slot
	it.equip_tag = tag
	it.stats = stats
	_save(it, "items")


func _items() -> void:
	_item("sword_wood", "Kiếm gỗ", "weapon", "sword", {"atk": 25.0})
	_item("sword_iron", "Kiếm sắt", "weapon", "sword", {"atk": 40.0, "crit": 0.02})
	_item("bow_wood", "Cung gỗ", "weapon", "bow", {"atk": 24.0, "crit": 0.03})
	_item("staff_wood", "Trượng gỗ", "weapon", "staff", {"matk": 30.0})
	_item("wand_wood", "Đũa gỗ", "weapon", "wand", {"matk": 22.0, "hp": 60.0})
	_item("armor_balanced_iron", "Giáp sắt", "armor", "armor_balanced", {"hp": 180.0, "def": 18.0, "mdef": 8.0})
	_item("armor_light_leather", "Áo da", "armor", "armor_light", {"hp": 100.0, "def": 14.0})
	_item("armor_magic_robe", "Áo choàng phép", "armor", "armor_magic", {"hp": 90.0, "mdef": 18.0})
	_item("helm_balanced_iron", "Mũ sắt", "helmet", "armor_balanced", {"hp": 80.0, "def": 8.0})
	_item("helm_light_leather", "Mũ da", "helmet", "armor_light", {"hp": 50.0, "def": 6.0})
	_item("helm_magic_hood", "Mũ trùm phép", "helmet", "armor_magic", {"hp": 40.0, "mdef": 8.0})
	_item("ring_power", "Nhẫn sức mạnh", "accessory", "accessory", {"atk": 10.0, "matk": 10.0})
	_item("amulet_life", "Bùa sinh mệnh", "accessory", "accessory", {"hp": 120.0})


# --- stages -----------------------------------------------------------------------

func _stage(id: String, name: String, waves: Array, rules: Array, rewards: Dictionary, idle: Dictionary, daily := false) -> void:
	var s := StageData.new()
	s.id = id
	s.display_name = name
	s.chapter = 0 if daily else 1
	s.is_daily = daily
	var typed_waves: Array[Dictionary] = []
	for w in waves:
		var monsters: Array = []
		for m in w:
			monsters.append({"id": m[0], "row": m[1]})
		typed_waves.append({"monsters": monsters})
	s.waves = typed_waves
	var typed_rules: Array[Dictionary] = []
	for r in rules:
		typed_rules.append(r)
	s.rules = typed_rules
	s.rewards = rewards
	s.idle_rate = idle
	_save(s, "stages")


func _stages() -> void:
	_stage("1_1", "1-1 Đồng cỏ", [[["slime_green", 0], ["slime_green", 0], ["slime_green", 1]]], [],
		{"gold": 120, "gem_0": 3}, {"gold": 60, "gem_0": 2})
	_stage("1_2", "1-2 Bìa rừng", [[["slime_green", 0], ["slime_green", 1]], [["slime_green", 0], ["slime_green", 0], ["slime_stone_green", 2]]], [],
		{"gold": 150, "gem_0": 4}, {"gold": 80, "gem_0": 3})
	_stage("1_3", "1-3 Vua slime", [[["slime_green", 0], ["slime_green", 0]], [["slime_king_green", 0], ["slime_green", 1]]], [],
		{"gold": 300, "gem_0": 8, "gem_1": 1}, {"gold": 110, "gem_0": 4})
	_stage("1_4", "1-4 Hang slime đá", [[["slime_stone_green", 0], ["slime_stone_green", 0], ["slime_stone_green", 1]]],
		[{"type": "enemy_immune", "damage_type": "physical"}, {"type": "require_class_count", "classes": ["mage", "priest"], "count": 1}],
		{"gold": 200, "gem_0": 6}, {"gold": 130, "gem_0": 5})
	_stage("1_5", "1-5 Đầm lầy", [[["slime_orange", 0], ["slime_orange", 0], ["slime_stone_orange", 2]], [["slime_orange", 0], ["slime_orange", 1], ["slime_stone_orange", 2]]],
		[{"type": "ban_class", "classes": ["mage"]}, {"type": "time_limit", "seconds": 75}],
		{"gold": 260, "gem_0": 8, "gem_1": 1}, {"gold": 150, "gem_0": 6, "gem_1": 0.5})
	_stage("d_gold", "Hầm vàng", [[["slime_orange", 0], ["slime_orange", 0], ["slime_orange", 1]]],
		[{"type": "enemy_modifier", "stat": "hp", "value": 1.0, "mode": "percent"}],
		{"gold": 800}, {}, true)
	_stage("d_gem", "Hang đá quý", [[["slime_stone_orange", 0], ["slime_stone_orange", 0], ["slime_orange", 1]]],
		[{"type": "enemy_immune", "damage_type": "magic"}],
		{"gem_0": 15, "gem_1": 2}, {}, true)


# --- config and economy -------------------------------------------------------------

func _config() -> void:
	var c := GameConfig.new()
	c.daily_schedule = {0: ["d_gold", "d_gem"], 1: ["d_gold"], 2: ["d_gem"], 3: ["d_gold"], 4: ["d_gem"], 5: ["d_gold"], 6: ["d_gold", "d_gem"]}
	ResourceSaver.save(c, OUT + "/config.tres")


func _economy() -> void:
	var colors := ["trắng", "lục", "lam", "tím", "vàng"]
	var gem_types := ["id,image,color,tier"]
	for tier in 10:
		gem_types.append("gem_%d,cap%d,%s,%d" % [tier, 1 + tier / 5, colors[tier % 5], tier])
	_write_csv("gem_types", gem_types)

	var curve := ["level,gem_tier,gem_count,gold_cost,success_rate,fail_drop"]
	for level in range(1, 201):
		var within := (level - 1) % 20
		var tier := (level - 1) / 20
		var gold := roundi(50 * level * (1.0 + 0.5 * tier))
		curve.append("%d,%d,%d,%d,%.3f,0" % [level, tier, 1 + within / 5, gold, maxf(0.5, 1.0 - 0.025 * within)])
	_write_csv("enhance_curve", curve)

	var merge := ["from_tier,to_tier,count_in,gold_cost"]
	for tier in 9:
		merge.append("%d,%d,3,%d" % [tier, tier + 1, 100 * (tier + 1)])
	_write_csv("gem_merge", merge)

	_write_csv("enhance_transfer", ["gold_per_level,keep_ratio", "50,1.0"])


func _write_csv(name: String, lines: Array) -> void:
	var path := "%s/economy/%s.csv" % [OUT, name]
	var f := FileAccess.open(path, FileAccess.WRITE)
	f.store_string("\n".join(lines) + "\n")
	f.close()
	# Godot imports .csv as translations by default; keep these as plain files.
	var imp := FileAccess.open(path + ".import", FileAccess.WRITE)
	imp.store_string("[remap]\n\nimporter=\"keep\"\n")
