extends Node

signal map_changed(map_id: String)

var current_world: Node2D = null
var current_map: String = ""
var world_root: Node = null
var running := false


func _ready() -> void:
	SaveManager.game_loaded.connect(_on_game_loaded)
	SaveManager.game_closed.connect(_on_game_closed)


func _on_game_loaded() -> void:
	running = true
	_resolve_world_root()


func _on_game_closed() -> void:
	running = false
	current_map = ""
	_clear_world()
	world_root = null


func _resolve_world_root() -> void:

	var scene := get_tree().current_scene

	if scene == null:
		return

	world_root = scene.get_node_or_null("WorldRoot")

	if world_root == null:
		world_root = scene


func _ensure_world_root() -> bool:

	if world_root == null or !is_instance_valid(world_root):
		_resolve_world_root()

	return world_root != null


func _clear_world() -> void:

	if current_world and is_instance_valid(current_world):
		current_world.queue_free()

	current_world = null


func change_map(map_id: String) -> void:
	print("CHANGE MAP =", map_id)
	if !running:
		return

	if map_id.is_empty():
		return

	if current_map == map_id \
	and current_world \
	and is_instance_valid(current_world):
		return

	if !_ensure_world_root():
		push_error("WorldRoot tidak ditemukan.")
		return

	var destination := DataManager.get_destination(map_id)

	if destination.is_empty():
		push_error("Destination tidak ditemukan : " + map_id)
		return

	var scene_path := String(destination.get("scene", ""))

	if scene_path.is_empty():
		push_error("Scene kosong.")
		return

	if current_world:
		print("DELETE =", current_world.name)
		var old := current_world
		old.queue_free()
		await old.tree_exited
		print("OLD REMOVED")

	var packed: PackedScene = load(scene_path)

	if packed == null:
		push_error(scene_path)
		return

	current_world = packed.instantiate()

	print("WORLD ROOT =", world_root)
	print("CURRENT WORLD =", current_world)
	print("SCENE ROOT =", get_tree().current_scene)

	world_root.add_child(current_world)

	current_map = map_id


	await get_tree().process_frame

	CharacterManager.refresh()
	var c := GameManager.get_active_character()
	if c:
		print("Character global =", c.global_position)
	print("World children:")
	for child in world_root.get_children():
		print(child.name)
	map_changed.emit(current_map)


func get_current_map() -> String:
	return current_map


func get_current_world() -> Node2D:
	return current_world


func get_world() -> Node2D:
	return current_world


func get_tilemap() -> TileMapLayer:

	if current_world == null:
		return null

	if current_world.has_method("get_tilemap"):
		return current_world.get_tilemap()

	return current_world.get_node_or_null("TileMapGround") as TileMapLayer


func tile_to_world(tile: Vector2i) -> Vector2:

	var tilemap: TileMapLayer = get_tilemap()

	if tilemap == null:
		return Vector2.ZERO

	return tilemap.to_global(
		tilemap.map_to_local(tile)
	)


func world_to_tile(pos: Vector2) -> Vector2i:

	var tilemap: TileMapLayer = get_tilemap()

	if tilemap == null:
		return Vector2i.ZERO

	return tilemap.local_to_map(
		tilemap.to_local(pos)
	)


func get_spawn_position(tile: Vector2i) -> Vector2:
	return tile_to_world(tile)


func get_spawn_tile(pos: Vector2) -> Vector2i:
	return world_to_tile(pos)


func get_object_layer() -> Node:

	if current_world == null:
		return null

	var layer := current_world.get_node_or_null("objects")

	if layer:
		return layer

	return current_world.get_node_or_null("Objects")
