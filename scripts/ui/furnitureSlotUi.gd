extends Button

signal clicked(item_id)
@onready var icon_texture = $item_icon
var item_id := ""
func setup(slot: Dictionary):
	print(icon_texture)
	item_id = slot["item_id"]
	var item = DataManager.get_item(item_id)
	if item == null:
		return
	print(item)
	var tex = load(item["icon"])
	print(item["icon"])
	print(tex)
	icon_texture.texture = tex
func _pressed():
	clicked.emit(item_id)
