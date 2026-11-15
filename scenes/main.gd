extends Node2D

var level_data: Dictionary = {}
var player: Player

func _ready() -> void:
	level_data = LevelLoader.load_level("res://levels/canvas_01.txt")
	if not level_data.get("valid", false):
		push_error("Failed to load Canvas Level 1: " + level_data.get("error", "Unknown error"))
		return

	player = Player.new()
	add_child(player)
	player.setup(level_data["grid"], level_data.get("player_spawn", Vector2i(1, 9)))
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
