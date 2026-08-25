extends NinePatchRect

@export var slot_scene: PackedScene = preload("res://scenes/ui/cookingSlotUi.tscn")
@export var queue_slot_scene: PackedScene = preload("res://scenes/ui/cookingQueueSlotUi.tscn")

@onready var title_label = $MarginContainer/VBoxContainer/header/titleLabel
@onready var close_button = $MarginContainer/VBoxContainer/header/closeButton
@onready var grid = $MarginContainer/VBoxContainer/body/leftPanel/ScrollContainer/GridContainer
@onready var recipe_name = $MarginContainer/VBoxContainer/body/rightPanel/MarginContainer/VBoxContainer/recipeName
@onready var ingredients_list = $MarginContainer/VBoxContainer/body/rightPanel/MarginContainer/VBoxContainer/ingredientsList
@onready var result_label = $MarginContainer/VBoxContainer/body/rightPanel/MarginContainer/VBoxContainer/resultLabel
@onready var cook_time_label = $MarginContainer/VBoxContainer/body/rightPanel/MarginContainer/VBoxContainer/cookTimeLabel
@onready var cook_button = $MarginContainer/VBoxContainer/body/rightPanel/MarginContainer/VBoxContainer/cookButton
@onready var queue_container = $MarginContainer/VBoxContainer/queuePanel/ScrollContainer/queueContainer

var current_character: CharacterBody2D = null
var selected_recipe_id: String = ""

# cooking queue items
var cooking_queue: Array = []

func _ready() -> void:
	hide()
	UiManager.register_ui("cooking_ui", self)
	close_button.pressed.connect(_on_close)
	cook_button.pressed.connect(_on_cook_pressed)
	clear_detail()
	
func _process(delta: float) -> void:
	if cooking_queue.is_empty(): return
	var to_remove = []
	for i in range(cooking_queue.size()):
		var q = cooking_queue[i]
		q["time_left"] -= delta * TimeManager.get_speed()
		if q["time_left"] <= 0:
			var res = DataManager.get_recipe(q["recipe_id"]).get("result", {})
			InventoryManager.add_item(res.get("item_id", ""), res.get("amount", 1))
			to_remove.append(i)
		else:
			if is_instance_valid(q["ui_node"]):
				var max_time = q["max_time"]
				q["ui_node"].setup(q["recipe_id"], ((max_time - q["time_left"]) / max_time) * 100.0)
	
	to_remove.reverse()
	for i in to_remove:
		var q = cooking_queue[i]
		if is_instance_valid(q["ui_node"]):
			q["ui_node"].queue_free()
		cooking_queue.remove_at(i)
		
	if not to_remove.is_empty():
		refresh_recipes()

func open(character: CharacterBody2D) -> void:
	current_character = character
	refresh_recipes()
	UiManager.fade_in(self)

func _on_close() -> void:
	UiManager.fade_out(self)

func refresh_recipes() -> void:
	for child in grid.get_children():
		child.queue_free()
		
	var recipes = DataManager.get_all_recipes()
	for r_id in recipes.keys():
		var slot = slot_scene.instantiate()
		grid.add_child(slot)
		slot.setup({"id": r_id, "name": recipes[r_id].get("name", r_id)})
		slot.clicked.connect(show_recipe)

	if selected_recipe_id != "":
		show_recipe(selected_recipe_id)

func show_recipe(recipe_id: String) -> void:
	selected_recipe_id = recipe_id
	var r_data = DataManager.get_recipe(recipe_id)
	if r_data.is_empty():
		return
		
	recipe_name.text = r_data.get("name", "Resep")
	
	var plain_text = ""
	var can_cook = true
	var ingredients = r_data.get("ingredients", [])
	
	for ing in ingredients:
		var item_id = ing.get("item_id", "")
		var required = int(ing.get("amount", 1))
		var item_data = DataManager.get_item(item_id)
		var item_name = item_data.get("item_name", item_id) if not item_data.is_empty() else item_id
		var owned = InventoryManager.get_amount(item_id)
		
		plain_text += "- %s: %d/%d\n" % [item_name, owned, required]
		if owned < required:
			can_cook = false
			
	ingredients_list.text = plain_text
		
	var result_data = r_data.get("result", {})
	var res_item_id = result_data.get("item_id", "")
	var res_item_data = DataManager.get_item(res_item_id)
	var res_name = res_item_data.get("item_name", res_item_id) if not res_item_data.is_empty() else res_item_id
	var res_amount = result_data.get("amount", 1)
	
	result_label.text = "Hasil: %dx %s" % [res_amount, res_name]
	cook_time_label.text = "Waktu Masak: " + str(r_data.get("cook_time", 5)) + " menit"
	
	cook_button.disabled = not can_cook

func _on_cook_pressed() -> void:
	if selected_recipe_id == "": return
	
	var r_data = DataManager.get_recipe(selected_recipe_id)
	var ingredients = r_data.get("ingredients", [])
	
	var can_cook = true
	for ing in ingredients:
		if InventoryManager.get_amount(ing.get("item_id", "")) < int(ing.get("amount", 1)):
			can_cook = false
			break
			
	if not can_cook:
		return
		
	for ing in ingredients:
		InventoryManager.remove_item(ing.get("item_id", ""), int(ing.get("amount", 1)))
		
	var cook_time = float(r_data.get("cook_time", 5))
	
	var q_ui = queue_slot_scene.instantiate()
	queue_container.add_child(q_ui)
	q_ui.setup(selected_recipe_id, 0.0)
	
	var queue_item = {
		"recipe_id": selected_recipe_id,
		"time_left": cook_time,
		"max_time": cook_time,
		"ui_node": q_ui
	}
	
	q_ui.cancel_pressed.connect(func(): _on_cancel_cook(queue_item))
	cooking_queue.append(queue_item)
	
	refresh_recipes()

func _on_cancel_cook(queue_item: Dictionary) -> void:
	if cooking_queue.has(queue_item):
		var r_data = DataManager.get_recipe(queue_item["recipe_id"])
		var ingredients = r_data.get("ingredients", [])
		for ing in ingredients:
			InventoryManager.add_item(ing.get("item_id", ""), int(ing.get("amount", 1)))
		if is_instance_valid(queue_item["ui_node"]):
			queue_item["ui_node"].queue_free()
		cooking_queue.erase(queue_item)
		refresh_recipes()

func clear_detail() -> void:
	recipe_name.text = ""
	ingredients_list.text = ""
	result_label.text = ""
	cook_time_label.text = ""
	cook_button.disabled = true

func _exit_tree() -> void:
	UiManager.unregister_ui("cooking_ui")
