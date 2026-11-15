class_name LevelLoader
extends RefCounted

const SEPARATOR := "---"

# Loads and validates a level file from disk path.
static func load_level(file_path: String) -> Dictionary:
	if not FileAccess.file_exists(file_path):
		return {"valid": false, "error": "File not found: " + file_path}

	var file := FileAccess.open(file_path, FileAccess.READ)
	if file == null:
		return {"valid": false, "error": "Failed to open file: " + file_path}

	var content := file.get_as_text()
	file.close()

	return parse_level(content)

# Parses raw level text string into a validated level data dictionary.
static func parse_level(content: String) -> Dictionary:
	var normalized := content.replace("\r\n", "\n").replace("\r", "\n")
	var lines := normalized.split("\n")

	var headers: Dictionary = {}
	var rows: Array[String] = []
	var found_separator := false

	for line in lines:
		var trimmed := line.strip_edges()
		if not found_separator:
			if trimmed == SEPARATOR:
				found_separator = true
			elif trimmed.is_empty():
				continue
			else:
				var eq_idx := trimmed.find("=")
				if eq_idx != -1:
					var key := trimmed.substr(0, eq_idx).strip_edges()
					var val := trimmed.substr(eq_idx + 1).strip_edges()
					if key == "par":
						headers[key] = int(val)
					else:
						headers[key] = val
		else:
			# If we already have 11 rows, ignore trailing empty lines
			if line.is_empty() and rows.size() >= LevelValidator.EXPECTED_HEIGHT:
				continue
			# Strip only trailing carriage return, keep row indentation if any
			var row_str := line.trim_suffix("\r")
			# Ignore empty lines before first grid row
			if row_str.is_empty() and rows.size() == 0:
				continue
			rows.append(row_str)

	if not found_separator:
		return {"valid": false, "error": "Missing '---' separator between headers and grid"}

	var level_data: Dictionary = {
		"name": headers.get("name", ""),
		"type": headers.get("type", ""),
		"par": headers.get("par", 0),
		"solution": headers.get("solution", ""),
		"raw_rows": rows,
		"width": LevelValidator.EXPECTED_WIDTH,
		"height": LevelValidator.EXPECTED_HEIGHT,
		"grid": {},
		"player_spawn": Vector2i(-1, -1),
		"exits": [],
		"hearts": [],
	}

	# Run validator
	var validation := LevelValidator.validate(level_data)
	if not validation["valid"]:
		return {"valid": false, "error": validation["error"]}

	# Build grid dictionary: Dictionary[Vector2i, String]
	var grid: Dictionary = {}
	for y in range(rows.size()):
		var row: String = rows[y]
		for x in range(row.length()):
			var pos := Vector2i(x, y)
			var tile: String = row[x]
			grid[pos] = tile
			if tile == "@":
				level_data["player_spawn"] = pos
			elif tile == "E":
				level_data["exits"].append(pos)
			elif tile == "H":
				level_data["hearts"].append(pos)

	level_data["grid"] = grid
	level_data["valid"] = true
	level_data["error"] = ""
	return level_data
