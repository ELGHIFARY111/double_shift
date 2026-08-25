extends Button

signal clicked(item_id: String)

@onready var name_label = $MarginContainer/VBoxContainer/NameLabel
@onready var price_label = $MarginContainer/VBoxContainer/PriceLabel

var _item_id: String = ""

func setup(data: Dictionary, type: String = "item") -> void:
	_item_id = String(data.get("id", ""))
	var item_name = data.get("item_name", data.get("name", "???"))
	name_label.text = str(item_name)
	price_label.text = "Rp " + _format_price(int(data.get("buy_price", 0)))


func _format_price(price: int) -> String:
	var s: String = str(price)
	var result: String = ""
	var count: int = 0

	for i in range(s.length() - 1, -1, -1):
		if count > 0 and count % 3 == 0:
			result = "." + result
		result = s[i] + result
		count += 1

	return result


func _pressed() -> void:
	clicked.emit(_item_id)
