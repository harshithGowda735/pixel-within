extends Node2D

var level_data: Dictionary = {}
var player: Player
var camera: Camera2D

# Transition overlay nodes
var overlay_layer: CanvasLayer
var overlay_rect: ColorRect
var overlay_material: ShaderMaterial

# Transition state flags
var is_transitioning: bool = false

# Particles and wave animation
var shockwave_particles: Array = []
var recolor_wave_active: bool = false
var recolor_wave_center := Vector2i(-1, -1)
var recolor_wave_timer := 0.0
var recolor_wave_duration := 0.6
var recolor_wave_color: Color = Palette.WATER_MID

func _ready() -> void:
	# 1. Setup Camera2D
	camera = Camera2D.new()
	camera.anchor_mode = Camera2D.ANCHOR_MODE_DRAG_CENTER
	camera.position = Vector2(160, 90)
	camera.zoom = Vector2(1.0, 1.0)
	camera.enabled = true
	add_child(camera)

	# 2. Setup Mosaic Shader Overlay (CanvasLayer on top)
	overlay_layer = CanvasLayer.new()
	overlay_layer.layer = 100
	add_child(overlay_layer)

	overlay_rect = ColorRect.new()
	overlay_rect.size = Vector2(320, 180)
	overlay_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay_rect.visible = false

	var shader = load("res://shaders/mosaic.gdshader")
	overlay_material = ShaderMaterial.new()
	overlay_material.shader = shader
	overlay_material.set_shader_parameter("block", 1.0)
	overlay_material.set_shader_parameter("flat_mix", 0.0)
	overlay_material.set_shader_parameter("flat_color", Palette.INK)
	overlay_rect.material = overlay_material
	overlay_layer.add_child(overlay_rect)

	# 3. Connect to Game autoload signals
	var game_node = get_node_or_null("/root/Game")
	if game_node != null:
		game_node.world_swapped.connect(_on_world_swapped)
		game_node.pigment_changed.connect(_on_pigment_changed)
		game_node.heart_painted.connect(_on_heart_painted)

	# 4. Instantiate player
	player = Player.new()
	add_child(player)

	# 5. Start initial canvas level if needed
	if game_node != null:
		if game_node.states.is_empty():
			game_node.start_canvas("res://levels/canvas_01.txt", "canvas_01")
		else:
			var cur: Dictionary = game_node.get_current_world()
			var spawn: Vector2i = cur.get("player_spawn", Vector2i(1, 9))
			_on_world_swapped(cur, Vector2(spawn.x * 16.0 + 4.0, spawn.y * 16.0 + 4.0))

func _process(delta: float) -> void:
	# Update shockwave particles
	if not shockwave_particles.is_empty():
		var surviving: Array = []
		for p in shockwave_particles:
			p["pos"] += p["vel"] * delta
			p["lifetime"] -= delta
			if p["lifetime"] > 0.0:
				surviving.append(p)
		shockwave_particles = surviving
		queue_redraw()

	# Update recolor wave
	if recolor_wave_active:
		recolor_wave_timer += delta
		queue_redraw()
		if recolor_wave_timer >= recolor_wave_duration:
			recolor_wave_active = false
			queue_redraw()

func _on_world_swapped(world_state: Dictionary, player_pos: Vector2) -> void:
	level_data = world_state
	if player != null:
		player.grid = world_state.get("grid", {})
		player.spawn_position = Vector2(world_state.get("player_spawn", Vector2i(1, 9)).x * 16.0 + 4.0, world_state.get("player_spawn", Vector2i(1, 9)).y * 16.0 + 4.0)
		player.sim_position = player_pos
		player.position = player_pos.round()
		player.velocity = Vector2.ZERO
		player.is_climbing = false
		player.is_swimming = false
		player.queue_redraw()
	queue_redraw()

func _on_pigment_changed(_pigment: String) -> void:
	queue_redraw()

func _on_heart_painted(_color: String) -> void:
	queue_redraw()

