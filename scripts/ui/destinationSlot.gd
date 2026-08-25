extends Button

signal selected(id)

var destination_id := ""

func setup(data: Dictionary, origin_map: String = "") -> void:

	destination_id = data["id"]

	var travel_time: int = _get_travel_time(origin_map, data)

	text = "%s (%d menit)" % [
		data["name"],
		travel_time
	]

func _get_travel_time(origin_map: String, dest_data: Dictionary) -> int:
	if origin_map == "":
		return int(dest_data.get("travel_time", 0))

	var origin_data: Dictionary = DataManager.get_destination(origin_map)
	var origin_pos: Dictionary = origin_data.get("map_position", {})
	var dest_pos: Dictionary = dest_data.get("map_position", {})

	if origin_pos.is_empty() or dest_pos.is_empty():
		return int(dest_data.get("travel_time", 0))

	var dx: float = abs(float(dest_pos.get("x", 0)) - float(origin_pos.get("x", 0)))
	var dy: float = abs(float(dest_pos.get("y", 0)) - float(origin_pos.get("y", 0)))
	var distance: float = dx + dy

	var travel_time: int = int(ceil(distance * TravelManager.MINUTES_PER_UNIT))

	return max(travel_time, 1)

func _pressed():
	selected.emit(destination_id)
