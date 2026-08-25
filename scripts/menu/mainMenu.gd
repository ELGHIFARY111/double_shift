extends Control

@export var save_card_scene: PackedScene

@onready var main_menu = $CenterContainer

@onready var save_list_panel = $saveListPanel
@onready var save_container = $saveListPanel/MarginContainer/VBoxContainer/ScrollContainer/saveList

@onready var new_game_panel = $newGamePanel
@onready var save_name = $newGamePanel/MarginContainer/VBoxContainer/saveName

# Main Menu
@onready var continue_button = $CenterContainer/VBoxContainer/continue
@onready var new_game_button = $CenterContainer/VBoxContainer/newGameButton
@onready var load_button = $CenterContainer/VBoxContainer/loadGameButton
@onready var exit_button = $CenterContainer/VBoxContainer/exitButton

# New Game
@onready var create_button = $newGamePanel/MarginContainer/VBoxContainer/HBoxContainer/createButton
@onready var cancel_button = $newGamePanel/MarginContainer/VBoxContainer/HBoxContainer/cancelButton

# Save List
@onready var back_button = $saveListPanel/MarginContainer/VBoxContainer/header/backButton
@onready var play_button = $saveListPanel/MarginContainer/VBoxContainer/HBoxContainer/playButton
@onready var rename_dialog = $renameDialog
@onready var rename_edit = $renameDialog/VBoxContainer/nameEdit
@onready var delete_dialog = $deleteDialog

var delete_path := ""
var rename_path := ""

var selected_path := ""
var selected_card = null


func _ready():

	hide_all_panels()

	main_menu.show()

	continue_button.disabled = !SaveManager.has_last_save()

	refresh_save_list()

	new_game_button.pressed.connect(_on_new_game_pressed)
	load_button.pressed.connect(_on_load_pressed)
	continue_button.pressed.connect(_on_continue_pressed)
	exit_button.pressed.connect(_on_exit_pressed)

	create_button.pressed.connect(_on_create_pressed)
	cancel_button.pressed.connect(_on_cancel_pressed)

	back_button.pressed.connect(_on_back_pressed)

	play_button.pressed.connect(_on_play_pressed)
	rename_dialog.confirmed.connect(_on_rename_confirmed)
	delete_dialog.confirmed.connect(_on_delete_confirmed)
	update_buttons()


func hide_all_panels():

	main_menu.hide()
	save_list_panel.hide()
	new_game_panel.hide()

	if has_node("deleteDialog"):
		$deleteDialog.hide()

	if has_node("renameDialog"):
		$renameDialog.hide()


func refresh_save_list():

	selected_path = ""
	selected_card = null

	for child in save_container.get_children():
		child.queue_free()

	var saves = SaveManager.get_all_saves()

	saves.sort_custom(func(a,b):
		return a["last_played"] > b["last_played"]
	)

	for save in saves:
		var card = save_card_scene.instantiate()
		save_container.add_child(card)
		card.setup(save)
		card.rename_pressed.connect(_on_rename_pressed)
		card.delete_pressed.connect(_on_delete_pressed)
		card.gui_input.connect(func(event):
			if event is InputEventMouseButton \
			and event.button_index == MOUSE_BUTTON_LEFT \
			and event.pressed:
				select_card(card, save["path"])
		)
	update_buttons()


func select_card(card, path):
	if selected_card:
		selected_card.set_selected(false)
	selected_card = card
	selected_path = path
	selected_card.set_selected(true)
	update_buttons()


func update_buttons():
	play_button.disabled = selected_path == ""


func _on_continue_pressed():

	var path = SaveManager.get_last_save()

	if path == "":
		return

	if SaveManager.load_game(path):
		get_tree().change_scene_to_file("res://scenes/main/main.tscn")


func _on_new_game_pressed():

	hide_all_panels()

	new_game_panel.show()

	save_name.text = ""

	save_name.grab_focus()


func _on_load_pressed():

	hide_all_panels()

	save_list_panel.show()

	refresh_save_list()


func _on_back_pressed():

	hide_all_panels()

	main_menu.show()


func _on_cancel_pressed():

	hide_all_panels()

	main_menu.show()


func _on_create_pressed() -> void:

	var name: String = save_name.text.strip_edges()

	if name.is_empty():
		name = "New Save"

	SaveManager.new_game(name)

	get_tree().change_scene_to_file(
		"res://scenes/main/main.tscn"
	)


func _on_play_pressed():
	if selected_path.is_empty():
		return
	if SaveManager.load_game(selected_path):
		get_tree().change_scene_to_file("res://scenes/main/main.tscn")


func _on_delete_pressed(path:String):
	print(path)
	delete_path = path

	delete_dialog.popup_centered()
func _on_delete_confirmed():
	SaveManager.delete_save(delete_path)
	refresh_save_list()
	continue_button.disabled = !SaveManager.has_last_save()

func _on_rename_pressed(path:String):
	print(path)
	rename_path = path
	rename_edit.text = ""
	rename_dialog.popup_centered()
func _on_rename_confirmed():
	var new_name = rename_edit.text.strip_edges()
	if new_name.is_empty():
		return
	SaveManager.rename_save(rename_path, new_name)
	refresh_save_list()

func _on_exit_pressed():

	get_tree().quit()
