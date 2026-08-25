import os

out_dir = r"d:\godotgame\double-shift\scripts\ui"

files = {
    "shopUi.gd": """extends NinePatchRect

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
\thide()
\tUiManager.register_ui("shop", self)
\tclose_button.pressed.connect(_on_close)
\tsearch_bar.text_changed.connect(_on_search_changed)
\tcategory_filter.item_selected.connect(_on_category_changed)
\t
\tcategory_filter.clear()
\tfor cat in CATEGORY:
\t\tcategory_filter.add_item(cat.capitalize())
\t\t
\tminus_button.pressed.connect(func(): _change_quantity(-1))
\tplus_button.pressed.connect(func(): _change_quantity(1))
\tquantity_input.text_changed.connect(_on_quantity_input_changed)
\tbuy_button.pressed.connect(_on_buy_pressed)
\tclear_detail()

func open(shop_id: String) -> void:
\tcurrent_shop_id = shop_id
\tvar shop_data = DataManager.get_shop(shop_id)
\ttitle_label.text = shop_data.get("shop_name", "Toko")
\trefresh()
\tUiManager.fade_in(self)

func _on_close() -> void:
\tUiManager.fade_out(self)

func _on_search_changed(text: String) -> void:
\tsearch_text = text.to_lower()
\trefresh()

func _on_category_changed(index: int) -> void:
\tselected_category = index
\trefresh()

func refresh() -> void:
\tmoney_label.text = "Uang: Rp " + str(SaveManager.get_money())
\tfor child in grid.get_children():
\t\tchild.queue_free()
\t\t
\tvar shop_items = ShopManager.get_shop_items(current_shop_id)
\tfor item_id in shop_items:
\t\tvar item = DataManager.get_item(item_id)
\t\tif item == null: continue
\t\t
\t\tif search_text != "" and not item.get("item_name", "").to_lower().contains(search_text):
\t\t\tcontinue
\t\t
\t\tif selected_category != 0 and item.get("category", "").to_lower() != CATEGORY[selected_category].to_lower():
\t\t\tcontinue
\t\t\t
\t\tvar slot = slot_scene.instantiate()
\t\tgrid.add_child(slot)
\t\tslot.setup({"item_id": item_id})
\t\tslot.clicked.connect(show_item)
\t
\tif selected_item_id != "":
\t\tshow_item(selected_item_id)

func show_item(item_id: String) -> void:
\tselected_item_id = item_id
\tbuy_quantity = 1
\tvar item = DataManager.get_item(item_id)
\tif item == null: return
\t
\tdetail_name.text = item.get("item_name", "")
\tdetail_category.text = item.get("category", "").capitalize()
\tdetail_icon.texture = load(item.get("icon", "res://icon.svg")) if item.has("icon") else null
\tdetail_desc.text = item.get("description", "")
\t
\tvar price = int(item.get("buy_price", 0))
\tdetail_price.text = "Harga: Rp " + str(price)
\tdetail_owned.text = "Dimiliki: " + str(InventoryManager.get_amount(item_id))
\t
\tif item.get("consumable", false) and item.has("effects"):
\t\tenergy_effect.text = "Energi: +" + str(item["effects"].get("energy", 0))
\t\thunger_effect.text = "Kenyang: +" + str(item["effects"].get("hunger", 0))
\t\tstress_effect.text = "Stres: " + str(item["effects"].get("stress", 0))
\telse:
\t\tenergy_effect.text = ""
\t\thunger_effect.text = ""
\t\tstress_effect.text = ""
\t
\tupdate_quantity_ui()

func update_quantity_ui() -> void:
\tvar item = DataManager.get_item(selected_item_id)
\tif item == null: return
\tvar price = int(item.get("buy_price", 0))
\tquantity_input.text = str(buy_quantity)
\tvar total = price * buy_quantity
\tbuy_button.text = "Beli (Rp " + str(total) + ")"
\tbuy_button.disabled = SaveManager.get_money() < total

func _change_quantity(amount: int) -> void:
\tbuy_quantity = maxi(1, buy_quantity + amount)
\tupdate_quantity_ui()

func _on_quantity_input_changed(new_text: String) -> void:
\tvar val = new_text.to_int()
\tif val > 0:
\t\tbuy_quantity = val
\t\tupdate_quantity_ui()

func _on_buy_pressed() -> void:
\tif selected_item_id.is_empty(): return
\tvar item = DataManager.get_item(selected_item_id)
\tif item == null: return
\tvar price = int(item.get("buy_price", 0))
\tvar total = price * buy_quantity
\tif SaveManager.get_money() >= total:
\t\tSaveManager.add_money(-total)
\t\tInventoryManager.add_item(selected_item_id, buy_quantity)
\t\trefresh()

func clear_detail() -> void:
\tdetail_icon.texture = null
\tdetail_name.text = ""
\tdetail_category.text = ""
\tdetail_desc.text = ""
\tdetail_price.text = ""
\tdetail_owned.text = ""
\tenergy_effect.text = ""
\thunger_effect.text = ""
\tstress_effect.text = ""
\tbuy_button.disabled = true
\tquantity_input.text = "1"

func _exit_tree() -> void:
\tUiManager.unregister_ui("shop")
""",

    "dialogueUi.gd": """extends NinePatchRect

@onready var name_label = $MarginContainer/VBoxContainer/NameLabel
@onready var text_label = $MarginContainer/VBoxContainer/TextLabel

var current_dialogue: Array = []
var current_index: int = 0

func _ready() -> void:
\thide()
\tUiManager.register_ui("dialogue", self)

func open(npc_id: String) -> void:
\tcurrent_dialogue = ["Halo!", "Ada yang bisa saya bantu?"] # Fallback
\tvar char_data = DataManager.get_character(npc_id)
\tif not char_data.is_empty() and char_data.has("dialogue"):
\t\tcurrent_dialogue = char_data["dialogue"]
\t
\tname_label.text = char_data.get("name", npc_id.capitalize())
\tcurrent_index = 0
\tshow_current()
\tUiManager.fade_in(self)

func show_current() -> void:
\tif current_index < current_dialogue.size():
\t\ttext_label.text = current_dialogue[current_index]
\telse:
\t\t_on_close()

func _input(event: InputEvent) -> void:
\tif visible and event.is_action_pressed("interact"):
\t\tcurrent_index += 1
\t\tshow_current()
\t\tget_viewport().set_input_as_handled()

func _on_close() -> void:
\tUiManager.fade_out(self)

func _exit_tree() -> void:
\tUiManager.unregister_ui("dialogue")
""",

    "questTrackerUi.gd": """extends MarginContainer

@onready var title_label = $VBoxContainer/TitleLabel
@onready var desc_label = $VBoxContainer/DescLabel
@onready var obj_container = $VBoxContainer/ObjectivesContainer

func _ready() -> void:
\tUiManager.register_ui("quest_tracker", self)
\tQuestManager.quest_updated.connect(refresh)
\trefresh()

func refresh(quest_id: String = "") -> void:
\tfor child in obj_container.get_children():
\t\tchild.queue_free()
\t\t
\tvar active = QuestManager.get_active_quests()
\tif active.is_empty():
\t\ttitle_label.text = "Tidak ada misi aktif"
\t\tdesc_label.text = ""
\t\treturn
\t\t
\tvar q_id = active.keys()[0]
\tvar q_data = DataManager.get_quest(q_id)
\tvar state = active[q_id]
\t
\ttitle_label.text = q_data.get("quest_name", "Misi")
\tdesc_label.text = q_data.get("description", "")
\t
\tfor obj in q_data.get("objectives", []):
\t\tvar l = Label.new()
\t\tvar max_v = obj.get("amount", 1)
\t\tvar cur_v = state.get(obj["objective_id"], 0)
\t\tl.text = "- " + obj.get("description", "") + " (" + str(cur_v) + "/" + str(max_v) + ")"
\t\tif cur_v >= max_v:
\t\t\tl.add_theme_color_override("font_color", Color.GREEN)
\t\tobj_container.add_child(l)

func _exit_tree() -> void:
\tUiManager.unregister_ui("quest_tracker")
""",

    "emailUi.gd": """extends Control

@onready var close_button = $Panel/MarginContainer/VBoxContainer/Header/CloseButton
@onready var email_list = $Panel/MarginContainer/VBoxContainer/Body/LeftPanel/ScrollContainer/EmailList
@onready var detail_title = $Panel/MarginContainer/VBoxContainer/Body/RightPanel/MarginContainer/VBoxContainer/Title
@onready var detail_sender = $Panel/MarginContainer/VBoxContainer/Body/RightPanel/MarginContainer/VBoxContainer/Sender
@onready var detail_body = $Panel/MarginContainer/VBoxContainer/Body/RightPanel/MarginContainer/VBoxContainer/BodyText

func _ready() -> void:
\thide()
\tUiManager.register_ui("email_ui", self)
\tclose_button.pressed.connect(func(): UiManager.fade_out(self))

func open(character: CharacterBody2D) -> void:
\trefresh()
\tUiManager.fade_in(self)

func refresh() -> void:
\tfor child in email_list.get_children():
\t\tchild.queue_free()
\t
\tvar emails = SaveManager.get_emails()
\tfor email in emails:
\t\tvar btn = Button.new()
\t\tbtn.text = email.get("subject", "Pesan")
\t\tbtn.pressed.connect(func(): show_email(email))
\t\temail_list.add_child(btn)

func show_email(email: Dictionary) -> void:
\tdetail_title.text = email.get("subject", "")
\tdetail_sender.text = "Dari: " + email.get("sender", "")
\tdetail_body.text = email.get("body", "")

func _exit_tree() -> void:
\tUiManager.unregister_ui("email_ui")
""",

    "cleaningUi.gd": """extends Control

func _ready() -> void:
\thide()
\tUiManager.register_ui("cleaning_ui", self)

func open(character: CharacterBody2D, task: String) -> void:
\t# Simplified cleaning interaction
\tUiManager.fade_in(self)
\tActivityManager.start_activity(character, task)
\t# Auto close after short delay
\tget_tree().create_timer(1.0).timeout.connect(func(): UiManager.fade_out(self))

func _exit_tree() -> void:
\tUiManager.unregister_ui("cleaning_ui")
""",

    "jobPortalUi.gd": """extends Control

func _ready() -> void:
\thide()
\tUiManager.register_ui("job_portal_ui", self)
\t
\t# Note: The UI is currently a stub for job applications
\t# Bind close buttons here if defined in scene

func open(character: CharacterBody2D) -> void:
\tUiManager.fade_in(self)
\t
func _exit_tree() -> void:
\tUiManager.unregister_ui("job_portal_ui")
""",

    "cookingUi.gd": """extends Control

func _ready() -> void:
\thide()
\tUiManager.register_ui("cooking_ui", self)
\t
func open(character: CharacterBody2D) -> void:
\tUiManager.fade_in(self)

func _exit_tree() -> void:
\tUiManager.unregister_ui("cooking_ui")
"""
}

for fname, content in files.items():
    with open(os.path.join(out_dir, fname), "w", encoding="utf-8") as f:
        f.write(content)
        
print("All missing scripts have been successfully rewritten!")
