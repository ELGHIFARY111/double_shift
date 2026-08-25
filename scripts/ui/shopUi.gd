extends NinePatchRect

@export var slot_scene: PackedScene

@onready var title_label = $MarginContainer/VBoxContainer/header/titleLabel
@onready var money_label = $MarginContainer/VBoxContainer/header/moneyLabel
@onready var close_button = $MarginContainer/VBoxContainer/header/closeButton
@onready var search_bar = $MarginContainer/VBoxContainer/body/leftPanel/searchBar
@onready var category_filter = $MarginContainer/VBoxContainer/body/leftPanel/categoryFilter
@onready var grid = $MarginContainer/VBoxContainer/body/leftPanel/ScrollContainer/GridContainer
@onready var detail_icon = $MarginContainer/VBoxContainer/body/rightPanel/MarginContainer/VBoxContainer/itemIcon
@onready var detail_name = $MarginContainer/VBoxContainer/body/rightPanel/MarginContainer/VBoxContainer/headerDetail/itemName
@onready var detail_category = $MarginContainer/VBoxContainer/body/rightPanel/MarginContainer/VBoxContainer/headerDetail/itemCategory
@onready var detail_desc = $MarginContainer/VBoxContainer/body/rightPanel/MarginContainer/VBoxContainer/description
@onready var detail_price = $MarginContainer/VBoxContainer/body/rightPanel/MarginContainer/VBoxContainer/priceLabel
@onready var detail_owned = $MarginContainer/VBoxContainer/body/rightPanel/MarginContainer/VBoxContainer/ownedLabel
@onready var energy_effect = $MarginContainer/VBoxContainer/body/rightPanel/MarginContainer/VBoxContainer/effectsContainer/energy
@onready var hunger_effect = $MarginContainer/VBoxContainer/body/rightPanel/MarginContainer/VBoxContainer/effectsContainer/hunger
@onready var stress_effect = $MarginContainer/VBoxContainer/body/rightPanel/MarginContainer/VBoxContainer/effectsContainer/stress
@onready var minus_button = $MarginContainer/VBoxContainer/body/rightPanel/MarginContainer/VBoxContainer/quantityContainer/minusButton
@onready var quantity_input = $MarginContainer/VBoxContainer/body/rightPanel/MarginContainer/VBoxContainer/quantityContainer/quantityInput
@onready var plus_button = $MarginContainer/VBoxContainer/body/rightPanel/MarginContainer/VBoxContainer/quantityContainer/plusButton
@onready var buy_button = $MarginContainer/VBoxContainer/body/rightPanel/MarginContainer/VBoxContainer/buyButton

var current_shop_id := ""
var selected_item_id := ""
var buy_quantity := 1
var search_text := ""
var selected_category := 0
const CATEGORY = ["Semua", "makanan", "bahan", "peralatan", "obat", "buku", "lainnya"]

func _ready() -> void:
	hide()
	UiManager.register_ui("shop", self)
	close_button.pressed.connect(_on_close)
	search_bar.text_changed.connect(_on_search_changed)
	category_filter.item_selected.connect(_on_category_changed)
	
	category_filter.clear()
	for cat in CATEGORY:
		category_filter.add_item(cat.capitalize())
		
	minus_button.pressed.connect(func(): _change_quantity(-1))
	plus_button.pressed.connect(func(): _change_quantity(1))
	quantity_input.text_changed.connect(_on_quantity_input_changed)
	buy_button.pressed.connect(_on_buy_pressed)
	clear_detail()

func open(shop_id: String) -> void:
	current_shop_id = shop_id
	var shop_names = {
		"toserba": "Toserba",
		"bookstore": "Toko Buku",
		"furniture": "Toko Perabotan"
	}
	title_label.text = shop_names.get(shop_id, shop_id.capitalize())
	refresh()
	UiManager.fade_in(self)

func _on_close() -> void:
	UiManager.fade_out(self)

func _on_search_changed(text: String) -> void:
	search_text = text.to_lower()
	refresh()

func _on_category_changed(index: int) -> void:
	selected_category = index
	refresh()

func refresh() -> void:
	money_label.text = "Uang: Rp " + str(SaveManager.get_money())
	for child in grid.get_children():
		child.queue_free()
		
	var shop_items = []
	shop_items.append_array(ShopManager.get_shop_items(current_shop_id))
	shop_items.append_array(ShopManager.get_shop_books(current_shop_id))
	shop_items.append_array(ShopManager.get_shop_furniture(current_shop_id))
	
	for item in shop_items:
		if search_text != "" and not item.get("item_name", item.get("name", "")).to_lower().contains(search_text):
			continue
		
		if selected_category != 0 and item.get("category", "Lainnya").to_lower() != CATEGORY[selected_category].to_lower():
			continue
			
		var slot = slot_scene.instantiate()
		grid.add_child(slot)
		slot.setup(item)
		slot.clicked.connect(show_item)
	
	if selected_item_id != "":
		show_item(selected_item_id)

func _get_any_item(id: String) -> Dictionary:
	var item = DataManager.get_item(id)
	if not item.is_empty(): return item
	item = DataManager.get_book(id)
	if not item.is_empty(): return item
	item = DataManager.get_furniture(id)
	return item

