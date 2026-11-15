extends Node

# Pixel Within - Core Game State Manager (Milestone M3)
# Central state model as specified in Sections 3.1, 3.4, 3.5, 3.7 and 9.

signal world_swapped(world_state: Dictionary, player_pos: Vector2)
signal pigment_changed(new_pigment: String)
signal heart_painted(new_color: String)

# Cached world instances, keyed by path string:
# e.g. "canvas_01", "canvas_01/10,9:R"
var states: Dictionary = {}

# Dive history stack: Array[Dictionary]
# Each entry contains { parent_key, cell, held_on_entry, tile_char }
var stack: Array = []

# Currently held pigment: "", "r", "b", "g", "y"
var held: String = ""
var held_source_world: String = ""
var held_source_cell: Vector2i = Vector2i(-1, -1)

# Active world key
var current_world_key: String = ""

# Guard against re-entrant world swaps
var is_swapping: bool = false

const DIVEABLE_TILES: Array[String] = ["R", "B", "G", "Y"]
const MAX_DIVE_DEPTH := 3

const CHILD_WORLD_FILES: Dictionary = {
	"R": "res://levels/world_red.txt",
	"B": "res://levels/world_blue.txt",
	"G": "res://levels/world_green.txt",
	"Y": "res://levels/world_yellow.txt",
}

func _ready() -> void:
	# Automatically start with Canvas Level 1 if not already initialized
	if states.is_empty():
		start_canvas("res://levels/canvas_01.txt", "canvas_01")

# Initializes or resets the game to a canvas level
func start_canvas(file_path: String, world_key: String = "canvas_01") -> bool:
	states.clear()
	stack.clear()
	held = ""
	held_source_world = ""
	held_source_cell = Vector2i(-1, -1)

	var world_data := LevelLoader.load_level(file_path)
	if not world_data.get("valid", false):
		push_error("Failed to load level: " + world_data.get("error", "Unknown error"))
		return false

	world_data["key"] = world_key
	world_data["color"] = ""
	world_data["collected_orbs"] = {}
	states[world_key] = world_data
	current_world_key = world_key

	var spawn: Vector2i = world_data.get("player_spawn", Vector2i(1, 9))
	var spawn_pos := Vector2(spawn.x * 16.0 + 4.0, spawn.y * 16.0 + 4.0)
	world_swapped.emit(world_data, spawn_pos)
	pigment_changed.emit(held)
	return true

func get_current_world() -> Dictionary:
	return states.get(current_world_key, {})

# Dive into chroma pixel at cell (Vector2i)
func dive(cell: Vector2i) -> bool:
	if is_swapping:
		return false

	var cur_world := get_current_world()
	if cur_world.is_empty():
		return false

	var grid: Dictionary = cur_world.get("grid", {})
	var tile_char: String = grid.get(cell, "")

	# Only R, B, G, Y are diveable (not L, W, V, S, stone, air)
	if not DIVEABLE_TILES.has(tile_char):
		return false

	# Maximum dive depth is 3
	if stack.size() >= MAX_DIVE_DEPTH:
		return false

	# Child world key includes the parent tile character
	var child_key := current_world_key + "/" + str(cell.x) + "," + str(cell.y) + ":" + tile_char

	# Load child world if not yet cached
	if not states.has(child_key):
		var file_path: String = CHILD_WORLD_FILES.get(tile_char, "")
		if file_path.is_empty() or not FileAccess.file_exists(file_path):
			push_error("Child world file not found for tile: " + tile_char)
			return false

		var child_data := LevelLoader.load_level(file_path)
		if not child_data.get("valid", false):
			push_error("Failed to load child world: " + child_data.get("error", ""))
			return false

		child_data["key"] = child_key
		child_data["color"] = tile_char
		child_data["collected_orbs"] = {}
		states[child_key] = child_data

	# Push dive history to stack
	stack.append({
		"parent_key": current_world_key,
		"cell": cell,
		"held_on_entry": held,
		"tile_char": tile_char,
	})

	# Switch active world
	current_world_key = child_key
	var child_state: Dictionary = states[child_key]
	var spawn: Vector2i = child_state.get("player_spawn", Vector2i(1, 9))
	var spawn_pos := Vector2(spawn.x * 16.0 + 4.0, spawn.y * 16.0 + 4.0)

	is_swapping = true
	world_swapped.emit(child_state, spawn_pos)
	is_swapping = false
	return true

# Surface to parent world
func surface() -> bool:
	if is_swapping or stack.is_empty():
		return false

	var entry: Dictionary = stack.pop_back()
	var parent_key: String = entry["parent_key"]
	var cell: Vector2i = entry["cell"]

	if not states.has(parent_key):
		push_error("Parent world state missing: " + parent_key)
		return false

	current_world_key = parent_key
	var parent_state: Dictionary = states[parent_key]

	# Return player near the dived chroma pixel
	var return_pos := Vector2(cell.x * 16.0 + 4.0, cell.y * 16.0 + 4.0)
	is_swapping = true
	world_swapped.emit(parent_state, return_pos)
	is_swapping = false
	return true

# Paint heart with held pigment
func paint_heart(pigment: String) -> bool:
	if is_swapping or stack.is_empty():
		return false # Only possible in child worlds and when not swapping

	if pigment.is_empty() or held.is_empty():
		return false # Must hold a pigment

	var child_state := get_current_world()
	var current_color: String = child_state.get("color", "")
	var new_tile: String = pigment.to_upper()

	# If pigment matches heart's current color: reject without consumption
	if new_tile == current_color:
		return false

	# Different color: Paint heart and update parent world!
	held = ""
	held_source_world = ""
	held_source_cell = Vector2i(-1, -1)
	pigment_changed.emit(held)

	# Update parent world tile
	var parent_entry: Dictionary = stack.back()
	var parent_key: String = parent_entry["parent_key"]
	var parent_cell: Vector2i = parent_entry["cell"]

	if states.has(parent_key):
		states[parent_key]["grid"][parent_cell] = new_tile

	child_state["color"] = new_tile
	heart_painted.emit(new_tile)

	# Auto-surface to parent world
	surface()
	return true

# Pigment collection with swap rule
func collect_pigment(orb_char: String, orb_cell: Vector2i) -> void:
	# If already holding a pigment, return old orb to where it was picked up
	if not held.is_empty():
		if not held_source_world.is_empty() and states.has(held_source_world):
			states[held_source_world]["grid"][held_source_cell] = held

	# Pick up new orb
	var cur := get_current_world()
	if not cur.is_empty() and cur.has("grid"):
		cur["grid"][orb_cell] = "."
		if not cur.has("collected_orbs"):
			cur["collected_orbs"] = {}
		cur["collected_orbs"][orb_cell] = orb_char

	held = orb_char
	held_source_world = current_world_key
	held_source_cell = orb_cell
	pigment_changed.emit(held)

# On player death: restore held pigment orb
func on_player_death() -> void:
	if not held.is_empty():
		if not held_source_world.is_empty() and states.has(held_source_world):
			states[held_source_world]["grid"][held_source_cell] = held
		held = ""
		held_source_world = ""
		held_source_cell = Vector2i(-1, -1)
		pigment_changed.emit(held)

# Restart current world
func restart_current_world() -> Vector2:
	var cur := get_current_world()
	var spawn: Vector2i = cur.get("player_spawn", Vector2i(1, 9))
	return Vector2(spawn.x * 16.0 + 4.0, spawn.y * 16.0 + 4.0)
