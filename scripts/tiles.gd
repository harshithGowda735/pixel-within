class_name Tiles
extends RefCounted

# Tile size in pixels
const TILE_SIZE := 16

# Stone variants
const STONE_ROWS_0: Array[String] = [
	"SSSSSSSSSSSSSSSS",
	"SssssssssssssssI",
	"SssssssssssssssI",
	"SssssssssssssssI",
	"SsssssIssssssssI",
	"SsssssIssssssssI",
	"SssssssssssssssI",
	"SssssssssssssssI",
	"SsssssssssIssssI",
	"SsssssssssIssssI",
	"SssssssssssssssI",
	"SssssssssssssssI",
	"SssssssssssssssI",
	"SssssssssssssssI",
	"SssssssssssssssI",
	"IIIIIIIIIIIIIIII",
]

const STONE_ROWS_1: Array[String] = [
	"SSSSSSSSSSSSSSSS",
	"SssssssssssssssI",
	"SsssssIssssssssI",
	"SssssssIsssssssI",
	"SsssssssIssssssI",
	"SssssssIsssssssI",
	"SsssssIssssssssI",
	"SssssssssssssssI",
	"SssssssssssssssI",
	"SssssssssssssssI",
	"SsssssssssIssssI",
	"SssssssssssIsssI",
	"SssssssssssssssI",
	"SssssssssssssssI",
	"SssssssssssssssI",
	"IIIIIIIIIIIIIIII",
]

# Water chroma pixel (B)
const WATER_PIXEL_ROWS: Array[String] = [
	"LLLLLLLLLLLLLLLL",
	"LMMMMMMMMMMMMMML",
	"LMMMMMMMMMMMMMML",
	"LMMMMMMMMMMMMMML",
	"LMMMMMMMMMMMMMML",
	"LMMMMMMMMMMMMMML",
	"LMMMMMDLMLLMMMML",
	"LMMMMMLMDMMMMMML",
	"LMMMMMDMLDMMMMML",
	"LMMMMMLDMLMMMMML",
	"LMMMMMMMMMMMMMML",
	"LMMMMMMMMMMMMMML",
	"LMMMMMMMMMMMMMML",
	"LMMMMMMMMMMMMMML",
	"LMMMMMMMMMMMMMML",
	"LLLLLLLLLLLLLLLL",
]

# Lava chroma pixel (R)
const LAVA_PIXEL_ROWS: Array[String] = [
	"LLLLLLLLLLLLLLLL",
	"LMMMMMMMMMMMMMML",
	"LMMMMMMMMMMMMMML",
	"LMMMMMMMMMMMMMML",
	"LMMMMMMMMMMMMMML",
	"LMMMMMMMMMMMMMML",
	"LMMMMMDLMLLMMMML",
	"LMMMMMLMDMMMMMML",
	"LMMMMMDMLDMMMMML",
	"LMMMMMLDMLMMMMML",
	"LMMMMMMMMMMMMMML",
	"LMMMMMMMMMMMMMML",
	"LMMMMMMMMMMMMMML",
	"LMMMMMMMMMMMMMML",
	"LMMMMMMMMMMMMMML",
	"LLLLLLLLLLLLLLLL",
]

# Exit door (E) - Stone arch with cream glow
const EXIT_DOOR_ROWS: Array[String] = [
	"IIISSSSSSSSSVIII",
	"IISSssssssssSSII",
	"ISSsyyyyyyyyySSI",
	"ISsyyYYYYYYyyySI",
	"SSsyYYYYYYYYyySS",
	"SsyyYYsIIsYYyyyS",
	"SsyyYYsIIsYYyyyS",
	"SsyyYYYYYYYYyyyS",
	"SsyyYYYYYYYYyyyS",
	"SsyyYYYYYYYYyyyS",
	"SsyyYYYYYYYYyyyS",
	"SsyyYYYYYYYYyyyS",
	"SsyyYYYYYYYYyyyS",
	"SsyyYYYYYYYYyyyS",
	"ISssssssssssssSI",
	"IISSSSSSSSSSSSII",
]

