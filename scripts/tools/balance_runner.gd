extends SceneTree

## Runs many headless battles and prints numbers for balancing
## (docs/khung-ky-thuat.md, section 10).
##
## Godot_console.exe --headless --path . -s res://scripts/tools/balance_runner.gd -- [runs] [team] [stage ...]
##   runs  : battles per stage (default 200)
##   team  : class:row list, e.g. knight:0,warrior:0,priest:1,archer:2 (default)
##   stage : stage ids (default: every main stage)
## Example: ... -- 500 archer:0,archer:0,archer:1,archer:2 1_3

const DEFAULT_TEAM := "knight:0,warrior:0,priest:1,archer:2"


func _initialize() -> void:
	GameDB.ensure_loaded()
	var args := OS.get_cmdline_user_args()
	var runs := int(args[0]) if args.size() > 0 else 200
	var team_spec: String = args[1] if args.size() > 1 else DEFAULT_TEAM
	var stage_ids: Array = Array(args.slice(2)) if args.size() > 2 else GameDB.main_stages().map(func(s: StageData) -> String: return String(s.id))
	print("Đội: %s | %d trận mỗi màn\n" % [team_spec, runs])
	for stage_id in stage_ids:
		_run_stage(GameDB.stage(stage_id), team_spec, runs)
	quit()


func _team(spec: String) -> Array[UnitState]:
	var team: Array[UnitState] = []
	var seen := {}
	for part in spec.split(","):
		var bits := part.split(":")
		var u := UnitFactory.hero_bare(bits[0], int(bits[1]))
		# Same class twice (testing only): give each copy its own id.
		seen[bits[0]] = seen.get(bits[0], 0) + 1
		if seen[bits[0]] > 1:
			u.id = "%s%d" % [bits[0], seen[bits[0]]]
		team.append(u)
	return team


func _run_stage(stage: StageData, team_spec: String, runs: int) -> void:
	var wins := 0
	var total_time := 0.0
	var damage := {}
	var healing := {}
	var casts := {}
	var deaths := {}
	var breaks := 0
	var boss_casts := 0
	var rules_errors := StageRules.validate(stage.rules, _members(team_spec))
	for seed_value in runs:
		var sim := BattleSim.new(stage, _team(team_spec), seed_value)
		if sim.run_to_end() == BattleSim.Result.WIN:
			wins += 1
		total_time += sim.ctx.time
		for ev in sim.ctx.events:
			match ev.type:
				&"damage":
					if sim.ctx.find(ev.source) and sim.ctx.find(ev.source).team == UnitState.Team.PLAYER:
						damage[ev.source] = damage.get(ev.source, 0.0) + ev.amount
				&"heal":
					healing[ev.source] = healing.get(ev.source, 0.0) + ev.amount
				&"skill_cast":
					casts[ev.skill] = casts.get(ev.skill, 0) + 1
				&"death":
					if not "#" in ev.target:
						deaths[ev.target] = deaths.get(ev.target, 0) + 1
				&"break":
					breaks += 1
				&"cast_start":
					boss_casts += 1
	print("== %s ==%s" % [stage.display_name, "  (đội không hợp lệ: %s)" % ", ".join(rules_errors) if rules_errors.size() > 0 else ""])
	print("  Thắng %d%% | trận trung bình %.1fs" % [roundi(100.0 * wins / runs), total_time / runs])
	print("  Sát thương / trận: %s" % _per_battle(damage, runs))
	print("  Hồi máu / trận   : %s" % _per_battle(healing, runs))
	print("  Chết / trận      : %s" % _per_battle(deaths, runs, 2))
	if boss_casts > 0:
		print("  Boss niệm %.1f lần/trận, vỡ thanh %.1f lần/trận" % [float(boss_casts) / runs, float(breaks) / runs])
	print("  Skill dùng / trận: %s\n" % _per_battle(casts, runs, 1))


func _members(spec: String) -> Array:
	var out := []
	for part in spec.split(","):
		var bits := part.split(":")
		out.append({"class_id": bits[0], "row": int(bits[1])})
	return out


func _per_battle(totals: Dictionary, runs: int, decimals: int = 0) -> String:
	var keys := totals.keys()
	keys.sort_custom(func(a, b) -> bool: return totals[a] > totals[b])
	var parts := PackedStringArray()
	for k in keys:
		parts.append(("%s %." + str(decimals) + "f") % [k, totals[k] / float(runs)])
	return ", ".join(parts) if parts.size() > 0 else "-"
