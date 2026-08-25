extends Node

signal activity_started(character, activity_id)
signal activity_finished(character, activity_id)

var running: bool = false


func _ready() -> void:
	SaveManager.game_loaded.connect(_on_game_loaded)
	SaveManager.game_closed.connect(_on_game_closed)
	TimeManager.minute_changed.connect(_on_minute_changed)
	TimeManager.day_changed.connect(_on_day_changed)


func _on_game_loaded() -> void:
	running = true


func _on_game_closed() -> void:
	running = false


func _on_minute_changed(_hour: int, minute: int) -> void:
	if !running:
		return

	for character: CharacterBody2D in CharacterManager.get_all():
		update_character(character)

	if minute % 30 == 0:
		for character: CharacterBody2D in CharacterManager.get_all():
			update_status(character)
			
		# Family Status update (sekali per 30 menit)
		var player = SaveManager.get_player()
		player["dirty_clothes"] = minf(float(player.get("dirty_clothes", 0.0)) + 1.0, 100.0)
		var is_dirty = false
		if float(player.get("dirty_clothes", 0.0)) >= 100.0:
			is_dirty = true
		if int(player.get("dirty_dishes", 0)) >= 20:
			is_dirty = true
			
		if is_dirty:
			player["family_hygiene"] = max(0, float(player.get("family_hygiene", 100.0)) - 2.0)
		else:
			player["family_hygiene"] = min(100.0, float(player.get("family_hygiene", 100.0)) + 1.0)
			
		SaveManager.save_game()


func start_activity(
	character: CharacterBody2D,
	activity_id: String,
	duration: int = -1,
	target: String = ""
) -> void:

	if !running:
		return

	if character == null:
		return

	var activity: Dictionary = character.get_activity()

	if str(activity.get("current_activity", "")) != "":
		return

	var data: Dictionary = DataManager.get_activity(activity_id)

	if data.is_empty():
		push_error("Activity tidak ditemukan : " + activity_id)
		return

	var final_duration: int

	if duration >= 0:
		final_duration = duration
	else:
		final_duration = int(data.get("duration", 0))

	if activity_id == "work":
		var current_hour = TimeManager.get_hour()
		if current_hour >= 9:
			activity["is_late"] = true
			print("Karakter terlambat absen. Mempersiapkan potong gaji 10%.")
		else:
			activity["is_late"] = false
			
		var job = character.get_job()
		var current_job = job.get("current_job", "")
		if current_job != "":
			var job_data = DataManager.get_job(current_job)
			if not job_data.is_empty():
				if duration < 0:
					final_duration = int(job_data.get("work_duration", final_duration))
		
		job["last_worked_day"] = SaveManager.get_day()
		job["missed_work_days"] = 0
					
	var owned_furnitures = SaveManager.get_furniture()
	
	if activity_id == "cook" and owned_furnitures.has("kompor"):
		var level = int(owned_furnitures["kompor"])
		var furn_data = DataManager.get_furniture("kompor")
		if level > 0 and not furn_data.is_empty():
			var levels = furn_data.get("levels", [])
			if level <= levels.size():
				var effects = levels[level-1].get("effects", {})
				if effects.has("cook_speed"):
					final_duration = int(float(final_duration) * float(effects["cook_speed"]))

	if activity_id == "wash_clothes" and owned_furnitures.has("mesin_cuci"):
		var level = int(owned_furnitures["mesin_cuci"])
		var furn_data = DataManager.get_furniture("mesin_cuci")
		if level > 0 and not furn_data.is_empty():
			var levels = furn_data.get("levels", [])
			if level <= levels.size():
				var effects = levels[level-1].get("effects", {})
				if effects.has("wash_speed"):
					final_duration = int(float(final_duration) * float(effects["wash_speed"]))

	activity["current_activity"] = activity_id
	activity["duration"] = final_duration
	activity["time_left"] = final_duration
	activity["progress"] = 0
	if target != "":
		activity["target"] = target

	SaveManager.save_game()

	activity_started.emit(character, activity_id)
	if activity_id == "sleep" or activity_id == "npc_sleep":
		check_family_sleep()


func finish_activity(character: CharacterBody2D) -> void:

	if character == null:
		return

	var activity: Dictionary = character.get_activity()

	activity["current_activity"] = ""
	activity["duration"] = 0
	activity["time_left"] = 0
	activity["progress"] = 0
	activity["target"] = ""

	SaveManager.save_game()


func update_character(character: CharacterBody2D) -> void:

	if character == null:
		return

	var activity: Dictionary = character.get_activity()

	var current: String = str(activity.get("current_activity", ""))

	if current == "":
		return

	if current == "sleep" or current == "npc_sleep":
		return

	activity["time_left"] = max(
		int(activity.get("time_left", 0)) - 1,
		0
	)

	if int(activity["time_left"]) > 0:
		return

	_apply_reward(character, current)
	
	# Tambahkan beban mental
	var player = SaveManager.get_player()
	var burden_dict = player.get("family_burden", {})
	var c_id = character.character_id
	if c_id == "kiki" or c_id == "jefri":
		var burden_added = 0
		if current == "cook": burden_added = 10
		elif current == "wash_dishes": burden_added = 5
		elif current == "wash_clothes": burden_added = 15
		elif current == "work": burden_added = 20
		
		if burden_added > 0:
			burden_dict[c_id] = float(burden_dict.get(c_id, 0.0)) + burden_added
			player["family_burden"] = burden_dict

	if current == "travel":
		TravelManager.finish_travel(character)
	elif current == "wash_clothes":
		player["dirty_clothes"] = 0.0
		finish_activity(character)
	elif current == "wash_dishes":
		player["dirty_dishes"] = 0
		QuestManager.update_progress("wash_dishes", 1)
		finish_activity(character)
	elif current == "cook":
		var target = str(activity.get("target", ""))
		if target != "":
			var recipe = DataManager.get_recipe(target)
			if !recipe.is_empty():
				InventoryManager.add_item(recipe["result"]["item_id"], recipe["result"]["amount"])
				
		var queue = SaveManager.get_cooking_queue()
		if queue.size() > 0:
			var next_item = queue.pop_front()
			activity["target"] = next_item["recipe_id"]
			activity["duration"] = next_item["time"]
			activity["time_left"] = next_item["time"]
			activity["progress"] = 0
			SaveManager.save_game()
			activity_started.emit(character, current) # Emit signal to notify UI of new sub-activity
			return
			
		finish_activity(character)
	else:
		finish_activity(character)

	activity_finished.emit(character, current)


