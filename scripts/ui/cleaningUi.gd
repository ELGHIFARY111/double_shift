extends Control

@onready var title_label = $Panel/MarginContainer/VBoxContainer/Header/Title
@onready var close_button = $Panel/MarginContainer/VBoxContainer/Header/CloseButton
@onready var progress_label = $Panel/MarginContainer/VBoxContainer/ProgressLabel
@onready var progress_bar = $Panel/MarginContainer/VBoxContainer/ProgressBar
@onready var start_button = $Panel/MarginContainer/VBoxContainer/StartButton

var current_character: CharacterBody2D = null
var current_task: String = ""

func _ready() -> void:
	hide()
	UiManager.register_ui("cleaning_ui", self)
	close_button.pressed.connect(_on_close)
	start_button.pressed.connect(_on_start_pressed)

func open(character: CharacterBody2D, task: String) -> void:
	current_character = character
	current_task = task
	
	if task == "wash_clothes":
		title_label.text = "Mesin Cuci"
	elif task == "wash_dishes":
		title_label.text = "Mencuci Piring"
		
	refresh()
	UiManager.fade_in(self)
	
var visual_time_left: float = 0.0

func _process(delta: float) -> void:
	if current_character == null: return
	var act = current_character.get_activity()
	if str(act.get("current_activity", "")) == current_task:
		var actual_left = float(act.get("time_left", 0.0))
		var total = float(act.get("duration", 1.0))
		
		if visual_time_left == 0.0 or abs(visual_time_left - actual_left) > 2.0:
			visual_time_left = actual_left
		else:
			visual_time_left -= delta * TimeManager.get_speed()
			visual_time_left = max(0.0, visual_time_left)
			
		if total > 0:
			progress_bar.value = ((total - visual_time_left) / total) * 100.0
			progress_label.text = "Sedang membersihkan... (%d menit tersisa)" % int(visual_time_left)
			start_button.disabled = true
			start_button.text = "Sedang Berjalan"
	else:
		visual_time_left = 0.0
		refresh()

func refresh() -> void:
	if current_character == null: return
	progress_bar.value = 0.0
	var act = current_character.get_activity()
	var current_act = str(act.get("current_activity", ""))
	if current_act == "":
		var player = SaveManager.get_player()
		var dirty_level = 0
		if current_task == "wash_clothes":
			dirty_level = int(player.get("dirty_clothes", 0))
			progress_label.text = "Baju kotor menumpuk: %d%%. Siap dicuci." % dirty_level
		elif current_task == "wash_dishes":
			dirty_level = int(player.get("dirty_dishes", 0))
			progress_label.text = "Piring kotor menumpuk: %d buah. Siap dicuci." % dirty_level
			
		if dirty_level <= 0:
			progress_label.text = "Sudah bersih, tidak ada yang perlu dicuci."
			start_button.disabled = true
			start_button.text = "Bersih"
		else:
			start_button.disabled = false
			start_button.text = "Mulai"
	elif current_act == current_task:
		# handled in process
		pass
	else:
		progress_label.text = "Karakter sedang sibuk dengan aktivitas lain."
		start_button.disabled = true
		start_button.text = "Sibuk"

func _on_start_pressed() -> void:
	if current_character != null:
		ActivityManager.start_activity(current_character, current_task)

func _on_close() -> void:
	UiManager.fade_out(self)

func _exit_tree() -> void:
	UiManager.unregister_ui("cleaning_ui")
