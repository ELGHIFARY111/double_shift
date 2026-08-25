extends Node

signal active_character_changed(character: CharacterBody2D)

var active_character: CharacterBody2D = null

var running: bool = false


func _ready() -> void:
	SaveManager.game_loaded.connect(_on_game_loaded)
	SaveManager.game_closed.connect(_on_game_closed)


func _on_game_loaded() -> void:
	running = true


func _on_game_closed() -> void:
	running = false
	active_character = null


func set_active_character(character: CharacterBody2D) -> void:
	if !running:
		return

	if character == null:
		return

	if active_character == character:
		return

	if active_character != null:
		active_character.is_active = false

	active_character = character
	active_character.is_active = true

	_update_character_ui()

	active_character_changed.emit(active_character)


func switch_to(id:String) -> void:

	var character := CharacterManager.get_character(id)
	if character == null:
		return
	if active_character:
		active_character.is_active = false
	active_character = character
	active_character.is_active = true

	# beri tahu semua manager dulu
	active_character_changed.emit(active_character)
	var map := CharacterManager.get_location(active_character)
	if map != WorldManager.get_current_map():
		await WorldManager.change_map(map)
	_update_character_ui()


func get_active_character() -> CharacterBody2D:
	return active_character


func get_active_character_id() -> String:
	if active_character == null:
		return ""

	return active_character.character_id


func get_character_data() -> Dictionary:
	if active_character == null:
		return {}

	return active_character.get_data()


func get_stats() -> Dictionary:
	if active_character == null:
		return {}

	return active_character.get_stats()


func get_skills() -> Dictionary:
	if active_character == null:
		return {}

	return active_character.get_skills()


func get_activity() -> Dictionary:
	if active_character == null:
		return {}

	return active_character.get_activity()


func _update_character_ui() -> void:
	if active_character == null:
		UiManager.hide_ui("travel_panel")
		return

	var activity: Dictionary = active_character.get_activity()

	if String(activity.get("current_activity", "")) == "travel":
		UiManager.call_ui(
			"travel_panel",
			"open",
			[active_character]
		)
	else:
		UiManager.hide_ui("travel_panel")

	if String(activity.get("current_activity", "")) == "cook":
		UiManager.call_ui(
			"cooking_ui",
			"open",
			[active_character]
		)
	else:
		UiManager.hide_ui("cooking_ui")

	UiManager.call_ui(
		"action_menu",
		"hide_menu"
	)

	UiManager.call_ui(
		"interact_prompt",
		"hide_prompt"
	)
