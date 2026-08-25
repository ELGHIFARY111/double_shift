extends CanvasLayer

@onready var day_label = $MarginContainer/VBoxContainer/Panel/HBoxContainer/dayLabel
@onready var time_label = $MarginContainer/VBoxContainer/Panel/HBoxContainer/timeLabel
@onready var speed_button = $MarginContainer/VBoxContainer/speedButton
@onready var money_label = $MarginContainer/VBoxContainer/Panel2/moneyLabel
@onready var status_button = $MarginContainerRight/VBoxContainerRight/statusButton
@onready var status_panel = $windows/statusPanel
@onready var family_status_button = $MarginContainerRight/VBoxContainerRight/familyStatusButton
@onready var family_status_panel = $windows/familyStatusPanel
@onready var family_hygiene_bar = $windows/familyStatusPanel/MarginContainer/VBoxContainer/HygieneGrid/hygieneBar
@onready var family_burden_bar = $windows/familyStatusPanel/MarginContainer/VBoxContainer/burdenBar
@onready var close_family_button = $windows/familyStatusPanel/MarginContainer/VBoxContainer/HBoxContainer/closeFamilyButton
@onready var character_name = $windows/statusPanel/MarginContainer/VBoxContainer/HBoxContainer/characterName
@onready var energy_label = $windows/statusPanel/MarginContainer/VBoxContainer/StatsGrid/energyLabel
@onready var energy_bar = $windows/statusPanel/MarginContainer/VBoxContainer/StatsGrid/energyBar
@onready var hunger_label = $windows/statusPanel/MarginContainer/VBoxContainer/StatsGrid/hungerLabel
@onready var hunger_bar = $windows/statusPanel/MarginContainer/VBoxContainer/StatsGrid/hungerBar
@onready var stress_label = $windows/statusPanel/MarginContainer/VBoxContainer/StatsGrid/stressLabel
@onready var stress_bar = $windows/statusPanel/MarginContainer/VBoxContainer/StatsGrid/stressBar

@onready var skill_list = $windows/statusPanel/MarginContainer/VBoxContainer/DetailsScroll/DetailsVBox/SkillList
@onready var furniture_list = $windows/familyStatusPanel/MarginContainer/VBoxContainer/FamilyDetailsScroll/FamilyDetailsVBox/FurnitureList
@onready var interact_prompt = $InteractProm

@onready var transition_rect = $dayTransitionLayer/transitionRect
@onready var transition_label = $dayTransitionLayer/transitionRect/dayLabel
@onready var action_menu = $actionMenu
@onready var travel_panel = $travelPanel
@onready var map_selection_ui = $MapSelectionUi
@onready var inventory_ui = $InventoryUi
@onready var career_ui = $CareerUi
@onready var close_button = $windows/statusPanel/MarginContainer/VBoxContainer/HBoxContainer/closeButton

func _process(_delta):
	if status_panel.visible:
		update_status()
	if family_status_panel != null and family_status_panel.visible:
		update_family_status()

func _ready() -> void:
	status_panel.hide()

	UiManager.register_ui("interact_prompt", interact_prompt)
	UiManager.register_ui("action_menu", action_menu)
	UiManager.register_ui("travel_panel", travel_panel)
	UiManager.register_ui("map_selection", map_selection_ui)
	UiManager.register_ui("inventory", inventory_ui)
	UiManager.register_ui("career_ui", career_ui)
	UiManager.register_ui("status_panel", status_panel)

	TimeManager.minute_changed.connect(_on_minute_changed)
	TimeManager.day_changed.connect(_on_day_changed)
	TimeManager.morning_arrived.connect(_on_morning_arrived)
	SaveManager.money_changed.connect(_on_money_changed)
	_on_money_changed(SaveManager.get_money())



	status_button.pressed.connect(show_status)
	close_button.pressed.connect(hide_status)
	if family_status_button != null:
		family_status_button.pressed.connect(show_family_status)
	if close_family_button != null:
		close_family_button.pressed.connect(hide_family_status)

	_refresh_clock()

func _on_morning_arrived(day: int) -> void:
	transition_label.text = "DAY %d" % day
	
	var tween = create_tween()
	tween.tween_property(transition_rect, "modulate", Color(1, 1, 1, 1), 0.5)
	tween.tween_interval(2.0)
	tween.tween_property(transition_rect, "modulate", Color(1, 1, 1, 0), 1.0)

func show_status():
	status_panel.show()
	if family_status_panel != null: family_status_panel.hide()
	update_status()

func hide_status():
	status_panel.hide()

func show_family_status():
	if family_status_panel != null:
		family_status_panel.show()
		status_panel.hide()
		update_family_status()

func hide_family_status():
	if family_status_panel != null:
		family_status_panel.hide()
func _on_money_changed(amount:int):
	money_label.text = str(amount)
