extends SceneTree

const LevelLoader = preload("res://scripts/level_loader.gd")
const GameScript = preload("res://autoload/game.gd")
const PlayerScript = preload("res://scripts/player.gd")

func _init() -> void:
	var all_passed := true
	print("==========================================")
	print("Running Milestone M3 Game State & Mechanics Tests")
	print("==========================================")

	var game := GameScript.new()

	# --- Test 1: Start Canvas Level 1 Initial State ---
	print("\n[Test 1] Testing Canvas Level 1 initial state...")
	var loaded: bool = game.start_canvas("res://levels/canvas_01.txt", "canvas_01")
	assert(loaded == true)
	assert(game.current_world_key == "canvas_01")
	assert(game.stack.is_empty())
	assert(game.held == "")
	var cur := game.get_current_world()
	assert(cur["name"] == "First Pixel")
	assert(cur["grid"][Vector2i(4, 9)] == "B")
	assert(cur["grid"][Vector2i(10, 9)] == "R")
	print("PASS: Canvas Level 1 initialized with empty stack and empty held pigment")

	# --- Test 2: Dive into Chroma Pixel (B) ---
	print("\n[Test 2] Testing Dive (Z) into Chroma Pixel B at (4, 9)...")
	var dive_ok: bool = game.dive(Vector2i(4, 9))
	assert(dive_ok == true)
	assert(game.stack.size() == 1)
	assert(game.stack[0]["parent_key"] == "canvas_01")
	assert(game.stack[0]["cell"] == Vector2i(4, 9))
	assert(game.stack[0]["held_on_entry"] == "")
	assert(game.stack[0]["tile_char"] == "B")
	assert(game.current_world_key == "canvas_01/4,9:B")
	var blue_world := game.get_current_world()
	assert(blue_world["color"] == "B")
	assert(blue_world["type"] == "child")
	print("PASS: Dive into B succeeded, stack pushed, active world is canvas_01/4,9:B")

	# --- Test 3: Rejection of Non-Diveable Tiles ---
	print("\n[Test 3] Testing rejection of non-diveable tiles (walls, air, terrain fills)...")
	# In world_blue, try diving into solid stone, air, or water fill W
	assert(game.dive(Vector2i(0, 0)) == false) # Wall #
	assert(game.dive(Vector2i(2, 2)) == false) # Air or Fill
	var orig_stack_size := game.stack.size()
	assert(orig_stack_size == 1)
	print("PASS: Non-diveable tiles correctly rejected without altering stack")

	# --- Test 4: Maximum Dive Depth Limit (3) ---
	print("\n[Test 4] Testing max dive depth limit of 3...")
	# For testing depth, add mock diveable tiles to stack
	blue_world["grid"][Vector2i(2, 2)] = "R"
	var d2: bool = game.dive(Vector2i(2, 2))
	assert(d2 == true)
	assert(game.stack.size() == 2)
	game.get_current_world()["grid"][Vector2i(3, 3)] = "G"
	var d3_key := "canvas_01/4,9:B/2,2:R/3,3:G"
	game.states[d3_key] = {"valid": true, "grid": {Vector2i(4, 4): "Y"}, "color": "G", "player_spawn": Vector2i(1, 9)}
	var d3: bool = game.dive(Vector2i(3, 3))
	assert(d3 == true)
	assert(game.stack.size() == 3)
	# 4th dive must be rejected by MAX_DIVE_DEPTH
	game.get_current_world()["grid"][Vector2i(4, 4)] = "Y"
	var d4: bool = game.dive(Vector2i(4, 4))
	assert(d4 == false)
	assert(game.stack.size() == 3)
	print("PASS: Max dive depth strictly capped at 3")

	# Unwind test depth back to 1
	game.surface()
	game.surface()
	assert(game.stack.size() == 1)
	assert(game.current_world_key == "canvas_01/4,9:B")

	# --- Test 5: Pigment Collection ---
	print("\n[Test 5] Testing Pigment Orb Collection...")
	# world_blue contains orb 'b'
	var orb_cell := Vector2i(10, 5)
	blue_world["grid"][orb_cell] = "b"
	game.collect_pigment("b", orb_cell)
	assert(game.held == "b")
	assert(game.held_source_world == "canvas_01/4,9:B")
	assert(game.held_source_cell == orb_cell)
	assert(game.get_current_world()["grid"][orb_cell] == ".")
	print("PASS: Pigment 'b' collected, removed from grid, held in Game.held")

	# --- Test 6: Surface Back to Canvas ---
	print("\n[Test 6] Testing Surface (C/Esc) back to Canvas...")
	var surface_ok: bool = game.surface()
	assert(surface_ok == true)
	assert(game.stack.is_empty())
	assert(game.current_world_key == "canvas_01")
	assert(game.held == "b") # Still holds pigment
	print("PASS: Surface restored canvas_01 as active world with held pigment preserved")

	# --- Test 7: Cached World State Persistence ---
	print("\n[Test 7] Testing child world state persistence across dives...")
	game.dive(Vector2i(4, 9))
	# The orb picked up previously should still be '.' in the cached world
	assert(game.get_current_world()["grid"][orb_cell] == ".")
	game.surface()
	print("PASS: Child world state correctly cached and preserved")

	# --- Test 8: Pigment Swapping Rule ---
	print("\n[Test 8] Testing Pigment Swapping Rule...")
	# Currently holding 'b' from (4, 9):B at orb_cell
	# Dive into R at (10, 9)
	game.dive(Vector2i(10, 9))
	assert(game.current_world_key == "canvas_01/10,9:R")
	var red_world := game.get_current_world()
	var red_orb_cell := Vector2i(8, 5)
	red_world["grid"][red_orb_cell] = "r"
	# Collect 'r' while holding 'b' -> should restore 'b' at world_blue!
	game.collect_pigment("r", red_orb_cell)
	assert(game.held == "r")
	assert(game.held_source_world == "canvas_01/10,9:R")
	# Check that world_blue restored 'b' at orb_cell
	assert(game.states["canvas_01/4,9:B"]["grid"][orb_cell] == "b")
	print("PASS: Swapping pigment returned previous orb 'b' to its original world cell")

	# Swap back: pick up blue again
	game.surface()
	game.dive(Vector2i(4, 9))
	game.collect_pigment("b", orb_cell)
	assert(game.held == "b")
	# Check that world_red restored 'r' at red_orb_cell
	assert(game.states["canvas_01/10,9:R"]["grid"][red_orb_cell] == "r")
	game.surface()
	print("PASS: Swap back verified symmetrically")

	# --- Test 9: Matching Heart Rejection ---
	print("\n[Test 9] Testing Matching Heart Rejection (b on blue heart)...")
	game.dive(Vector2i(4, 9))
	# Blue world heart is already 'B'
	var paint_same: bool = game.paint_heart("b")
	assert(paint_same == false)
	assert(game.held == "b") # Not consumed
	assert(game.stack.size() == 1) # No auto-surface
	print("PASS: Painting matching heart rejected without consuming pigment")
	game.surface()

	# --- Test 10: Painting Heart with Different Pigment ---
	print("\n[Test 10] Testing Heart Painting with Different Pigment (b on red heart)...")
	# Dive into R at (10, 9)
	game.dive(Vector2i(10, 9))
	assert(game.current_world_key == "canvas_01/10,9:R")
	var paint_ok: bool = game.paint_heart("b")
	assert(paint_ok == true)
	assert(game.held == "") # Consumed
	# Auto-surfaced to canvas_01!
	assert(game.stack.is_empty())
	assert(game.current_world_key == "canvas_01")
	# Canvas tile at (10, 9) updated from R to B!
	assert(game.get_current_world()["grid"][Vector2i(10, 9)] == "B")
	print("PASS: Heart painted! Pigment consumed, parent tile updated to B, auto-surfaced")

	# --- Test 11: Repainted Tile Keying (Fresh Child World) ---
	print("\n[Test 11] Testing repainted tile loads fresh world with key matching new color...")
	# Tile at (10, 9) is now "B". Diving into it should create key canvas_01/10,9:B
	game.dive(Vector2i(10, 9))
	assert(game.current_world_key == "canvas_01/10,9:B")
	assert(game.get_current_world()["color"] == "B")
	print("PASS: Repainted tile produces distinct child world key canvas_01/10,9:B")
	game.surface()

	# --- Test 12: Player Death Restores Held Pigment ---
	print("\n[Test 12] Testing player death restores held pigment to its world...")
	game.dive(Vector2i(4, 9))
	game.collect_pigment("b", orb_cell)
	assert(game.held == "b")
	assert(game.get_current_world()["grid"][orb_cell] == ".")
	# Trigger player death
	game.on_player_death()
	assert(game.held == "")
	assert(game.get_current_world()["grid"][orb_cell] == "b")
	print("PASS: On death, held pigment cleared and orb restored at origin")
	game.surface()

	# --- Test 13: Player Body Color Updates ---
	print("\n[Test 13] Testing Player body color updates based on held pigment...")
	var player = PlayerScript.new()
	player.update_body_color("")
	assert(player.current_pigment == "")
	player.update_body_color("b")
	assert(player.current_pigment == "b")
	player.update_body_color("r")
	assert(player.current_pigment == "r")
	player.update_body_color("")
	assert(player.current_pigment == "")
	print("PASS: Player body color dynamically updates with pigment")

	# --- Test 14: Complete Canvas Level 1 Playable Walkthrough ---
	print("\n[Test 14] Testing complete Canvas Level 1 playable solution...")
	# Solution: "dive B, take blue orb, surface, dive R, paint heart, walk through water, exit"
	game.start_canvas("res://levels/canvas_01.txt", "canvas_01")
	# 1. Start at spawn (1, 9)
	assert(game.current_world_key == "canvas_01")
	# 2. Walk to B at (4, 9) and dive
	assert(game.dive(Vector2i(4, 9)) == true)
	# 3. Collect blue orb b
	game.collect_pigment("b", Vector2i(10, 5))
	assert(game.held == "b")
	# 4. Surface to canvas
	assert(game.surface() == true)
	# 5. Walk to R at (10, 9) and dive
	assert(game.dive(Vector2i(10, 9)) == true)
	# 6. Reach heart and paint it with blue pigment
	assert(game.paint_heart("b") == true)
	# 7. Player is auto-surfaced to canvas_01
	assert(game.current_world_key == "canvas_01")
	# 8. Lava tile at (10, 9) is now water 'B'
	assert(game.get_current_world()["grid"][Vector2i(10, 9)] == "B")
	# 9. Exit door at (17, 9) is reachable without deadly lava in the path
	var exit_tile: String = game.get_current_world()["grid"][Vector2i(17, 9)]
	assert(exit_tile == "E")
	print("PASS: Complete Canvas Level 1 core loop successfully executed end-to-end!")

	# --- Test 15: Interaction Range, Corner Brackets, Empty Stack Surface & Swap Guard ---
	print("\n[Test 15] Testing Dive Target Range, Empty Surface, and Swap Guards...")
	# Empty stack surface:
	assert(game.stack.is_empty())
	assert(game.surface() == false)
	print("PASS: Surfacing with empty stack cleanly returns false")

	# Swap guard:
	game.is_swapping = true
	assert(game.dive(Vector2i(4, 9)) == false)
	assert(game.surface() == false)
	assert(game.paint_heart("b") == false)
	game.is_swapping = false
	print("PASS: Re-entrant dive/surface/paint during swap safely rejected")

	# Target selection & range:
	var canvas_grid: Dictionary = game.get_current_world()["grid"]
	player.setup(canvas_grid, Vector2i(1, 9)) # At (1, 9), distance to B at (4, 9) is 3 tiles = 48 px (> 24 px)
	player.update_interaction_targets()
	assert(player.nearest_dive_target == Vector2i(-1, -1))
	print("PASS: Chroma tile at 48 px correctly NOT targeted (range > 24 px)")

	# Move player closer: tile (3, 9) center is at (56, 152), tile (4, 9) center is at (72, 152) -> distance is 16 px (< 24 px)
	player.sim_position = Vector2(3 * 16.0 + 4.0, 9 * 16.0 + 4.0)
	player.update_interaction_targets()
	assert(player.nearest_dive_target == Vector2i(4, 9))
	print("PASS: Nearest chroma tile at 16 px correctly targeted")

	# Verify non-chroma tiles (walls, air, fill) are never targeted
	canvas_grid[Vector2i(3, 8)] = "W"
	canvas_grid[Vector2i(3, 7)] = "#"
	player.update_interaction_targets()
	assert(player.nearest_dive_target == Vector2i(4, 9)) # Still points only to B
	print("PASS: Non-chroma tiles (W, #) never selected as dive target")

	# --- Test 16: Child World Death, Stack Integrity, and Re-Dive ---
	print("\n[Test 16] Testing Child World Death, Stack Validity, and Re-Diving...")
	# Dive into B
	assert(game.dive(Vector2i(4, 9)) == true)
	assert(game.stack.size() == 1)
	assert(game.current_world_key == "canvas_01/4,9:B")
	# Collect orb
	game.collect_pigment("b", Vector2i(10, 5))
	assert(game.held == "b")
	assert(game.get_current_world()["grid"][Vector2i(10, 5)] == ".")
	# Player dies inside child world
	game.on_player_death()
	assert(game.held == "")
	# Orb restored to child world grid!
	assert(game.get_current_world()["grid"][Vector2i(10, 5)] == "b")
	# Stack and parent world remain intact!
	assert(game.stack.size() == 1)
	assert(game.current_world_key == "canvas_01/4,9:B")
	assert(game.states.has("canvas_01"))
	# Surface after death
	assert(game.surface() == true)
	assert(game.stack.is_empty())
	assert(game.current_world_key == "canvas_01")
	# Dive into the same tile again
	assert(game.dive(Vector2i(4, 9)) == true)
	assert(game.current_world_key == "canvas_01/4,9:B")
	assert(game.get_current_world()["grid"][Vector2i(10, 5)] == "b")
	game.surface()
	print("PASS: Death in child world preserves stack, restores orb, and allows re-diving")

	print("\n==========================================")
	print("ALL 16 MILESTONE M3 GAME STATE TESTS PASSED!")
	print("==========================================")
	player.free()
	game.free()
	quit(0)