func show_item(item_id: String) -> void:
	selected_item_id = item_id
	buy_quantity = 1
	var item = _get_any_item(item_id)
	if item.is_empty(): return
	
	detail_name.text = item.get("item_name", item.get("name", ""))
	detail_category.text = item.get("category", "Lainnya").capitalize()
	detail_icon.texture = load(item.get("icon", "res://icon.svg")) if item.has("icon") else null
	detail_desc.text = item.get("description", "")
	
	var price = 0
	var owned_amount = 0
	
	if not DataManager.get_furniture(item_id).is_empty():
		var furn_level = int(SaveManager.get_furniture().get(item_id, 0))
		owned_amount = furn_level
		if furn_level == 0:
			price = int(item.get("buy_price", 0))
		else:
			if item.get("upgradeable", false) and furn_level < item.get("levels", []).size():
				price = int(item["levels"][furn_level].get("upgrade_price", 0))
			else:
				price = 0 # Max level
	else:
		price = int(item.get("buy_price", 0))
		owned_amount = InventoryManager.get_amount(item_id)
		
	detail_price.text = "Harga: Rp " + str(price)
	if price == 0 and owned_amount > 0 and not DataManager.get_furniture(item_id).is_empty():
		detail_price.text = "Maksimal"
		
	detail_owned.text = "Dimiliki: " + str(owned_amount)
	
	if item.get("consumable", false) and item.has("effects"):
		energy_effect.text = "Energi: +" + str(item["effects"].get("energy", 0))
		hunger_effect.text = "Kenyang: +" + str(item["effects"].get("hunger", 0))
		stress_effect.text = "Stres: " + str(item["effects"].get("stress", 0))
	else:
		energy_effect.text = ""
		hunger_effect.text = ""
		stress_effect.text = ""
	
	update_quantity_ui()

func update_quantity_ui() -> void:
	var item = _get_any_item(selected_item_id)
	if item.is_empty(): return
	
	var price = 0
	var is_furn = not DataManager.get_furniture(selected_item_id).is_empty()
	var is_book = not DataManager.get_book(selected_item_id).is_empty()
	var max_stack = int(item.get("max_stack", 99))
	var owned_amount = 0
	
	if is_furn:
		var furn_level = int(SaveManager.get_furniture().get(selected_item_id, 0))
		owned_amount = furn_level
		if furn_level == 0:
			price = int(item.get("buy_price", 0))
		else:
			if item.get("upgradeable", false) and furn_level < item.get("levels", []).size():
				price = int(item["levels"][furn_level].get("upgrade_price", 0))
			else:
				price = 0 # Max level
		buy_quantity = 1 # Force 1 for furniture
		quantity_input.editable = false
	elif is_book:
		owned_amount = 1 if InventoryManager.has_item(selected_item_id) else 0
		price = int(item.get("buy_price", 0))
		buy_quantity = 1 # Force 1 for books
		quantity_input.editable = false
	else:
		owned_amount = InventoryManager.get_amount(selected_item_id)
		price = int(item.get("buy_price", 0))
		quantity_input.editable = true
		
		var space_left = max_stack - owned_amount
		if space_left <= 0:
			buy_quantity = 0
		elif buy_quantity > space_left:
			buy_quantity = space_left
		
	quantity_input.text = str(buy_quantity)
	var total = price * buy_quantity
	
	if is_furn and price == 0 and int(SaveManager.get_furniture().get(selected_item_id, 0)) > 0:
		buy_button.text = "Maksimal"
		buy_button.disabled = true
	elif is_book and InventoryManager.has_item(selected_item_id):
		buy_button.text = "Sudah Dibeli"
		buy_button.disabled = true
	elif not is_furn and not is_book and owned_amount >= max_stack:
		buy_button.text = "Penuh"
		buy_button.disabled = true
	else:
		buy_button.text = "Beli (Rp " + str(total) + ")"
		buy_button.disabled = SaveManager.get_money() < total or total <= 0 or buy_quantity <= 0

func _change_quantity(amount: int) -> void:
	if not quantity_input.editable: return
	
	var item = _get_any_item(selected_item_id)
	var max_stack = int(item.get("max_stack", 99))
	var owned = InventoryManager.get_amount(selected_item_id)
	var space_left = max_stack - owned
	
	buy_quantity = clampi(buy_quantity + amount, 1, space_left)
	update_quantity_ui()

func _on_quantity_input_changed(new_text: String) -> void:
	if not quantity_input.editable: return
	var val = new_text.to_int()
	if val > 0:
		var item = _get_any_item(selected_item_id)
		var max_stack = int(item.get("max_stack", 99))
		var owned = InventoryManager.get_amount(selected_item_id)
		var space_left = max_stack - owned
		
		buy_quantity = clampi(val, 1, space_left)
		update_quantity_ui()

func _on_buy_pressed() -> void:
	if selected_item_id.is_empty(): return
	var item = _get_any_item(selected_item_id)
	if item.is_empty(): return
	
	var is_furn = not DataManager.get_furniture(selected_item_id).is_empty()
	var is_book = not DataManager.get_book(selected_item_id).is_empty()
	
	var success = false
	if is_furn:
		success = ShopManager.buy_furniture(selected_item_id)
	elif is_book:
		success = ShopManager.buy_book(selected_item_id)
	else:
		success = ShopManager.buy_item(selected_item_id, buy_quantity)
		
	if success:
		refresh()

func clear_detail() -> void:
	detail_icon.texture = null
	detail_name.text = ""
	detail_category.text = ""
	detail_desc.text = ""
	detail_price.text = ""
	detail_owned.text = ""
	energy_effect.text = ""
	hunger_effect.text = ""
	stress_effect.text = ""
	buy_button.disabled = true
	quantity_input.text = "1"

func _exit_tree() -> void:
	UiManager.unregister_ui("shop")
