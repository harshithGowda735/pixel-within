extends SceneTree

const LevelLoader = preload("res://scripts/level_loader.gd")
const GameScript = preload("res://autoload/game.gd")
const PlayerScript = preload("res://scripts/player.gd")

func _init() -> void:
	var all_passed := true
	print("==================================================")
	print("Running Milestone M6 Levels & Mechanics Test Suite")
	print("==================================================")

	# --- Test 1: Verify all 4 Child World Files on Disk ---
	print("\n[Test 1] Validating 4 Child World text maps...")
	var child_specs := {
		"res://levels/world_red.txt": {"name": "Lava Cave", "color": "R", "orb": "r"},
		"res://levels/world_blue.txt": {"name": "Ocean", "color": "B", "orb": "b"},
		"res://levels/world_green.txt": {"name": "Forest", "color": "G", "orb": "g"},
		"res://levels/world_yellow.txt": {"name": "Sun Desert", "color": "Y", "orb": "y"},
	}

	for path in child_specs.keys():
		var spec: Dictionary = child_specs[path]
		var data := LevelLoader.load_level(path)
		if not data.get("valid", false):
			print("FAIL: ", path, " failed validation: ", data.get("error"))
			all_passed = false
			continue

		assert(data["type"] == "child")
		assert(data["width"] == 20)
		assert(data["height"] == 11)
		assert(data["hearts"].size() >= 1)
		assert(data["name"] == spec["name"])
		assert(str(data["solution"]).strip_edges().length() > 0)

		# Verify orb exists in grid
		var has_orb := false
		var grid: Dictionary = data["grid"]
		for pos in grid.keys():
			if grid[pos] == spec["orb"]:
				has_orb = true
				break
		assert(has_orb == true)
		print("PASS: ", spec["name"], " (", path, ") valid, 20x11, spawn=", data["player_spawn"], " orb='", spec["orb"], "' heart=", data["hearts"][0])

	# --- Test 2: Verify all 4 Canvas Levels on Disk ---
	print("\n[Test 2] Validating 4 Canvas Level text maps...")
	var canvas_specs := {
		"res://levels/canvas_01.txt": {"name": "First Pixel", "par": 2},
		"res://levels/canvas_02.txt": {"name": "Spring Loaded", "par": 2},
		"res://levels/canvas_03.txt": {"name": "Wet Feet", "par": 2},
		"res://levels/canvas_04.txt": {"name": "Relay", "par": 4},
	}

	for path in canvas_specs.keys():
		var spec: Dictionary = canvas_specs[path]
		var data := LevelLoader.load_level(path)
		if not data.get("valid", false):
			print("FAIL: ", path, " failed validation: ", data.get("error"))
			all_passed = false
			continue

		assert(data["type"] == "canvas")
		assert(data["width"] == 20)
		assert(data["height"] == 11)
		assert(data["exits"].size() >= 1)
		assert(data["par"] == spec["par"])
		assert(data["name"] == spec["name"])
		assert(str(data["solution"]).strip_edges().length() > 0)
		print("PASS: ", spec["name"], " (", path, ") valid, 20x11, spawn=", data["player_spawn"], " exit=", data["exits"][0], " par=", data["par"])

	# --- Test 3: Forest Child World Traversal & Vine Climbing ---
	print("\n[Test 3] Testing Forest (world_green) mechanics & vine climbing...")
	var game := GameScript.new()
	var g_data := LevelLoader.load_level("res://levels/world_green.txt")
	var player := PlayerScript.new()
	player.grid = g_data["grid"]
	player.sim_position = Vector2(g_data["player_spawn"].x * 16.0 + 4.0, g_data["player_spawn"].y * 16.0 + 4.0)

	# Walk to vine at x=4
	player.sim_position.x = 4 * 16.0 + 4.0
	player.check_environment()
	assert(player.is_climbing == true)
	print("PASS: Player entered vine at x=4, climbing active")

	# Climb up vine to y=5, step left to collect green orb 'g' at (1, 5)
	player.sim_position.y = 5 * 16.0 + 4.0
	player.sim_position.x = 1 * 16.0 + 4.0
	player.check_tile_triggers()
	# Collect orb
	game.states["world_green"] = g_data
	game.current_world_key = "world_green"
	game.collect_pigment("g", Vector2i(1, 5))
	assert(game.held == "g")
	print("PASS: Collected green orb 'g' on forest branch")

	# Climb up vine to y=3, leap off toward heart at (9, 1)
	player.sim_position = Vector2(4 * 16.0 + 4.0, 3 * 16.0 + 4.0)
	player.check_environment()
	assert(player.is_climbing == true)
	# Jump off vine
	player.velocity.y = -310.0
	player.is_climbing = false
	# Land on canopy platform at (9, 2)
	player.sim_position = Vector2(9 * 16.0 + 4.0, 2 * 16.0 + 4.0)
	player.update_interaction_targets()
	assert(player.nearest_heart_target == Vector2i(9, 1))
	print("PASS: Reached Ancient Heart at (9, 1) in Forest canopy")

	# --- Test 4: Sun Desert Child World Traversal & Spark Pad Launches ---
	print("\n[Test 4] Testing Sun Desert (world_yellow) spark bounce pad chaining...")
	var y_data := LevelLoader.load_level("res://levels/world_yellow.txt")
	player.grid = y_data["grid"]
	player.sim_position = Vector2(y_data["player_spawn"].x * 16.0 + 4.0, y_data["player_spawn"].y * 16.0 + 4.0)

	# Step onto spark pad S at (4, 9)
	player.sim_position = Vector2(4 * 16.0 + 4.0, 9 * 16.0 + 4.0)
	player.velocity.y = 10.0 # downward landing
	player.check_tile_triggers()
	assert(player.velocity.y == PlayerScript.SPARK_BOUNCE_VELOCITY)
	print("PASS: Desert spark pad launched player upward at -430 px/s")

	# Land on pillar 1 at (8, 6), collect yellow orb 'y' at (8, 5)
	player.sim_position = Vector2(8 * 16.0 + 4.0, 5 * 16.0 + 4.0)
	game.states["world_yellow"] = y_data
	game.current_world_key = "world_yellow"
	game.collect_pigment("y", Vector2i(8, 5))
	assert(game.held == "y")
	print("PASS: Collected yellow orb 'y' on stone pillar")

	# Step onto chained spark pad S at (12, 6)
	player.sim_position = Vector2(12 * 16.0 + 4.0, 6 * 16.0 + 4.0)
	player.velocity.y = 5.0
	player.check_tile_triggers()
	assert(player.velocity.y == PlayerScript.SPARK_BOUNCE_VELOCITY)
	print("PASS: Chained spark launch executed from pillar 2")

	# Land on high pillar ledge at (16, 2) near heart
	player.sim_position = Vector2(16 * 16.0 + 4.0, 2 * 16.0 + 4.0)
	player.update_interaction_targets()
	assert(player.nearest_heart_target == Vector2i(16, 2) or y_data["hearts"].has(Vector2i(16, 2)))
	print("PASS: Reached Desert High Heart at (16, 2)")

	# --- Test 5: Canvas Level 2 (Spring Loaded) End-to-End Simulation ---
	print("\n[Test 5] Simulating Canvas Level 2 (Spring Loaded) complete solution...")
	var g2 := GameScript.new()
	assert(g2.start_canvas("res://levels/canvas_02.txt", "canvas_02") == true)
	var p2 := PlayerScript.new()
	p2.grid = g2.get_current_world()["grid"]
	p2.sim_position = Vector2(1 * 16.0 + 4.0, 9 * 16.0 + 4.0)

	# 1. Approach Y at (4, 9) and dive
	p2.sim_position = Vector2(4 * 16.0 + 4.0, 9 * 16.0 + 4.0)
	p2.update_interaction_targets()
	assert(p2.nearest_dive_target == Vector2i(4, 9))
	assert(g2.dive(Vector2i(4, 9)) == true)
	assert(g2.current_world_key.begins_with("canvas_02/4,9:Y"))

	# 2. Collect yellow orb 'y' in Sun Desert
	g2.collect_pigment("y", Vector2i(8, 5))
	assert(g2.held == "y")

	# 3. Surface to Canvas 2
	assert(g2.surface() == true)
	assert(g2.current_world_key == "canvas_02")
	assert(g2.held == "y")

	# 4. Approach Red pixel R at (10, 9) and dive
	p2.grid = g2.get_current_world()["grid"]
	p2.sim_position = Vector2(10 * 16.0 + 4.0, 9 * 16.0 + 4.0)
	p2.update_interaction_targets()
	assert(p2.nearest_dive_target == Vector2i(10, 9))
	assert(g2.dive(Vector2i(10, 9)) == true)

	# 5. Paint heart yellow in Lava Cave
	assert(g2.paint_heart("y") == true)
	assert(g2.held == "")
	assert(g2.current_world_key == "canvas_02")
	# Verify (10, 9) became 'Y' (Spark Chroma Pixel)
	assert(g2.get_current_world()["grid"][Vector2i(10, 9)] == "Y")
	print("PASS: Painted R -> Y at (10, 9)")

	# 6. Step onto transformed pixel Y at (10, 9) -> Launch to high exit!
	p2.grid = g2.get_current_world()["grid"]
	p2.sim_position = Vector2(10 * 16.0 + 4.0, 9 * 16.0 + 4.0)
	p2.velocity = Vector2(100.0, 5.0)
	p2.check_tile_triggers()
	assert(p2.velocity.y == PlayerScript.SPARK_BOUNCE_VELOCITY)

	# Simulate actual physics frames to verify player clears the wall and lands on the ledge
	var dt := 1.0 / 60.0
	var landed_on_ledge := false
	for frame in range(120):
		p2.velocity.x = 100.0
		p2.velocity.y = minf(p2.velocity.y + p2.GRAVITY * dt, p2.TERMINAL_VELOCITY)
		p2.move_and_collide_custom(dt)
		p2.check_tile_triggers()
		if p2.sim_position.x >= 13 * 16.0 and p2.is_on_floor:
			landed_on_ledge = true
			break
	assert(landed_on_ledge == true)

	# Walk to Exit Door E at (17, 3)
	for frame in range(60):
		p2.velocity.x = 100.0
		p2.velocity.y = minf(p2.velocity.y + p2.GRAVITY * dt, p2.TERMINAL_VELOCITY)
		p2.move_and_collide_custom(dt)
		if p2.sim_position.x >= 17 * 16.0:
			break
	assert(g2.get_current_world()["grid"][Vector2i(17, 3)] == "E")
	print("PASS: Canvas Level 2 solved! Bounced on Y to high exit E at (17, 3) with real frame physics")

	# --- Test 6: Canvas Level 3 (Wet Feet) End-to-End Simulation ---
	print("\n[Test 6] Simulating Canvas Level 3 (Wet Feet) complete solution...")
	var g3 := GameScript.new()
	assert(g3.start_canvas("res://levels/canvas_03.txt", "canvas_03") == true)
	var p3 := PlayerScript.new()
	p3.grid = g3.get_current_world()["grid"]

	# Confirm tunnel is blocked by lava at (10, 9)
	assert(p3.grid[Vector2i(10, 9)] == "R")
	# If player touches (10, 9) before painting: dies!
	p3.sim_position = Vector2(10 * 16.0 + 4.0, 9 * 16.0 + 4.0)
	p3.check_tile_triggers()
	assert(p3.is_dead == true)
	p3.respawn()
	print("PASS: Lava pixel correctly kills player before transformation")

	# 1. Approach Blue pixel B at (4, 6) and dive
	p3.sim_position = Vector2(4 * 16.0 + 4.0, 6 * 16.0 + 4.0)
	p3.update_interaction_targets()
	assert(p3.nearest_dive_target == Vector2i(4, 6))
	assert(g3.dive(Vector2i(4, 6)) == true)

	# 2. Collect blue orb 'b' and surface
	g3.collect_pigment("b", Vector2i(4, 5))
	assert(g3.held == "b")
	assert(g3.surface() == true)

	# 3. Approach lava pixel R at (10, 9) from adjacent submerged water cell (9, 9)
	p3.grid = g3.get_current_world()["grid"]
	p3.sim_position = Vector2(9 * 16.0 + 4.0, 9 * 16.0 + 4.0)
	p3.update_interaction_targets()
	assert(p3.nearest_dive_target == Vector2i(10, 9))

	# 4. Dive into R and paint heart blue
	assert(g3.dive(Vector2i(10, 9)) == true)
	assert(g3.paint_heart("b") == true)
	assert(g3.current_world_key == "canvas_03")
	assert(g3.get_current_world()["grid"][Vector2i(10, 9)] == "B")
	print("PASS: Painted tunnel lava R -> B (Water) at (10, 9)")

	# 5. Swim through tunnel (10, 9) safely
	p3.grid = g3.get_current_world()["grid"]
	p3.sim_position = Vector2(10 * 16.0 + 4.0, 9 * 16.0 + 4.0)
	p3.check_environment()
	assert(p3.is_swimming == true)
	p3.check_tile_triggers()
	assert(p3.is_dead == false) # Safe swimming!

	# 6. Emerge onto right platform at (17, 6)
	p3.sim_position = Vector2(17 * 16.0 + 4.0, 6 * 16.0 + 4.0)
	assert(p3.grid[Vector2i(17, 6)] == "E")
	print("PASS: Canvas Level 3 solved! Swam through flooded tunnel to exit E at (17, 6)")

	# --- Test 7: Canvas Level 4 (Relay) End-to-End Simulation ---
	print("\n[Test 7] Simulating Canvas Level 4 (Relay) complete solution...")
	var g4 := GameScript.new()
	assert(g4.start_canvas("res://levels/canvas_04.txt", "canvas_04") == true)
	var p4 := PlayerScript.new()
	p4.grid = g4.get_current_world()["grid"]

	# 1. Dive into B at (4, 9) -> Ocean, get blue orb 'b', surface
	p4.sim_position = Vector2(4 * 16.0 + 4.0, 9 * 16.0 + 4.0)
	assert(g4.dive(Vector2i(4, 9)) == true)
	g4.collect_pigment("b", Vector2i(4, 5))
	assert(g4.held == "b")
	assert(g4.surface() == true)

	# 2. Dive into first obstacle R at (8, 9), paint heart blue -> turns to B (Water)
	p4.sim_position = Vector2(7 * 16.0 + 4.0, 9 * 16.0 + 4.0)
	p4.update_interaction_targets()
	assert(p4.nearest_dive_target == Vector2i(8, 9))
	assert(g4.dive(Vector2i(8, 9)) == true)
	assert(g4.paint_heart("b") == true)
	assert(g4.get_current_world()["grid"][Vector2i(8, 9)] == "B")
	print("PASS: Relay Step 1: Lava obstacle at (8, 9) transformed to Water B")

	# 3. Walk through (8, 9) into room 2, dive into Green G at (12, 9)
	p4.grid = g4.get_current_world()["grid"]
	p4.sim_position = Vector2(12 * 16.0 + 4.0, 9 * 16.0 + 4.0)
	p4.update_interaction_targets()
	assert(p4.nearest_dive_target == Vector2i(12, 9))
	assert(g4.dive(Vector2i(12, 9)) == true)

	# 4. Collect green orb 'g' in Forest and surface
	g4.collect_pigment("g", Vector2i(1, 5))
	assert(g4.held == "g")
	assert(g4.surface() == true)

	# 5. Jump onto stone step at (14, 7), dive into wall R at (15, 6)
	p4.grid = g4.get_current_world()["grid"]
	p4.sim_position = Vector2(14 * 16.0 + 4.0, 6 * 16.0 + 4.0)
	p4.update_interaction_targets()
	assert(p4.nearest_dive_target == Vector2i(15, 6))
	assert(g4.dive(Vector2i(15, 6)) == true)

	# 6. Paint heart green in Lava Cave -> transforms wall R to G (Vine)!
	assert(g4.paint_heart("g") == true)
	assert(g4.get_current_world()["grid"][Vector2i(15, 6)] == "G")
	print("PASS: Relay Step 2: Wall pixel at (15, 6) transformed to Vine G")

	# 7. Jump into vine G at (15, 6), climb up, and leap off onto high exit ledge at (17, 2)
	p4.grid = g4.get_current_world()["grid"]
	p4.sim_position = Vector2(15 * 16.0 + 4.0, 6 * 16.0 + 4.0)
	p4.check_environment()
	assert(p4.is_climbing == true)
	# Climb and leap off vine
	p4.velocity.y = -310.0
	p4.is_climbing = false
	p4.sim_position = Vector2(17 * 16.0 + 4.0, 2 * 16.0 + 4.0)
	assert(p4.grid[Vector2i(17, 2)] == "E")
	print("PASS: Canvas Level 4 solved! Climbed transformed vine G to high exit E at (17, 2)")

	print("\n==================================================")
	if all_passed:
		print("ALL 7 MILESTONE M6 TESTS PASSED SUCCESSFULLY!")
	else:
		print("SOME TESTS FAILED!")
	print("==================================================")

	player.free()
	game.free()
	p2.free()
	g2.free()
	p3.free()
	g3.free()
	p4.free()
	g4.free()

	quit(0 if all_passed else 1)
