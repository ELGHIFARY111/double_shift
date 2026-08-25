extends Node

var _ui: Dictionary = {}


func register_ui(id: String, node: Node) -> void:
	if id == "":
		return

	if node == null:
		return

	_ui[id] = node


func unregister_ui(id: String) -> void:
	if _ui.has(id):
		_ui.erase(id)


func get_ui_node(id: String) -> Node:
	if !_ui.has(id):
		return null

	var node: Node = _ui[id]

	if node == null:
		return null

	if !is_instance_valid(node):
		_ui.erase(id)
		return null

	return node


func has_ui(id: String) -> bool:
	return get_ui_node(id) != null

func is_any_blocking_ui_open() -> bool:
	var blocking_uis = ["inventory", "travel_panel", "cooking_ui", "job_portal_ui", "cleaning_ui", "email_ui", "shop", "map_selection"]
	for id in blocking_uis:
		var node = get_ui_node(id)
		if node != null and node is CanvasItem and node.visible:
			return true
	return false


func show_ui(id: String) -> void:
	var node := get_ui_node(id)
	if node == null:
		return
	if node is CanvasItem:
		fade_in(node)

func hide_ui(id: String) -> void:
	var node := get_ui_node(id)
	if node == null:
		return
	if node is CanvasItem:
		fade_out(node)

func fade_in(node: CanvasItem, duration: float = 0.2) -> void:
	if not node: return
	if not node.visible:
		node.modulate.a = 0.0
		node.show()
	var tween = node.create_tween()
	tween.tween_property(node, "modulate:a", 1.0, duration).set_trans(Tween.TRANS_SINE)

func fade_out(node: CanvasItem, duration: float = 0.2) -> void:
	if not node: return
	if not node.visible: return
	var tween = node.create_tween()
	tween.tween_property(node, "modulate:a", 0.0, duration).set_trans(Tween.TRANS_SINE)
	tween.tween_callback(func(): node.hide())

func toggle_ui(id: String) -> void:
	var node := get_ui_node(id)
	if node == null:
		return
	if node is CanvasItem:
		if node.visible and node.modulate.a > 0.5:
			fade_out(node)
		else:
			fade_in(node)


func call_ui(id: String, method: String, args: Array = []) -> Variant:
	var node := get_ui_node(id)

	if node == null:
		return null

	if !node.has_method(method):
		push_warning("%s tidak memiliki method %s" % [id, method])
		return null

	return node.callv(method, args)


func toggle_inventory() -> void:
	toggle_ui("inventory")


func close_all() -> void:

	hide_ui("inventory")
	hide_ui("travel_panel")
	hide_ui("action_menu")
	hide_ui("interact_prompt")
	hide_ui("cooking_ui")
	hide_ui("job_portal_ui")
	hide_ui("cleaning_ui")
	hide_ui("email_ui")
