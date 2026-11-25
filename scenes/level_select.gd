extends Node2D

const SaveManagerScript = preload("res://scripts/save_manager.gd")

var anim_time := 0.0
var selected_index := 0

const LEVEL_NAMES: Array[String] = [
	"CANVAS 1 - FIRST STEP",
	"CANVAS 2 - SPARK BOUNCE",
	"CANVAS 3 - WATER WAY",
	"CANVAS 4 - FOREST CLIMB",
	"CANVAS 5 - DEPTH TWO",
	"CANVAS 6 - ZOOM OUT",
]

func _ready() -> void:
	SaveManagerScript.ensure_loaded()

func _process(delta: float) -> void:
	anim_time += delta
	queue_redraw()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("move_up") or (event is InputEventKey and event.pressed and (event.keycode == KEY_UP or event.keycode == KEY_W)):
		selected_index = (selected_index - 1 + SaveManagerScript.LEVEL_ORDER.size()) % SaveManagerScript.LEVEL_ORDER.size()
		queue_redraw()
	elif event.is_action_pressed("move_down") or (event is InputEventKey and event.pressed and (event.keycode == KEY_DOWN or event.keycode == KEY_S)):
		selected_index = (selected_index + 1) % SaveManagerScript.LEVEL_ORDER.size()
		queue_redraw()
	elif event.is_action_pressed("ui_accept") or (event is InputEventKey and event.pressed and (event.keycode == KEY_ENTER or event.keycode == KEY_SPACE or event.keycode == KEY_Z)):
		_select_level(selected_index)
	elif event is InputEventKey and event.pressed and (event.keycode == KEY_ESCAPE or event.keycode == KEY_C):
		get_tree().change_scene_to_file("res://scenes/title_screen.tscn")

func _select_level(idx: int) -> void:
	var lvl_id: String = SaveManagerScript.LEVEL_ORDER[idx]
	if not SaveManagerScript.is_unlocked(lvl_id):
		return
	var path := "res://levels/" + lvl_id + ".txt"
	var game_node = get_node_or_null("/root/Game")
	if game_node != null:
		game_node.start_canvas(path, lvl_id)
	get_tree().change_scene_to_file("res://scenes/main.tscn")

func _draw() -> void:
	PixelBackground.draw(self, "canvas_01", anim_time)

	# Container frame
	draw_rect(Rect2(15, 10, 290, 160), Palette.INK)
	draw_rect(Rect2(15, 10, 290, 160), Palette.STONE_DARK, false, 1.0)
	draw_rect(Rect2(17, 12, 286, 156), Palette.STONE_LIGHT, false, 1.0)

	# Header
	PixelFont.draw_text(self, "SELECT LEVEL", Vector2(110, 18), Palette.SPARK_LIGHT, 1, 1)

	# List 6 levels
	for i in range(SaveManagerScript.LEVEL_ORDER.size()):
		var lvl_id: String = SaveManagerScript.LEVEL_ORDER[i]
		var lvl_name: String = LEVEL_NAMES[i]
		var unlocked := SaveManagerScript.is_unlocked(lvl_id)
		var stars := SaveManagerScript.get_stars(lvl_id)
		var gem_data := SaveManagerScript.get_gems(lvl_id)
		var y_pos := 36 + i * 19

		var is_selected := (i == selected_index)

		# Row background highlight if selected
		if is_selected:
			draw_rect(Rect2(25, y_pos - 2, 270, 16), Palette.STONE_DARK)

		if not unlocked:
			PixelFont.draw_text(self, lvl_name, Vector2(35, y_pos + 2), Palette.STONE_DARK, 1, 1)
			PixelFont.draw_text(self, "LOCKED", Vector2(235, y_pos + 2), Palette.STONE_DARK, 1, 1)
		else:
			var name_col: Color = Palette.SPARK_LIGHT if is_selected else Palette.STONE_LIGHT
			PixelFont.draw_text(self, lvl_name, Vector2(35, y_pos + 2), name_col, 1, 1)

			# Star icons
			var star_str := ""
			for s in range(3):
				if s < stars:
					star_str += "* "
				else:
					star_str += "- "
			PixelFont.draw_text(self, star_str.strip_edges(), Vector2(195, y_pos + 2), Palette.SPARK_MID if stars > 0 else Palette.STONE_DARK, 1, 1)

			# Gem progress
			var g_coll: int = gem_data[0] if gem_data.size() > 0 else 0
			var g_tot: int = gem_data[1] if gem_data.size() > 1 else 0
			var g_str := "*" + str(g_coll) + "/" + str(g_tot) if g_tot > 0 else ""
			if not g_str.is_empty():
				PixelFont.draw_text(self, g_str, Vector2(245, y_pos + 2), Palette.PINK, 1, 1)

		if is_selected:
			PixelFont.draw_text(self, ">", Vector2(27, y_pos + 2), Palette.PINK, 1, 1)

	# Footer
	PixelFont.draw_text(self, "ENTER: PLAY   ESC: TITLE", Vector2(95, 154), Palette.STONE_DARK, 1, 1)
