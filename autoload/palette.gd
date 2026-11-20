extends Node

# Pixel Within - 16 Color Palette
# Exactly 16 colors specified by the project specification (Section 6.2).

# Ink (outline, background)
const INK := Color("#0f0b1f")

# Stone
const STONE_DARK := Color("#2a2547")
const STONE_LIGHT := Color("#4f4a7a")

# Lava (dark, mid, light)
const LAVA_DARK := Color("#6e1423")
const LAVA_MID := Color("#e03c2d")
const LAVA_LIGHT := Color("#ff9a3c")

# Water (dark, mid, light)
const WATER_DARK := Color("#10346e")
const WATER_MID := Color("#2a78e0")
const WATER_LIGHT := Color("#7bd8ff")

# Vine (dark, mid, light)
const VINE_DARK := Color("#11502f")
const VINE_MID := Color("#2fa84f")
const VINE_LIGHT := Color("#b4f06a")

# Spark (dark, mid, light)
const SPARK_DARK := Color("#8a5a00")
const SPARK_MID := Color("#f2c01e")
const SPARK_LIGHT := Color("#fff4a3")

# Accent pink
const PINK := Color("#ff5fa8")

# Collection of all 16 colors
const ALL_COLORS: Array[Color] = [
	INK,
	STONE_DARK,
	STONE_LIGHT,
	LAVA_DARK,
	LAVA_MID,
	LAVA_LIGHT,
	WATER_DARK,
	WATER_MID,
	WATER_LIGHT,
	VINE_DARK,
	VINE_MID,
	VINE_LIGHT,
	SPARK_DARK,
	SPARK_MID,
	SPARK_LIGHT,
	PINK,
]

# Quick lookup by name
const COLOR_MAP: Dictionary = {
	"ink": INK,
	"stone_dark": STONE_DARK,
	"stone_light": STONE_LIGHT,
	"lava_dark": LAVA_DARK,
	"lava_mid": LAVA_MID,
	"lava_light": LAVA_LIGHT,
	"water_dark": WATER_DARK,
	"water_mid": WATER_MID,
	"water_light": WATER_LIGHT,
	"vine_dark": VINE_DARK,
	"vine_mid": VINE_MID,
	"vine_light": VINE_LIGHT,
	"spark_dark": SPARK_DARK,
	"spark_mid": SPARK_MID,
	"spark_light": SPARK_LIGHT,
	"pink": PINK,
}

static func is_palette_color(c: Color) -> bool:
	for palette_color in ALL_COLORS:
		if c.is_equal_approx(palette_color):
			return true
	return false
