extends Area2D
class_name Interactable

@export var id: String = ""
@export var prompt_text: String = "Interact"

var _original_texture: Texture2D = null

func focus() -> void:
	if has_method("_on_focus"):
		call("_on_focus")
		return
		
	var sprite = get_node_or_null("Sprite2D")
	if sprite and sprite is Sprite2D:
		var tex = sprite.texture
		if tex and _original_texture == null:
			_original_texture = tex
			
		if _original_texture != null:
			var path = _original_texture.resource_path
			if path != "":
				var ext = path.get_extension()
				var base_path = path.get_basename()
				if not base_path.ends_with("_focus"):
					var focus_path = base_path + "_focus." + ext
					if ResourceLoader.exists(focus_path):
						sprite.texture = load(focus_path)

func unfocus() -> void:
	if has_method("_on_unfocus"):
		call("_on_unfocus")
		return
		
	var sprite = get_node_or_null("Sprite2D")
	if sprite and sprite is Sprite2D and _original_texture != null:
		sprite.texture = _original_texture

func get_actions(_character: CharacterBody2D) -> Array:
	return []

func execute_action(_character: CharacterBody2D, _action_id: String) -> void:
	pass
