extends Node

signal game_loaded
signal game_closed
signal money_changed(amount: int)

const SAVE_FOLDER: String = "user://saves/"
const CONFIG_PATH: String = "user://config.json"
const DEFAULT_SAVE_PATH: String = "res://resources/save/default_save.json"

var data: Dictionary = {}
var current_save_path: String = ""
var current_save_name: String = ""


func _ready() -> void:
	_ensure_save_folder()
	await get_tree().process_frame

	var last_save_path: String = _get_last_save_path()

	if last_save_path != "" and FileAccess.file_exists(last_save_path):
		load_game(last_save_path)


func _ensure_save_folder() -> void:
	DirAccess.make_dir_recursive_absolute(SAVE_FOLDER)


func new_game(save_name: String = "save") -> void:
	var base_data: Dictionary = _load_json_file(DEFAULT_SAVE_PATH)

	if base_data.is_empty():
		base_data = _default_save_data()

	data = _normalize_data(base_data)
	current_save_name = save_name
	current_save_path = SAVE_FOLDER + save_name + "_" + str(Time.get_unix_time_from_system()) + ".json"

	save_game()
	_set_last_save_path(current_save_path)

	game_loaded.emit()


func load_game(path: String) -> bool:
	if path == "":
		return false

	if !FileAccess.file_exists(path):
		push_error("Save tidak ditemukan: " + path)
		return false

	var loaded: Dictionary = _load_json_file(path)

	if loaded.is_empty():
		push_error("Save kosong / rusak: " + path)
		return false

	data = _normalize_data(loaded)
	current_save_path = path
	current_save_name = _extract_save_name(path)

	_save_current_config()
	game_loaded.emit()
	return true


func close_game() -> void:
	data = {}
	current_save_path = ""
	current_save_name = ""
	game_closed.emit()


func save_game() -> void:
	if current_save_path == "":
		current_save_path = SAVE_FOLDER + "autosave_" + str(Time.get_unix_time_from_system()) + ".json"

	_ensure_save_folder()
	_write_json_file(current_save_path, data)
	_set_last_save_path(current_save_path)


func save_as(path: String) -> bool:
	if path == "":
		return false

	current_save_path = path
	save_game()
	return true


func has_save(path: String) -> bool:
	return path != "" and FileAccess.file_exists(path)


func get_current_save_path() -> String:
	return current_save_path


func get_current_save_name() -> String:
	return current_save_name


func get_player() -> Dictionary:
	if !data.has("player") or !(data["player"] is Dictionary):
		data["player"] = _default_player_data()

	return data["player"]


func get_money() -> int:
	var player: Dictionary = get_player()
	return int(player.get("money", 0))


func set_money(amount: int) -> void:
	var player: Dictionary = get_player()
	player["money"] = max(amount, 0)

	money_changed.emit(player["money"])


func add_money(amount: int) -> void:
	set_money(get_money() + amount)


func get_day() -> int:
	var player: Dictionary = get_player()
	return int(player.get("day", 1))


func set_day(day: int) -> void:
	var player: Dictionary = get_player()
	player["day"] = max(day, 1)


func get_hour() -> int:
	var player: Dictionary = get_player()
	var time_data: Dictionary = player.get("time", {})
	return int(time_data.get("hour", 6))


func set_hour(hour: int) -> void:
	var player: Dictionary = get_player()
	if !player.has("time") or !(player["time"] is Dictionary):
		player["time"] = {"hour": 6, "minute": 0}

	player["time"]["hour"] = clamp(hour, 0, 23)


func get_minute() -> int:
	var player: Dictionary = get_player()
	var time_data: Dictionary = player.get("time", {})
	return int(time_data.get("minute", 0))


func set_minute(minute: int) -> void:
	var player: Dictionary = get_player()
	if !player.has("time") or !(player["time"] is Dictionary):
		player["time"] = {"hour": 6, "minute": 0}

	player["time"]["minute"] = clamp(minute, 0, 59)


func set_time(hour: int, minute: int) -> void:
	set_hour(hour)
	set_minute(minute)


func get_inventory() -> Array:
	var player: Dictionary = get_player()

	if !player.has("inventory") or !(player["inventory"] is Array):
		player["inventory"] = []

	return player["inventory"]


func get_cooking_queue() -> Array:
	var player: Dictionary = get_player()

	if !player.has("cooking_queue") or !(player["cooking_queue"] is Array):
		player["cooking_queue"] = []

	return player["cooking_queue"]


func get_furniture() -> Dictionary:
	var player: Dictionary = get_player()

	if !player.has("furniture") or !(player["furniture"] is Dictionary):
		player["furniture"] = {}

	return player["furniture"]


