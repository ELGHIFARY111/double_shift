extends Node

signal quest_updated(quest_id: String)
signal quest_completed(quest_id: String)

func _ready():
	if not Engine.is_editor_hint():
		TimeManager.day_changed.connect(_on_day_changed)
		SaveManager.game_loaded.connect(_on_game_loaded)

func _on_game_loaded():
	_on_day_changed(SaveManager.get_day())

func _on_day_changed(day: int):
	# Check if any quest triggers today
	var active = get_active_quest()
	if active != "":
		return # Already have an active quest
		
	var quests_db = DataManager.quests
	for q_id in quests_db:
		var q_data = quests_db[q_id]
		if q_data.has("trigger_day") and int(q_data["trigger_day"]) == day:
			if not is_quest_completed(q_id):
				advance_quest("", q_id)
				break

func get_quest_data() -> Dictionary:
	var player = SaveManager.get_player()
	if not player.has("quests"):
		player["quests"] = {
			"active": "",
			"objectives_progress": {},
			"completed": []
		}
	return player["quests"]

func get_active_quest() -> String:
	return get_quest_data().get("active", "")

func get_objectives_progress() -> Dictionary:
	return get_quest_data().get("objectives_progress", {})
	
func is_quest_completed(quest_id: String) -> bool:
	return quest_id in get_quest_data().get("completed", [])

func advance_quest(quest_id: String, next_quest_id: String):
	var q_data = get_quest_data()
	if quest_id not in q_data["completed"]:
		q_data["completed"].append(quest_id)
	q_data["active"] = next_quest_id
	q_data["objectives_progress"] = {}
	SaveManager.save_game()
	quest_completed.emit(quest_id)

func update_progress(objective_type: String, amount: int = 1):
	var active_id = get_active_quest()
	if active_id == "":
		return
		
	var quest_info = DataManager.get_quest(active_id)
	if quest_info.is_empty():
		return
		
	var objectives = quest_info.get("objectives", [])
	var q_data = get_quest_data()
	var progress = q_data.get("objectives_progress", {})
	
	var changed = false
	var all_completed = true
	
	for obj in objectives:
		var o_id = obj["id"]
		var o_type = obj["type"]
		var o_target = int(obj["target"])
		
		var curr_prog = int(progress.get(o_id, 0))
		
		if o_type == objective_type and curr_prog < o_target:
			curr_prog = min(curr_prog + amount, o_target)
			progress[o_id] = curr_prog
			changed = true
			
		if curr_prog < o_target:
			all_completed = false
			
	if changed:
		q_data["objectives_progress"] = progress
		SaveManager.save_game()
		quest_updated.emit(active_id)
		
	if all_completed and objectives.size() > 0:
		_complete_active_quest(active_id, quest_info)

func _complete_active_quest(quest_id: String, quest_info: Dictionary):
	# Give rewards
	var rewards = quest_info.get("rewards", {})
	if rewards.has("money"):
		SaveManager.add_money(int(rewards["money"]))
		
	var next_quest = quest_info.get("next_quest", "")
	advance_quest(quest_id, next_quest)
