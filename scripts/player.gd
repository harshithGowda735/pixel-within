class_name Player
extends Node2D

# Hitbox configuration
const HITBOX_WIDTH := 8.0
const HITBOX_HEIGHT := 12.0

# Movement physics constants from specification (Section 4)
const RUN_SPEED := 100.0
const ACCELERATION := 800.0
const FRICTION := 1000.0
const GRAVITY := 900.0
const TERMINAL_VELOCITY := 260.0

const JUMP_VELOCITY := -310.0
const VARIABLE_JUMP_MULTIPLIER := 0.45
const COYOTE_TIME := 0.10
const JUMP_BUFFER_TIME := 0.10

# Swimming constants
const SWIM_GRAVITY := 220.0
const SWIM_TERMINAL_VELOCITY := 50.0
const SWIM_SPEED := 70.0
const SWIM_STROKE_VELOCITY := -120.0
const SWIM_STROKE_COOLDOWN := 0.25

# Climbing and bounce constants
const CLIMB_SPEED := 55.0
const SPARK_BOUNCE_VELOCITY := -430.0

# Death and respawn constants
const DEATH_FREEZE_TIME := 0.50

# State variables
var sim_position := Vector2.ZERO
var velocity := Vector2.ZERO
var spawn_position := Vector2.ZERO
var is_on_floor := false
var is_swimming := false
var is_climbing := false
var is_dead := false
var facing_right := true

var coyote_timer := 0.0
var jump_buffer_timer := 0.0
var swim_stroke_timer := 0.0
var death_timer := 0.0

# Edge-detection for jump inputs
var prev_jump_held := false

# Reference to the level grid: Dictionary[Vector2i, String]
var grid: Dictionary = {}

# Sprite textures
var texture_right: Texture2D
var texture_left: Texture2D

