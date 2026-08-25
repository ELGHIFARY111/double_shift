extends NinePatchRect

@export var slot_scene: PackedScene

@onready var close_button = $MarginContainer/VBoxContainer/header/closeButton
@onready var destination_list = $MarginContainer/VBoxContainer/destinationList

var current_character: CharacterBody2D = null

func _ready() -> void:
	hide()
	UiManager.register_ui("map_selection", self)
	close_button.pressed.connect(_on_close)

func open(character: CharacterBody2D) -> void:
	current_character = character
	refresh()
	UiManager.fade_in(self)

func refresh() -> void:
	for child in destination_list.get_children():
		child.queue_free()
	
	var maps = DataManager.get_all_destination()
	for map_id in maps.keys():
		if map_id == WorldManager.current_map: continue
		var slot = slot_scene.instantiate()
		destination_list.add_child(slot)
		
		var dest_data = DataManager.get_destination(map_id)
		slot.setup(dest_data, WorldManager.current_map)
		slot.selected.connect(_on_map_selected)

func _on_map_selected(map_id: String) -> void:
	if current_character != null:
		TravelManager.travel(current_character, map_id)
		_on_close()

func _on_close() -> void:
	UiManager.fade_out(self)

func _exit_tree() -> void:
	UiManager.unregister_ui("map_selection")
