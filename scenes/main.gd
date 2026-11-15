extends Node2D

@onready var test_sprite: Sprite2D = $TestSprite

# 10x14 pixel art test sprite representing Pix
const SPRITE_ROWS: Array[String] = [
	"  ....    ",
	" .YYYY.   ",
	" .Y.YY.   ",
	" .YYYY.   ",
	".PPPPPP.  ",
	".PPPPPPPP.",
	" .YYYY.  .",
	" .YYYY... ",
	" .YYYY.   ",
	" .YYYY.   ",
	" .YY.YY.  ",
	" .YY.YY.  ",
	" .ss.ss.  ",
	"  .. ..   ",
]

func _ready() -> void:
	var sprite_texture := create_test_sprite_texture()
	test_sprite.texture = sprite_texture
	test_sprite.position = Vector2(160, 80)

func create_test_sprite_texture() -> ImageTexture:
	var width := 10
	var height := 14
	var img := Image.create(width, height, false, Image.FORMAT_RGBA8)

	var char_to_color := {
		" ": Color(0, 0, 0, 0),
		".": Palette.INK,
		"Y": Palette.SPARK_LIGHT,
		"P": Palette.PINK,
		"s": Palette.STONE_DARK,
	}

	for y in range(height):
		var row := SPRITE_ROWS[y]
		for x in range(width):
			var ch := row[x]
			var color: Color = char_to_color.get(ch, Color(0, 0, 0, 0))
			img.set_pixel(x, y, color)

	return ImageTexture.create_from_image(img)

func _draw() -> void:
	# Draw all 16 palette colors as 8x8 swatches to verify the palette visually
	var swatch_size := 8
	var start_x := (320 - (Palette.ALL_COLORS.size() * swatch_size)) / 2
	var y := 140
	for i in range(Palette.ALL_COLORS.size()):
		var color: Color = Palette.ALL_COLORS[i]
		draw_rect(Rect2(start_x + (i * swatch_size), y, swatch_size, swatch_size), color)
