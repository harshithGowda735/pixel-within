extends SceneTree

# Milestone M4 Transition and Recolor-Wave Unit Tests
const MainScene = preload("res://scenes/main.tscn")
const PaletteScript = preload("res://autoload/palette.gd")

var main_node: Node2D
var game_node: Node
var player_node: Node2D
var test_step := 0
var timer := 0.0

func _init() -> void:
	print("==========================================")
	print("Running Milestone M4 Transition Tests")
	print("==========================================")
	change_scene_to_file("res://scenes/main.tscn")

func _process(delta: float) -> bool:
	if main_node == null or player_node == null:
		main_node = root.get_node_or_null("Main")
		game_node = root.get_node_or_null("Game")
		if main_node != null and "player" in main_node and main_node.player != null:
			player_node = main_node.player
		return false

	timer += delta

	match test_step:
		0:
			# Test 1: Verify Shader and Overlay Setup
			print("\n[Test 1] Testing Mosaic Shader Overlay and Camera Setup...")
			assert(main_node.camera != null)
			assert(main_node.camera.position == Vector2(160, 90))
			assert(main_node.camera.zoom == Vector2(1.0, 1.0))
			assert(main_node.overlay_layer != null)
			assert(main_node.overlay_layer.layer == 100)
			assert(main_node.overlay_rect != null)
			assert(main_node.overlay_rect.visible == false)
			assert(main_node.overlay_material != null)
			print("PASS: Camera2D and Mosaic Shader overlay correctly initialized")

			# Test 2: Input Locking
			print("\n[Test 2] Testing Player Input Locking during Transition...")
			player_node.input_disabled = true
			player_node.sim_position = Vector2(50, 148)
			player_node.velocity = Vector2(100, -200)
			player_node.update_physics(0.016)
			assert(player_node.velocity == Vector2.ZERO)
			assert(player_node.sim_position == Vector2(50, 148))
			player_node.input_disabled = false
			print("PASS: Player input and movement strictly halted when input_disabled is true")

			# Test 3: Start Dive Transition
			print("\n[Test 3] Testing Dive Transition (Canvas -> Child World)...")
			var dive_cell := Vector2i(4, 9) # Blue chroma pixel
			main_node.start_dive_transition(dive_cell)
			assert(main_node.is_transitioning == true)
			assert(player_node.input_disabled == true)
			assert(main_node.overlay_rect.visible == true)
			print("PASS: Dive transition started, player locked, overlay active")
			test_step = 1
			timer = 0.0

		1:
			# Wait for dive transition to complete (~1.0s)
			if not main_node.is_transitioning:
				assert(game_node.current_world_key == "canvas_01/4,9:B")
				assert(game_node.stack.size() == 1)
				assert(main_node.camera.position == Vector2(160, 90))
				assert(main_node.camera.zoom == Vector2(1.0, 1.0))
				assert(main_node.overlay_rect.visible == false)
				assert(player_node.input_disabled == false)
				print("PASS: Dive transition completed cleanly: world swapped once, camera reset, player unlocked")

				# Pick up blue orb
				game_node.collect_pigment("b", Vector2i(10, 5))
				assert(game_node.held == "b")

				# Test 4: Surface Transition
				print("\n[Test 4] Testing Surface Transition (Child World -> Canvas)...")
				main_node.start_surface_transition()
				assert(main_node.is_transitioning == true)
				assert(player_node.input_disabled == true)
				test_step = 2
				timer = 0.0

		2:
			# Wait for surface transition to complete (~0.9s)
			if not main_node.is_transitioning:
				assert(game_node.current_world_key == "canvas_01")
				assert(game_node.stack.is_empty())
				assert(main_node.camera.position == Vector2(160, 90))
				assert(main_node.camera.zoom == Vector2(1.0, 1.0))
				assert(main_node.overlay_rect.visible == false)
				assert(player_node.input_disabled == false)
				assert(game_node.held == "b")
				print("PASS: Surface transition completed cleanly: camera zoom restored, player unlocked")

				# Test 5: Dive into Red Cave
				print("\n[Test 5] Diving into Lava Cave (10, 9)...")
				main_node.start_dive_transition(Vector2i(10, 9))
				test_step = 3
				timer = 0.0

		3:
			if not main_node.is_transitioning:
				assert(game_node.current_world_key == "canvas_01/10,9:R")
				assert(game_node.stack.size() == 1)

				# Test 6: Paint Transition & Recolor Wave
				print("\n[Test 6] Testing Paint Transition, Shockwave & Recolor Wave...")
				# Heart in world_red is at (9, 3) or find it
				var heart_cell := Vector2i(-1, -1)
				var red_grid: Dictionary = game_node.get_current_world()["grid"]
				for pos in red_grid.keys():
					if red_grid[pos] == "H":
						heart_cell = pos
						break
				assert(heart_cell != Vector2i(-1, -1))

				main_node.start_paint_transition(heart_cell, "b")
				assert(main_node.is_transitioning == true)
				assert(player_node.input_disabled == true)
				test_step = 4
				timer = 0.0

		4:
			if not main_node.is_transitioning:
				assert(game_node.current_world_key == "canvas_01")
				assert(game_node.stack.is_empty())
				assert(game_node.get_current_world()["grid"][Vector2i(10, 9)] == "B")
				assert(main_node.camera.position == Vector2(160, 90))
				assert(main_node.camera.zoom == Vector2(1.0, 1.0))
				assert(main_node.overlay_rect.visible == false)
				assert(player_node.input_disabled == false)
				print("PASS: Paint transition completed! Shockwave executed, parent tile repainted to B, recolor wave finished")

				print("\n==========================================")
				print("ALL MILESTONE M4 TRANSITION TESTS PASSED!")
				print("==========================================")
				quit(0)

	return false
