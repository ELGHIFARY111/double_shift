extends NinePatchRect

@onready var title_bar = $MarginContainer/VBoxContainer/HBoxContainer/titleBar
@onready var back_button = $MarginContainer/VBoxContainer/HBoxContainer/backButton
@onready var destination_label = $MarginContainer/VBoxContainer/destinationLabel
@onready var time_label = $MarginContainer/VBoxContainer/timeLabel
@onready var progress_bar = $MarginContainer/VBoxContainer/ProgressBar
@onready var cancel_button = $MarginContainer/VBoxContainer/cancelButton

var current_character: CharacterBody2D = null

func _ready() -> void:
	hide()
	UiManager.register_ui("travel_panel", self)
	cancel_button.pressed.connect(_on_cancel)
	back_button.pressed.connect(_on_cancel)

func open(character: CharacterBody2D, destination_name: String, duration: int) -> void:
	current_character = character
	destination_label.text = "Tujuan: " + destination_name
	progress_bar.max_value = float(duration)
	progress_bar.value = 0.0
	UiManager.fade_in(self)

func update_progress(time_left: int) -> void:
	progress_bar.value = float(progress_bar.max_value - time_left)
	time_label.text = "Sisa Waktu: " + str(time_left) + " menit"

func _on_cancel() -> void:
	if current_character != null:
		TravelManager.cancel_travel(current_character)
	UiManager.fade_out(self)

func _exit_tree() -> void:
	UiManager.unregister_ui("travel_panel")
