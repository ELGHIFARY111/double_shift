extends Node

var _cached_tilemap: TileMapLayer = null
var _tilemap_cached: bool = false


func _ready() -> void:
	WorldManager.map_changed.connect(_on_map_changed)


func _on_map_changed(_map_id: String) -> void:
	_tilemap_cached = false
	_cached_tilemap = null


func get_tilemap() -> TileMapLayer:
	if !_tilemap_cached:
		_cached_tilemap = WorldManager.get_tilemap()
		_tilemap_cached = true
	return _cached_tilemap


func get_character_layer() -> Node:
	return CharacterManager.get_character_layer()


func tile_to_world(tile: Vector2i) -> Vector2:
	var tilemap: TileMapLayer = get_tilemap()

	if tilemap == null:
		return Vector2.ZERO

	return tilemap.to_global(
		tilemap.map_to_local(tile)
	)


func world_to_tile(world_position: Vector2) -> Vector2i:
	var tilemap: TileMapLayer = get_tilemap()

	if tilemap == null:
		return Vector2i.ZERO

	return tilemap.local_to_map(
		tilemap.to_local(world_position)
	)


func spawn_character(character: CharacterBody2D) -> void:
	if character == null:
		return

	var tilemap: TileMapLayer = get_tilemap()

	if tilemap == null:
		return

	var layer: Node = get_character_layer()

	if layer == null:
		return

	if character.get_parent() != layer:

		if character.get_parent() != null:
			character.get_parent().remove_child(character)

		layer.add_child(character)

	var tile: Vector2i = CharacterManager.get_tile(character)

	character.global_position = tile_to_world(tile)


func despawn_character(character: CharacterBody2D) -> void:

	if character == null:
		return

	if character.get_parent() != null:
		character.get_parent().remove_child(character)


func move_character(
	character: CharacterBody2D,
	tile: Vector2i
) -> void:

	if character == null:
		return

	character.global_position = tile_to_world(tile)

	CharacterManager.set_tile(character, tile)

	SaveManager.save_game()


func teleport_character(
	character: CharacterBody2D,
	tile: Vector2i
) -> void:

	move_character(character, tile)


func save_character_position(character: CharacterBody2D) -> void:

	if character == null:
		return

	var tile: Vector2i = world_to_tile(character.global_position)

	CharacterManager.set_tile(character, tile)

	SaveManager.save_game()


func get_character_tile(character: CharacterBody2D) -> Vector2i:

	if character == null:
		return Vector2i.ZERO

	return world_to_tile(character.global_position)


func spawn_active_character() -> void:

	var character: CharacterBody2D = GameManager.get_active_character()

	if character == null:
		return

	spawn_character(character)
