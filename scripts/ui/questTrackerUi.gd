extends MarginContainer

@onready var title_label = $VBoxContainer/TitleLabel
@onready var desc_label = $VBoxContainer/DescLabel
@onready var obj_container = $VBoxContainer/ObjectivesContainer

func _ready() -> void:
	UiManager.register_ui("quest_tracker", self)
	QuestManager.quest_updated.connect(refresh)
	refresh()

func refresh(quest_id: String = "") -> void:
	for child in obj_container.get_children():
		child.queue_free()
		
	var active_id = QuestManager.get_active_quest()
	if active_id == "":
		title_label.text = "Tidak ada misi aktif"
		desc_label.text = ""
		return
		
	var q_data = DataManager.get_quest(active_id)
	if q_data.is_empty():
		return
		
	var state = QuestManager.get_objectives_progress()
	
	title_label.text = q_data.get("quest_name", "Misi")
	desc_label.text = q_data.get("description", "")
	
	for obj in q_data.get("objectives", []):
		var l = Label.new()
		var max_v = int(obj.get("target", 1))
		var cur_v = int(state.get(obj.get("id", ""), 0))
		l.text = "- " + obj.get("description", "") + " (" + str(cur_v) + "/" + str(max_v) + ")"
		if cur_v >= max_v:
			l.add_theme_color_override("font_color", Color.GREEN)
		obj_container.add_child(l)

func _exit_tree() -> void:
	UiManager.unregister_ui("quest_tracker")
