extends Control

@onready var close_button = $Panel/MarginContainer/VBoxContainer/Header/CloseButton
@onready var job_name_label = $Panel/MarginContainer/VBoxContainer/JobName
@onready var salary_label = $Panel/MarginContainer/VBoxContainer/Salary
@onready var duration_label = $Panel/MarginContainer/VBoxContainer/Duration
@onready var resign_button = $Panel/MarginContainer/VBoxContainer/ResignButton

var current_character: CharacterBody2D = null

func _ready() -> void:
	hide()
	UiManager.register_ui("career_ui", self)
	close_button.pressed.connect(close)
	resign_button.pressed.connect(_on_resign_pressed)

func open(character: CharacterBody2D) -> void:
	current_character = character
	refresh()
	show()

func close() -> void:
	hide()
	current_character = null

func refresh() -> void:
	if current_character == null:
		return
	
	var job_data = current_character.get_job()
	var current_job_id = str(job_data.get("current_job", ""))
	
	if current_job_id == "":
		job_name_label.text = "Pekerjaan: Belum bekerja"
		salary_label.text = "Gaji: -"
		duration_label.text = "Durasi: -"
		resign_button.disabled = true
	else:
		var job_details = DataManager.get_job(current_job_id)
		job_name_label.text = "Pekerjaan: " + str(job_details.get("name", "Unknown"))
		salary_label.text = "Gaji: Rp." + str(job_data.get("current_salary", 0))
		duration_label.text = "Durasi: " + str(job_details.get("work_duration", 0)) + " menit"
		resign_button.disabled = false

func _on_resign_pressed() -> void:
	var job_data = current_character.get_job()
	job_data["current_job"] = ""
	job_data["current_salary"] = 0
	SaveManager.save_game()
	refresh()
	print("Anda telah resign dari pekerjaan.")
