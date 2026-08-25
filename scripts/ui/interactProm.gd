extends MarginContainer

@onready var label: Label = $PanelContainer/Label

func _ready() -> void:
	hide()
	UiManager.register_ui("interact_prompt", self)

var _target_char_pos: Vector2 = Vector2.ZERO
var _target_int_pos: Vector2 = Vector2.ZERO

func _process(delta: float) -> void:
	if visible and _target_int_pos != Vector2.ZERO:
		var screen_int_pos = get_viewport().get_canvas_transform() * _target_int_pos
		var offset_x = 40.0
		var offset_y = -15.0
		
		if _target_char_pos.x < _target_int_pos.x:
			global_position = screen_int_pos + Vector2(offset_x, offset_y)
		else:
			global_position = screen_int_pos - Vector2(size.x + offset_x, -offset_y)

func show_prompt(text: String, char_pos: Vector2 = Vector2.ZERO, int_pos: Vector2 = Vector2.ZERO) -> void:
	label.text = "[E] " + text
	_target_char_pos = char_pos
	_target_int_pos = int_pos
	UiManager.fade_in(self)

func hide_prompt() -> void:
	UiManager.fade_out(self)

func _exit_tree() -> void:
	UiManager.unregister_ui("interact_prompt")
