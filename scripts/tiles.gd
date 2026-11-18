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

# Vine chroma pixel (G)
const VINE_PIXEL_ROWS: Array[String] = [
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

# Spark chroma pixel (Y)
const SPARK_PIXEL_ROWS: Array[String] = [
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

# Vine fill (V) - Climbable
const VINE_FILL_ROWS: Array[String] = [
	"IIIIIIIDMMDIIIII",
	"IIIIIIIDLLDIIIII",
	"IIIIILLDMMDIIIII",
	"IIIIIMMDMMDLLIII",
	"IIIIIIIDMMDMMIII",
	"IIIIIIIDLLDIIIII",
	"IIIILLIDMMDIIIII",
	"IIIIMMDDMMDIIIII",
	"IIIIIIIDLLDMMIII",
	"IIIIIIIDMMDLLIII",
	"IIIIIIIDMMDIIIII",
	"IIIIILLDMMDIIIII",
	"IIIIIMMDLLDIIIII",
	"IIIIIIIDMMDMMIII",
	"IIIIIIIDMMDLLIII",
	"IIIIIIIDLLDIIIII",
]

# Spark fill (S) - Bounce pad
const SPARK_FILL_ROWS: Array[String] = [
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
	"IIIIMIIIIIIIIMII",
	"IIIMLMIIIIIIMLMI",
	"IIMLLLMIIIIIMLLM",
	"DDDDDDDDDDDDDDDD",
	"DMMMMMMMMMMMMMMD",
	"DLLLLLLLLLLLLLLD",
]

# Water fill (W)
const WATER_FILL_ROWS: Array[String] = [
	"DDLLDDDDDDLLDDDD",
	"DDMMDDDDDDMMDDDD",
	"DDDDDDDDDDDDDDDD",
	"DDDDDDLLDDDDDDLL",
	"DDDDDDMMDDDDDDMM",
	"DDDDDDDDDDDDDDDD",
	"DDLLDDDDDDLLDDDD",
	"DDMMDDDDDDMMDDDD",
	"DDDDDDDDDDDDDDDD",
	"DDDDDDLLDDDDDDLL",
	"DDDDDDMMDDDDDDMM",
	"DDDDDDDDDDDDDDDD",
	"DDLLDDDDDDLLDDDD",
	"DDMMDDDDDDMMDDDD",
	"DDDDDDDDDDDDDDDD",
	"DDDDDDDDDDDDDDDD",
]

# Lava fill (L)
const LAVA_FILL_ROWS: Array[String] = [
	"DDLLDDDDDDLLDDDD",
	"DDMMDDDDDDMMDDDD",
	"DDDDDDDDDDDDDDDD",
	"DDDDDDLLDDDDDDLL",
	"DDDDDDMMDDDDDDMM",
	"DDDDDDDDDDDDDDDD",
	"DDLLDDDDDDLLDDDD",
	"DDMMDDDDDDMMDDDD",
	"DDDDDDDDDDDDDDDD",
	"DDDDDDLLDDDDDDLL",
	"DDDDDDMMDDDDDDMM",
	"DDDDDDDDDDDDDDDD",
	"DDLLDDDDDDLLDDDD",
	"DDMMDDDDDDMMDDDD",
	"DDDDDDDDDDDDDDDD",
	"DDDDDDDDDDDDDDDD",
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

# Heart (H) - Bright 4x4 pixel pulsing with sparkle ring
const HEART_ROWS: Array[String] = [
	"IIIIIIIIIIIIIIII",
	"IIIIIIIIIIIIIIII",
	"IIIIIIIIIIIIIIII",
	"IIIIIISSIISIIIII",
	"IIIIIIIIIIIIIIII",
	"IIIIIIIIIIIIIIII",
	"IIISIILLLLIIISII",
	"IIIIIILLLLIIIIII",
	"IIIIIILLLLIIIIII",
	"IIISIILLLLIIISII",
	"IIIIIIIIIIIIIIII",
	"IIIIIIIIIIIIIIII",
	"IIIIIISSIISIIIII",
	"IIIIIIIIIIIIIIII",
	"IIIIIIIIIIIIIIII",
	"IIIIIIIIIIIIIIII",
]

# Pigment orb (r, b, g, y)
const ORB_ROWS: Array[String] = [
	"IIIIIIIIIIIIIIII",
	"IIIIIIIIIIIIIIII",
	"IIIIIIIIIIIIIIII",
	"IIIIIIIIIIIIIIII",
	"IIIIILLMMIIIIIII",
	"IIIILLLLMMIIIIII",
	"IIIMLLLLMMDIIIII",
	"IIIMMMMMMDDIIIII",
	"IIIMMMMMMDDIIIII",
	"IIIIIMMMDDIIIIII",
	"IIIIIIIDDIIIIIII",
	"IIIIIIIIIIIIIIII",
	"IIIIIIIIIIIIIIII",
	"IIIIIIIIIIIIIIII",
	"IIIIIIIIIIIIIIII",
	"IIIIIIIIIIIIIIII",
]

# Gem (*) - Pink diamond
const GEM_ROWS: Array[String] = [
	"IIIIIIIIIIIIIIII",
	"IIIIIIIIIIIIIIII",
	"IIIIIIIIIIIIIIII",
	"IIIIIIISIIIIIIII",
	"IIIIIISSSIIIIIII",
	"IIIIIIPPPPIIIIII",
	"IIIIIPPPPPPIIIII",
	"IIIIPPPPPPPPIIII",
	"IIIIIPPPPPPIIIII",
	"IIIIIIPPPPIIIIII",
	"IIIIIISSSIIIIIII",
	"IIIIIIISIIIIIIII",
	"IIIIIIIIIIIIIIII",
	"IIIIIIIIIIIIIIII",
	"IIIIIIIIIIIIIIII",
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

static func get_animation_frame_count(tile_char: String) -> int:
	match tile_char:
		"#": return 2
		"R", "L": return 4
		"B", "W": return 4
		"G", "V": return 2
		"Y", "S": return 3
		"H": return 4
		"r", "b", "g", "y", "*": return 3
		"E": return 3
		_: return 1

static func get_tile_texture(tile_char: String, pos: Vector2i = Vector2i.ZERO, frame: int = 0) -> Texture2D:
	var key := tile_char + "_f" + str(frame % get_animation_frame_count(tile_char))
	if tile_char == "#":
		var variant := (pos.x + pos.y) % 2
		key += "_" + str(variant)

	if _textures.has(key):
		return _textures[key]

	var texture := _create_tile_texture(key, tile_char, frame)
	_textures[key] = texture
	return texture

static func _create_tile_texture(key: String, tile_char: String, frame: int = 0) -> Texture2D:
	var phase := frame % get_animation_frame_count(tile_char)
	match tile_char:
		"#":
			if key.ends_with("_1"):
				return _build_texture_from_strings(_animate_rows(STONE_ROWS_1, tile_char, phase), {
					"S": Palette.STONE_LIGHT,
					"s": Palette.STONE_DARK,
					"I": Palette.INK,
				})
			else:
				return _build_texture_from_strings(_animate_rows(STONE_ROWS_0, tile_char, phase), {
					"S": Palette.STONE_LIGHT,
					"s": Palette.STONE_DARK,
					"I": Palette.INK,
				})
		"B":
			return _build_texture_from_strings(_animate_rows(WATER_PIXEL_ROWS, tile_char, phase), {
				"L": Palette.WATER_LIGHT,
				"M": Palette.WATER_MID,
				"D": Palette.WATER_DARK,
			})
		"W":
			return _build_texture_from_strings(_animate_rows(WATER_FILL_ROWS, tile_char, phase), {
				"L": Palette.WATER_LIGHT,
				"M": Palette.WATER_MID,
				"D": Palette.WATER_DARK,
			})
		"R":
			return _build_texture_from_strings(_animate_rows(LAVA_PIXEL_ROWS, tile_char, phase), {
				"L": Palette.LAVA_LIGHT,
				"M": Palette.LAVA_MID,
				"D": Palette.LAVA_DARK,
			})
		"L":
			return _build_texture_from_strings(_animate_rows(LAVA_FILL_ROWS, tile_char, phase), {
				"L": Palette.LAVA_LIGHT,
				"M": Palette.LAVA_MID,
				"D": Palette.LAVA_DARK,
			})
		"G":
			return _build_texture_from_strings(_animate_rows(VINE_PIXEL_ROWS, tile_char, phase), {
				"L": Palette.VINE_LIGHT,
				"M": Palette.VINE_MID,
				"D": Palette.VINE_DARK,
			})
		"V":
			return _build_texture_from_strings(_animate_rows(VINE_FILL_ROWS, tile_char, phase), {
				"L": Palette.VINE_LIGHT,
				"M": Palette.VINE_MID,
				"D": Palette.VINE_DARK,
				"I": Palette.INK,
			})
		"Y":
			return _build_texture_from_strings(_animate_rows(SPARK_PIXEL_ROWS, tile_char, phase), {
				"L": Palette.SPARK_LIGHT,
				"M": Palette.SPARK_MID,
				"D": Palette.SPARK_DARK,
			})
		"S":
			return _build_texture_from_strings(_animate_rows(SPARK_FILL_ROWS, tile_char, phase), {
				"L": Palette.SPARK_LIGHT,
				"M": Palette.SPARK_MID,
				"D": Palette.SPARK_DARK,
				"I": Palette.INK,
			})
		"E":
			return _build_texture_from_strings(_animate_rows(EXIT_DOOR_ROWS, tile_char, phase), {
				"S": Palette.STONE_LIGHT,
				"s": Palette.STONE_DARK,
				"I": Palette.INK,
				"V": Palette.STONE_LIGHT,
				"y": Palette.SPARK_MID,
				"Y": Palette.SPARK_LIGHT,
			})
		"H":
			return _build_texture_from_strings(_animate_rows(HEART_ROWS, tile_char, phase), {
				"L": Palette.PINK,
				"S": Palette.SPARK_LIGHT,
				"I": Palette.INK,
			})
		"r":
			return _build_texture_from_strings(_animate_rows(ORB_ROWS, tile_char, phase), {
				"L": Palette.LAVA_LIGHT,
				"M": Palette.LAVA_MID,
				"D": Palette.LAVA_DARK,
				"I": Palette.INK,
			})
		"b":
			return _build_texture_from_strings(ORB_ROWS, {
				"L": Palette.WATER_LIGHT,
				"M": Palette.WATER_MID,
				"D": Palette.WATER_DARK,
				"I": Palette.INK,
			})
		"g":
			return _build_texture_from_strings(ORB_ROWS, {
				"L": Palette.VINE_LIGHT,
				"M": Palette.VINE_MID,
				"D": Palette.VINE_DARK,
				"I": Palette.INK,
			})
		"y":
			return _build_texture_from_strings(ORB_ROWS, {
				"L": Palette.SPARK_LIGHT,
				"M": Palette.SPARK_MID,
				"D": Palette.SPARK_DARK,
				"I": Palette.INK,
			})
		"*":
			return _build_texture_from_strings(_animate_rows(GEM_ROWS, tile_char, phase), {
				"P": Palette.PINK,
				"S": Palette.SPARK_LIGHT,
				"I": Palette.INK,
			})
		"@", ".":
			return _build_texture_from_strings(AIR_ROWS, {
				"I": Palette.INK,
			})
		_:
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

static func _animate_rows(source: Array[String], tile_char: String, phase: int) -> Array[String]:
	var rows: Array[String] = source.duplicate()
	# Reuse the same 16x16 definitions and shift only highlight pixels: this
	# keeps frame dimensions, palette membership, and cache behavior stable.
	if tile_char in ["B", "W"]:
		var ripple_y := 1 + phase * 3
		rows[ripple_y] = _replace_at(rows[ripple_y], 2, "L")
		rows[ripple_y] = _replace_at(rows[ripple_y], 3, "L")
	elif tile_char in ["R", "L"]:
		var bubble_y := 5 + phase * 2
		rows[bubble_y] = _replace_at(rows[bubble_y], 4 + phase % 4, "L")
	elif tile_char in ["G", "V"]:
		var leaf_y := 3 + phase * 5
		rows[leaf_y] = _replace_at(rows[leaf_y], 3 + phase, "L")
	elif tile_char in ["Y", "S"]:
		var spark_y := 10 + phase
		rows[spark_y] = _replace_at(rows[spark_y], 4 + phase * 2, "L")
	elif tile_char == "H":
		var pulse := 6 if phase % 2 == 0 else 7
		rows[pulse] = _replace_at(rows[pulse], 6, "L")
	elif tile_char == "E":
		var glow := 2 + phase
		rows[glow] = _replace_at(rows[glow], 7, "Y")
	elif tile_char in ["r", "b", "g", "y", "*"]:
		var sparkle_y := 4 + phase
		rows[sparkle_y] = _replace_at(rows[sparkle_y], 5 + phase, "L" if tile_char != "*" else "S")
	return rows

static func _replace_at(row: String, index: int, value: String) -> String:
	if index < 0 or index >= row.length():
		return row
	return row.substr(0, index) + value + row.substr(index + 1)
