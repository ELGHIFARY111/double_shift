extends Node


func _ready() -> void:
	WorldManager.map_changed.connect(_on_map_changed)


func refresh() -> void:

	var objects_root := WorldManager.get_object_layer()

	if objects_root == null:
		return

	var owned := SaveManager.get_furniture()
	var all_furniture := DataManager.get_all_furniture()

	for furniture_id: String in all_furniture.keys():

		var node := objects_root.get_node_or_null(furniture_id)

		if node == null:
			continue

		var level := int(owned.get(furniture_id, 0))

		_apply_furniture_state(node, level)


func action_or_upgrade(furniture_id: String) -> void:

	var player_furniture := SaveManager.get_furniture()

	var owned_level := int(player_furniture.get(furniture_id, 0))

	var furniture_data := DataManager.get_furniture(furniture_id)

	if furniture_data.is_empty():
		return

	# =====================
	# BELI
	# =====================

	if owned_level == 0:

		var buy_price := int(
			furniture_data.get("buy_price", 0)
		)

		if SaveManager.get_money() < buy_price:
			print("Uang tidak cukup")
			return

		SaveManager.add_money(-buy_price)

		player_furniture[furniture_id] = 1

		SaveManager.save_game()

		refresh()

		return

	# =====================
	# UPGRADE
	# =====================

	if !bool(furniture_data.get("upgradeable", false)):
		return

	var levels: Array = furniture_data.get("levels", [])

	if owned_level >= levels.size():
		return

	var level_data: Dictionary = levels[owned_level]

	var price := int(
		level_data.get("upgrade_price", 0)
	)

	if SaveManager.get_money() < price:
		print("Uang tidak cukup")
		return

	SaveManager.add_money(-price)

	player_furniture[furniture_id] = owned_level + 1

	SaveManager.save_game()

	refresh()


func _apply_furniture_state(
	node: Node,
	level: int
) -> void:

	var unlocked := level > 0

	node.visible = unlocked

	node.process_mode = (
		Node.PROCESS_MODE_INHERIT
		if unlocked
		else Node.PROCESS_MODE_DISABLED
	)

	_set_collision(node, unlocked)

	_update_level(node, level)


func _set_collision(
	node: Node,
	enabled: bool
) -> void:

	for child in node.get_children():

		if child is CollisionShape2D:
			child.disabled = !enabled


func _update_level(
	node: Node,
	level: int
) -> void:

	for child in node.get_children():

		if child.name.begins_with("Lv"):
			child.visible = (
				child.name == "Lv%d" % level
			)

func _get_objects_root() -> Node:
	var world := WorldManager.get_current_world()

	if world == null:
		return null

	var objects := world.get_node_or_null("objects")

	if objects == null:
		objects = world.get_node_or_null("Objects")

	return objects
func _on_map_changed(_map_id: String) -> void:
	refresh()