const SPRITE_RIGHT_ROWS: Array[String] = [
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

func _init() -> void:
	_init_textures()

func setup(level_grid: Dictionary, spawn_tile: Vector2i) -> void:
	grid = level_grid
	# Hitbox is 8x12, placed inside 16x16 tile, standing on bottom edge
	spawn_position = Vector2(spawn_tile.x * 16.0 + 4.0, spawn_tile.y * 16.0 + 4.0)
	respawn()

func _physics_process(delta: float) -> void:
	update_physics(delta)
	# Align Node2D position to integer coordinates for pixel-perfect rendering
	position = Vector2(round(sim_position.x), round(sim_position.y))
	queue_redraw()

func update_physics(delta: float) -> void:
	if is_dead:
		death_timer -= delta
		if death_timer <= 0.0:
			respawn()
		return

	# Manual restart
	if is_restart_just_pressed():
		respawn()
		return

	# Check environment (water, vine)
	check_environment()

	# Handle timers
	if swim_stroke_timer > 0.0:
		swim_stroke_timer -= delta

	# Process horizontal movement
	var input_x := get_horizontal_input()
	if input_x > 0.0:
		facing_right = true
	elif input_x < 0.0:
		facing_right = false

	var target_speed := (SWIM_SPEED if is_swimming else RUN_SPEED) * input_x
	if input_x != 0.0:
		velocity.x = move_toward(velocity.x, target_speed, ACCELERATION * delta)
	else:
		velocity.x = move_toward(velocity.x, 0.0, FRICTION * delta)

	# Jump input edge detection
	var jump_held := is_jump_input_held()
	var jump_just_pressed := jump_held and not prev_jump_held
	var jump_just_released := prev_jump_held and not jump_held
	prev_jump_held = jump_held

	# Process vertical movement
	if is_climbing:
		var input_y := get_vertical_input()
		# When climbing: Space (or jump button) leaps off the vine; W/Up climbs
		var space_pressed := Input.is_physical_key_pressed(KEY_SPACE) or Input.is_action_just_pressed("ui_accept")
		if space_pressed or (jump_just_pressed and input_y == 0.0):
			velocity.y = JUMP_VELOCITY
			is_climbing = false
		else:
			velocity.y = input_y * CLIMB_SPEED
	elif is_swimming:
		var input_y := get_vertical_input()
		var swim_jump := Input.is_physical_key_pressed(KEY_SPACE) or Input.is_action_just_pressed("ui_accept") or jump_just_pressed
		if swim_jump and swim_stroke_timer <= 0.0:
			velocity.y = SWIM_STROKE_VELOCITY
			swim_stroke_timer = SWIM_STROKE_COOLDOWN
		elif input_y < 0.0:
			velocity.y = move_toward(velocity.y, -SWIM_SPEED, ACCELERATION * delta)
		elif input_y > 0.0:
			velocity.y = move_toward(velocity.y, SWIM_SPEED, ACCELERATION * delta)
		else:
			velocity.y = minf(velocity.y + SWIM_GRAVITY * delta, SWIM_TERMINAL_VELOCITY)
	else:
		# Normal ground / air physics
		velocity.y = minf(velocity.y + GRAVITY * delta, TERMINAL_VELOCITY)

		# Coyote time
		if is_on_floor:
			coyote_timer = COYOTE_TIME
		else:
			coyote_timer = maxf(coyote_timer - delta, 0.0)

		# Jump buffer
		if jump_just_pressed:
			jump_buffer_timer = JUMP_BUFFER_TIME
		else:
			jump_buffer_timer = maxf(jump_buffer_timer - delta, 0.0)

		# Execute buffered jump
		if jump_buffer_timer > 0.0 and coyote_timer > 0.0:
			velocity.y = JUMP_VELOCITY
			coyote_timer = 0.0
			jump_buffer_timer = 0.0
			is_on_floor = false

		# Variable jump: release jump early cuts upward velocity (applies once on release frame)
		if jump_just_released and velocity.y < 0.0:
			velocity.y *= VARIABLE_JUMP_MULTIPLIER

	# Custom tile collision
	move_and_collide_custom(delta)

	# Environmental triggers (lava, spark bounce, pit)
	check_tile_triggers()

func move_and_collide_custom(delta: float) -> void:
	# 1. Horizontal movement and collision
	sim_position.x += velocity.x * delta
	var box := get_hitbox()

	var min_tx := int(floor(box.position.x / 16.0))
	var max_tx := int(floor((box.position.x + box.size.x - 0.001) / 16.0))
	var min_ty := int(floor(box.position.y / 16.0))
	var max_ty := int(floor((box.position.y + box.size.y - 0.001) / 16.0))

	if velocity.x > 0.0:
		for ty in range(min_ty, max_ty + 1):
			if is_tile_solid(max_tx, ty):
				sim_position.x = max_tx * 16.0 - HITBOX_WIDTH
				velocity.x = 0.0
				break
	elif velocity.x < 0.0:
		for ty in range(min_ty, max_ty + 1):
			if is_tile_solid(min_tx, ty):
				sim_position.x = (min_tx + 1) * 16.0
				velocity.x = 0.0
				break

	# 2. Vertical movement and collision
	is_on_floor = false
	sim_position.y += velocity.y * delta
	box = get_hitbox()

	min_tx = int(floor(box.position.x / 16.0))
	max_tx = int(floor((box.position.x + box.size.x - 0.001) / 16.0))
	min_ty = int(floor(box.position.y / 16.0))
	max_ty = int(floor((box.position.y + box.size.y - 0.001) / 16.0))

	if velocity.y > 0.0:
		for tx in range(min_tx, max_tx + 1):
			if is_tile_solid(tx, max_ty):
				sim_position.y = max_ty * 16.0 - HITBOX_HEIGHT
				velocity.y = 0.0
				is_on_floor = true
				break
	elif velocity.y < 0.0:
		for tx in range(min_tx, max_tx + 1):
			if is_tile_solid(tx, min_ty):
				sim_position.y = (min_ty + 1) * 16.0
				velocity.y = 0.0
				break

	# 3. Ground detection when stationary
	if not is_on_floor and velocity.y >= 0.0:
		var floor_box := Rect2(sim_position.x, sim_position.y + 1.0, HITBOX_WIDTH, HITBOX_HEIGHT)
		var f_min_tx := int(floor(floor_box.position.x / 16.0))
		var f_max_tx := int(floor((floor_box.position.x + floor_box.size.x - 0.001) / 16.0))
		var f_ty := int(floor((floor_box.position.y + floor_box.size.y - 0.001) / 16.0))
		for tx in range(f_min_tx, f_max_tx + 1):
			if is_tile_solid(tx, f_ty):
				is_on_floor = true
				break

func check_environment() -> void:
	var box := get_hitbox()
	var min_tx := int(floor(box.position.x / 16.0))
	var max_tx := int(floor((box.position.x + box.size.x - 0.001) / 16.0))
	var min_ty := int(floor(box.position.y / 16.0))
	var max_ty := int(floor((box.position.y + box.size.y - 0.001) / 16.0))

	var touching_water := false
	var touching_vine := false

	for ty in range(min_ty, max_ty + 1):
		for tx in range(min_tx, max_tx + 1):
			var tile: String = grid.get(Vector2i(tx, ty), ".")
			if tile == "B" or tile == "W":
				touching_water = true
			elif tile == "G" or tile == "V":
				touching_vine = true

	is_swimming = touching_water
	is_climbing = touching_vine

func check_tile_triggers() -> void:
	# Falling out of bounds
	if sim_position.y > 180.0:
		die()
		return

	var box := get_hitbox()
	var min_tx := int(floor(box.position.x / 16.0))
	var max_tx := int(floor((box.position.x + box.size.x - 0.001) / 16.0))
	var min_ty := int(floor(box.position.y / 16.0))
	var max_ty := int(floor((box.position.y + box.size.y - 0.001) / 16.0))

	for ty in range(min_ty, max_ty + 1):
		for tx in range(min_tx, max_tx + 1):
			var tile: String = grid.get(Vector2i(tx, ty), ".")
			if tile == "R" or tile == "L":
				# Touching lava kills
				die()
				return
			elif tile == "Y" or tile == "S":
				# Spark bounce pad launches player upward when falling/landing on it
				# Guarding with velocity.y >= 0 prevents repeated retriggering while ascending through contact
				if velocity.y >= 0.0:
					velocity.y = SPARK_BOUNCE_VELOCITY
					is_on_floor = false
					coyote_timer = 0.0

func is_tile_solid(tx: int, ty: int) -> bool:
	if tx < 0 or tx >= 20 or ty < 0:
		return true
	if ty >= 11:
		return false
	var tile: String = grid.get(Vector2i(tx, ty), ".")
	return tile == "#"

func get_hitbox() -> Rect2:
	return Rect2(sim_position.x, sim_position.y, HITBOX_WIDTH, HITBOX_HEIGHT)

func die() -> void:
	if is_dead:
		return
	is_dead = true
	death_timer = DEATH_FREEZE_TIME
	velocity = Vector2.ZERO

func respawn() -> void:
	is_dead = false
	death_timer = 0.0
	sim_position = spawn_position
	position = Vector2(round(sim_position.x), round(sim_position.y))
	velocity = Vector2.ZERO
	is_on_floor = false
	is_swimming = false
	is_climbing = false
	coyote_timer = 0.0
	jump_buffer_timer = 0.0
	prev_jump_held = false

func _draw() -> void:
	if is_dead:
		# Draw pixel burst particles around local center (4, 6)
		var center := Vector2(4, 6)
		var progress := 1.0 - (death_timer / DEATH_FREEZE_TIME)
		var spread := progress * 8.0
		# 2x2 square particles from palette
		draw_rect(Rect2(center.x - spread, center.y - spread, 2, 2), Palette.PINK)
		draw_rect(Rect2(center.x + spread, center.y - spread, 2, 2), Palette.SPARK_LIGHT)
		draw_rect(Rect2(center.x - spread, center.y + spread, 2, 2), Palette.SPARK_MID)
		draw_rect(Rect2(center.x + spread, center.y + spread, 2, 2), Palette.PINK)
		draw_rect(Rect2(center.x, center.y - spread * 1.2, 2, 2), Palette.LAVA_LIGHT)
		draw_rect(Rect2(center.x, center.y + spread * 1.2, 2, 2), Palette.LAVA_LIGHT)
		return

	# Draw player sprite centered over the 8x12 hitbox (offset -1, -2)
	var tex := texture_right if facing_right else texture_left
	if tex != null:
		draw_texture(tex, Vector2(-1.0, -2.0))

# Input helpers
func get_horizontal_input() -> float:
	var left := Input.is_physical_key_pressed(KEY_A) or Input.is_physical_key_pressed(KEY_LEFT) or Input.is_action_pressed("move_left")
	var right := Input.is_physical_key_pressed(KEY_D) or Input.is_physical_key_pressed(KEY_RIGHT) or Input.is_action_pressed("move_right")
	var val := 0.0
	if right: val += 1.0
	if left: val -= 1.0
	return val

func get_vertical_input() -> float:
	var up := Input.is_physical_key_pressed(KEY_W) or Input.is_physical_key_pressed(KEY_UP) or Input.is_action_pressed("move_up")
	var down := Input.is_physical_key_pressed(KEY_S) or Input.is_physical_key_pressed(KEY_DOWN) or Input.is_action_pressed("move_down")
	var val := 0.0
	if down: val += 1.0
	if up: val -= 1.0
	return val

func is_jump_input_held() -> bool:
	return Input.is_physical_key_pressed(KEY_SPACE) or Input.is_physical_key_pressed(KEY_W) or Input.is_physical_key_pressed(KEY_UP) or Input.is_action_pressed("jump") or Input.is_action_pressed("ui_accept")

func is_restart_just_pressed() -> bool:
	return Input.is_physical_key_pressed(KEY_R) or Input.is_action_just_pressed("restart")

func _init_textures() -> void:
	texture_right = _create_sprite_texture(SPRITE_RIGHT_ROWS)
	
	# Create horizontally flipped rows for facing left
	var left_rows: Array[String] = []
	for row in SPRITE_RIGHT_ROWS:
		var flipped := ""
		for i in range(row.length() - 1, -1, -1):
			flipped += row[i]
		left_rows.append(flipped)
	texture_left = _create_sprite_texture(left_rows)

func _create_sprite_texture(rows: Array[String]) -> Texture2D:
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
		var row: String = rows[y]
		for x in range(width):
			var ch := row[x]
			var color: Color = char_to_color.get(ch, Color(0, 0, 0, 0))
			img.set_pixel(x, y, color)

	return ImageTexture.create_from_image(img)
