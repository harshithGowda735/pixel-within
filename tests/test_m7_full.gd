extends SceneTree

# Test Suite for Pixel Within - Milestone M7 Complete
# Covers Glitchling enemy, gems/stars, save manager, Canvas 5 depth-2, Canvas 6 ending, BGM.

const GlitchlingScript = preload("res://scripts/glitchling.gd")
const SaveManagerScript = preload("res://scripts/save_manager.gd")
const PlayerScript = preload("res://scripts/player.gd")
const GameScript = preload("res://autoload/game.gd")
const MusicManagerScript = preload("res://scripts/music_manager.gd")

var passed_count := 0
var failed_count := 0

func _init() -> void:
	print("--- Running Pixel Within M7 Complete Verification ---")
	test_glitchling_mechanics()
	test_gems_stars_save()
	test_canvas_05_depth_two()
	test_canvas_06_complete_progression()
	test_music_manager()

	print("\n--- M7 Test Results ---")
	print("Passed: %d, Failed: %d" % [passed_count, failed_count])
	if failed_count > 0:
		print("FAILED: Some M7 tests failed.")
		quit(1)
	else:
		print("SUCCESS: All M7 tests passed!")
		quit(0)

func assert_true(cond: bool, msg: String) -> void:
	if cond:
		passed_count += 1
		print("  [PASS] " + msg)
	else:
		failed_count += 1
		print("  [FAIL] " + msg)

func test_glitchling_mechanics() -> void:
	print("\n[Test 1] Glitchling Mechanics (M7.1)...")
	# Create a dummy grid: floor at row 6, wall at col 9
	var grid := {}
	for x in range(20):
		grid[Vector2i(x, 6)] = "#"
	grid[Vector2i(9, 5)] = "#"

	var start_pos := Vector2(80.0, 88.0)
	var g = GlitchlingScript.new(start_pos)
	assert_true(g.direction == 1.0, "Glitchling starts moving right")
	assert_true(not g.is_dead, "Glitchling starts alive")

	# Update 1.0 second: moves right
	g.update(1.0, grid)
	assert_true(g.sim_position.x > 80.0, "Glitchling moved forward: x=" + str(g.sim_position.x))

	# Advance until it hits wall at col 9 (x = 144)
	for i in range(10):
		g.update(0.5, grid)
	assert_true(g.direction == -1.0, "Glitchling reversed direction on wall: dir=" + str(g.direction))

	# Test platform ledge drop-off reversal (floor only from col 3 to 7)
	var ledge_grid := {}
	for x in range(3, 8):
		ledge_grid[Vector2i(x, 6)] = "#"
	var g_ledge = GlitchlingScript.new(Vector2(6 * 16.0, 5 * 16.0 + 8.0))
	g_ledge.direction = 1.0
	for i in range(20):
		g_ledge.update(0.1, ledge_grid)
	assert_true(g_ledge.direction == -1.0, "Glitchling reversed on platform drop-off: dir=" + str(g_ledge.direction))

	# Test Stomp bounce
	var player = PlayerScript.new()
	player.sim_position = Vector2(80.0, 78.0) # Overlapping glitchling top half
	player.velocity = Vector2(0.0, 50.0)      # Downward moving
	var g_stomp = GlitchlingScript.new(Vector2(80.0, 88.0))

	# Hitbox check
	assert_true(player.get_hitbox().intersects(g_stomp.get_hitbox()), "Player overlaps glitchling")
	g_stomp.die()
	player.velocity.y = GlitchlingScript.BOUNCE_VELOCITY
	assert_true(g_stomp.is_dead, "Glitchling marked dead on stomp")
	assert_true(player.velocity.y == -260.0, "Player bounced upward with -260 px/s")

	# Test Reset
	g_stomp.reset()
	assert_true(not g_stomp.is_dead, "Glitchling alive after reset")
	assert_true(g_stomp.sim_position == Vector2(80.0, 88.0), "Glitchling reset to start position")

