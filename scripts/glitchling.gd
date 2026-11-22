class_name Glitchling
extends RefCounted

# Glitchling Enemy (Milestone M7.1)
# Small horizontal patrol enemy in child worlds.
# Reverses on solid walls and platform ledges.
# Stomp kills enemy and bounces player; side/bottom contact kills player.

const SPEED := 30.0
const WIDTH := 8.0
const HEIGHT := 8.0
const BOUNCE_VELOCITY := -260.0

var start_position := Vector2.ZERO
var sim_position := Vector2.ZERO
var direction := 1.0 # 1.0 = right, -1.0 = left
var is_dead := false
var anim_timer := 0.0
var anim_frame := 0

# Sprite rows (8x8)
# D: LAVA_DARK, P: PINK, S: SPARK_LIGHT, .: Transparent
const FRAME_0_ROWS: Array[String] = [
	"..DDDD..",
	".DPPPPD.",
	"DPSSSSD.",
	"DPPSSPPD",
	"DPPPPPPD",
	".DPPPPD.",
	"..D..D..",
	".D....D.",
]

const FRAME_1_ROWS: Array[String] = [
	"..DDDD..",
	".DPPPPD.",
	"DPSSSSPD",
	"DPPSSPD.",
	"DPPPPPPD",
	".DPPPPD.",
	".D....D.",
	"..D..D..",
]

static var _texture_0: Texture2D
static var _texture_1: Texture2D

func _init(initial_pos: Vector2) -> void:
	start_position = initial_pos
	sim_position = initial_pos
	_ensure_textures()

static func _ensure_textures() -> void:
	if _texture_0 != null:
		return
	_texture_0 = _build_texture(FRAME_0_ROWS)
	_texture_1 = _build_texture(FRAME_1_ROWS)

static func _build_texture(rows: Array[String]) -> Texture2D:
	var img := Image.create(8, 8, false, Image.FORMAT_RGBA8)
	var char_map := {
		"D": Palette.LAVA_DARK,
		"P": Palette.PINK,
		"S": Palette.SPARK_LIGHT,
		".": Color(0, 0, 0, 0),
	}
	for y in range(8):
		var row: String = rows[y]
		for x in range(8):
			var c: String = row[x]
			img.set_pixel(x, y, char_map.get(c, Color(0, 0, 0, 0)))
	return ImageTexture.create_from_image(img)

func update(delta: float, grid: Dictionary) -> void:
	if is_dead:
		return

	anim_timer += delta
	if anim_timer >= 0.15:
		anim_timer = 0.0
		anim_frame = 1 - anim_frame

	# Calculate potential new x
	var move_dist := direction * SPEED * delta
	var new_x := sim_position.x + move_dist

	# Check wall collision ahead
	var check_x := new_x + (WIDTH if direction > 0.0 else 0.0)
	var front_tx := int(floor(check_x / 16.0))
	var top_ty := int(floor(sim_position.y / 16.0))
	var bot_ty := int(floor((sim_position.y + HEIGHT - 0.001) / 16.0))

	var hit_wall := false
	if front_tx < 0 or front_tx >= 20:
		hit_wall = true
	else:
		for ty in range(top_ty, bot_ty + 1):
			if _is_tile_solid(grid, front_tx, ty):
				hit_wall = true
				break

	# Check platform ledge drop-off ahead
	var has_floor := false
	var floor_ty := int(floor((sim_position.y + HEIGHT + 1.0) / 16.0))
	if _is_tile_solid(grid, front_tx, floor_ty):
		has_floor = true

	if hit_wall or not has_floor:
		# Reverse direction
		direction = -direction
	else:
		sim_position.x = new_x

func _is_tile_solid(grid: Dictionary, tx: int, ty: int) -> bool:
	if tx < 0 or tx >= 20 or ty < 0:
		return true
	if ty >= 11:
		return false
	var tile: String = grid.get(Vector2i(tx, ty), ".")
	return tile == "#"

func get_hitbox() -> Rect2:
	return Rect2(sim_position.x, sim_position.y, WIDTH, HEIGHT)

func die() -> void:
	is_dead = true

func reset() -> void:
	sim_position = start_position
	direction = 1.0
	is_dead = false
	anim_timer = 0.0
	anim_frame = 0

func draw(canvas: CanvasItem) -> void:
	if is_dead:
		return
	var tex: Texture2D = _texture_0 if anim_frame == 0 else _texture_1
	if tex != null:
		canvas.draw_texture(tex, sim_position.round())
