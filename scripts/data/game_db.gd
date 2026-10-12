class_name GameDB
extends RefCounted

## Loads every data resource under res://data once and looks them up by id.

const DATA_DIR := "res://data"

static var config: GameConfig
static var classes: Dictionary = {}
static var skills: Dictionary = {}
static var monsters: Dictionary = {}
static var items: Dictionary = {}
static var stages: Dictionary = {}
## CSV name (without extension) -> Array of row Dictionaries.
static var tables: Dictionary = {}
static var _loaded := false


static func ensure_loaded() -> void:
	if _loaded:
		return
	_loaded = true
	config = load(DATA_DIR + "/config.tres") as GameConfig
	config.apply_to_battle()
	_load_dir("classes", classes)
	_load_dir("skills", skills)
	_load_dir("monsters", monsters)
	_load_dir("items", items)
	_load_dir("stages", stages)
	for name in ["enhance_curve", "enhance_transfer", "gem_merge", "gem_types"]:
		tables[name] = read_csv("%s/economy/%s.csv" % [DATA_DIR, name])


static func skill(id) -> SkillData:
	ensure_loaded()
	return skills.get(String(id))


static func class_data(id) -> ClassData:
	ensure_loaded()
	return classes.get(String(id))


static func monster(id) -> MonsterData:
	ensure_loaded()
	return monsters.get(String(id))


static func item(id) -> ItemData:
	ensure_loaded()
	return items.get(String(id))


static func stage(id) -> StageData:
	ensure_loaded()
	return stages.get(String(id))


## "gold" -> "Vàng", "gem_3" -> "Đá tím (bậc 4)".
static func currency_name(key: String) -> String:
	ensure_loaded()
	if key == "gold":
		return "Vàng"
	for row in tables.get("gem_types", []):
		if row.id == key:
			return "Đá %s (bậc %d)" % [row.color, int(row.tier) + 1]
	return key


## Main stages sorted by chapter then id (daily dungeons excluded).
static func main_stages() -> Array[StageData]:
	ensure_loaded()
	var out: Array[StageData] = []
	for s: StageData in stages.values():
		if not s.is_daily:
			out.append(s)
	out.sort_custom(func(a: StageData, b: StageData) -> bool:
		return a.chapter < b.chapter or (a.chapter == b.chapter and String(a.id) < String(b.id)))
	return out


static func read_csv(path: String) -> Array[Dictionary]:
	var rows: Array[Dictionary] = []
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		push_error("Cannot open %s" % path)
		return rows
	var header := f.get_csv_line()
	while not f.eof_reached():
		var line := f.get_csv_line()
		if line.size() < header.size():
			continue
		var row := {}
		for i in header.size():
			var cell := line[i]
			row[header[i]] = cell.to_float() if cell.is_valid_float() else cell
		rows.append(row)
	return rows


static func _load_dir(sub: String, into: Dictionary) -> void:
	var dir := DirAccess.open("%s/%s" % [DATA_DIR, sub])
	if dir == null:
		push_error("Missing data folder %s" % sub)
		return
	for file in dir.get_files():
		# Exported builds list "x.tres.remap" instead of "x.tres".
		file = file.trim_suffix(".remap")
		if not file.ends_with(".tres"):
			continue
		var res := load("%s/%s/%s" % [DATA_DIR, sub, file])
		if res and "id" in res:
			into[String(res.id)] = res
