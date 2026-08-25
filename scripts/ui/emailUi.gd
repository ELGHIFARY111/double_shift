extends Control

@onready var close_button = $Panel/MarginContainer/VBoxContainer/Header/CloseButton
@onready var email_list = $Panel/MarginContainer/VBoxContainer/Body/LeftPanel/ScrollContainer/EmailList
@onready var detail_title = $Panel/MarginContainer/VBoxContainer/Body/RightPanel/MarginContainer/VBoxContainer/Title
@onready var detail_sender = $Panel/MarginContainer/VBoxContainer/Body/RightPanel/MarginContainer/VBoxContainer/Sender
@onready var detail_body = $Panel/MarginContainer/VBoxContainer/Body/RightPanel/MarginContainer/VBoxContainer/BodyText
@onready var action_container = $Panel/MarginContainer/VBoxContainer/Body/RightPanel/MarginContainer/VBoxContainer/ActionContainer

var current_character: CharacterBody2D = null
var current_email: Dictionary = {}

func _ready() -> void:
	hide()
	UiManager.register_ui("email_ui", self)
	close_button.pressed.connect(func(): UiManager.fade_out(self))

func open(character: CharacterBody2D) -> void:
	current_character = character
	refresh()
	UiManager.fade_in(self)

func refresh() -> void:
	for child in email_list.get_children():
		child.queue_free()
		
	detail_title.text = ""
	detail_sender.text = ""
	detail_body.text = ""
	for child in action_container.get_children():
		child.queue_free()
	
	var player = SaveManager.get_player()
	var emails = player.get("emails", [])
	
	for i in range(emails.size() - 1, -1, -1):
		var email = emails[i]
		var btn = Button.new()
		var prefix = "" if email.get("read", false) else "[BARU] "
		btn.text = prefix + email.get("title", "Pesan")
		btn.pressed.connect(func(): show_email(email))
		email_list.add_child(btn)

func show_email(email: Dictionary) -> void:
	email["read"] = true
	current_email = email
	detail_title.text = email.get("title", "")
	detail_sender.text = "Dari: " + email.get("sender", "")
	detail_body.text = email.get("body", "")
	
	for child in action_container.get_children():
		child.queue_free()
		
	if email.get("type", "") == "job_offer":
		var char_job = current_character.get_job() if current_character != null else {}
		if char_job.get("current_job", "") != "":
			var warn_lbl = Label.new()
			warn_lbl.text = "Harus resign dulu dari pekerjaan saat ini."
			warn_lbl.add_theme_color_override("font_color", Color.RED)
			action_container.add_child(warn_lbl)
		else:
			var accept = Button.new()
			accept.text = "Terima Pekerjaan"
			accept.pressed.connect(func(): _accept_job(email))
			action_container.add_child(accept)
	
	var del_btn = Button.new()
	del_btn.text = "Hapus Email"
	del_btn.pressed.connect(func(): _delete_email(email))
	action_container.add_child(del_btn)
	
	# update list visually (to remove [BARU])
	for i in range(email_list.get_child_count()):
		var btn = email_list.get_child(i)
		btn.text = btn.text.replace("[BARU] ", "")

func _accept_job(email: Dictionary) -> void:
	if current_character == null: return
	var job_dict = current_character.get_job()
	job_dict["current_job"] = email.get("job_id", "")
	job_dict["current_salary"] = email.get("offered_salary", 0)
		
	_delete_email(email)
	
	var job_data = DataManager.get_job(email.get("job_id", ""))
	
	detail_title.text = "Berhasil"
	detail_sender.text = ""
	detail_body.text = "Anda telah resmi diterima bekerja sebagai " + job_data.get("name", "Karyawan") + " dengan gaji Rp " + str(email.get("offered_salary", 0)) + "!"
	
func _delete_email(email: Dictionary) -> void:
	var player = SaveManager.get_player()
	var emails = player.get("emails", [])
	emails.erase(email)
	refresh()

func _exit_tree() -> void:
	UiManager.unregister_ui("email_ui")
