
extends Button

signal clicked(item_id)
@onready var icon_texture = $item_icon
@onready var amount_label = $amountLabel
var item_id := ""
func setup(slot: Dictionary):
	print(icon_texture)
	print(amount_label)
	item_id = slot["item_id"]
	var item = DataManager.get_item(item_id)
	if item == null or item.is_empty():
		return
	print(item)
	var tex = load(item.get("icon", ""))
	print(item.get("icon", ""))
	print(tex)
	icon_texture.texture = tex
	amount_label.text = str(int(slot["amount"]))
func _pressed():
	clicked.emit(item_id)
