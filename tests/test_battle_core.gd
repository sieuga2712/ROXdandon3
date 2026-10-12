extends SceneTree

## Headless tests for the battle core (stats, skills, targeting, effects).
## Run: Godot_console.exe --headless --path . -s res://tests/test_battle_core.gd
## Exit code = number of failed checks.

var _failed := 0
var _passed := 0
var _current := ""


func _initialize() -> void:
	for method in get_method_list():
		var name: String = method.name
		if name.begins_with("test_"):
			_current = name
			call(name)
	print("\n%d passed, %d failed" % [_passed, _failed])
	quit(_failed)


func check(condition: bool, label: String) -> void:
	if condition:
		_passed += 1
	else:
		_failed += 1
		printerr("FAIL %s: %s" % [_current, label])


func near(a: float, b: float, label: String, eps: float = 0.001) -> void:
	check(absf(a - b) <= eps, "%s (got %.4f, want %.4f)" % [label, a, b])


# --- helpers -----------------------------------------------------------------

func make_unit(id: String, team: UnitState.Team, x: float, base: Dictionary = {}) -> UnitState:
	var stats_base := {"hp": 1000.0, "atk": 100.0, "matk": 100.0}
	stats_base.merge(base, true)
	var u := UnitState.new(id, team, Stats.new(stats_base))
	u.x = x
	return u


func make_ctx(units: Array[UnitState]) -> BattleContext:
	var ctx := BattleContext.new(42)
	ctx.units = units
	return ctx


func make_skill(effects: Array[Dictionary], extra: Dictionary = {}) -> Dictionary:
	var s := SkillData.new()
	s.id = &"test_skill"
	s.effects = effects
	var resolved := s.resolve(1)
	resolved.merge(extra, true)
	return resolved


# --- stats -------------------------------------------------------------------

func test_stats_flat_and_percent() -> void:
	var s := Stats.new({"atk": 100.0})
	s.add_modifier("atk", 20.0, Stats.Mode.FLAT)
	s.add_modifier("atk", 0.5, Stats.Mode.PERCENT)
	near(s.get_value("atk"), 180.0, "(100 + 20) * 1.5")


func test_stats_stack_rules() -> void:
	var s := Stats.new({"atk": 100.0})
	s.add_modifier("atk", 0.1, Stats.Mode.PERCENT, "archer_passive")
	s.add_modifier("atk", 0.1, Stats.Mode.PERCENT, "archer_passive")
	near(s.get_value("atk"), 120.0, "stack adds both")
	var h := Stats.new({"atk": 100.0})
	h.add_modifier("atk", 0.1, Stats.Mode.PERCENT, "p", Stats.StackRule.HIGHEST)
	h.add_modifier("atk", 0.3, Stats.Mode.PERCENT, "p", Stats.StackRule.HIGHEST)
	near(h.get_value("atk"), 130.0, "highest keeps the largest")


func test_stats_caps_and_remove() -> void:
	var s := Stats.new({"crit": 0.5})
	var id := s.add_modifier("crit", 2.0)
	near(s.get_value("crit"), 1.0, "crit capped at 1")
	s.remove_modifier(id)
	near(s.get_value("crit"), 0.5, "modifier removed")
	near(Stats.new().get_value("damage_taken"), 1.0, "damage_taken defaults to 1")


# --- skill data --------------------------------------------------------------

func test_skill_levels_override() -> void:
	var s := SkillData.new()
	s.cooldown = 8.0
	s.effects = [{"type": "damage", "scale": 0.6}]
	s.levels = [{}, {"cooldown": 7.5, "effects": [{"scale": 0.7}]}]
	var l1 := s.resolve(1)
	var l2 := s.resolve(2)
	near(l1.cooldown, 8.0, "level 1 keeps base cooldown")
	near(l2.cooldown, 7.5, "level 2 overrides cooldown")
	near(l2.effects[0].scale, 0.7, "level 2 overrides effect scale")
	near(s.effects[0].scale, 0.6, "resolve does not mutate the resource")
	near(s.resolve(9).cooldown, 7.5, "level past the table uses the last entry")


