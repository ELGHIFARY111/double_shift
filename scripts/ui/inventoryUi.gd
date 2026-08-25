extends NinePatchRect

@export var slot_scene: PackedScene

@onready var grid = $MarginContainer/VBoxContainer/body/leftPanel/ScrollContainer/GridContainer

@onready var item_icon = $MarginContainer/VBoxContainer/body/rightPanel/NinePatchRect/MarginContainer/VBoxContainer/itemIcon
@onready var item_name = $MarginContainer/VBoxContainer/body/rightPanel/NinePatchRect/MarginContainer/VBoxContainer/header/itemName
@onready var item_category = $MarginContainer/VBoxContainer/body/rightPanel/NinePatchRect/MarginContainer/VBoxContainer/header/itemCategory
@onready var description = $MarginContainer/VBoxContainer/body/rightPanel/NinePatchRect/MarginContainer/VBoxContainer/description
@onready var buy_price = $MarginContainer/VBoxContainer/body/rightPanel/NinePatchRect/MarginContainer/VBoxContainer/HBoxContainer/VBoxContainer2/buyPrice
@onready var sell_price = $MarginContainer/VBoxContainer/body/rightPanel/NinePatchRect/MarginContainer/VBoxContainer/HBoxContainer/VBoxContainer2/sellPrice
@onready var quantity = $MarginContainer/VBoxContainer/body/rightPanel/NinePatchRect/MarginContainer/VBoxContainer/HBoxContainer/VBoxContainer2/quantity

@onready var use_button = $MarginContainer/VBoxContainer/body/rightPanel/NinePatchRect/MarginContainer/VBoxContainer/buttonContainer/useButton
@onready var sell_button = $MarginContainer/VBoxContainer/body/rightPanel/NinePatchRect/MarginContainer/VBoxContainer/buttonContainer/sellButton

@onready var close_button = $MarginContainer/VBoxContainer/header/closeButton
@onready var search_bar = $MarginContainer/VBoxContainer/body/leftPanel/searchBar
@onready var category = $MarginContainer/VBoxContainer/body/leftPanel/category

@onready var energy_effect = $MarginContainer/VBoxContainer/body/rightPanel/NinePatchRect/MarginContainer/VBoxContainer/HBoxContainer/VBoxContainer/energy
@onready var hunger_effect = $MarginContainer/VBoxContainer/body/rightPanel/NinePatchRect/MarginContainer/VBoxContainer/HBoxContainer/VBoxContainer/hunger
@onready var stress_effect = $MarginContainer/VBoxContainer/body/rightPanel/NinePatchRect/MarginContainer/VBoxContainer/HBoxContainer/VBoxContainer/stress

var search_text := ""
var selected_category := -1
var selected_item_id := ""

const CATEGORY = [
	"",
	"makanan",
	"bahan",
	"peralatan",
	"furniture",
	"elektronik",
	"obat",
	"buku",
	"lainnya"
]


func _ready():

	UiManager.register_ui("inventory", self)
	UiManager.fade_out(self)

	close_button.pressed.connect(func(): UiManager.fade_out(self))

	if !InventoryManager.inventory_changed.is_connected(refresh):
		InventoryManager.inventory_changed.connect(refresh)

	search_bar.text_changed.connect(_on_search_changed)

	category.clear()
	category.add_item("Semua")
	category.add_item("Makanan")
	category.add_item("Bahan")
	category.add_item("Peralatan")
	category.add_item("Furniture")
	category.add_item("Elektronik")
	category.add_item("Obat")
	category.add_item("Buku")
	category.add_item("Lainnya")

	category.item_selected.connect(_on_category_changed)
	use_button.pressed.connect(_on_use_pressed)
	sell_button.pressed.connect(_on_sell_pressed)

	refresh()
	clear_information()


func _on_search_changed(text):
	search_text = text.to_lower()
	refresh()


func _on_category_changed(index):
	selected_category = index - 1
	refresh()


func _on_use_pressed():
	if selected_item_id.is_empty():
		return

	var character := GameManager.get_active_character()

	if character == null:
		return

	InventoryManager.use_item(character, selected_item_id)


func _on_sell_pressed():
	if selected_item_id.is_empty():
		return

	InventoryManager.sell_item(selected_item_id)


func refresh():
	for child in grid.get_children():
		child.queue_free()

	await get_tree().process_frame

	for slot in InventoryManager.get_slots():
		var item = DataManager.get_item(slot["item_id"])
		if item == null:
			clear_information()
			continue

		if search_text != "":
			if !item["item_name"].to_lower().contains(search_text):
				continue

		if selected_category != -1:
			if item["category"].to_lower() != CATEGORY[selected_category + 1]:
				continue

		var ui = slot_scene.instantiate()
		grid.add_child(ui)
		ui.setup(slot)
		ui.clicked.connect(show_item)

	await get_tree().process_frame

	if selected_item_id != "" and InventoryManager.get_amount(selected_item_id) > 0:
		show_item(selected_item_id)
	else:
		selected_item_id = ""
		clear_information()


func show_item(item_id: String):
	selected_item_id = item_id

	var item = DataManager.get_item(item_id)
	if item == null:
		return

	item_icon.texture = load(item["icon"])
	item_name.text = item["item_name"]
	item_category.text = item["category"].capitalize()
	description.text = item["description"]
	buy_price.text = "Harga Beli : Rp%d" % item["buy_price"]
	sell_price.text = "Harga Jual : Rp%d" % item["sell_price"]
	quantity.text = "Dimiliki : %d" % InventoryManager.get_amount(item_id)

	if item["consumable"]:
		format_effect(energy_effect, "Energi ", item["effects"]["energy"])
		format_effect(hunger_effect, "Lapar ", item["effects"]["hunger"])
		format_effect(stress_effect, "Stress ", item["effects"]["stress"], true)
	else:
		energy_effect.text = ""
		hunger_effect.text = ""
		stress_effect.text = ""

	use_button.disabled = !item["consumable"]
	sell_button.disabled = !item["sellable"]


func clear_information():
	item_icon.texture = null
	item_name.text = ""
	item_category.text = ""
	description.text = ""
	buy_price.text = ""
	sell_price.text = ""
	quantity.text = ""

	energy_effect.text = ""
	hunger_effect.text = ""
	stress_effect.text = ""

	use_button.disabled = true
	sell_button.disabled = true


func format_effect(label: Label, icon: String, value: int, reverse := false):
	if value == 0:
		label.text = "%s 0" % icon
		label.modulate = Color.WHITE
		return

	var sign = "+" if value > 0 else ""
	label.text = "%s %s%d" % [icon, sign, value]

	if reverse:
		if value < 0:
			label.modulate = Color.LIME_GREEN
		else:
			label.modulate = Color.INDIAN_RED
	else:
		if value > 0:
			label.modulate = Color.LIME_GREEN
		else:
			label.modulate = Color.INDIAN_RED


func toggle():
	visible = !visible
	if visible:
		refresh()
		get_viewport().gui_release_focus()

func _exit_tree():
	UiManager.unregister_ui("inventory")