# --- M4 Dive Transition: Canvas to Child World ---
func start_dive_transition(cell: Vector2i) -> void:
	if is_transitioning:
		return
	var game_node = get_node_or_null("/root/Game")
	if game_node == null:
		return

	var cur_world: Dictionary = game_node.get_current_world()
	var tile_char: String = cur_world.get("grid", {}).get(cell, "")
	if not Game.DIVEABLE_TILES.has(tile_char):
		return
	if game_node.stack.size() >= Game.MAX_DIVE_DEPTH:
		return

	is_transitioning = true
	if player != null:
		player.input_disabled = true
		player.velocity = Vector2.ZERO

	# Palette mid-color for the selected tile
	var flat_color: Color = Palette.SPARK_MID
	match tile_char:
		"R": flat_color = Palette.LAVA_MID
		"B": flat_color = Palette.WATER_MID
		"G": flat_color = Palette.VINE_MID
		"Y": flat_color = Palette.SPARK_MID

	overlay_material.set_shader_parameter("flat_color", flat_color)
	overlay_material.set_shader_parameter("block", 1.0)
	overlay_material.set_shader_parameter("flat_mix", 0.0)
	overlay_rect.visible = true

	var tile_center := Vector2(cell.x * 16.0 + 8.0, cell.y * 16.0 + 8.0)
	var duration := 0.5

	# Phase A & B: Zoom into selected pixel and collapse mosaic
	var tween_in := create_tween().set_parallel(true)
	tween_in.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween_in.tween_property(camera, "position", tile_center, duration)
	tween_in.tween_property(camera, "zoom", Vector2(20.0, 20.0), duration)
	tween_in.tween_method(func(v: float): overlay_material.set_shader_parameter("block", v), 1.0, 64.0, duration)
	tween_in.tween_method(func(v: float): overlay_material.set_shader_parameter("flat_mix", v), 0.0, 1.0, duration)

	await tween_in.finished

	# Phase C: World swap (once flat)
	game_node.dive(cell)

	# Phase D: Reset camera to normal view, reveal child world
	camera.position = Vector2(160, 90)
	camera.zoom = Vector2(1.0, 1.0)

	var tween_out := create_tween().set_parallel(true)
	tween_out.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween_out.tween_method(func(v: float): overlay_material.set_shader_parameter("block", v), 64.0, 1.0, duration)
	tween_out.tween_method(func(v: float): overlay_material.set_shader_parameter("flat_mix", v), 1.0, 0.0, duration)

	await tween_out.finished

	overlay_rect.visible = false
	camera.position = Vector2(160, 90)
	camera.zoom = Vector2(1.0, 1.0)
	if player != null:
		player.input_disabled = false
	is_transitioning = false

# --- M4 Surface Transition: Child to Parent ---
func start_surface_transition(override_color: Color = Color(0, 0, 0, 0)) -> void:
	if is_transitioning:
		return
	var game_node = get_node_or_null("/root/Game")
	if game_node == null or game_node.stack.is_empty():
		return

	is_transitioning = true
	if player != null:
		player.input_disabled = true
		player.velocity = Vector2.ZERO

	# Determine flat color from current child world color
	var flat_color := override_color
	if flat_color.a == 0.0:
		var cur_world: Dictionary = game_node.get_current_world()
		var cur_col: String = cur_world.get("color", "")
		match cur_col:
			"R": flat_color = Palette.LAVA_MID
			"B": flat_color = Palette.WATER_MID
			"G": flat_color = Palette.VINE_MID
			"Y": flat_color = Palette.SPARK_MID
			_: flat_color = Palette.STONE_LIGHT

	overlay_material.set_shader_parameter("flat_color", flat_color)
	overlay_material.set_shader_parameter("block", 1.0)
	overlay_material.set_shader_parameter("flat_mix", 0.0)
	overlay_rect.visible = true

	var duration := 0.45

	# Phase A: Collapse child world into flat color
	var tween_in := create_tween().set_parallel(true)
	tween_in.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween_in.tween_method(func(v: float): overlay_material.set_shader_parameter("block", v), 1.0, 64.0, duration)
	tween_in.tween_method(func(v: float): overlay_material.set_shader_parameter("flat_mix", v), 0.0, 1.0, duration)

	await tween_in.finished

	# Retrieve parent cell from stack before popping
	var parent_cell: Vector2i = game_node.stack.back()["cell"]

	# Phase B: Perform world swap to parent world exactly once
	game_node.surface()

	# Show parent world zoomed in around selected pixel
	var parent_center := Vector2(parent_cell.x * 16.0 + 8.0, parent_cell.y * 16.0 + 8.0)
	camera.position = parent_center
	camera.zoom = Vector2(20.0, 20.0)

	# Phase C: Zoom camera back out to normal position, reverse mosaic
	var tween_out := create_tween().set_parallel(true)
	tween_out.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween_out.tween_property(camera, "position", Vector2(160, 90), duration)
	tween_out.tween_property(camera, "zoom", Vector2(1.0, 1.0), duration)
	tween_out.tween_method(func(v: float): overlay_material.set_shader_parameter("block", v), 64.0, 1.0, duration)
	tween_out.tween_method(func(v: float): overlay_material.set_shader_parameter("flat_mix", v), 1.0, 0.0, duration)

	await tween_out.finished

	overlay_rect.visible = false
	camera.position = Vector2(160, 90)
	camera.zoom = Vector2(1.0, 1.0)
	if player != null:
		player.input_disabled = false
	is_transitioning = false

