extends Node

const CHARACTER_SCENE: PackedScene = preload("res://scenes/characters/character.tscn")

var _characters: Dictionary = {}
var _character_layer: Node = null


func _ready() -> void:
	WorldManager.map_changed.connect(_on_map_changed)


func register_character_layer(layer: Node) -> void:
	_character_layer = layer


func get_character_layer() -> Node:
	return _character_layer


func spawn(character_id: String) -> CharacterBody2D:
	if _characters.has(character_id):
		return _characters[character_id]

	if CHARACTER_SCENE == null:
		push_error("Character scene belum di-set.")
		return null

	if _character_layer == null or !is_instance_valid(_character_layer):
		push_error("CharacterLayer belum diregister.")
		return null

	var character := CHARACTER_SCENE.instantiate() as CharacterBody2D

	if character == null:
		push_error("Gagal instantiate Character.")
		return null

	character.character_id = character_id
	character.visible = false

	_character_layer.add_child(character)
	_characters[character_id] = character

	_refresh_character(character)

	return character


func spawn_all() -> void:
	var characters: Dictionary = SaveManager.get_characters()

	for id: String in characters.keys():
		spawn(id)

	refresh()


func despawn(character_id: String) -> void:
	if !_characters.has(character_id):
		return

	var character := _characters[character_id] as CharacterBody2D

	if character != null and is_instance_valid(character):
		SpawnManager.save_character_position(character)
		character.queue_free()

	_characters.erase(character_id)


func despawn_all() -> void:
	for id: String in get_all_ids():
		despawn(id)


func get_character(character_id: String) -> CharacterBody2D:
	if !_characters.has(character_id):
		return null

	return _characters[character_id]


func has_character(character_id: String) -> bool:
	return _characters.has(character_id)


func get_all() -> Array[CharacterBody2D]:
	var result: Array[CharacterBody2D] = []

	for character: CharacterBody2D in _characters.values():
		result.append(character)

	return result


func get_all_ids() -> Array[String]:
	var ids: Array[String] = []

	for key: Variant in _characters.keys():
		ids.append(String(key))

	return ids


func refresh() -> void:
	var current_map: String = WorldManager.get_current_map()

	for character: CharacterBody2D in get_all():
		_refresh_character(character, current_map)


func _refresh_character(character: CharacterBody2D, current_map: String = "") -> void:
	if character == null:
		return

	if !is_instance_valid(character):
		return

	if current_map == "":
		current_map = WorldManager.get_current_map()

	var map_id: String = get_location(character)

	var visible_on_map: bool = map_id == current_map

	character.visible = visible_on_map

	if visible_on_map:
		# Restore collision and processing
		character.collision_layer = 1
		character.collision_mask = 1
		character.process_mode = Node.PROCESS_MODE_INHERIT
		SpawnManager.spawn_character(character)
	else:
		# Disable collision and processing for off-map characters
		character.collision_layer = 0
		character.collision_mask = 0
		character.process_mode = Node.PROCESS_MODE_DISABLED


func get_data(character: CharacterBody2D) -> Dictionary:
	return character.get_data()


func get_stats(character: CharacterBody2D) -> Dictionary:
	return character.get_stats()


func get_skills(character: CharacterBody2D) -> Dictionary:
	return character.get_skills()


func get_job(character: CharacterBody2D) -> Dictionary:
	return character.get_job()


func get_activity(character: CharacterBody2D) -> Dictionary:
	return character.get_activity()


func get_location(character: CharacterBody2D) -> String:
	return String(character.get_data().get("map", ""))


func set_location(character: CharacterBody2D, map_id: String) -> void:
	character.get_data()["map"] = map_id


func get_tile(character: CharacterBody2D) -> Vector2i:
	var tile: Dictionary = character.get_data()["tile_position"]

	return Vector2i(
		int(tile.get("x", 0)),
		int(tile.get("y", 0))
	)


func set_tile(character: CharacterBody2D, tile: Vector2i) -> void:
	character.get_data()["tile_position"] = {
		"x": tile.x,
		"y": tile.y
	}


func move_to(character: CharacterBody2D, map_id: String, tile: Vector2i) -> void:
	if character == null:
		return

	set_location(character, map_id)
	set_tile(character, tile)

	if map_id == WorldManager.get_current_map():
		SpawnManager.teleport_character(character, tile)

	_refresh_character(character)
	SaveManager.save_game()


func _on_map_changed(_map_id: String) -> void:
	refresh()
