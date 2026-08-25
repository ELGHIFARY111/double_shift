extends PanelContainer

signal cancel_pressed

@onready var icon_rect: TextureRect = $MarginContainer/VBoxContainer/TextureRect
@onready var progress_bar: ProgressBar = $MarginContainer/VBoxContainer/ProgressBar
@onready var cancel_button: Button = $cancelButton

func _ready() -> void:
	cancel_button.pressed.connect(func(): cancel_pressed.emit())

func setup(recipe_id: String, progress: float = 0.0) -> void:
	var recipe = DataManager.get_recipe(recipe_id)
	if recipe.is_empty():
		return
		
	var result_data = recipe.get("result", {})
	var result_item_id = result_data.get("item_id", "")
	var result_item = DataManager.get_item(result_item_id)
	
	if !result_item.is_empty() and result_item.has("icon") and result_item["icon"] != "":
		icon_rect.texture = load(result_item["icon"])
	
	progress_bar.value = progress

