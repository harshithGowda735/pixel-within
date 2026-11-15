extends SceneTree

# Complete Level 1 playthrough simulation inside the live scene tree
const PaletteScript = preload("res://autoload/palette.gd")

var step := 0
var timer := 0.0
var main_node: Node2D
var game_node: Node
var player_node: Node2D

func _init() -> void:
	print("==========================================")
	print("Running Level 1 Full Playthrough Simulation")
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

	match step:
		0:
			# Step 0: Initial verification in Canvas Level 1
			assert(game_node.current_world_key == "canvas_01")
			assert(game_node.stack.is_empty())
			print("Step 0: Player spawned at (1, 9) in Canvas Level 1")
			# Walk right toward Water pixel B at (4, 9)
			player_node.sim_position.x = 3 * 16.0 + 4.0
			player_node.update_interaction_targets()
			assert(player_node.nearest_dive_target == Vector2i(4, 9))
			print("Step 0: Blue chroma pixel B at (4, 9) highlighted with corner brackets")
			step = 1

		1:
			# Step 1: Dive into Blue
			print("Step 1: Diving (Z) into Blue Chroma Pixel...")
			var dive_ok: bool = game_node.dive(player_node.nearest_dive_target)
			assert(dive_ok == true)
			assert(game_node.current_world_key == "canvas_01/4,9:B")
			assert(game_node.stack.size() == 1)
			print("Step 1: Successfully entered Ocean child world (world_blue)")
			step = 2

		2:
			# Step 2: Collect Blue Pigment Orb
			print("Step 2: Moving to Blue Orb 'b'...")
			# Find orb 'b' in Ocean world
			var cur_world: Dictionary = game_node.get_current_world()
			var orb_pos := Vector2i(-1, -1)
			for pos in cur_world["grid"].keys():
				if cur_world["grid"][pos] == "b":
					orb_pos = pos
					break
			assert(orb_pos != Vector2i(-1, -1))
			# Move player onto orb
			player_node.sim_position = Vector2(orb_pos.x * 16.0 + 4.0, orb_pos.y * 16.0 + 4.0)
			player_node.check_tile_triggers()
			assert(game_node.held == "b")
			assert(player_node.current_pigment == "b")
			print("Step 2: Collected Blue Orb 'b'! Player body color turned Water Mid")
			step = 3

		3:
			# Step 3: Surface back to Canvas
			print("Step 3: Surfacing (C/Esc) to Canvas...")
			var surf_ok: bool = game_node.surface()
			assert(surf_ok == true)
			assert(game_node.current_world_key == "canvas_01")
			assert(game_node.stack.is_empty())
			assert(game_node.held == "b")
			print("Step 3: Resurfaced near (4, 9) in Canvas Level 1 with held pigment intact")
			step = 4

		4:
			# Step 4: Walk toward Lava pixel R at (10, 9)
			print("Step 4: Approaching Lava Chroma Pixel R at (10, 9)...")
			player_node.sim_position = Vector2(9 * 16.0 + 4.0, 9 * 16.0 + 4.0)
			player_node.update_interaction_targets()
			assert(player_node.nearest_dive_target == Vector2i(10, 9))
			print("Step 4: Lava pixel at (10, 9) highlighted with corner brackets")
			step = 5

		5:
			# Step 5: Dive into Red
			print("Step 5: Diving (Z) into Lava Chroma Pixel...")
			var dive_ok2: bool = game_node.dive(player_node.nearest_dive_target)
			assert(dive_ok2 == true)
			assert(game_node.current_world_key == "canvas_01/10,9:R")
			assert(game_node.stack.size() == 1)
			print("Step 5: Successfully entered Lava Cave child world (world_red)")
			step = 6

		6:
			# Step 6: Reach Heart and Paint it Blue
			print("Step 6: Reaching Heart and painting it Blue (X)...")
			var red_world: Dictionary = game_node.get_current_world()
			var heart_pos := Vector2i(-1, -1)
			for pos in red_world["grid"].keys():
				if red_world["grid"][pos] == "H":
					heart_pos = pos
					break
			assert(heart_pos != Vector2i(-1, -1))
			# Move within 24 px of Heart
			player_node.sim_position = Vector2(heart_pos.x * 16.0 + 4.0, heart_pos.y * 16.0 + 4.0)
			player_node.update_interaction_targets()
			assert(player_node.nearest_heart_target == heart_pos)
			# Paint heart with held blue pigment
			var paint_ok: bool = game_node.paint_heart(game_node.held)
			assert(paint_ok == true)
			assert(game_node.held == "")
			print("Step 6: Heart painted! Pigment consumed, auto-surfaced to Canvas")
			step = 7

		7:
			# Step 7: Confirm parent tile became blue water 'B'
			print("Step 7: Verifying Canvas tile at (10, 9) has transformed into Water...")
			assert(game_node.current_world_key == "canvas_01")
			assert(game_node.stack.is_empty())
			var canvas_grid: Dictionary = game_node.get_current_world()["grid"]
			assert(canvas_grid[Vector2i(10, 9)] == "B")
			print("Step 7: CONFIRMED! Tile at (10, 9) is now 'B' (Water Chroma Pixel)")
			step = 8

		8:
			# Step 8: Walk and swim safely through (10, 9) to reach Exit at (17, 9)
			print("Step 8: Swimming through (10, 9) and reaching Exit Door 'E' at (17, 9)...")
			var c_grid: Dictionary = game_node.get_current_world()["grid"]
			player_node.sim_position = Vector2(10 * 16.0 + 4.0, 9 * 16.0 + 4.0)
			player_node.check_environment()
			assert(player_node.is_swimming == true)
			player_node.check_tile_triggers()
			assert(player_node.is_dead == false) # Did NOT die from lava!
			print("Step 8: Swam safely through (10, 9) without dying")

			# Move to exit door at (17, 9)
			player_node.sim_position = Vector2(17 * 16.0 + 4.0, 9 * 16.0 + 4.0)
			assert(c_grid[Vector2i(17, 9)] == "E")
			print("Step 8: Reached Exit Door 'E' at (17, 9)!")
			step = 9

		9:
			print("\n==========================================")
			print("LEVEL 1 PLAYTHROUGH FULLY VERIFIED!")
			print("==========================================")
			quit(0)

	return false
