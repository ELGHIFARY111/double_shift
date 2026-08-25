extends Node2D

@onready var camera: Camera2D = $Camera2D

var initialized := false


func _ready() -> void:

	CameraManager.register_camera(camera)

	CharacterManager.register_character_layer($CharacterLayer)

	SaveManager.game_loaded.connect(_on_game_loaded)

	if _has_save_data():
		await _initialize_game()


func _exit_tree() -> void:

	CameraManager.unregister_camera()


func _on_game_loaded() -> void:

	if initialized:
		return

	if _has_save_data():
		await _initialize_game()


func _input(event: InputEvent) -> void:

	if event.is_action_pressed("switch_character"):
		_switch_character()
		get_viewport().set_input_as_handled()
		return

	if event.is_action_pressed("inventory"):

		var focus := get_viewport().gui_get_focus_owner()

		if focus is LineEdit:
			return

		UiManager.toggle_inventory()


func _has_save_data() -> bool:

	return !SaveManager.get_characters().is_empty()


func _initialize_game() -> void:

	if initialized:
		return

	CharacterManager.spawn_all()

	var all_ids := CharacterManager.get_all_ids()
	var ids: Array[String] = []
	for id in all_ids:
		if id != "wildan":
			ids.append(id)

	if ids.is_empty():
		return

	var first_id: String = ids[0]

	GameManager.switch_to(first_id)

	var character := CharacterManager.get_character(first_id)

	if character != null:

		var map_id := CharacterManager.get_location(character)

		if map_id != "":
			await WorldManager.change_map(map_id)

	initialized = true


func _switch_character() -> void:

	var all_ids := CharacterManager.get_all_ids()
	var ids: Array[String] = []
	for id in all_ids:
		if id != "wildan":
			ids.append(id)

	if ids.size() <= 1:
		return

	var current := GameManager.get_active_character_id()

	var index := ids.find(current)

	if index == -1:
		index = 0

	index = (index + 1) % ids.size()

	GameManager.switch_to(ids[index])
