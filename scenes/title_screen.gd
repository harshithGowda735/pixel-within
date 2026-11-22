extends Node2D

const SaveManagerScript = preload("res://scripts/save_manager.gd")

var anim_time := 0.0
var selected_index := 0
var options := ["PLAY", "LEVEL SELECT"]

func _ready() -> void:
	SaveManagerScript.ensure_loaded()
	if not SaveManagerScript.completed_levels.is_empty():
		options[0] = "CONTINUE"

func _process(delta: float) -> void:
	anim_time += delta
	queue_redraw()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("move_up") or (event is InputEventKey and event.pressed and (event.keycode == KEY_UP or event.keycode == KEY_W)):
		selected_index = (selected_index - 1 + options.size()) % options.size()
		queue_redraw()
	elif event.is_action_pressed("move_down") or (event is InputEventKey and event.pressed and (event.keycode == KEY_DOWN or event.keycode == KEY_S)):
		selected_index = (selected_index + 1) % options.size()
		queue_redraw()
	elif event.is_action_pressed("ui_accept") or (event is InputEventKey and event.pressed and (event.keycode == KEY_ENTER or event.keycode == KEY_SPACE or event.keycode == KEY_Z)):
		_select_option(selected_index)

func _select_option(idx: int) -> void:
	if idx == 0:
		var target_lvl := "canvas_01"
		for lvl in SaveManagerScript.LEVEL_ORDER:
			if SaveManagerScript.is_unlocked(lvl) and not SaveManagerScript.is_completed(lvl):
				target_lvl = lvl
				break
			elif SaveManagerScript.is_unlocked(lvl):
				target_lvl = lvl
		Game.start_canvas("res://levels/" + target_lvl + ".txt", target_lvl)
		get_tree().change_scene_to_file("res://scenes/main.tscn")
	elif idx == 1:
		get_tree().change_scene_to_file("res://scenes/level_select.tscn")

func _draw() -> void:
	PixelBackground.draw(self, "canvas_01", anim_time)

	# Decorative frame
	draw_rect(Rect2(20, 15, 280, 150), Palette.INK)
	draw_rect(Rect2(20, 15, 280, 150), Palette.STONE_DARK, false, 1.0)
	draw_rect(Rect2(22, 17, 276, 146), Palette.STONE_LIGHT, false, 1.0)

	# Title: "PIXEL WITHIN" in scale 2
	PixelFont.draw_text(self, "PIXEL WITHIN", Vector2(88, 35), Palette.SPARK_LIGHT, 2, 2)

	# Subtitle
	PixelFont.draw_text(self, "EVERY PIXEL IS A WORLD", Vector2(96, 62), Palette.VINE_LIGHT, 1, 1)

	# Menu options
	for i in range(options.size()):
		var opt_name: String = options[i]
		var y_pos := 95 + i * 20
		var is_selected := (i == selected_index)
		var text_color: Color = Palette.SPARK_LIGHT if is_selected else Palette.STONE_LIGHT

		if is_selected:
			var pulse := int(floor(anim_time * 4.0)) % 2
			var arrow_x := 105 + pulse
			PixelFont.draw_text(self, ">", Vector2(arrow_x, y_pos), Palette.PINK, 1, 1)
			PixelFont.draw_text(self, opt_name, Vector2(120, y_pos), Palette.SPARK_MID, 1, 1)
		else:
			PixelFont.draw_text(self, opt_name, Vector2(120, y_pos), text_color, 1, 1)

	# Footer hints
	PixelFont.draw_text(self, "W/S OR ARROWS: SELECT   ENTER/Z: CONFIRM", Vector2(48, 145), Palette.STONE_DARK, 1, 1)
	PixelFont.draw_text(self, "M: MUTE", Vector2(250, 145), Palette.STONE_DARK, 1, 1)