func _on_day_changed(day: int) -> void:
	var chars = SaveManager.data.get("player", {}).get("characters", {})
	for char_id in chars:
		var char_data = chars[char_id]
		var job = char_data.get("job", {})
		if job.get("current_job", "") != "":
			var last_worked = int(job.get("last_worked_day", 0))
			if last_worked < day - 1:
				var missed = int(job.get("missed_work_days", 0)) + 1
				job["missed_work_days"] = missed
				if missed >= 3:
					job["current_job"] = ""
					job["missed_work_days"] = 0
					job["last_worked_day"] = 0
					job["current_salary"] = 0
					
					var player = SaveManager.get_player()
					var emails = player.get("emails", [])
					emails.append({
						"id": str(Time.get_unix_time_from_system()),
						"type": "fired",
						"title": "Pemberhentian Kerja",
						"sender": "HRD",
						"body": "Anda telah dipecat karena mangkir kerja selama 3 hari berturut-turut.",
						"read": false
					})
					player["emails"] = emails
	SaveManager.save_game()

func update_status(character: CharacterBody2D) -> void:

	if character == null:
		return

	character.add_hunger(-1)
	character.add_energy(-1)

	var stats: Dictionary = character.get_stats()

	if int(stats.get("energy", 0)) < 30:
		character.add_stress(1)

	if int(stats.get("hunger", 0)) < 20:
		character.add_stress(1)


func is_busy(character: CharacterBody2D) -> bool:

	if character == null:
		return false

	var activity: Dictionary = character.get_activity()

	return str(activity.get("current_activity", "")) != ""


func get_current_activity(character: CharacterBody2D) -> String:

	if character == null:
		return ""

	var activity: Dictionary = character.get_activity()

	return str(activity.get("current_activity", ""))


func _apply_reward(
	character: CharacterBody2D,
	activity_id: String
) -> void:

	var data: Dictionary = DataManager.get_activity(activity_id)

	if data.is_empty():
		return

	var energy_reward = int(data.get("energy", 0))
						
	character.add_energy(energy_reward)

	character.add_hunger(
		int(data.get("hunger", 0))
	)

	character.add_stress(
		int(data.get("stress", 0))
	)



	var money: int = int(data.get("money", 0))

	if activity_id == "work":
		var job = character.get_job()
		var current_job = job.get("current_job", "")
		if current_job != "":
			money = int(job.get("current_salary", money))
			var activity_dict = character.get_activity()
			if activity_dict.get("is_late", false):
				money = int(float(money) * 0.9)

	if money != 0:
		SaveManager.add_money(money)

	var skill: String = str(data.get("skill", ""))

	if skill != "":
		character.add_skill(
			skill,
			int(data.get("skill_exp", 0))
		)

func check_family_sleep() -> void:
	var player = SaveManager.get_player()
	var chars = player.get("characters", {})
	var all_sleeping = true
	
	for char_id in chars:
		var char_data = chars[char_id]
		var activity = char_data.get("activity", {}).get("current_activity", "")
		if activity != "sleep" and activity != "npc_sleep":
			all_sleeping = false
			break
			
	if all_sleeping:
		TimeManager.skip_to_next_morning()
		
		var owned_furnitures = SaveManager.get_furniture()
		var bed_level = int(owned_furnitures.get("kasur", 0))
		var stress_reduction = 0
		var energy_recovery = 100
		
		if bed_level > 0:
			var furn_data = DataManager.get_furniture("kasur")
			if not furn_data.is_empty():
				var levels = furn_data.get("levels", [])
				if bed_level <= levels.size():
					var effects = levels[bed_level-1].get("effects", {})
					stress_reduction = int(effects.get("stress_reduction", 0))
					energy_recovery = int(effects.get("energy_recovery", 100))
		
		for char_id in chars:
			var char_node = CharacterManager.get_character(char_id)
			if char_node != null:
				char_node.add_energy(energy_recovery)
				char_node.add_stress(-stress_reduction)
				finish_activity(char_node)
			else:
				var char_data = chars[char_id]
				char_data["stats"]["energy"] = clampi(int(char_data["stats"].get("energy", 0)) + energy_recovery, 0, 100)
				char_data["stats"]["stress"] = max(0, int(char_data["stats"].get("stress", 0)) - stress_reduction)
				char_data["activity"]["current_activity"] = ""
				char_data["activity"]["time_left"] = 0
				char_data["activity"]["duration"] = 0
				char_data["activity"]["progress"] = 0
		SaveManager.save_game()
