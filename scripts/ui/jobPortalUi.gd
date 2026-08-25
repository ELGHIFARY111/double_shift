extends Control

@onready var title_label = $Panel/MarginContainer/VBoxContainer/Header/Title
@onready var close_button = $Panel/MarginContainer/VBoxContainer/Header/CloseButton
@onready var job_list = $Panel/MarginContainer/VBoxContainer/ScrollContainer/JobList

var current_character: CharacterBody2D = null

func _ready() -> void:
	hide()
	UiManager.register_ui("job_portal_ui", self)
	close_button.pressed.connect(_on_close)

func open(character: CharacterBody2D) -> void:
	current_character = character
	_check_and_generate_daily_jobs()
	refresh_jobs()
	UiManager.fade_in(self)

func _check_and_generate_daily_jobs() -> void:
	var player = SaveManager.get_player()
	var current_day = SaveManager.get_day()
	var last_refresh = int(player.get("last_job_refresh_day", 0))
	
	if current_day != last_refresh or not player.has("daily_jobs") or (player.get("daily_jobs") as Array).is_empty():
		player["last_job_refresh_day"] = current_day
		var all_jobs = DataManager.get_all_jobs()
		var job_keys = all_jobs.keys()
		
		# Generate 3 random jobs
		var daily_jobs = []
		
		# For first day or if we want an easy job guaranteed:
		if current_day <= 1:
			if job_keys.has("cleaning_service"):
				_add_daily_job("cleaning_service", all_jobs["cleaning_service"], daily_jobs)
				job_keys.erase("cleaning_service")
				
		job_keys.shuffle()
		
		while daily_jobs.size() < 3 and job_keys.size() > 0:
			var j_id = job_keys.pop_front()
			_add_daily_job(j_id, all_jobs[j_id], daily_jobs)
			
		player["daily_jobs"] = daily_jobs
		SaveManager.save_game()

func _add_daily_job(j_id: String, job_data: Dictionary, target_array: Array) -> void:
	var s_min = int(job_data.get("salary_min", 0))
	var s_max = int(job_data.get("salary_max", 0))
	var offered = s_min
	if s_max > s_min:
		offered = s_min + randi() % (s_max - s_min + 1)
		
	target_array.append({
		"job_id": j_id,
		"offered_salary": offered,
		"applied": false
	})

func refresh_jobs() -> void:
	for child in job_list.get_children():
		child.queue_free()
		
	var player = SaveManager.get_player()
	var daily_jobs = player.get("daily_jobs", [])
	
	var all_jobs = DataManager.get_all_jobs()
	
	# add empty state if no jobs
	if daily_jobs.is_empty():
		var lbl = Label.new()
		lbl.text = "Tidak ada lowongan tersedia hari ini."
		job_list.add_child(lbl)
		return
	
	for i in range(daily_jobs.size()):
		var d_job = daily_jobs[i]
		var j_id = d_job["job_id"]
		var job = all_jobs.get(j_id, {})
		if job.is_empty(): continue
		
		var panel = PanelContainer.new()
		var vbox = VBoxContainer.new()
		panel.add_child(vbox)
		
		var label = Label.new()
		label.text = "%s\nGaji: Rp %d / hari\nDurasi: %d menit" % [job.get("name", ""), int(d_job["offered_salary"]), int(job.get("work_duration", 0))]
		vbox.add_child(label)
		
		var req_skills = job.get("required_skill", {})
		if not req_skills.is_empty():
			var sk_lbl = Label.new()
			sk_lbl.text = "Syarat Skill:"
			for sk in req_skills:
				sk_lbl.text += "\n- %s: %d" % [sk.capitalize(), int(req_skills[sk])]
			sk_lbl.add_theme_color_override("font_color", Color.LIGHT_GRAY)
			vbox.add_child(sk_lbl)
			
		var apply_btn = Button.new()
		if d_job.get("applied", false):
			apply_btn.text = "Sudah Dilamar"
			apply_btn.disabled = true
		else:
			apply_btn.text = "Lamar Pekerjaan"
			apply_btn.pressed.connect(func(): _apply_job(i, j_id, d_job["offered_salary"]))
		vbox.add_child(apply_btn)
		
		job_list.add_child(panel)

func _apply_job(index: int, job_id: String, offered_salary: int) -> void:
	if current_character == null: return
	
	var job = DataManager.get_job(job_id)
	var char_skills = current_character.get_skills()
	var req_skills = job.get("required_skill", {})
	
	var qualified = true
	for sk in req_skills:
		if int(char_skills.get(sk, 0)) < int(req_skills[sk]):
			qualified = false
			break
			
	var player = SaveManager.get_player()
	if not player.has("emails"):
		player["emails"] = []
	var emails = player.get("emails", [])
	
	if qualified:
		emails.append({
			"id": str(Time.get_unix_time_from_system()),
			"type": "job_offer",
			"job_id": job_id,
			"offered_salary": offered_salary,
			"title": "Tawaran Kerja: " + job.get("name", ""),
			"sender": "HRD",
			"body": "Selamat! Lamaran Anda untuk posisi " + job.get("name", "") + " telah diterima dengan penawaran gaji sebesar Rp " + str(offered_salary) + ".\nSilakan konfirmasi untuk mengambil pekerjaan ini.",
			"read": false
		})
	else:
		emails.append({
			"id": str(Time.get_unix_time_from_system()),
			"type": "job_reject",
			"title": "Penolakan Lamaran",
			"sender": "HRD",
			"body": "Mohon maaf, Anda belum memenuhi kualifikasi untuk posisi " + job.get("name", "") + ".\nTingkatkan skill Anda dan coba lagi nanti.",
			"read": false
		})
		
	# Mark as applied
	var daily_jobs = player.get("daily_jobs", [])
	if index >= 0 and index < daily_jobs.size():
		daily_jobs[index]["applied"] = true
		SaveManager.save_game()
		
	print("Lamaran dikirim. Cek email!")
	refresh_jobs()

func _on_close() -> void:
	UiManager.fade_out(self)

func _exit_tree() -> void:
	UiManager.unregister_ui("job_portal_ui")
