extends Node

var current_character: CharacterBody2D = null
var current_interactable: Interactable = null


func _ready() -> void:
	GameManager.active_character_changed.connect(_on_active_character_changed)
	WorldManager.map_changed.connect(_on_map_changed)
	SaveManager.game_closed.connect(_on_game_closed)


func enter(
	character: CharacterBody2D,
	interactable: Interactable
) -> void:

	if !_is_valid(character, interactable):
		return

	if current_interactable != null and current_interactable != interactable:
		current_interactable.unfocus()

	current_character = character
	current_interactable = interactable
	current_interactable.focus()

	UiManager.call_ui(
		"interact_prompt",
		"show_prompt",
		[
			interactable.prompt_text,
			character.global_position,
			interactable.global_position
		]
	)


func exit(
	character: CharacterBody2D,
	interactable: Interactable
) -> void:

	if current_character != character:
		return

	if current_interactable != interactable:
		return

	clear()


func interact() -> void:

	if !_is_valid(current_character, current_interactable):
		clear()
		return

	UiManager.hide_ui("interact_prompt")

	UiManager.call_ui(
		"action_menu",
		"open",
		[
			current_character,
			current_interactable
		]
	)


func clear() -> void:

	if current_interactable != null:
		current_interactable.unfocus()

	current_character = null
	current_interactable = null

	UiManager.hide_ui("interact_prompt")

	UiManager.call_ui(
		"action_menu",
		"hide_menu"
	)


func _is_valid(
	character: CharacterBody2D,
	interactable: Interactable
) -> bool:

	if character == null:
		return false

	if interactable == null:
		return false

	if !is_instance_valid(character):
		return false

	if !is_instance_valid(interactable):
		return false

	if character != GameManager.get_active_character():
		return false

	var world := WorldManager.get_current_world()

	if world == null:
		return false

	var char_layer := CharacterManager.get_character_layer()

	if !world.is_ancestor_of(interactable):
		if char_layer == null or !char_layer.is_ancestor_of(interactable):
			return false

	return true


func _on_active_character_changed(
	_character: CharacterBody2D
) -> void:
	clear()


func _on_map_changed(
	_map_id: String
) -> void:
	clear()


func _on_game_closed() -> void:
	clear()
