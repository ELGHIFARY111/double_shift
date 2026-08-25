extends NinePatchRect

@onready var name_label = $MarginContainer/VBoxContainer/NameLabel
@onready var text_label = $MarginContainer/VBoxContainer/TextLabel

var current_dialogue: Array = []
var current_index: int = 0

func _ready() -> void:
	hide()
	UiManager.register_ui("dialogue", self)

func open(npc_id: String) -> void:
	current_dialogue = ["Halo!", "Ada yang bisa saya bantu?"] # Fallback
	var char_data = DataManager.get_character(npc_id)
	if not char_data.is_empty() and char_data.has("dialogue"):
		current_dialogue = char_data["dialogue"]
	
	name_label.text = char_data.get("name", npc_id.capitalize())
	current_index = 0
	show_current()
	UiManager.fade_in(self)

func show_current() -> void:
	if current_index < current_dialogue.size():
		text_label.text = current_dialogue[current_index]
	else:
		_on_close()

func _input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("interact"):
		current_index += 1
		show_current()
		get_viewport().set_input_as_handled()

func _on_close() -> void:
	UiManager.fade_out(self)

func _exit_tree() -> void:
	UiManager.unregister_ui("dialogue")