func test_skill_class_tags() -> void:
	var shared := SkillData.new()
	var archer_only := SkillData.new()
	archer_only.class_tags = ["archer"]
	check(shared.is_shared() and shared.can_equip("mage"), "shared skill fits any class")
	check(archer_only.can_equip("archer") and not archer_only.can_equip("mage"), "class skill fits only its class")


# --- targeting ---------------------------------------------------------------

func test_targeting_nearest_and_taunt() -> void:
	var hero := make_unit("hero", UnitState.Team.PLAYER, 0.0)
	var near_m := make_unit("near", UnitState.Team.ENEMY, 100.0)
	var far_m := make_unit("far", UnitState.Team.ENEMY, 300.0)
	var ctx := make_ctx([hero, near_m, far_m])
	check(Targeting.default_target(hero, ctx) == near_m, "nearest enemy by x")
	hero.statuses["taunt"] = {"source_id": "far", "expires_at": 10.0}
	check(Targeting.default_target(hero, ctx) == far_m, "taunt overrides nearest")


func test_targeting_area_and_hp() -> void:
	var hero := make_unit("hero", UnitState.Team.PLAYER, 0.0)
	var ally := make_unit("ally", UnitState.Team.PLAYER, -50.0)
	ally.hp = 100.0
	var a := make_unit("a", UnitState.Team.ENEMY, 100.0)
	var b := make_unit("b", UnitState.Team.ENEMY, 150.0)
	var c := make_unit("c", UnitState.Team.ENEMY, 400.0)
	c.hp = 2000.0
	var ctx := make_ctx([hero, ally, a, b, c])
	check(Targeting.select(&"enemies_near_target", hero, ctx, 0, 60.0).size() == 2, "radius around nearest enemy hits a and b")
	check(Targeting.select(&"highest_hp_enemy", hero, ctx)[0] == c, "highest hp enemy")
	check(Targeting.select(&"lowest_hp_ally", hero, ctx)[0] == ally, "lowest hp ally by ratio")
	check(Targeting.select(&"random_enemy", hero, ctx, 5).size() == 3, "random never picks the same enemy twice")
	c.alive = false
	check(Targeting.select(&"all_enemies", hero, ctx, 0).size() == 2, "dead units are skipped")


# --- effects -----------------------------------------------------------------

func test_damage_formula() -> void:
	var hero := make_unit("hero", UnitState.Team.PLAYER, 0.0, {"atk": 200.0})
	var mob := make_unit("mob", UnitState.Team.ENEMY, 50.0, {"def": 100.0})
	var ctx := make_ctx([hero, mob])
	# 200 atk * 1.5 scale * 100 / (100 + 100) = 150
	near(Effects.deal_damage(hero, mob, 1.5, "physical", 1, false, ctx), 150.0, "physical damage after def")
	near(mob.hp, 850.0, "hp reduced")
	near(Effects.deal_damage(hero, mob, 1.0, "physical", 1, true, ctx), 150.0, "forced crit uses crit_dmg 1.5")
	mob.stats.add_modifier("damage_taken", -0.3)
	near(Effects.deal_damage(hero, mob, 1.0, "magic", 1, false, ctx), 70.0, "magic ignores def, damage_taken 0.7")


func test_shield_lifesteal_undying() -> void:
	var hero := make_unit("hero", UnitState.Team.PLAYER, 0.0, {"atk": 100.0, "lifesteal": 0.5})
	hero.hp = 500.0
	var mob := make_unit("mob", UnitState.Team.ENEMY, 50.0)
	mob.shields.append({"amount": 30.0, "expires_at": 10.0})
	var ctx := make_ctx([hero, mob])
	Effects.deal_damage(hero, mob, 1.0, "physical", 1, false, ctx)
	near(mob.hp, 930.0, "shield absorbs 30 of 100")
	near(hero.hp, 550.0, "lifesteal heals 50% of 100")
	mob.statuses["undying"] = {"expires_at": 10.0}
	Effects.take_damage(mob, 99999.0, ctx)
	check(mob.alive and is_equal_approx(mob.hp, 1.0), "undying keeps 1 hp")
	mob.statuses.erase("undying")
	Effects.take_damage(mob, 5.0, ctx)
	check(not mob.alive, "dies without undying")
	check(ctx.events.any(func(ev: Dictionary) -> bool: return ev.type == &"death"), "death event emitted")


