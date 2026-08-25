extends NinePatchRect

@onready var close_button = $MarginContainer/VBoxContainer/header/closeButton
@onready var search_bar = $MarginContainer/VBoxContainer/body/leftPanel/searchBar
@onready var grid = $MarginContainer/VBoxContainer/body/leftPanel/ScrollContainer/GridContainer
@onready var item_name = $MarginContainer/VBoxContainer/body/rightPanel/MarginContainer/VBoxContainer/header/itemName
@onready var item_category = $MarginContainer/VBoxContainer/body/rightPanel/MarginContainer/VBoxContainer/header/itemCategory
@onready var item_icon = $MarginContainer/VBoxContainer/body/rightPanel/MarginContainer/VBoxContainer/itemIcon
@onready var description = $MarginContainer/VBoxContainer/body/rightPanel/MarginContainer/VBoxContainer/description
@onready var buy_price = $MarginContainer/VBoxContainer/body/rightPanel/MarginContainer/VBoxContainer/HBoxContainer/VBoxContainer2/buyPrice
@onready var upgrade_price = $MarginContainer/VBoxContainer/body/rightPanel/MarginContainer/VBoxContainer/HBoxContainer/VBoxContainer2/upgradePrice
@onready var effect_label = $MarginContainer/VBoxContainer/body/rightPanel/MarginContainer/VBoxContainer/HBoxContainer/VBoxContainer2/effectLabel
@onready var level_label = $MarginContainer/VBoxContainer/body/rightPanel/MarginContainer/VBoxContainer/HBoxContainer/VBoxContainer/levelLabel
@onready var action_button = $MarginContainer/VBoxContainer/body/rightPanel/MarginContainer/VBoxContainer/buttonContainer/actionButton

@export var slot_scene: PackedScene = preload("res://scenes/ui/furnitureSlotUi.tscn")

var selected_furniture_id := ""
var search_text := ""

func _ready() -> void:
	hide()
	UiManager.register_ui("furniture", self)
	close_button.pressed.connect(_on_close)
	search_bar.text_changed.connect(_on_search_changed)
	action_button.pressed.connect(_on_action_pressed)
	clear_info()

func open() -> void:
	refresh()
	UiManager.fade_in(self)

func _on_close() -> void:
	UiManager.fade_out(self)

func _on_search_changed(text: String) -> void:
	search_text = text.to_lower()
	refresh()

func _on_action_pressed() -> void:
	if selected_furniture_id.is_empty():
		return
	FurnitureManager.action_or_upgrade(selected_furniture_id)
	show_furniture(selected_furniture_id)
	refresh()

func refresh() -> void:
	for child in grid.get_children():
		child.queue_free()
	
	var furnitures = DataManager.get_all_furniture()
	for f_id in furnitures.keys():
		var f_data = furnitures[f_id]
		if search_text != "" and not f_data.get("name", "").to_lower().contains(search_text):
			continue
			
		var slot = slot_scene.instantiate()
		grid.add_child(slot)
		slot.setup(f_id)
		slot.clicked.connect(show_furniture)
	
	if selected_furniture_id != "":
		show_furniture(selected_furniture_id)

func show_furniture(f_id: String) -> void:
	selected_furniture_id = f_id
	var f_data = DataManager.get_furniture(f_id)
	if f_data.is_empty():
		return
		
	var owned_level = int(SaveManager.get_furniture().get(f_id, 0))
	
	item_name.text = f_data.get("name", "")
	item_category.text = "Furniture"
	item_icon.texture = load(f_data.get("icon", "res://icon.svg")) if f_data.has("icon") else null
	description.text = f_data.get("description", "")
	
	if owned_level == 0:
		buy_price.text = "Harga: Rp " + str(f_data.get("buy_price", 0))
		upgrade_price.text = ""
		level_label.text = "Belum Dimiliki"
		action_button.text = "Beli"
		action_button.disabled = SaveManager.get_money() < int(f_data.get("buy_price", 0))
	else:
		buy_price.text = "Dimiliki"
		level_label.text = "Level " + str(owned_level)
		
		if f_data.get("upgradeable", false):
			var levels = f_data.get("levels", [])
			if owned_level >= levels.size():
				upgrade_price.text = "Max Level"
				action_button.text = "Maks"
				action_button.disabled = true
			else:
				var next_level_data = levels[owned_level]
				var price = int(next_level_data.get("upgrade_price", 0))
				upgrade_price.text = "Upgrade: Rp " + str(price)
				action_button.text = "Upgrade"
				action_button.disabled = SaveManager.get_money() < price
		else:
			upgrade_price.text = ""
			action_button.text = "Sudah Punya"
			action_button.disabled = true
			
	effect_label.text = ""

func clear_info() -> void:
	item_name.text = ""
	item_category.text = ""
	item_icon.texture = null
	description.text = ""
	buy_price.text = ""
	upgrade_price.text = ""
	level_label.text = ""
	effect_label.text = ""
	action_button.disabled = true

func _exit_tree() -> void:
	UiManager.unregister_ui("furniture")
