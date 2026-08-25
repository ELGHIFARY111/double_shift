extends Button

signal clicked(recipe_id: String)

var _recipe_id: String = ""

func setup(data: Dictionary) -> void:
	_recipe_id = String(data.get("id", ""))
	text = String(data.get("name", "???"))

func _pressed() -> void:
	clicked.emit(_recipe_id)
