extends Panel

@export var button_scene: PackedScene

@onready var title_label = $MarginContainer/VBoxContainer/title
@onready var action_list = $MarginContainer/VBoxContainer/actionList

var current_character: CharacterBody2D = null
var current_interactable: Interactable = null

func _ready() -> void:
	hide()
	UiManager.register_ui("action_menu", self)

func open(character: CharacterBody2D, interactable: Interactable) -> void:
	current_character = character
	current_interactable = interactable
	if current_interactable == null:
		hide_menu()
		return
	title_label.text = current_interactable.prompt_text
	for child in action_list.get_children():
		action_list.remove_child(child)
		child.queue_free()

	var actions: Array = []
	if current_interactable.id == "character_npc":
		var target_char = current_interactable.get_parent()
		var target_id = target_char.character_id if target_char != null and "character_id" in target_char else ""
		
		if target_id == "wildan":
			var follow_action = {"id": "follow_me", "name": "Ikut Ayah/Ibu"}
			if target_char != null and target_char.get("_follow_target") != null:
				follow_action = {"id": "stop_follow", "name": "Berhenti Ikut"}
				
			var sleep_action = {"id": "npc_sleep", "name": "Suruh Tidur"}
			if target_char != null and (target_char.get_activity().get("current_activity", "") == "npc_sleep" or target_char.get_activity().get("current_activity", "") == "sleep"):
				sleep_action = {"id": "cancel_sleep_npc", "name": "Bangunkan"}
				
			actions = [
				follow_action,
				{"id": "npc_cook", "name": "Suruh Masak"},
				sleep_action,
				{"id": "npc_wash_clothes", "name": "Suruh Cuci Baju"},
				{"id": "npc_wash_dishes", "name": "Suruh Cuci Piring"}
			]
		else:
			actions = [
				{"id": "npc_talk", "name": "Bicara"}
			]
	elif current_interactable.id.begins_with("npc_"):
		actions = [
			{"id": "talk_npc", "name": "Bicara"}
		]
	else:
		var furniture = DataManager.get_furniture(current_interactable.id)
		if furniture.is_empty():
			hide_menu()
			return
		actions = furniture.get("actions", []).duplicate() as Array
		
		# Override kasur if already sleeping
		if current_interactable.id == "kasur":
			if current_character.get_activity().get("current_activity", "") == "sleep":
				actions = [{"id": "cancel_sleep", "name": "Bangun"}]
		
	if actions.is_empty():
		hide_menu()
		return
	for action in actions:
		var button: Button = button_scene.instantiate() as Button
		button.text = String(action.get("name", "Action"))
		var action_id: String = String(action.get("id", ""))
		button.pressed.connect(
			func():
				_on_action_selected(action_id)
		)
		action_list.add_child(button)
	UiManager.fade_in(self)
	CameraManager.zoom_in(1.2)

func _on_action_selected(action_id: String):
	var character = current_character
	var interactable = current_interactable
	hide_menu()
	
	if action_id.begins_with("npc_"):
		var actual_action = action_id.replace("npc_", "")
		if interactable != null and is_instance_valid(interactable):
			var target_char = interactable.get_parent()
			if target_char != null and target_char.has_method("command_activity"):
				target_char.command_activity(actual_action)
		return
		
	if action_id == "talk_npc":
		if interactable != null and interactable.id.begins_with("npc_"):
			var n_id = interactable.id.replace("npc_", "")
			UiManager.call_ui("dialogue", "open", [n_id])
		return
		
	match action_id:
		"travel":
			UiManager.call_ui("map_selection", "open", [character])
		"shop":
			if interactable != null and "shop_id" in interactable:
				UiManager.call_ui("shop", "open", [interactable.shop_id])
		"job_portal":
			UiManager.call_ui("job_portal_ui", "open", [character])
		"career_status":
			UiManager.call_ui("career_ui", "open", [character])
		"email":
			UiManager.call_ui("email_ui", "open", [character])
		"cancel_sleep":
			ActivityManager.finish_activity(character)
		"cancel_sleep_npc":
			if interactable != null:
				var target_char = interactable.get_parent()
				if target_char != null:
					ActivityManager.finish_activity(target_char)
		"follow_me":
			if interactable != null:
				var target_char = interactable.get_parent()
				if target_char != null and target_char.has_method("set_follow_target"):
					target_char.set_follow_target(character)
		"stop_follow":
			if interactable != null:
				var target_char = interactable.get_parent()
				if target_char != null and target_char.has_method("set_follow_target"):
					target_char.set_follow_target(null)
		"cook":
			UiManager.call_ui("cooking_ui", "open", [character])
		"wash_clothes", "wash_dishes":
			UiManager.call_ui("cleaning_ui", "open", [character, action_id])
		_:
			ActivityManager.start_activity(character, action_id)

func hide_menu() -> void:
	UiManager.fade_out(self)
	CameraManager.zoom_out()
	current_character = null
	current_interactable = null
	# Wait for fade out to complete before clearing children
	get_tree().create_timer(0.2).timeout.connect(func():
		for child in action_list.get_children():
			child.queue_free()
	)

func _exit_tree() -> void:
	UiManager.unregister_ui("action_menu")