func test_cc_and_cc_resist() -> void:
	var hero := make_unit("hero", UnitState.Team.PLAYER, 0.0)
	var mob := make_unit("mob", UnitState.Team.ENEMY, 50.0, {"cc_resist": 0.5})
	mob.casting = {"skill": {}, "finish_at": 5.0}
	var ctx := make_ctx([hero, mob])
	Effects.apply_effect({"type": "stun", "duration": 2.0}, hero, mob, ctx)
	near(mob.statuses.stun.expires_at, 1.0, "stun 2s halved by cc_resist 0.5")
	check(not mob.is_casting(), "stun interrupts a normal unit's cast")
	Effects.apply_effect({"type": "slow", "value": 0.3, "duration": 3.0}, hero, mob, ctx)
	near(mob.current_atsp(), 0.7, "slow 30% lowers atsp")
	Effects.apply_effect({"type": "cleanse", "count": 1}, hero, mob, ctx)
	check(not mob.has_status("stun") and mob.has_status("slow"), "cleanse 1 removes stun first")


func test_timed_modifier_expires() -> void:
	var hero := make_unit("hero", UnitState.Team.PLAYER, 0.0)
	var ctx := make_ctx([hero])
	Effects.apply_effect({"type": "modify_stat", "stat": "atk", "value": 0.5, "mode": "percent", "duration": 8.0}, hero, hero, ctx)
	near(hero.stats.get_value("atk"), 150.0, "buff applied")
	hero.expire(7.9)
	near(hero.stats.get_value("atk"), 150.0, "buff still on at 7.9s")
	hero.expire(8.0)
	near(hero.stats.get_value("atk"), 100.0, "buff gone at 8s")


func test_taunt_skill_with_self_effect() -> void:
	# Khiêu khích: taunt enemies around, -30% damage taken on self.
	var knight := make_unit("knight", UnitState.Team.PLAYER, 0.0)
	var a := make_unit("a", UnitState.Team.ENEMY, 50.0)
	var b := make_unit("b", UnitState.Team.ENEMY, 80.0)
	var ctx := make_ctx([knight, a, b])
	var skill := make_skill([
		{"type": "taunt", "duration": 4.0},
		{"type": "modify_stat", "stat": "damage_taken", "value": -0.3, "duration": 4.0, "on": "self"},
	])
	Effects.apply_skill(skill, knight, Targeting.select(&"enemies_near_self", knight, ctx, 0, 100.0), ctx)
	check(Targeting.default_target(a, ctx) == knight and Targeting.default_target(b, ctx) == knight, "both enemies taunted")
	near(knight.stats.get_value("damage_taken"), 0.7, "self effect applied once")


func test_boss_break_bar() -> void:
	var mage := make_unit("mage", UnitState.Team.PLAYER, 0.0)
	var boss := make_unit("boss", UnitState.Team.ENEMY, 200.0)
	boss.is_boss = true
	boss.break_max = 100.0
	boss.break_value = 100.0
	var ctx := make_ctx([mage, boss])
	var meteor := make_skill([{"type": "damage", "scale": 1.0, "damage_type": "magic"}, {"type": "stun", "duration": 2.0}], {"break_power": 60.0})

	Effects.apply_skill(meteor, mage, [boss], ctx)
	check(not boss.has_status("stun"), "boss immune to normal stun")
	near(boss.break_value, 100.0, "bar not hit while boss is not casting")

	boss.casting = {"skill": {}, "finish_at": 3.0}
	Effects.apply_skill(meteor, mage, [boss], ctx)
	near(boss.break_value, 40.0, "cc skill hits the bar while casting")
	var plain_hit := make_skill([{"type": "damage", "scale": 1.0}], {"break_power": 60.0})
	Effects.apply_skill(plain_hit, mage, [boss], ctx)
	near(boss.break_value, 40.0, "skill without cc does not hit the bar")

	Effects.apply_skill(meteor, mage, [boss], ctx)
	check(not boss.is_casting(), "break cancels the cast")
	near(boss.statuses.stun.expires_at, 1.0, "break stuns 1s")
	near(boss.break_value, 100.0, "bar refilled after break")
	boss.casting = {"skill": {}, "finish_at": 3.0}
	Effects.apply_skill(meteor, mage, [boss], ctx)
	near(boss.break_value, 100.0, "bar locked right after break")
