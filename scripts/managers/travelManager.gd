extends Node

const MINUTES_PER_UNIT: float = 3.0


func travel(
	character: CharacterBody2D,
	destination_id: String
) -> void:

	if character == null:
		return

	var destination: Dictionary = DataManager.get_destination(destination_id)

	if destination.is_empty():
		push_error("Destination tidak ditemukan : " + destination_id)
		return

	if ActivityManager.is_busy(character):
		return

	var activity: Dictionary = character.get_activity()

	var origin_tile := CharacterManager.get_tile(character)
	var origin_map := CharacterManager.get_location(character)

	activity["target"] = destination_id
	activity["origin"] = {
		"map": origin_map,
		"tile_position": {
			"x": origin_tile.x,
			"y": origin_tile.y
		}
	}
	activity["returning"] = false

	SaveManager.save_game()

	var travel_time := _calculate_travel_time(origin_map, destination_id)

	ActivityManager.start_activity(
		character,
		"travel",
		travel_time
	)

	if character == GameManager.get_active_character():
		UiManager.call_ui(
			"travel_panel",
			"open",
			[character]
		)


func finish_travel(character: CharacterBody2D) -> void:
	if character == null:
		return
	var activity: Dictionary = character.get_activity()
	if bool(activity.get("returning", false)):
		_finish_return(character)
		return
	var destination_id: String = str(activity.get("target", ""))
	if destination_id == "":
		return
	var destination := DataManager.get_destination(destination_id)
	if destination.is_empty():
		return
	var spawn: Dictionary = destination.get("spawn_tile", {})
	var target_tile = Vector2i(
		int(spawn.get("x", 0)),
		int(spawn.get("y", 0))
	)
	
	CharacterManager.move_to(
		character,
		destination_id,
		target_tile
	)
	
	for follower in CharacterManager.get_all():
		if follower.get("_follow_target") == character:
			var follower_tile = target_tile + Vector2i(1, 0)
			CharacterManager.move_to(
				follower,
				destination_id,
				follower_tile
			)
			
	activity["target"] = ""
	activity["origin"] = {}
	activity["returning"] = false
	SaveManager.save_game()
	ActivityManager.finish_activity(character)

	if character == GameManager.get_active_character():
		await WorldManager.change_map(destination_id)

	UiManager.hide_ui("travel_panel")


func cancel_travel(character: CharacterBody2D) -> void:

	if character == null:
		return

	var activity: Dictionary = character.get_activity()

	if str(activity.get("current_activity", "")) != "travel":
		return

	if bool(activity.get("returning", false)):
		return

	var duration := int(activity.get("duration", 0))
	var time_left := int(activity.get("time_left", 0))
	var travelled := duration - time_left

	if travelled <= 0:
		_finish_return(character)
		return

	activity["returning"] = true
	activity["time_left"] = travelled

	SaveManager.save_game()

	if character == GameManager.get_active_character():
		UiManager.call_ui(
			"travel_panel",
			"refresh"
		)


func _finish_return(character: CharacterBody2D) -> void:

	var activity: Dictionary = character.get_activity()

	var origin: Dictionary = activity.get("origin", {})

	if origin.is_empty():
		return

	var tile: Dictionary = origin.get("tile_position", {})
	var map_id = str(origin.get("map", ""))
	var target_tile = Vector2i(
		int(tile.get("x", 0)),
		int(tile.get("y", 0))
	)

	CharacterManager.move_to(
		character,
		map_id,
		target_tile
	)
	
	for follower in CharacterManager.get_all():
		if follower.get("_follow_target") == character:
			var follower_tile = target_tile + Vector2i(1, 0)
			CharacterManager.move_to(
				follower,
				map_id,
				follower_tile
			)

	ActivityManager.finish_activity(character)
	activity["target"] = ""
	activity["origin"] = {}
	activity["returning"] = false

	SaveManager.save_game()
	if character == GameManager.get_active_character():
		WorldManager.change_map(
			CharacterManager.get_location(character)
		)

	UiManager.hide_ui("travel_panel")


func _calculate_travel_time(origin_id: String, destination_id: String) -> int:
	var origin_data: Dictionary = DataManager.get_destination(origin_id)
	var dest_data: Dictionary = DataManager.get_destination(destination_id)

	# Get map positions
	var origin_pos: Dictionary = origin_data.get("map_position", {})
	var dest_pos: Dictionary = dest_data.get("map_position", {})

	# If either location has no map_position, fallback to destination's fixed travel_time
	if origin_pos.is_empty() or dest_pos.is_empty():
		return int(dest_data.get("travel_time", 0))

	# Calculate Manhattan distance
	var dx: float = abs(float(dest_pos.get("x", 0)) - float(origin_pos.get("x", 0)))
	var dy: float = abs(float(dest_pos.get("y", 0)) - float(origin_pos.get("y", 0)))
	var distance: float = dx + dy

	var travel_time: int = int(ceil(distance * MINUTES_PER_UNIT))

	# Minimum 1 minute for any travel
	return max(travel_time, 1)
