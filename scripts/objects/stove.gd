extends Interactable

@onready var sprite = $Sprite2D
var anim_sprite: AnimatedSprite2D

func _ready():
	id = "kompor"
	prompt_text = "Kompor"
	
	if Engine.is_editor_hint():
		return
		
	anim_sprite = AnimatedSprite2D.new()
	var frames = SpriteFrames.new()
	
	frames.add_animation("idle")
	var idle_tex = load("res://asset/art/objects/kompor1.png")
	if idle_tex:
		frames.add_frame("idle", idle_tex)
		
	frames.add_animation("cook")
	frames.set_animation_loop("cook", true)
	frames.set_animation_speed("cook", 5.0)
	for i in range(4):
		var tex = load("res://asset/art/objects/anim/komporMasak_frame_%d.png" % i)
		if tex:
			frames.add_frame("cook", tex)
			
	anim_sprite.sprite_frames = frames
	add_child(anim_sprite)
	
	if sprite:
		sprite.hide()
	anim_sprite.play("idle")

func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
		
	var is_cooking = false
	var player = SaveManager.get_player()
	if player.has("characters"):
		var chars = player["characters"]
		for c_id in chars:
			var act = chars[c_id].get("activity", {}).get("current_activity", "")
			if act == "cook":
				is_cooking = true
				break
				
	if is_cooking:
		if anim_sprite.animation != "cook" or not anim_sprite.is_playing():
			anim_sprite.play("cook")
	else:
		if anim_sprite.animation != "idle" or not anim_sprite.is_playing():
			anim_sprite.play("idle")

func _on_focus() -> void:
	if sprite:
		var tex = load("res://asset/art/objects/kompor1_focus.png")
		if tex:
			sprite.texture = tex
		sprite.show()

func _on_unfocus() -> void:
	if sprite:
		sprite.hide()
