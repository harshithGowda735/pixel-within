class_name PixelBackground
extends RefCounted

const BAYER_4X4 := [[0, 8, 2, 10], [12, 4, 14, 6], [3, 11, 1, 9], [15, 7, 13, 5]]

static func theme_colors(world_key: String) -> Array:
	if world_key.contains("red") or world_key.contains(":R"):
		return [Palette.INK, Palette.LAVA_DARK, Palette.STONE_DARK]
	if world_key.contains("blue") or world_key.contains(":B"):
		return [Palette.INK, Palette.WATER_DARK, Palette.STONE_DARK]
	if world_key.contains("green") or world_key.contains(":G"):
		return [Palette.INK, Palette.VINE_DARK, Palette.STONE_DARK]
	if world_key.contains("yellow") or world_key.contains(":Y"):
		return [Palette.INK, Palette.SPARK_DARK, Palette.STONE_DARK]
	return [Palette.INK, Palette.STONE_DARK, Palette.STONE_LIGHT]

static func draw(canvas: CanvasItem, world_key: String, time: float) -> void:
	var colors := theme_colors(world_key)
	canvas.draw_rect(Rect2(0, 0, 320, 176), colors[0])
	# Two slow layers; all motion is background-only, so the gameplay camera stays fixed.
	for layer in range(2):
		var speed := 0.7 if layer == 0 else 1.3
		var offset := int(floor(time * speed)) % 16
		var cell_size := 16 if layer == 0 else 32
		for y in range(0, 176, cell_size):
			for x in range(0, 320, cell_size):
				var bx := posmod(x + offset + layer * 2, 16)
				var by := posmod(y + offset, 16)
				var threshold: int = BAYER_4X4[by % 4][bx % 4]
				var col: Color = colors[1] if threshold < (5 + layer * 3) else colors[0]
				canvas.draw_rect(Rect2(x, y, cell_size, cell_size), col)
	# Fine dithered horizon band gives Canvas and child worlds depth without gradients.
	for y in range(144, 176, 4):
		for x in range(0, 320, 4):
			var threshold: int = BAYER_4X4[(int(y / 4)) % 4][(int(x / 4)) % 4]
			if threshold < 6:
				canvas.draw_rect(Rect2(x, y, 4, 4), colors[2])