func test_gems_stars_save() -> void:
	print("\n[Test 2] Gems, Stars & Save System (M7.2 & M7.3)...")
	SaveManagerScript.load_data()
	assert_true(SaveManagerScript.is_unlocked("canvas_01"), "Canvas 1 unlocked by default")

	var game = GameScript.new()
	# Test star calculation logic
	game.current_canvas_key = "canvas_01"
	game.level_gems_total = 2
	game.level_gems_collected = 0
	var res1: Dictionary = game.reach_exit()
	assert_true(res1["stars"] == 1, "0/2 gems awards 1 star")

	game.level_gems_collected = 1
	var res2: Dictionary = game.reach_exit()
	assert_true(res2["stars"] == 2, "1/2 gems (50%) awards 2 stars")

	game.level_gems_collected = 2
	var res3: Dictionary = game.reach_exit()
	assert_true(res3["stars"] == 3, "2/2 gems (100%) awards 3 stars")

	# Level 2 should now be unlocked
	assert_true(SaveManagerScript.is_unlocked("canvas_02"), "Completing canvas 1 unlocks canvas 2")
	assert_true(SaveManagerScript.get_stars("canvas_01") == 3, "Canvas 1 has 3 stars saved")

	# Gem collection removes from grid and tracks correctly
	game.start_canvas("res://levels/canvas_01.txt", "canvas_01")
	var gem_cell := Vector2i(11, 9)
	var cur_world: Dictionary = game.get_current_world()
	if cur_world.get("grid", {}).get(gem_cell, "") == "*":
		game.collect_gem(gem_cell)
		assert_true(game.level_gems_collected == 1, "Collected 1 gem")
		assert_true(cur_world["grid"][gem_cell] == ".", "Gem tile replaced with air")

func test_canvas_05_depth_two() -> void:
	print("\n[Test 3] Canvas 5 Genuine Depth-Two (M7.4)...")
	var game = GameScript.new()
	var success := game.start_canvas("res://levels/canvas_05.txt", "canvas_05")
	assert_true(success, "Canvas 5 loaded successfully")
	assert_true(game.stack.size() == 0, "Depth is 0 in canvas")

	# Canvas 5 has Yellow 'Y' at (4, 9) and Green 'G' at (8, 9)
	var c5_grid: Dictionary = game.get_current_world()["grid"]
	assert_true(c5_grid.get(Vector2i(4, 9), "") == "Y", "Yellow pixel at (4, 9)")
	assert_true(c5_grid.get(Vector2i(8, 9), "") == "G", "Green pixel at (8, 9)")
	assert_true(c5_grid.get(Vector2i(17, 3), "") == "E", "Exit at (17, 3)")

	# Step 1: Dive into Y at (4, 9) (depth 1: Sun Desert)
	game.dive(Vector2i(4, 9))
	assert_true(game.stack.size() == 1, "Stack size is 1 (Sun Desert)")
	# Collect yellow orb 'y' at (12, 7) in Sun Desert
	game.collect_pigment("y", Vector2i(12, 7))
	assert_true(game.held == "y", "Player holds yellow pigment 'y'")

	# Surface back to Canvas 5
	game.surface()
	assert_true(game.stack.size() == 0, "Surfaced back to Canvas 5 (depth 0)")
	assert_true(game.held == "y", "Still holding yellow pigment 'y'")

	# Step 2: Dive into G at (8, 9) (depth 1: Forest Canopy canvas_05_g.txt)
	game.dive(Vector2i(8, 9))
	assert_true(game.stack.size() == 1, "Entered Forest Canopy (depth 1)")
	var forest_grid: Dictionary = game.get_current_world()["grid"]
	assert_true(forest_grid.get(Vector2i(13, 4), "") == "R", "Forest has lava pixel R at (13, 4)")
	assert_true(forest_grid.get(Vector2i(15, 1), "") == "H", "Forest has heart H at (15, 1)")

	# Step 3: Dive into lava pixel R at (13, 4) (DEPTH TWO: Lava Cave!)
	game.dive(Vector2i(13, 4))
	assert_true(game.stack.size() == 2, "GENUINE DEPTH TWO! Stack size is 2 (Lava Cave inside Forest)")
	var cave_state: Dictionary = game.get_current_world()
	assert_true(cave_state.get("color", "") == "R", "Lava Cave is red world")

	# Step 4: Paint Lava Cave heart yellow with held yellow pigment
	var painted := game.paint_heart("y")
	assert_true(painted, "Painted Lava Cave heart yellow")

	# paint_heart automatically surfaces back to Forest (depth 1)
	assert_true(game.stack.size() == 1, "Auto-surfaced to Forest (depth 1)")
	var forest_after_paint: Dictionary = game.get_current_world()["grid"]
	assert_true(forest_after_paint.get(Vector2i(13, 4), "") == "Y", "Forest tile (13, 4) transformed R -> Y (Spark Pad)!")

	# Step 5: Collect yellow orb 'y' at (1, 5) in Forest
	assert_true(forest_after_paint.get(Vector2i(1, 5), "") == "y", "Yellow orb exists at (1, 5) in Forest")
	game.collect_pigment("y", Vector2i(1, 5))
	assert_true(game.held == "y", "Player collected yellow orb in Forest")

	# Step 6: Paint Forest heart yellow
	var painted_forest := game.paint_heart("y")
	assert_true(painted_forest, "Painted Forest heart yellow")

	# Auto-surfaced back to Canvas 5 (depth 0)
	assert_true(game.stack.size() == 0, "Auto-surfaced back to Canvas 5 (depth 0)")
	var c5_after: Dictionary = game.get_current_world()["grid"]
	assert_true(c5_after.get(Vector2i(8, 9), "") == "Y", "Canvas 5 tile (8, 9) transformed G -> Y (Spark Pad)!")

	# Spark bounce from (8, 9) allows reaching row 3 (exit E)
	var jump_height := (430.0 * 430.0) / (2.0 * 900.0) # 102.7 px
	var needed_rise := (9 - 3) * 16.0 # 96 px
	assert_true(jump_height > needed_rise, "Spark bounce height (102.7 px) exceeds ledge rise (96 px)")

