extends "res://tests/test_battle_core.gd"

## Battle simulation and meta systems on the real data in res://data.
## Run: Godot_console.exe --headless --path . -s res://tests/test_battle_sim.gd
## (inherits the checks of test_battle_core.gd, so it runs those too)

const NOW := 1_760_000_000


func default_team() -> Array[UnitState]:
	var team: Array[UnitState] = []
	team.append(UnitFactory.hero_bare("knight", 0))
	team.append(UnitFactory.hero_bare("warrior", 0))
	team.append(UnitFactory.hero_bare("priest", 1))
	team.append(UnitFactory.hero_bare("archer", 2))
	return team


func count_events(sim: BattleSim, type: StringName, filter: Callable = Callable()) -> int:
	var n := 0
	for ev in sim.ctx.events:
		if ev.type == type and (not filter.is_valid() or filter.call(ev)):
			n += 1
	return n


# --- data ----------------------------------------------------------------------

func test_data_loaded() -> void:
	GameDB.ensure_loaded()
	check(GameDB.classes.size() == 5, "5 classes")
	check(GameDB.main_stages().size() == 5, "5 main stages, daily excluded")
	check(GameDB.tables.enhance_curve.size() == 200, "200 enhance levels")
	for c: ClassData in GameDB.classes.values():
		var member := {"class_id": String(c.id), "row": 0, "passives": Array(c.default_passives), "actives": Array(c.default_actives), "ultimate": String(c.default_ultimate)}
		check(Profile.new().validate_member(member).is_empty(), "%s default loadout is valid" % c.id)
	var gold_ok := true
	for i in range(1, 200):
		if GameDB.tables.enhance_curve[i].gold_cost < GameDB.tables.enhance_curve[i - 1].gold_cost:
			gold_ok = false
	check(gold_ok, "enhance gold cost never goes down")


# --- battle --------------------------------------------------------------------

func test_sim_first_stage_win() -> void:
	var sim := BattleSim.new(GameDB.stage("1_1"), default_team(), 1)
	check(sim.run_to_end() == BattleSim.Result.WIN, "default team clears 1-1")
	check(count_events(sim, &"move") > 0, "units walked")
	check(count_events(sim, &"attack") > 0, "units attacked")
	check(count_events(sim, &"skill_cast", func(ev): return ev.skill == &"archer_arrow_rain") > 0, "cooldown skill used")
	check(sim.ctx.time < 120.0, "battle ends in time (%.1fs)" % sim.ctx.time)


func test_sim_is_deterministic() -> void:
	var a := BattleSim.new(GameDB.stage("1_2"), default_team(), 7)
	var b := BattleSim.new(GameDB.stage("1_2"), default_team(), 7)
	a.run_to_end()
	b.run_to_end()
	check(a.ctx.events.size() == b.ctx.events.size() and is_equal_approx(a.ctx.time, b.ctx.time), "same seed, same battle")


func test_sim_waves() -> void:
	var sim := BattleSim.new(GameDB.stage("1_2"), default_team(), 3)
	sim.run_to_end()
	check(count_events(sim, &"wave") == 2, "two waves spawned")


func test_always_passives_apply() -> void:
	var sim := BattleSim.new(GameDB.stage("1_1"), default_team(), 1)
	var knight := sim.ctx.find("knight")
	# knight_team_guard +10% def, priest +10% hp, archer +10% atsp, warrior +8% atk.
	near(knight.stats.get_value("def"), 66.0, "team def +10%")
	near(knight.max_hp(), 1980.0, "team hp +10%")
	near(knight.stats.get_value("atk"), 86.4, "team atk +8%")