# Player spawn (@) - Pix standing at spawn
const SPAWN_ROWS: Array[String] = [
	"IIIIIIIIIIIIIIII",
	"IIII  ....  IIII",
	"IIII .YYYY. IIII",
	"IIII .Y.YY. IIII",
	"IIII .YYYY. IIII",
	"III.PPPPPP. IIII",
	"III.PPPPPPPP.III",
	"IIII .YYYY.  .II",
	"IIII .YYYY... II",
	"IIII .YYYY. IIII",
	"IIII .YYYY. IIII",
	"IIII .YY.YY.IIII",
	"IIII .YY.YY.IIII",
	"IIII .ss.ss.IIII",
	"IIII  .. .. IIII",
	"IIIIIIIIIIIIIIII",
]

# Air tile (.)
const AIR_ROWS: Array[String] = [
	"IIIIIIIIIIIIIIII",
	"IIIIIIIIIIIIIIII",
	"IIIIIIIIIIIIIIII",
	"IIIIIIIIIIIIIIII",
	"IIIIIIIIIIIIIIII",
	"IIIIIIIIIIIIIIII",
	"IIIIIIIIIIIIIIII",
	"IIIIIIIIIIIIIIII",
	"IIIIIIIIIIIIIIII",
	"IIIIIIIIIIIIIIII",
	"IIIIIIIIIIIIIIII",
	"IIIIIIIIIIIIIIII",
	"IIIIIIIIIIIIIIII",
	"IIIIIIIIIIIIIIII",
	"IIIIIIIIIIIIIIII",
	"IIIIIIIIIIIIIIII",
]

# Texture cache
static var _textures: Dictionary = {}

static func get_tile_texture(tile_char: String, pos: Vector2i = Vector2i.ZERO) -> Texture2D:
	var key := tile_char
	if tile_char == "#":
		# Alternate stone variants based on position
		var variant := (pos.x + pos.y) % 2
		key = "#_" + str(variant)

	if _textures.has(key):
		return _textures[key]

	var texture := _create_tile_texture(key, tile_char)
	_textures[key] = texture
	return texture

static func _create_tile_texture(key: String, tile_char: String) -> Texture2D:
	match tile_char:
		"#":
			if key.ends_with("_1"):
				return _build_texture_from_strings(STONE_ROWS_1, {
					"S": Palette.STONE_LIGHT,
					"s": Palette.STONE_DARK,
					"I": Palette.INK,
				})
			else:
				return _build_texture_from_strings(STONE_ROWS_0, {
					"S": Palette.STONE_LIGHT,
					"s": Palette.STONE_DARK,
					"I": Palette.INK,
				})
		"B":
			return _build_texture_from_strings(WATER_PIXEL_ROWS, {
				"L": Palette.WATER_LIGHT,
				"M": Palette.WATER_MID,
				"D": Palette.WATER_DARK,
			})
		"R":
			return _build_texture_from_strings(LAVA_PIXEL_ROWS, {
				"L": Palette.LAVA_LIGHT,
				"M": Palette.LAVA_MID,
				"D": Palette.LAVA_DARK,
			})
		"E":
			return _build_texture_from_strings(EXIT_DOOR_ROWS, {
				"S": Palette.STONE_LIGHT,
				"s": Palette.STONE_DARK,
				"I": Palette.INK,
				"V": Palette.STONE_LIGHT,
				"y": Palette.SPARK_MID,
				"Y": Palette.SPARK_LIGHT,
			})
		"@":
			return _build_texture_from_strings(SPAWN_ROWS, {
				"I": Palette.INK,
				" ": Palette.INK,
				".": Palette.INK,
				"Y": Palette.SPARK_LIGHT,
				"P": Palette.PINK,
				"s": Palette.STONE_DARK,
			})
		".":
			return _build_texture_from_strings(AIR_ROWS, {
				"I": Palette.INK,
			})
		_:
			# Fallback for any other valid tile
			return _build_flat_tile(Palette.INK)

static func _build_texture_from_strings(rows: Array[String], char_map: Dictionary) -> Texture2D:
	var img := Image.create(TILE_SIZE, TILE_SIZE, false, Image.FORMAT_RGBA8)
	for y in range(TILE_SIZE):
		var row: String = rows[y]
		for x in range(TILE_SIZE):
			var ch := row[x]
			var color: Color = char_map.get(ch, Palette.INK)
			img.set_pixel(x, y, color)
	return ImageTexture.create_from_image(img)

static func _build_flat_tile(color: Color) -> Texture2D:
	var img := Image.create(TILE_SIZE, TILE_SIZE, false, Image.FORMAT_RGBA8)
	img.fill(color)
	return ImageTexture.create_from_image(img)
