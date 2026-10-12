class_name SaveService
extends RefCounted

## JSON save with a version number (docs/khung-ky-thuat.md, section 9).
## When the save layout changes: bump Profile.SAVE_VERSION and add a step to
## _migrate(). Old saves are upgraded step by step, never edited in place.

const DEFAULT_PATH := "user://save.json"


static func save(profile: Profile, path: String = DEFAULT_PATH) -> bool:
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f == null:
		push_error("Cannot write save %s" % path)
		return false
	f.store_string(JSON.stringify(profile.data, "\t"))
	return true


## Returns null when there is no save yet.
static func load_profile(path: String = DEFAULT_PATH) -> Profile:
	if not FileAccess.file_exists(path):
		return null
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if not parsed is Dictionary:
		push_error("Save %s is not valid JSON" % path)
		return null
	var p := Profile.new()
	p.data = _migrate(parsed)
	return p


static func load_or_create(now_unix: int, path: String = DEFAULT_PATH) -> Profile:
	var p := load_profile(path)
	if p == null:
		p = Profile.create_new(now_unix)
		save(p, path)
	return p


static func _migrate(data: Dictionary) -> Dictionary:
	var version := int(data.get("save_version", 1))
	# JSON numbers come back as floats; fix the counters that must be ints.
	data["next_uid"] = int(data.get("next_uid", 1))
	data["active_preset"] = int(data.get("active_preset", 0))
	while version < Profile.SAVE_VERSION:
		match version:
			# 1: data = _v1_to_v2(data)
			_:
				pass
		version += 1
	data["save_version"] = Profile.SAVE_VERSION
	return data
