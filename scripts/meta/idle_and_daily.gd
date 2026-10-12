class_name IdleAndDaily
extends RefCounted

## Idle rewards and daily dungeons (docs/khung-ky-thuat.md, sections 8.2 and 8.3).
## Time comes from the device clock: changing it is a cheat we accept (offline game).


## What claiming now would give, without changing the profile.
static func idle_preview(profile: Profile, now_unix: int) -> Dictionary:
	var highest: String = profile.data.progress.highest
	var stage: StageData = GameDB.stage(highest) if highest != "" else null
	if stage == null:
		return {"hours": 0.0, "rewards": {}}
	var hours := clampf((now_unix - int(profile.data.idle_last_claim)) / 3600.0, 0.0, GameDB.config.idle_max_hours)
	var rewards := {}
	for key in stage.idle_rate:
		var value := floorf(stage.idle_rate[key] * hours)
		if value > 0.0:
			rewards[key] = value
	return {"hours": hours, "rewards": rewards}


static func claim_idle(profile: Profile, now_unix: int) -> Dictionary:
	var preview := idle_preview(profile, now_unix)
	profile.add_rewards(preview.rewards, "idle")
	profile.data.idle_last_claim = now_unix
	return preview


## "YYYY-MM-DD" of the device's local day.
static func day_key(now_unix: int) -> String:
	var d := Time.get_datetime_dict_from_unix_time(now_unix + _utc_offset_seconds())
	return "%04d-%02d-%02d" % [d.year, d.month, d.day]


static func weekday(now_unix: int) -> int:
	return Time.get_datetime_dict_from_unix_time(now_unix + _utc_offset_seconds()).weekday


## Daily dungeons open today.
static func todays_dungeons(now_unix: int) -> Array[StageData]:
	var out: Array[StageData] = []
	for stage_id in GameDB.config.daily_schedule.get(weekday(now_unix), []):
		var s := GameDB.stage(stage_id)
		if s:
			out.append(s)
	return out


static func attempts_left(profile: Profile, stage_id: String, now_unix: int) -> int:
	_reset_if_new_day(profile, now_unix)
	return GameDB.config.daily_attempts - int(profile.data.daily.used.get(stage_id, 0))


## Call when a daily dungeon battle is won.
static func use_attempt(profile: Profile, stage_id: String, now_unix: int) -> bool:
	if attempts_left(profile, stage_id, now_unix) <= 0:
		return false
	profile.data.daily.used[stage_id] = int(profile.data.daily.used.get(stage_id, 0)) + 1
	return true


static func _reset_if_new_day(profile: Profile, now_unix: int) -> void:
	var today := day_key(now_unix)
	if profile.data.daily.date != today:
		profile.data.daily = {"date": today, "used": {}}


static func _utc_offset_seconds() -> int:
	return Time.get_time_zone_from_system().bias * 60
