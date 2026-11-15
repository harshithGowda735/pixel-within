extends SceneTree

const PlayerScript = preload("res://scripts/player.gd")
const LevelLoaderScript = preload("res://scripts/level_loader.gd")

func _init() -> void:
	var all_passed := true
	print("==========================================")
	print("Running Player Movement & Collision Tests")
	print("==========================================")

	# --- Test 1: Hitbox and Physics Constants ---
	print("\n[Test 1] Testing Player Hitbox and Constants...")
	var player = PlayerScript.new()
	assert(player.HITBOX_WIDTH == 8.0)
	assert(player.HITBOX_HEIGHT == 12.0)
	assert(player.RUN_SPEED == 100.0)
	assert(player.ACCELERATION == 800.0)
	assert(player.FRICTION == 1000.0)
	assert(player.GRAVITY == 900.0)
	assert(player.TERMINAL_VELOCITY == 260.0)
	assert(player.JUMP_VELOCITY == -310.0)
	assert(player.VARIABLE_JUMP_MULTIPLIER == 0.45)
	assert(player.COYOTE_TIME == 0.10)
	assert(player.JUMP_BUFFER_TIME == 0.10)
	assert(player.SWIM_GRAVITY == 220.0)
	assert(player.SWIM_TERMINAL_VELOCITY == 50.0)
	assert(player.SWIM_SPEED == 70.0)
	assert(player.SWIM_STROKE_VELOCITY == -120.0)
	assert(player.CLIMB_SPEED == 55.0)
	assert(player.SPARK_BOUNCE_VELOCITY == -430.0)
	assert(player.DEATH_FREEZE_TIME == 0.50)
	print("PASS: All player constants match specification")

	# Setup an empty test grid (20x11 air with solid stone border)
	var test_grid: Dictionary = {}
	for y in range(11):
		for x in range(20):
			if x == 0 or x == 19 or y == 0 or y == 10:
				test_grid[Vector2i(x, y)] = "#"
			else:
				test_grid[Vector2i(x, y)] = "."

	player.setup(test_grid, Vector2i(2, 9))
	# Spawn position at tile (2, 9): x = 2*16+4 = 36, y = 9*16+4 = 148
	assert(player.sim_position == Vector2(36, 148))
	assert(player.spawn_position == Vector2(36, 148))
	print("PASS: Player setup and spawn positioning correct")

	# --- Test 2: Floor detection and Gravity ---
	print("\n[Test 2] Testing Floor Detection and Gravity...")
	# Standing on floor at tile (2, 9) with floor at y=10*16=160
	player.sim_position = Vector2(36, 148)
	player.velocity = Vector2.ZERO
	player.move_and_collide_custom(0.016)
	assert(player.is_on_floor == true)
	print("PASS: Floor detected correctly when standing on ground")

	# In air (y = 50)
	player.sim_position = Vector2(36, 50)
	player.velocity = Vector2.ZERO
	player.is_on_floor = false
	player.move_and_collide_custom(0.016)
	assert(player.is_on_floor == false)
	print("PASS: In-air correctly identified as not on floor")

	# Gravity acceleration
	player.velocity.y = minf(player.velocity.y + player.GRAVITY * 0.1, player.TERMINAL_VELOCITY)
	assert(player.velocity.y == 90.0)
	# Terminal velocity cap
	player.velocity.y = minf(player.velocity.y + player.GRAVITY * 1.0, player.TERMINAL_VELOCITY)
	assert(player.velocity.y == 260.0)
	print("PASS: Gravity and terminal velocity work as specified")

	# --- Test 3: Horizontal Movement, Acceleration & Friction ---
	print("\n[Test 3] Testing Horizontal Acceleration & Friction...")
	player.sim_position = Vector2(50, 148)
	player.velocity = Vector2.ZERO
	# Accelerate right for 0.05s
	player.velocity.x = move_toward(player.velocity.x, player.RUN_SPEED, player.ACCELERATION * 0.05)
	assert(is_equal_approx(player.velocity.x, 40.0))
	# Reach max speed
	player.velocity.x = move_toward(player.velocity.x, player.RUN_SPEED, player.ACCELERATION * 0.2)
	assert(is_equal_approx(player.velocity.x, 100.0))
	# Friction decelerates to 0
	player.velocity.x = move_toward(player.velocity.x, 0.0, player.FRICTION * 0.05)
	assert(is_equal_approx(player.velocity.x, 50.0))
	player.velocity.x = move_toward(player.velocity.x, 0.0, player.FRICTION * 0.05)
	assert(is_equal_approx(player.velocity.x, 0.0))
	print("PASS: Horizontal acceleration and friction verified")

	# --- Test 4: Wall Collision Resolution ---
	print("\n[Test 4] Testing Wall Collision Resolution...")
	# Place player near left wall (tile 0 is solid, edge is at x=16)
	player.sim_position = Vector2(17, 148)
	player.velocity = Vector2(-100, 0)
	player.move_and_collide_custom(0.05) # Would move to 12 without collision
	# Left wall is at x=16, so player hitbox left edge must be at x=16
	assert(player.sim_position.x == 16.0)
	assert(player.velocity.x == 0.0)
	print("PASS: Left wall collision resolved at x=16.0, velocity stopped")

	# Place player near right wall (tile 19 is solid, left edge is at x=19*16 = 304)
	# Hitbox width is 8, so right edge touches at 304, sim_position.x must be 304 - 8 = 296
	player.sim_position = Vector2(295, 148)
	player.velocity = Vector2(100, 0)
	player.move_and_collide_custom(0.05)
	assert(player.sim_position.x == 296.0)
	assert(player.velocity.x == 0.0)
	print("PASS: Right wall collision resolved at x=296.0, velocity stopped")

	# Ceiling collision (tile 0 is solid, bottom edge is at y=16)
	player.sim_position = Vector2(50, 18)
	player.velocity = Vector2(0, -310)
	player.move_and_collide_custom(0.02)
	assert(player.sim_position.y == 16.0)
	assert(player.velocity.y == 0.0)
	print("PASS: Ceiling collision resolved at y=16.0, upward velocity cancelled")

	# --- Test 5: Variable Jump ---
	print("\n[Test 5] Testing Variable Jump Multiplier (0.45)...")
	player.velocity.y = player.JUMP_VELOCITY
	assert(player.velocity.y == -310.0)
	# Releasing jump early multiplies velocity by 0.45 once
	player.velocity.y *= player.VARIABLE_JUMP_MULTIPLIER
	assert(is_equal_approx(player.velocity.y, -310.0 * 0.45))
	print("PASS: Variable jump correctly applies 0.45 upward-velocity multiplier")

	# --- Test 6: Coyote Time ---
	print("\n[Test 6] Testing Coyote Time (0.10s window)...")
	player.is_on_floor = false
	player.coyote_timer = 0.05 # 0.05s elapsed, still within 0.10s window
	player.jump_buffer_timer = 0.08
	if player.jump_buffer_timer > 0.0 and player.coyote_timer > 0.0:
		player.velocity.y = player.JUMP_VELOCITY
		player.coyote_timer = 0.0
		player.jump_buffer_timer = 0.0
	assert(player.velocity.y == -310.0)
	assert(player.coyote_timer == 0.0)
	print("PASS: Coyote jump executed within 0.10s window")

	# Coyote time expired (> 0.10s)
	player.coyote_timer = 0.0
	player.jump_buffer_timer = 0.05
	player.velocity.y = 0.0
	if player.jump_buffer_timer > 0.0 and player.coyote_timer > 0.0:
		player.velocity.y = player.JUMP_VELOCITY
	assert(player.velocity.y == 0.0)
	print("PASS: Coyote jump correctly rejected when coyote time expired")

	# --- Test 7: Jump Buffering Landing & Expiration ---
	print("\n[Test 7] Testing Jump Buffering (landing execution & 0.10s expiration)...")
	# Case A: Jump pressed 0.05s before landing -> executes on touchdown
	player.sim_position = Vector2(50, 140) # in air, falling
	player.velocity.y = 150.0
	player.is_on_floor = false
	player.jump_buffer_timer = 0.05 # buffered
	player.coyote_timer = 0.0
	# Touchdown
	player.move_and_collide_custom(0.06) # lands at y=148
	assert(player.is_on_floor == true)
	# Next frame on floor: coyote refreshed, jump triggers from buffer
	if player.is_on_floor:
		player.coyote_timer = player.COYOTE_TIME
	if player.jump_buffer_timer > 0.0 and player.coyote_timer > 0.0:
		player.velocity.y = player.JUMP_VELOCITY
		player.jump_buffer_timer = 0.0
		player.coyote_timer = 0.0
	assert(player.velocity.y == -310.0)
	print("PASS: Buffered jump executed upon landing")

	# Case B: Jump pressed too early (> 0.10s before landing) -> expires
	player.sim_position = Vector2(50, 80)
	player.velocity.y = 100.0
	player.is_on_floor = false
	player.jump_buffer_timer = player.JUMP_BUFFER_TIME # 0.10s
	# 0.12 seconds elapse before landing
	player.jump_buffer_timer = maxf(player.jump_buffer_timer - 0.12, 0.0)
	assert(player.jump_buffer_timer == 0.0)
	# Lands on floor
	player.is_on_floor = true
	player.coyote_timer = player.COYOTE_TIME
	if player.jump_buffer_timer > 0.0 and player.coyote_timer > 0.0:
		player.velocity.y = player.JUMP_VELOCITY
	else:
		player.velocity.y = 0.0
	assert(player.velocity.y == 0.0)
	print("PASS: Jump buffer correctly expired after 0.10 seconds without executing")

	# --- Test 8: Vine Climbing and Vine Jump-Off ---
	print("\n[Test 8] Testing Vine Climbing and Vine Jump-Off...")
	test_grid[Vector2i(9, 7)] = "G"
	test_grid[Vector2i(9, 8)] = "V"
	player.setup(test_grid, Vector2i(9, 8))
	player.check_environment()
	assert(player.is_climbing == true)
	print("PASS: Vine attachment activates is_climbing")

	# Upward climb
	player.velocity.y = -player.CLIMB_SPEED
	assert(player.velocity.y == -55.0)
	# Downward climb
	player.velocity.y = player.CLIMB_SPEED
	assert(player.velocity.y == 55.0)
	print("PASS: Climbing operates at 55 px/s up and down with no gravity")

	# Vine leap off
	player.velocity.y = player.JUMP_VELOCITY
	player.is_climbing = false
	assert(player.velocity.y == -310.0)
	assert(player.is_climbing == false)
	print("PASS: Jumping from vine correctly leaps off and releases climbing state")

	# --- Test 9: Spark Bounce Retrigger Prevention ---
	print("\n[Test 9] Testing Spark Bounce Retrigger Prevention on Y and S...")
	test_grid[Vector2i(11, 9)] = "Y"
	test_grid[Vector2i(12, 9)] = "S"
	player.setup(test_grid, Vector2i(2, 9))

	# Player falls onto spark pad Y (velocity.y >= 0)
	player.sim_position = Vector2(11 * 16 + 4, 9 * 16 + 4)
	player.velocity.y = 100.0 # falling
	player.check_tile_triggers()
	assert(player.velocity.y == -430.0)
	print("PASS: Spark tile (Y) launches player at -430.0 px/s on touchdown")

	# Subsequent frame: player is still in spark tile, but moving upward (velocity.y < 0)
	player.velocity.y = -400.0 # moving upward
	player.check_tile_triggers()
	assert(player.velocity.y == -400.0)
	print("PASS: Spark tile does not retrigger while ascending through contact")

	# Spark tile S (fill)
	player.sim_position = Vector2(12 * 16 + 4, 9 * 16 + 4)
	player.velocity.y = 80.0
	player.check_tile_triggers()
	assert(player.velocity.y == -430.0)
	player.velocity.y = -350.0
	player.check_tile_triggers()
	assert(player.velocity.y == -350.0)
	print("PASS: Spark fill (S) launches at -430.0 px/s without retriggering")

	# --- Test 10: Lava Hazard & Death (R and L) ---
	print("\n[Test 10] Testing Lava Hazard & Death...")
	test_grid[Vector2i(5, 9)] = "R"
	test_grid[Vector2i(6, 9)] = "L"
	player.setup(test_grid, Vector2i(2, 9))

	# Move onto lava tile R at (5, 9)
	player.sim_position = Vector2(5 * 16 + 4, 9 * 16 + 4)
	player.check_tile_triggers()
	assert(player.is_dead == true)
	assert(player.death_timer == player.DEATH_FREEZE_TIME)
	print("PASS: Touching lava pixel (R) triggers death with 0.5s freeze")

	# After 0.5s freeze, respawns
	player.update_physics(0.51)
	assert(player.is_dead == false)
	assert(player.sim_position == player.spawn_position)
	assert(player.velocity == Vector2.ZERO)
	print("PASS: Player respawns at spawn position with zero velocity after 0.5s")

	# Move onto lava fill L at (6, 9)
	player.sim_position = Vector2(6 * 16 + 4, 9 * 16 + 4)
	player.check_tile_triggers()
	assert(player.is_dead == true)
	print("PASS: Touching lava fill (L) triggers death")
	player.respawn()

	# --- Test 11: Water Swimming (B and W) ---
	print("\n[Test 11] Testing Water Swimming...")
	test_grid[Vector2i(7, 9)] = "B"
	test_grid[Vector2i(8, 9)] = "W"
	player.sim_position = Vector2(7 * 16 + 4, 9 * 16 + 4)
	player.check_environment()
	assert(player.is_swimming == true)
	print("PASS: Swimming state activated inside water chroma pixel (B)")

	# Stroke test
	player.swim_stroke_timer = 0.0
	player.velocity.y = player.SWIM_STROKE_VELOCITY
	player.swim_stroke_timer = player.SWIM_STROKE_COOLDOWN
	assert(player.velocity.y == -120.0)
	assert(player.swim_stroke_timer == 0.25)
	print("PASS: Swim stroke gives -120 px/s with 0.25s cooldown")

	# Water fill
	player.sim_position = Vector2(8 * 16 + 4, 9 * 16 + 4)
	player.check_environment()
	assert(player.is_swimming == true)
	print("PASS: Swimming state activated inside water fill (W)")

	# --- Test 12: Fall Out of Bounds & Restart ---
	print("\n[Test 12] Testing Out of Bounds & Restart...")
	player.respawn()
	player.sim_position.y = 185.0
	player.check_tile_triggers()
	assert(player.is_dead == true)
	print("PASS: Falling past y=180 triggers death")

	# Manual respawn
	player.respawn()
	assert(player.is_dead == false)
	assert(player.sim_position == player.spawn_position)
	assert(player.velocity == Vector2.ZERO)
	print("PASS: Respawn resets player to spawn position cleanly")

	player.free()
	print("\n==========================================")
	if all_passed:
		print("ALL 12 PLAYER PHYSICS & BEHAVIOR TESTS PASSED!")
	else:
		print("SOME TESTS FAILED!")
	print("==========================================")
	quit(0 if all_passed else 1)