func test_ultimate_auto_and_manual() -> void:
	var sim := BattleSim.new(GameDB.stage("1_3"), default_team(), 5)
	sim.run_to_end()
	check(count_events(sim, &"skill_cast", func(ev): return ev.skill == &"warrior_rage") > 0, "auto ultimate fires")

	var team := default_team()
	for u in team:
		u.auto_ultimate = false
	var manual := BattleSim.new(GameDB.stage("1_3"), team, 5)
	for i in 400:
		manual.step()
	check(count_events(manual, &"skill_cast", func(ev): return ev.skill == &"warrior_rage") == 0, "auto off: ultimate waits")
	var warrior := manual.ctx.find("warrior")
	if warrior.alive and manual.result == BattleSim.Result.RUNNING:
		warrior.mana = warrior.mana_max
		warrior.ultimate.ready_at = 0.0
		manual.cast_ultimate("warrior")
		manual.step()
		check(count_events(manual, &"skill_cast", func(ev): return ev.skill == &"warrior_rage") == 1, "button press casts it")


func test_boss_casts_and_breaks() -> void:
	var team := default_team()
	team[3] = UnitFactory.hero_bare("mage", 2)
	var sim := BattleSim.new(GameDB.stage("1_3"), team, 11)
	sim.run_to_end()
	check(count_events(sim, &"cast_start", func(ev): return ev.skill == &"slime_king_quake") > 0, "boss casts its big skill")
	check(count_events(sim, &"break_damage") > 0, "cc skills hit the break bar")


func test_stage_rules() -> void:
	var s14 := GameDB.stage("1_4")
	var members := [{"class_id": "knight", "row": 0}, {"class_id": "warrior", "row": 0}]
	check(StageRules.validate(s14.rules, members).size() == 1, "1-4 requires a mage or priest")
	members.append({"class_id": "mage", "row": 2})
	check(StageRules.validate(s14.rules, members).is_empty(), "with a mage the team is valid")
	var sim := BattleSim.new(s14, default_team(), 2)
	var hit_by_physical := 0.0
	sim.run_to_end()
	for ev in sim.ctx.events:
		if ev.type == &"damage" and ev.source in ["knight", "warrior", "archer"] and ev.target.begins_with("slime_stone"):
			hit_by_physical += ev.amount
	near(hit_by_physical, 0.0, "stone slimes immune to physical")
	check(StageRules.validate(GameDB.stage("1_5").rules, [{"class_id": "mage", "row": 2}]).size() == 1, "1-5 bans mage")
	near(StageRules.time_limit(GameDB.stage("1_5").rules), 75.0, "1-5 time limit")


# --- profile, items, enhance -------------------------------------------------------

func test_profile_defaults_and_equip() -> void:
	var p := Profile.create_new(NOW)
	check(p.data.presets[0].members.size() == 4, "default preset has 4")
	var knight_weapon: String = p.data.classes.knight.equipment.weapon
	check(p.item_base(knight_weapon).id == &"sword_wood", "knight starts with a sword")
	check(not p.equip("archer", knight_weapon), "archer cannot wear a sword")
	check(p.equip("warrior", knight_weapon), "warrior can take the knight's sword")
	check(not p.data.classes.knight.equipment.has("weapon"), "sword left the knight")
	var hero := UnitFactory.hero(p, p.default_member("warrior", 0))
	near(hero.stats.get_value("atk"), 115.0 + 25.0 + 10.0, "warrior atk = base + one sword + ring")


func test_item_stats_scale_with_enhance() -> void:
	var p := Profile.create_new(NOW)
	var uid := p.add_item("sword_iron")
	p.data.inventory[uid].level = 200
	near(p.item_stats(uid).atk, 40.0 * 11.0, "level 200 = 11x base (linear 5%)")
	near(p.item_stats(uid).crit, 0.02 * 11.0, "percent stats scale too for now")


