class_name LevelValidator
extends RefCounted

# Allowed tile characters from the specification table (Section 3.3)
# Valid symbols: # . R B G Y L W V S @ E H r b g y * x (no space)
const VALID_TILES: String = "#.RBGYLWVS@EHrbgy*x"
const VALID_TYPES: Array[String] = ["canvas", "child"]
const EXPECTED_WIDTH: int = 20
const EXPECTED_HEIGHT: int = 11

# Validates parsed level data dictionary. Returns {"valid": bool, "error": String}.
static func validate(level_data: Dictionary) -> Dictionary:
	# 1. Header validations
	if not level_data.has("name") or str(level_data["name"]).strip_edges().is_empty():
		return {"valid": false, "error": "Missing or empty level name"}

	if not level_data.has("type") or not VALID_TYPES.has(str(level_data["type"])):
		return {"valid": false, "error": "Invalid level type: '%s'. Must be 'canvas' or 'child'" % str(level_data.get("type", ""))}

	if not level_data.has("par") or int(level_data["par"]) < 1:
		return {"valid": false, "error": "Invalid par: must be an integer >= 1"}

	if not level_data.has("solution") or str(level_data["solution"]).strip_edges().is_empty():
		return {"valid": false, "error": "Missing or empty solution line"}

	# 2. Row count validation
	if not level_data.has("raw_rows") or not (level_data["raw_rows"] is Array):
		return {"valid": false, "error": "Level data missing raw_rows array"}

	var rows: Array = level_data["raw_rows"]
	if rows.size() != EXPECTED_HEIGHT:
		return {"valid": false, "error": "Level must have exactly %d rows, found %d" % [EXPECTED_HEIGHT, rows.size()]}

	var spawn_count := 0
	var exit_count := 0
	var heart_count := 0

	# 3. Column count and tile characters validation
	for y in range(rows.size()):
		var row: String = str(rows[y])
		if row.length() != EXPECTED_WIDTH:
			return {"valid": false, "error": "Row %d must have exactly %d columns, found %d" % [y, EXPECTED_WIDTH, row.length()]}

		for x in range(row.length()):
			var ch := row[x]
			if VALID_TILES.find(ch) == -1:
				return {"valid": false, "error": "Unknown character '%s' at position (%d, %d)" % [ch, x, y]}

			if ch == "@":
				spawn_count += 1
			elif ch == "E":
				exit_count += 1
			elif ch == "H":
				heart_count += 1

	# 4. Spawn validation
	if spawn_count == 0:
		return {"valid": false, "error": "Missing player spawn (@)"}
	if spawn_count > 1:
		return {"valid": false, "error": "Expected exactly one player spawn (@), found %d" % spawn_count}

	# 5. Type-specific requirement validation
	var level_type: String = str(level_data["type"])
	if level_type == "canvas":
		if exit_count == 0:
			return {"valid": false, "error": "Canvas level requires at least one exit door (E)"}
	elif level_type == "child":
		if heart_count == 0:
			return {"valid": false, "error": "Child world requires at least one heart (H)"}

	return {"valid": true, "error": ""}