# --- M4 Paint Transition: Shockwave, Recolor Wave, and Auto-Surface ---
func start_paint_transition(heart_pos: Vector2i, pigment: String) -> void:
	if is_transitioning:
		return
	var game_node = get_node_or_null("/root/Game")
	if game_node == null or game_node.stack.is_empty():
		return

	var cur_world: Dictionary = game_node.get_current_world()
	var cur_color: String = cur_world.get("color", "")
	var new_color: String = pigment.to_upper()
	if new_color == cur_color or pigment.is_empty():
		return # Matching pigment rejected without consumption

	is_transitioning = true
	if player != null:
		player.input_disabled = true
		player.velocity = Vector2.ZERO

	# 1. Spawn square particle shockwave around the heart
	_spawn_heart_shockwave(heart_pos, pigment)
	await get_tree().create_timer(0.25).timeout

	# 2. Determine new pigment color
	var new_pigment_color: Color = Palette.WATER_MID
	match new_color:
		"R": new_pigment_color = Palette.LAVA_MID
		"B": new_pigment_color = Palette.WATER_MID
		"G": new_pigment_color = Palette.VINE_MID
		"Y": new_pigment_color = Palette.SPARK_MID

	# 3. Collapse child world with new pigment color
	overlay_material.set_shader_parameter("flat_color", new_pigment_color)
	overlay_material.set_shader_parameter("block", 1.0)
	overlay_material.set_shader_parameter("flat_mix", 0.0)
	overlay_rect.visible = true

	var collapse_dur := 0.4
	var tween_collapse := create_tween().set_parallel(true)
	tween_collapse.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween_collapse.tween_method(func(v: float): overlay_material.set_shader_parameter("block", v), 1.0, 64.0, collapse_dur)
	tween_collapse.tween_method(func(v: float): overlay_material.set_shader_parameter("flat_mix", v), 0.0, 1.0, collapse_dur)

	await tween_collapse.finished

	# Retrieve parent cell before paint_heart performs surface()
	var parent_cell: Vector2i = game_node.stack.back()["cell"]

	# 4. Perform heart painting and world swap in Game state exactly once
	game_node.paint_heart(pigment)

	# 5. Zoom out from parent world repainted tile
	var parent_center := Vector2(parent_cell.x * 16.0 + 8.0, parent_cell.y * 16.0 + 8.0)
	camera.position = parent_center
	camera.zoom = Vector2(20.0, 20.0)

	var tween_reveal := create_tween().set_parallel(true)
	tween_reveal.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween_reveal.tween_property(camera, "position", Vector2(160, 90), collapse_dur)
	tween_reveal.tween_property(camera, "zoom", Vector2(1.0, 1.0), collapse_dur)
	tween_reveal.tween_method(func(v: float): overlay_material.set_shader_parameter("block", v), 64.0, 1.0, collapse_dur)
	tween_reveal.tween_method(func(v: float): overlay_material.set_shader_parameter("flat_mix", v), 1.0, 0.0, collapse_dur)

	await tween_reveal.finished
	overlay_rect.visible = false
	camera.position = Vector2(160, 90)
	camera.zoom = Vector2(1.0, 1.0)

	# 6. Start tile-by-tile recolor wave expanding outward from the repainted tile (0.6s)
	recolor_wave_active = true
	recolor_wave_center = parent_cell
	recolor_wave_timer = 0.0
	recolor_wave_duration = 0.6
	recolor_wave_color = new_pigment_color

	await get_tree().create_timer(0.6).timeout
	recolor_wave_active = false
	queue_redraw()

	if player != null:
		player.input_disabled = false
	is_transitioning = false

