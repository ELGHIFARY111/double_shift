extends ProgressBar

@export var tracked_activities: Array[String] = ["cook", "travel", "work", "wash_clothes", "wash_dishes", "sleep", "clean_room", "watch_tv"]

var current_character: CharacterBody2D = null

func _ready() -> void:
	hide()
	# The script assumes this is placed as a child of the CharacterBody2D
	if get_parent() is CharacterBody2D:
		current_character = get_parent()
	else:
		# Fallback if we decide to place it outside, but we should inject the character
		pass

func _process(_delta: float) -> void:
	if current_character == null or !is_instance_valid(current_character):
		hide()
		return
		
	var activity = current_character.get_activity()
	var current_act = activity.get("current_activity", "")
	
	if current_act in tracked_activities:
		var time_left = float(activity.get("time_left", 0))
		var duration = float(activity.get("duration", 1))
		var total_duration = duration
		
		if current_act == "cook":
			var queue = SaveManager.get_cooking_queue()
			for q in queue:
				time_left += float(q.get("time", 0))
				
			if not activity.has("queue_total_duration"):
				activity["queue_total_duration"] = time_left
				
			total_duration = float(activity.get("queue_total_duration", time_left))
			
			if time_left > total_duration:
				total_duration = time_left
				activity["queue_total_duration"] = total_duration
				
		var progress = 1.0 - (time_left / max(total_duration, 1.0))
		
		value = progress
		
		if !visible:
			show()
	else:
		if activity.has("queue_total_duration"):
			activity.erase("queue_total_duration")
		if visible:
			hide()