func update_status():
	var character = GameManager.active_character
	if character == null:
		return
	var data: Dictionary = character.get_data()
	var stats = data["stats"]
	
	var job = data.get("job", {})
	var current_job = job.get("current_job", "")
	var job_name = "Pengangguran"
	if current_job != "":
		var job_data = DataManager.get_job(current_job)
		if not job_data.is_empty():
			job_name = job_data.get("name", "Pekerja")
			
	var full_text = data["name"] + " | " + job_name
	character_name.text = full_text
	
	var base_font_size = 40
	var min_font_size = 12
	var max_width = 180
	var current_font_size = base_font_size
	var font = character_name.get_theme_font("font")
	
	while current_font_size > min_font_size:
		var text_size = font.get_string_size(full_text, HORIZONTAL_ALIGNMENT_LEFT, -1, current_font_size)
		if text_size.x <= max_width:
			break
		current_font_size -= 1
		
	character_name.add_theme_font_size_override("font_size", current_font_size)
	#energy_label.text = "Energy : %d" % stats["energy"]
	#hunger_label.text = "Hunger : %d" % stats["hunger"]
	#stress_label.text = "Stress : %d" % stats["stress"]
	#hygiene_label.text = "Kebersihan : %d" % stats.get("hygiene", 100)
	energy_bar.value = stats["energy"]
	hunger_bar.value = stats["hunger"]
	stress_bar.value = stats["stress"]
	
	for child in skill_list.get_children():
		child.queue_free()
	for child in furniture_list.get_children():
		child.queue_free()
		
	var skills = character.get_skills()
	if skills.is_empty():
		var lbl = Label.new()
		lbl.text = "Tidak ada skill"
		lbl.add_theme_font_size_override("font_size", 30)
		skill_list.add_child(lbl)
	else:
		for skill_name in skills:
			var lbl = Label.new()
			lbl.text = "%s: %d" % [skill_name.capitalize(), skills[skill_name]]
			lbl.add_theme_font_size_override("font_size", 30)
			skill_list.add_child(lbl)

func update_family_status():
	var player = SaveManager.get_player()
	family_hygiene_bar.value = player.get("family_hygiene", 100.0)
	
	var burden = player.get("family_burden", {})
	var kiki = float(burden.get("kiki", 0.0))
	var jefri = float(burden.get("jefri", 0.0))
	var total = kiki + jefri
	
	if total <= 0:
		family_burden_bar.value = 50.0
	else:
		family_burden_bar.value = (kiki / total) * 100.0
		
	for child in furniture_list.get_children():
		child.queue_free()
		
	var owned_furnitures = SaveManager.get_furniture()
	var has_furn_effect = false
	for furn_id in owned_furnitures:
		var level = int(owned_furnitures[furn_id])
		if level <= 0:
			continue
		var furn_data = DataManager.get_furniture(furn_id)
		if furn_data.is_empty():
			continue
		var levels = furn_data.get("levels", [])
		if level <= levels.size():
			var effects = levels[level-1].get("effects", {})
			if not effects.is_empty():
				has_furn_effect = true
				var effect_text = "%s (Lv %d): " % [furn_data.get("name", "Furnitur"), level]
				var effect_strings = []
				for key in effects:
					effect_strings.append("%s %s" % [key.capitalize(), str(effects[key])])
				effect_text += ", ".join(effect_strings)
				
				var lbl = Label.new()
				lbl.text = effect_text
				lbl.add_theme_font_size_override("font_size", 30)
				lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
				furniture_list.add_child(lbl)
				
	if not has_furn_effect:
		var lbl = Label.new()
		lbl.text = "Tidak ada efek"
		lbl.add_theme_font_size_override("font_size", 30)
		furniture_list.add_child(lbl)
		
func _get_day_name(day: int) -> String:
	var days = ["Sabtu", "Minggu", "Senin", "Selasa", "Rabu", "Kamis", "Jumat"]
	return days[(day - 1) % 7]

func _refresh_clock():
	var day = SaveManager.get_day()
	day_label.text = "%s ,Day %d," % [_get_day_name(day), day]
	time_label.text = "%02d:%02d" % [
		SaveManager.get_hour(),
		SaveManager.get_minute()
	]

	money_label.text = "Rp %d" % SaveManager.get_money()

	speed_button.text = "x%d" % TimeManager.get_speed()


func _on_minute_changed(hour:int, minute:int):
	time_label.text = "%02d:%02d" % [hour, minute]


func _on_day_changed(day:int):
	day_label.text = "%s (Day %d)" % [_get_day_name(day), day]


func _on_speed_pressed():
	TimeManager.cycle_speed()
	speed_button.text = "x%d" % TimeManager.get_speed()
func _exit_tree() -> void:

	UiManager.unregister_ui("interact_prompt")
	UiManager.unregister_ui("action_menu")
	UiManager.unregister_ui("travel_panel")
	UiManager.unregister_ui("map_selection")
	UiManager.unregister_ui("inventory")
	UiManager.unregister_ui("status_panel")