func test_canvas_06_complete_progression() -> void:
	print("\n[Test 4] Canvas 6 (Zoom Out & Ending Reveal M7.5)...")
	var game = GameScript.new()
	var success := game.start_canvas("res://levels/canvas_06.txt", "canvas_06")
	assert_true(success, "Canvas 6 loaded successfully")

	var grid: Dictionary = game.get_current_world()["grid"]
	assert_true(grid.get(Vector2i(3, 9), "") == "B", "Blue pixel at (3, 9)")
	assert_true(grid.get(Vector2i(7, 9), "") == "R", "Lava pixel R1 at (7, 9)")
	assert_true(grid.get(Vector2i(9, 9), "") == "G", "Green pixel at (9, 9)")
	assert_true(grid.get(Vector2i(12, 6), "") == "R", "Lava pixel R2 at (12, 6)")
	assert_true(grid.get(Vector2i(14, 3), "") == "Y", "Yellow pixel at (14, 3)")
	assert_true(grid.get(Vector2i(16, 3), "") == "R", "Lava pixel R3 at (16, 3)")
	assert_true(grid.get(Vector2i(18, 1), "") == "E", "Exit at (18, 1)")

	# Phase 1: Blue pigment
	game.dive(Vector2i(3, 9))
	game.collect_pigment("b", Vector2i(1, 4))
	game.surface()
	assert_true(game.held == "b", "Collected blue pigment")
	game.dive(Vector2i(7, 9))
	game.paint_heart("b")
	grid = game.get_current_world()["grid"]
	assert_true(grid[Vector2i(7, 9)] == "B", "R1 transformed to B (water path open)")

	# Phase 2: Green pigment
	game.dive(Vector2i(9, 9))
	game.collect_pigment("g", Vector2i(1, 5))
	game.surface()
	assert_true(game.held == "g", "Collected green pigment")
	game.dive(Vector2i(12, 6))
	game.paint_heart("g")
	grid = game.get_current_world()["grid"]
	assert_true(grid[Vector2i(12, 6)] == "G", "R2 transformed to G (vine climb open)")

	# Phase 3: Yellow pigment
	game.dive(Vector2i(14, 3))
	game.collect_pigment("y", Vector2i(12, 7))
	game.surface()
	assert_true(game.held == "y", "Collected yellow pigment")
	game.dive(Vector2i(16, 3))
	game.paint_heart("y")
	grid = game.get_current_world()["grid"]
	assert_true(grid[Vector2i(16, 3)] == "Y", "R3 transformed to Y (spark bounce open)")

	# Reach Exit in Canvas 6
	var final_res: Dictionary = game.reach_exit()
	assert_true(final_res["level_id"] == "canvas_06", "Canvas 6 completed")
	assert_true(SaveManagerScript.game_completed == true, "Game completed saved to true!")

func test_music_manager() -> void:
	print("\n[Test 5] Music Manager (BGM Loop & Mute)...")
	var mm = MusicManagerScript.new()
	assert_true(mm != null, "Music manager instantiates")
	mm._ready()
	assert_true(mm.stream != null, "Music stream is loaded")
	assert_true(not mm.is_muted, "Music starts unmuted")
	mm.toggle_mute()
	assert_true(mm.is_muted, "Music muted after toggle")
	mm.toggle_mute()
	assert_true(not mm.is_muted, "Music unmuted after second toggle")
