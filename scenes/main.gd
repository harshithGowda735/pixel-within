extends Node2D

var level_data: Dictionary = {}
var player: Player

func _ready() -> void:
	# Connect to Game autoload signals
	var game_node = get_node_or_null("/root/Game")
	if game_node != null:
		game_node.world_swapped.connect(_on_world_swapped)
		game_node.pigment_changed.connect(_on_pigment_changed)
		game_node.heart_painted.connect(_on_heart_painted)

	player = Player.new()
	add_child(player)

	# Start initial canvas level if needed
	if game_node != null:
		if game_node.states.is_empty():
			game_node.start_canvas("res://levels/canvas_01.txt", "canvas_01")
		else:
			var cur: Dictionary = game_node.get_current_world()
			var spawn: Vector2i = cur.get("player_spawn", Vector2i(1, 9))
			_on_world_swapped(cur, Vector2(spawn.x * 16.0 + 4.0, spawn.y * 16.0 + 4.0))

func _on_world_swapped(world_state: Dictionary, player_pos: Vector2) -> void:
	level_data = world_state
	if player != null:
		player.grid = world_state.get("grid", {})
		player.spawn_position = Vector2(world_state.get("player_spawn", Vector2i(1, 9)).x * 16.0 + 4.0, world_state.get("player_spawn", Vector2i(1, 9)).y * 16.0 + 4.0)
		player.sim_position = player_pos
		player.position = player_pos.round()
		player.velocity = Vector2.ZERO
		player.is_climbing = false
		player.is_swimming = false
		player.queue_redraw()
	queue_redraw()

func _on_pigment_changed(_pigment: String) -> void:
	queue_redraw()

func _on_heart_painted(_color: String) -> void:
	queue_redraw()

func _draw() -> void:
	if not level_data.get("valid", false):
		return

	var grid: Dictionary = level_data.get("grid", {})
	for pos in grid.keys():
		var tile_char: String = grid[pos]
		var tex := Tiles.get_tile_texture(tile_char, pos)
		draw_texture(tex, Vector2(pos.x * Tiles.TILE_SIZE, pos.y * Tiles.TILE_SIZE))

	# 4px HUD strip at bottom (y: 176 to 180)
	draw_line(Vector2(0, 176), Vector2(320, 176), Palette.STONE_DARK, 1.0)
	
	# Draw breadcrumbs and held pigment indicator in the HUD strip
	_draw_hud()

func _draw_hud() -> void:
	var game_node = get_node_or_null("/root/Game")
	if game_node == null:
		return

	# Breadcrumbs: one 3x3 swatch per depth (Section 3.5)
	# Canvas is depth 0 (drawn as Stone Light swatch)
	draw_rect(Rect2(4, 177, 3, 3), Palette.STONE_LIGHT)

	# Each stack entry draws a swatch matching the child world's color
	for i in range(game_node.stack.size()):
		var entry: Dictionary = game_node.stack[i]
		var col_char: String = entry.get("tile_char", "")
		var swatch_color := Palette.SPARK_LIGHT
		match col_char:
			"R": swatch_color = Palette.LAVA_MID
			"B": swatch_color = Palette.WATER_MID
			"G": swatch_color = Palette.VINE_MID
			"Y": swatch_color = Palette.SPARK_MID
		draw_rect(Rect2(4 + (i + 1) * 6, 177, 3, 3), swatch_color)

	# Held pigment indicator at right side of HUD (x: 300..316)
	if not game_node.held.is_empty():
		var pigment_color := Palette.SPARK_LIGHT
		match game_node.held:
			"r": pigment_color = Palette.LAVA_LIGHT
			"b": pigment_color = Palette.WATER_LIGHT
			"g": pigment_color = Palette.VINE_LIGHT
			"y": pigment_color = Palette.SPARK_LIGHT
		# Draw glowing 4x3 swatch
		draw_rect(Rect2(310, 177, 6, 3), pigment_color)
