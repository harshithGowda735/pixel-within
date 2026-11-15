extends SceneTree

const LevelLoader = preload("res://scripts/level_loader.gd")
const LevelValidator = preload("res://scripts/validator.gd")

func _init() -> void:
	var all_passed := true
	print("========================================")
	print("Running Level Loader & Validator Tests")
	print("========================================")

	# --- Test 1: Load and validate Canvas Level 1 ---
	print("\n[Test 1] Loading Canvas Level 1 (levels/canvas_01.txt)...")
	var level: Dictionary = LevelLoader.load_level("res://levels/canvas_01.txt")
	if not level.get("valid", false):
		print("FAIL: canvas_01.txt failed validation: ", level.get("error"))
		all_passed = false
	else:
		print("PASS: canvas_01.txt is valid")
		assert(level["name"] == "First Pixel")
		assert(level["type"] == "canvas")
		assert(level["par"] == 2)
		assert(level["width"] == 20)
		assert(level["height"] == 11)
		assert(level["player_spawn"] == Vector2i(1, 9))
		assert(level["exits"].has(Vector2i(17, 9)))
		assert(level["grid"][Vector2i(4, 9)] == "B")
		assert(level["grid"][Vector2i(10, 9)] == "R")
		print("PASS: All Canvas Level 1 metadata and tile positions verified")

	# Base valid canvas template for broken tests
	var base_template := """name=Test Level
type=canvas
par=1
solution=none
---
####################
#..................#
#..................#
#..................#
#..................#
#..................#
#..................#
#..................#
#..................#
#@................E#
####################"""

	# --- Test 2: Invalid dimensions (10 rows instead of 11) ---
	print("\n[Test 2] Testing invalid row count (10 rows)...")
	var bad_rows := """name=Test
type=canvas
par=1
solution=none
---
####################
#..................#
#..................#
#..................#
#..................#
#..................#
#..................#
#..................#
#..................#
#@................E#"""
	var res2: Dictionary = LevelLoader.parse_level(bad_rows)
	if not res2["valid"] and "11 rows" in res2["error"]:
		print("PASS: Correctly rejected 10 rows: ", res2["error"])
	else:
		print("FAIL: Expected rejection for row count: ", res2)
		all_passed = false

	# --- Test 3: Invalid column count (19 columns) ---
	print("\n[Test 3] Testing invalid column count (19 columns in row 1)...")
	var bad_cols := base_template.replace("#..................#", "#.................#")
	var res3: Dictionary = LevelLoader.parse_level(bad_cols)
	if not res3["valid"] and "20 columns" in res3["error"]:
		print("PASS: Correctly rejected 19 columns: ", res3["error"])
	else:
		print("FAIL: Expected rejection for column count: ", res3)
		all_passed = false

	# --- Test 4: Unknown character ---
	print("\n[Test 4] Testing unknown character ('?')...")
	var bad_char := base_template.replace("#..................#", "#........?.........#")
	var res4: Dictionary = LevelLoader.parse_level(bad_char)
	if not res4["valid"] and "Unknown character" in res4["error"]:
		print("PASS: Correctly rejected unknown character: ", res4["error"])
	else:
		print("FAIL: Expected rejection for unknown character: ", res4)
		all_passed = false

	# --- Test 5: Missing player spawn ---
	print("\n[Test 5] Testing missing player spawn (@)...")
	var no_spawn := base_template.replace("@", ".")
	var res5: Dictionary = LevelLoader.parse_level(no_spawn)
	if not res5["valid"] and "Missing player spawn" in res5["error"]:
		print("PASS: Correctly rejected missing spawn: ", res5["error"])
	else:
		print("FAIL: Expected rejection for missing spawn: ", res5)
		all_passed = false

	# --- Test 6: Multiple player spawns ---
	print("\n[Test 6] Testing multiple player spawns (@)...")
	var multi_spawn := base_template.replace("#..................#", "#........@.........#")
	var res6: Dictionary = LevelLoader.parse_level(multi_spawn)
	if not res6["valid"] and "Expected exactly one player spawn" in res6["error"]:
		print("PASS: Correctly rejected multiple spawns: ", res6["error"])
	else:
		print("FAIL: Expected rejection for multiple spawns: ", res6)
		all_passed = false

	# --- Test 7: Missing exit on canvas level ---
	print("\n[Test 7] Testing missing exit door on canvas level...")
	var no_exit := base_template.replace("E", ".")
	var res7: Dictionary = LevelLoader.parse_level(no_exit)
	if not res7["valid"] and "requires at least one exit door" in res7["error"]:
		print("PASS: Correctly rejected missing canvas exit: ", res7["error"])
	else:
		print("FAIL: Expected rejection for missing exit: ", res7)
		all_passed = false

	# --- Test 8: Missing heart on child world ---
	print("\n[Test 8] Testing missing heart on child world...")
	var child_no_heart := """name=Child World
type=child
par=1
solution=none
---
####################
#..................#
#..................#
#..................#
#..................#
#..................#
#..................#
#..................#
#..................#
#@.................#
####################"""
	var res8: Dictionary = LevelLoader.parse_level(child_no_heart)
	if not res8["valid"] and "requires at least one heart" in res8["error"]:
		print("PASS: Correctly rejected child world without heart: ", res8["error"])
	else:
		print("FAIL: Expected rejection for missing heart: ", res8)
		all_passed = false

	# --- Test 9: Invalid level type ---
	print("\n[Test 9] Testing invalid level type...")
	var bad_type := base_template.replace("type=canvas", "type=dungeon")
	var res9: Dictionary = LevelLoader.parse_level(bad_type)
	if not res9["valid"] and "Invalid level type" in res9["error"]:
		print("PASS: Correctly rejected invalid type: ", res9["error"])
	else:
		print("FAIL: Expected rejection for invalid type: ", res9)
		all_passed = false

	# --- Test 10: Missing solution line ---
	print("\n[Test 10] Testing missing solution line...")
	var no_solution := base_template.replace("solution=none\n", "")
	var res10: Dictionary = LevelLoader.parse_level(no_solution)
	if not res10["valid"] and "Missing or empty solution line" in res10["error"]:
		print("PASS: Correctly rejected missing solution: ", res10["error"])
	else:
		print("FAIL: Expected rejection for missing solution: ", res10)
		all_passed = false

	# --- Test 11: Broken file test on disk ---
	print("\n[Test 11] Testing broken file on disk...")
	var test_file_path := "res://levels/broken_test.txt"
	var f := FileAccess.open(test_file_path, FileAccess.WRITE)
	f.store_string("corrupted level without headers")
	f.close()

	var disk_res: Dictionary = LevelLoader.load_level(test_file_path)
	# Clean up immediately
	DirAccess.remove_absolute(ProjectSettings.globalize_path(test_file_path))

	if not disk_res["valid"]:
		print("PASS: Broken disk file correctly rejected: ", disk_res["error"])
	else:
		print("FAIL: Expected rejection for corrupted file")
		all_passed = false

	print("\n========================================")
	if all_passed:
		print("ALL 11 TESTS PASSED SUCCESSFULLY!")
	else:
		print("SOME TESTS FAILED!")
	print("========================================")
	quit(0 if all_passed else 1)
