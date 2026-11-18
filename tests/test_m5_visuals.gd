extends SceneTree

const TilesScript = preload("res://scripts/tiles.gd")
const PlayerScript = preload("res://scripts/player.gd")
const FontScript = preload("res://scripts/pixel_font.gd")
const BackgroundScript = preload("res://scripts/background.gd")
const PaletteScript = preload("res://autoload/palette.gd")

func _init() -> void:
	print("==========================================")
	print("Running Milestone M5 Visual Tests")
	print("==========================================")

	# Frame counts and dimensions are the contract for reusable procedural art.
	for tile in ["#", "R", "L", "B", "W", "G", "V", "Y", "S", "H", "r", "b", "g", "y", "*", "E"]:
		assert(TilesScript.get_animation_frame_count(tile) >= 1)
		var tex: Texture2D = TilesScript.get_tile_texture(tile, Vector2i(2, 2), 0)
		assert(tex.get_width() == 16)
		assert(tex.get_height() == 16)
		var image := tex.get_image()
		for y in range(16):
			for x in range(16):
				assert(PaletteScript.is_palette_color(image.get_pixel(x, y)))
	print("PASS: all tile frames are 16x16 and palette compliant")

	assert(PlayerScript.SPRITE_RIGHT_ROWS.size() == 14)
	for row in PlayerScript.SPRITE_RIGHT_ROWS:
		assert(row.length() == 10)
	var player := PlayerScript.new()
	player.update_body_color("b")
	assert(player.texture_right.get_width() == 10)
	assert(player.texture_right.get_height() == 14)
	assert(player.animation_textures_right.has("idle0"))
	assert(player.animation_textures_right.has("run3"))
	assert(player.animation_textures_right.has("swim1"))
	assert(player.animation_textures_right.has("climb1"))
	print("PASS: Pix sprite frames are 10x14 and animation states exist")
	player.free()

	assert(FontScript.supports("PIXEL WITHIN 123!?:/-"))
	assert(not FontScript.supports("~"))
	print("PASS: custom 5x7 font supports required UI glyphs")

	for world_key in ["canvas_01", "canvas_01/4,9:B", "canvas_01/10,9:R", "world_green", "world_yellow"]:
		var colors: Array = BackgroundScript.theme_colors(world_key)
		assert(colors.size() == 3)
		for color in colors:
			assert(PaletteScript.is_palette_color(color))
	print("PASS: background themes use existing palette colors only")

	print("ALL MILESTONE M5 VISUAL TESTS PASSED!")
	quit(0)