func get_characters() -> Dictionary:
	var player: Dictionary = get_player()

	if !player.has("characters") or !(player["characters"] is Dictionary):
		player["characters"] = {}

	return player["characters"]


func _load_json_file(path: String) -> Dictionary:
	if !FileAccess.file_exists(path):
		return {}

	var file: FileAccess = FileAccess.open(path, FileAccess.READ)

	if file == null:
		return {}

	var text: String = file.get_as_text()
	var parsed: Variant = JSON.parse_string(text)

	if !(parsed is Dictionary):
		return {}

	return parsed


func _write_json_file(path: String, payload: Dictionary) -> void:
	var file: FileAccess = FileAccess.open(path, FileAccess.WRITE)

	if file == null:
		push_error("Gagal menulis save: " + path)
		return

	file.store_string(JSON.stringify(payload, "\t"))


func _save_current_config() -> void:
	var cfg: Dictionary = {
		"last_save_path": current_save_path,
		"last_save_name": current_save_name
	}

	_write_json_file(CONFIG_PATH, cfg)


func _set_last_save_path(path: String) -> void:
	var cfg: Dictionary = _load_json_file(CONFIG_PATH)

	cfg["last_save_path"] = path
	cfg["last_save_name"] = _extract_save_name(path)

	_write_json_file(CONFIG_PATH, cfg)


func _get_last_save_path() -> String:
	var cfg: Dictionary = _load_json_file(CONFIG_PATH)
	return String(cfg.get("last_save_path", ""))


func _extract_save_name(path: String) -> String:
	var file_name: String = path.get_file()
	return file_name.trim_suffix(".json")


func _normalize_data(raw: Dictionary) -> Dictionary:
	var result: Dictionary = raw.duplicate(true)

	if !result.has("version"):
		result["version"] = 1

	if !result.has("player") or !(result["player"] is Dictionary):
		result["player"] = _default_player_data()
	else:
		result["player"] = _normalize_player(result["player"])

	return result


func _normalize_player(player: Dictionary) -> Dictionary:
	var result: Dictionary = player.duplicate(true)

	if !result.has("money"):
		result["money"] = 0

	if !result.has("day"):
		result["day"] = 1

	if !result.has("time") or !(result["time"] is Dictionary):
		result["time"] = {"hour": 6, "minute": 0}
	else:
		var time_data: Dictionary = result["time"]
		if !time_data.has("hour"):
			time_data["hour"] = 6
		if !time_data.has("minute"):
			time_data["minute"] = 0

	if !result.has("inventory") or !(result["inventory"] is Array):
		result["inventory"] = []

	if !result.has("cooking_queue") or !(result["cooking_queue"] is Array):
		result["cooking_queue"] = []

	if !result.has("dirty_clothes"):
		result["dirty_clothes"] = 0.0
		
	if !result.has("dirty_dishes"):
		result["dirty_dishes"] = 0
		
	if !result.has("family_hygiene"):
		result["family_hygiene"] = 100.0
		
	if !result.has("family_burden") or !(result["family_burden"] is Dictionary):
		result["family_burden"] = {"kiki": 10.0, "jefri": 10.0}

	if !result.has("furniture") or !(result["furniture"] is Dictionary):
		result["furniture"] = {}

	if !result.has("characters") or !(result["characters"] is Dictionary):
		result["characters"] = {}

	var characters: Dictionary = result["characters"]
	var normalized_characters: Dictionary = {}
	
	# Pastikan karakter dari default_save masuk ke save lama
	var default_data = _load_json_file(DEFAULT_SAVE_PATH)
	if default_data.has("player") and default_data["player"].has("characters"):
		var default_characters = default_data["player"]["characters"]
		for default_id in default_characters.keys():
			if not characters.has(default_id):
				characters[default_id] = default_characters[default_id]

	for character_id: String in characters.keys():
		var character_data: Dictionary = {}

		if characters[character_id] is Dictionary:
			character_data = (characters[character_id] as Dictionary).duplicate(true)

		normalized_characters[character_id] = _normalize_character(character_id, character_data)

	result["characters"] = normalized_characters
	return result