func _spawn_heart_shockwave(heart_pos: Vector2i, pigment: String) -> void:
	var center := Vector2(heart_pos.x * 16.0 + 8.0, heart_pos.y * 16.0 + 8.0)
	var colors := [Palette.PINK, Palette.SPARK_LIGHT]
	match pigment.to_upper():
		"R":
			colors.append(Palette.LAVA_LIGHT)
			colors.append(Palette.LAVA_MID)
		"B":
			colors.append(Palette.WATER_LIGHT)
			colors.append(Palette.WATER_MID)
		"G":
			colors.append(Palette.VINE_LIGHT)
			colors.append(Palette.VINE_MID)
		"Y":
			colors.append(Palette.SPARK_LIGHT)
			colors.append(Palette.SPARK_MID)

	for i in range(16):
		var angle := (PI * 2.0 / 16.0) * float(i)
		var speed := randf_range(30.0, 60.0)
		var vel := Vector2(cos(angle), sin(angle)) * speed
		var col: Color = colors[i % colors.size()]
		shockwave_particles.append({
			"pos": center,
			"vel": vel,
			"lifetime": 0.25,
			"max_lifetime": 0.25,
			"color": col,
			"size": 2.0 if (i % 2 == 0) else 3.0,
		})

func _draw() -> void:
	if not level_data.get("valid", false):
		return

	var grid: Dictionary = level_data.get("grid", {})
	for pos in grid.keys():
		var tile_char: String = grid[pos]
		var tex := Tiles.get_tile_texture(tile_char, pos)
		draw_texture(tex, Vector2(pos.x * Tiles.TILE_SIZE, pos.y * Tiles.TILE_SIZE))

	# Recolor wave expanding outward tile-by-tile
	if recolor_wave_active and recolor_wave_center != Vector2i(-1, -1):
		var current_r := (recolor_wave_timer / recolor_wave_duration) * 22.0
		for pos in grid.keys():
			var dist := Vector2(pos).distance_to(Vector2(recolor_wave_center))
			var diff := absf(dist - current_r)
			if diff < 1.2:
				var tile_rect := Rect2(pos.x * 16.0, pos.y * 16.0, 16.0, 16.0)
				draw_rect(tile_rect, recolor_wave_color, false, 1.0)
				draw_rect(Rect2(pos.x * 16.0 + 7.0, pos.y * 16.0 + 7.0, 2.0, 2.0), Palette.SPARK_LIGHT)

	# Shockwave particles
	for p in shockwave_particles:
		draw_rect(Rect2(p["pos"].x, p["pos"].y, p["size"], p["size"]), p["color"])

	# 4px HUD strip at bottom (y: 176 to 180)
	draw_line(Vector2(0, 176), Vector2(320, 176), Palette.STONE_DARK, 1.0)
	
	# Draw breadcrumbs and held pigment indicator in the HUD strip
	_draw_hud()

func _draw_hud() -> void:
	var game_node = get_node_or_null("/root/Game")
	if game_node == null:
		return

	# Breadcrumbs: one 3x3 swatch per depth (Section 3.5)
	draw_rect(Rect2(4, 177, 3, 3), Palette.STONE_LIGHT)

	for i in range(game_node.stack.size()):
		var entry: Dictionary = game_node.stack[i]
		var col_char: String = entry.get("tile_char", "")
		var swatch_color := Palette.SPARK_LIGHT
		match col_char:
			"R": swatch_color = Palette.LAVA_MID
			"B": swatch_color = Palette.WATER_MID
			"G": swatch_color = Palette.VINE_MID
			"Y": swatch_color = Palette.SPARK_MID
		draw_rect(Rect2(4 + (i + 1) * 6, 177, 3, 3), swatch_color)

	# Held pigment indicator at right side of HUD (x: 300..316)
	if not game_node.held.is_empty():
		var pigment_color := Palette.SPARK_LIGHT
		match game_node.held:
			"r": pigment_color = Palette.LAVA_LIGHT
			"b": pigment_color = Palette.WATER_LIGHT
			"g": pigment_color = Palette.VINE_LIGHT
			"y": pigment_color = Palette.SPARK_LIGHT
		draw_rect(Rect2(310, 177, 6, 3), pigment_color)