func test_enhance_transfer_merge() -> void:
	var p := Profile.create_new(NOW)
	var rng := RandomNumberGenerator.new()
	rng.seed = 1
	var uid: String = p.data.classes.knight.equipment.weapon
	check(Enhance.enhance(p, uid, rng) == "not_enough", "no gems, no enhance")
	p.add("gem_0", 100, "test")
	p.add("gold", 100000, "test")
	var ok := 0
	for i in 10:
		if Enhance.enhance(p, uid, rng) == "ok":
			ok += 1
	check(p.item_level(uid) == ok and ok > 0, "levels gained = successes (%d)" % ok)
	var new_uid := p.add_item("sword_iron")
	var level_before := p.item_level(uid)
	check(Enhance.transfer(p, uid, new_uid) == "ok", "transfer to same slot")
	check(p.item_level(new_uid) == level_before and p.item_level(uid) == 0, "level moved")
	check(Enhance.transfer(p, new_uid, p.data.classes.knight.equipment.armor) == "different_slot", "no transfer across slots")
	var gems_before := p.amount("gem_0")
	check(Enhance.merge_gems(p, 0, 2) == 2, "merged twice")
	near(p.amount("gem_0"), gems_before - 6, "3 gems per merge")
	near(p.amount("gem_1"), 2, "got 2 next-tier gems")
	check(p.data.ledger.has("gold:enhance"), "gold spending logged per reason")


func test_skill_levels_shared_vs_class() -> void:
	var p := Profile.create_new(NOW)
	p.set_skill_level("knight", "shared_stun_strike", 3)
	check(p.skill_level("mage", "shared_stun_strike") == 3, "shared skill level is per account")
	p.set_skill_level("knight", "knight_taunt", 4)
	check(p.skill_level("knight", "knight_taunt") == 4, "class skill level per class")
	var bad := {"class_id": "mage", "row": 2, "passives": ["knight_barrier"], "actives": [], "ultimate": ""}
	check(p.validate_member(bad).size() == 1, "mage cannot slot a knight skill")
	var shared := {"class_id": "mage", "row": 2, "passives": [], "actives": ["shared_stun_strike"], "ultimate": "mage_meteor"}
	check(p.validate_member(shared).is_empty(), "any class can slot a shared skill")


# --- idle, daily, save ---------------------------------------------------------------

func test_idle_rewards() -> void:
	var p := Profile.create_new(NOW)
	check(IdleAndDaily.idle_preview(p, NOW + 3600).rewards.is_empty(), "nothing before the first clear")
	p.mark_cleared(GameDB.stage("1_1"))
	p.mark_cleared(GameDB.stage("1_2"))
	check(p.data.progress.highest == "1_2", "highest cleared stage")
	var got := IdleAndDaily.claim_idle(p, NOW + 2 * 3600)
	near(got.rewards.gold, 160.0, "2h × 80 gold/h of 1-2")
	var capped := IdleAndDaily.idle_preview(p, NOW + 2 * 3600 + 100 * 3600)
	near(capped.hours, 12.0, "idle capped at 12h")


func test_daily_attempts() -> void:
	var p := Profile.create_new(NOW)
	var stage_id := "d_gold"
	check(IdleAndDaily.attempts_left(p, stage_id, NOW) == 3, "3 attempts a day")
	for i in 3:
		IdleAndDaily.use_attempt(p, stage_id, NOW)
	check(not IdleAndDaily.use_attempt(p, stage_id, NOW), "no 4th attempt")
	check(IdleAndDaily.attempts_left(p, stage_id, NOW + 86400) == 3, "reset next day")
	check(IdleAndDaily.todays_dungeons(NOW).size() >= 1, "some dungeon open every day")


func test_save_roundtrip() -> void:
	var p := Profile.create_new(NOW)
	p.add("gold", 1234, "test")
	var uid := p.add_item("sword_iron")
	p.data.inventory[uid].level = 7
	var path := "user://test_save.json"
	check(SaveService.save(p, path), "saved")
	var loaded := SaveService.load_profile(path)
	near(loaded.amount("gold"), 1234.0, "gold survives")
	check(loaded.item_level(uid) == 7, "item level survives")
	check(loaded.data.save_version == Profile.SAVE_VERSION, "version stamped")
	var again := loaded.add_item("bow_wood")
	check(not p.data.inventory.has(again) or again != uid, "uid counter survives as int")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
