class_name SaveManager
extends RefCounted

# Persistent Save System for Pixel Within (Milestone M7)
# Stored at user://save.cfg using ConfigFile

const SAVE_PATH := "user://save.cfg"

const LEVEL_ORDER: Array[String] = [
	"canvas_01",
	"canvas_02",
	"canvas_03",
	"canvas_04",
	"canvas_05",
	"canvas_06",
]

static var unlocked_levels: Array[String] = ["canvas_01"]
static var completed_levels: Array[String] = []
static var stars: Dictionary = {} # level_id -> int (1..3)
static var gems: Dictionary = {}  # level_id -> Array[int] [collected, total]
static var game_completed: bool = false
static var is_loaded: bool = false

static func ensure_loaded() -> void:
	if is_loaded:
		return
	load_data()

static func load_data() -> void:
	is_loaded = true
	var cfg := ConfigFile.new()
	var err := cfg.load(SAVE_PATH)
	if err != OK:
		# Fresh default save
		unlocked_levels = ["canvas_01"]
		completed_levels = []
		stars = {}
		gems = {}
		game_completed = false
		save_data()
		return

	# Load progress section
	var unl: Array = cfg.get_value("progress", "unlocked_levels", ["canvas_01"])
	unlocked_levels.clear()
	for l in unl:
		unlocked_levels.append(str(l))
	if not unlocked_levels.has("canvas_01"):
		unlocked_levels.append("canvas_01")

	var comp: Array = cfg.get_value("progress", "completed_levels", [])
	completed_levels.clear()
	for c in comp:
		completed_levels.append(str(c))

	stars = cfg.get_value("progress", "stars", {})
	gems = cfg.get_value("progress", "gems", {})
	game_completed = cfg.get_value("progress", "game_completed", false)

static func save_data() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("progress", "unlocked_levels", unlocked_levels)
	cfg.set_value("progress", "completed_levels", completed_levels)
	cfg.set_value("progress", "stars", stars)
	cfg.set_value("progress", "gems", gems)
	cfg.set_value("progress", "game_completed", game_completed)
	cfg.save(SAVE_PATH)

static func is_unlocked(level_id: String) -> bool:
	ensure_loaded()
	return unlocked_levels.has(level_id)

static func is_completed(level_id: String) -> bool:
	ensure_loaded()
	return completed_levels.has(level_id)

static func get_stars(level_id: String) -> int:
	ensure_loaded()
	return int(stars.get(level_id, 0))

static func get_gems(level_id: String) -> Array:
	ensure_loaded()
	return gems.get(level_id, [0, 0])

static func complete_level(level_id: String, earned_stars: int, gems_coll: int, gems_tot: int) -> void:
	ensure_loaded()
	if not completed_levels.has(level_id):
		completed_levels.append(level_id)

	# Keep best stars
	var cur_stars: int = int(stars.get(level_id, 0))
	stars[level_id] = maxi(cur_stars, earned_stars)

	# Keep best gems
	var cur_gems: Array = gems.get(level_id, [0, gems_tot])
	var best_coll: int = maxi(int(cur_gems[0]), gems_coll)
	gems[level_id] = [best_coll, gems_tot]

	# Unlock next level
	var idx := LEVEL_ORDER.find(level_id)
	if idx != -1 and idx + 1 < LEVEL_ORDER.size():
		var next_lvl := LEVEL_ORDER[idx + 1]
		if not unlocked_levels.has(next_lvl):
			unlocked_levels.append(next_lvl)
	elif level_id == "canvas_06":
		game_completed = true

	save_data()

static func reset_data() -> void:
	unlocked_levels = ["canvas_01"]
	completed_levels = []
	stars = {}
	gems = {}
	game_completed = false
	save_data()
