extends Panel

signal rename_pressed(path)
signal delete_pressed(path)
var save_path := ""

@onready var save_name = $MarginContainer/HBoxContainer/VBoxContainer/saveName
@onready var day_label = $MarginContainer/HBoxContainer/VBoxContainer/dayLabel
@onready var money_label = $MarginContainer/HBoxContainer/VBoxContainer/moneyLabel
@onready var last_played = $MarginContainer/HBoxContainer/VBoxContainer/lastPlayed

@onready var rename_button = $MarginContainer/HBoxContainer/VBoxContainer2/renameButton
@onready var delete_button = $MarginContainer/HBoxContainer/VBoxContainer2/deleteButton

func setup(save:Dictionary):
	print(save_name)
	if save_name == null:
		push_error("save_name NULL")
		return
	print("save_name =", save_name)
	print("day_label =", day_label)
	print("money_label =", money_label)
	print("last_played =", last_played)
	save_path = save["path"]
	save_name.text = save.get("save_name","No Name")
	last_played.text = save.get("last_played","")
	var player = save.get("player",{})
	day_label.text = "Day %d" % int(player.get("day",1))
	money_label.text = "$%d" % int(player.get("money",0))
func set_selected(selected: bool):
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.12, 0.12, 0.12)
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	if selected:
		style.border_width_left = 2
		style.border_width_top = 2
		style.border_width_right = 2
		style.border_width_bottom = 2
		style.border_color = Color.WHITE
	add_theme_stylebox_override("panel", style)
func _on_rename_button_pressed():
	print("Rename Click")
	rename_pressed.emit(save_path)

func _on_delete_button_pressed():
	print("Delete Click")
	delete_pressed.emit(save_path)