func _normalize_character(character_id: String, character_data: Dictionary) -> Dictionary:
	var result: Dictionary = character_data.duplicate(true)

	if !result.has("name"):
		result["name"] = character_id

	if !result.has("map"):
		result["map"] = "house"

	if !result.has("tile_position") or !(result["tile_position"] is Dictionary):
		result["tile_position"] = {"x": 0, "y": 0}
	else:
		var tile: Dictionary = result["tile_position"]
		if !tile.has("x"):
			tile["x"] = 0
		if !tile.has("y"):
			tile["y"] = 0

	if !result.has("stats") or !(result["stats"] is Dictionary):
		result["stats"] = _default_stats()

	if !result.has("skills") or !(result["skills"] is Dictionary):
		result["skills"] = _default_skills()

	if !result.has("job") or !(result["job"] is Dictionary):
		result["job"] = _default_job()

	if !result.has("activity") or !(result["activity"] is Dictionary):
		result["activity"] = _default_activity()
	else:
		result["activity"] = _normalize_activity(result["activity"] as Dictionary)

	# Migrasi data lama
	if result.has("position") and result["position"] is Dictionary:
		var legacy_position: Dictionary = result["position"]

		if String(result.get("map", "")) == "":
			var legacy_scene: String = String(legacy_position.get("scene", ""))
			var resolved_map: String = _resolve_map_from_scene(legacy_scene)

			if resolved_map != "":
				result["map"] = resolved_map

		if result["tile_position"] is Dictionary:
			var tile_data: Dictionary = result["tile_position"]
			tile_data["x"] = int(legacy_position.get("x", tile_data.get("x", 0)))
			tile_data["y"] = int(legacy_position.get("y", tile_data.get("y", 0)))

		result.erase("position")

	return result


func _normalize_activity(activity: Dictionary) -> Dictionary:
	var result: Dictionary = activity.duplicate(true)

	if !result.has("current_activity"):
		result["current_activity"] = ""

	if !result.has("time_left"):
		result["time_left"] = 0

	if !result.has("duration"):
		result["duration"] = 0

	if !result.has("target"):
		result["target"] = ""

	if !result.has("origin") or !(result["origin"] is Dictionary):
		result["origin"] = {}

	if !result.has("returning"):
		result["returning"] = false

	if !result.has("progress"):
		result["progress"] = 0

	return result


func _default_save_data() -> Dictionary:
	return {
		"version": 1,
		"player": _default_player_data()
	}


func _default_player_data() -> Dictionary:
	return {
		"money": 0,
		"day": 1,
		"time": {
			"hour": 6,
			"minute": 0
		},
		"inventory": [],
		"cooking_queue": [],
		"dirty_clothes": 0.0,
		"dirty_dishes": 0,
		"family_hygiene": 100.0,
		"family_burden": {"kiki": 10.0, "jefri": 10.0},
		"furniture": {},
		"characters": {},
		"quests": {
			"active": "",
			"objectives_progress": {},
			"completed": []
		}
	}
func _default_stats() -> Dictionary:
	return {
		"energy": 100,
		"hunger": 100,
		"stress": 0
	}
func _default_skills() -> Dictionary:
	return {
		"programming": 0,
		"cooking": 0,
		"communication": 0,
		"discipline": 0,
		"computer": 0
	}
func _default_job() -> Dictionary:
	return {
		"current_job": ""
	}
func _default_activity() -> Dictionary:
	return {
		"current_activity": "",
		"time_left": 0,
		"duration": 0,
		"target": "",
		"origin": {},
		"returning": false,
		"progress": 0
	}
func _resolve_map_from_scene(scene_path: String) -> String:
	if scene_path == "":
		return ""

	var destinations: Dictionary = DataManager.get_all_destination()

	for destination_id: String in destinations.keys():
		var destination: Dictionary = destinations[destination_id]
		var destination_scene: String = String(destination.get("scene", ""))

		if destination_scene == scene_path:
			return destination_id

	return ""
func has_last_save() -> bool:
	return _get_last_save_path() != ""


func get_last_save() -> String:
	return _get_last_save_path()


func get_all_saves() -> Array:
	var saves:Array = []

	var dir := DirAccess.open(SAVE_FOLDER)

	if dir == null:
		return saves

	dir.list_dir_begin()

	while true:

		var file := dir.get_next()

		if file == "":
			break

		if dir.current_is_dir():
			continue

		if !file.ends_with(".json"):
			continue

		var path := SAVE_FOLDER + file

		var data := _load_json_file(path)

		var player := {}

		if data.has("player"):
			player = data["player"]

		saves.append({
			"save_name": file.trim_suffix(".json"),
			"path": path,
			"player": player,
			"last_played": Time.get_datetime_string_from_unix_time(
				FileAccess.get_modified_time(path)
			)
		})

	dir.list_dir_end()

	return saves


func delete_save(path:String)->void:

	if path == "":
		return

	if !FileAccess.file_exists(path):
		return

	DirAccess.remove_absolute(path)

	if current_save_path == path:
		close_game()


func rename_save(path:String,new_name:String)->void:

	if path == "":
		return

	if new_name == "":
		return

	if !FileAccess.file_exists(path):
		return

	var new_path := SAVE_FOLDER + new_name + ".json"

	DirAccess.rename_absolute(path,new_path)

	if current_save_path == path:
		current_save_path = new_path
		current_save_name = new_name
		_set_last_save_path(new_path)
