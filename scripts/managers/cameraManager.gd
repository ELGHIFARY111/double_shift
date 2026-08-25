extends Node

@export var smooth_speed: float = 8.0

var camera: Camera2D = null
var target: CharacterBody2D = null

var running: bool = false
var default_zoom: Vector2 = Vector2(3, 3)
var target_zoom: Vector2 = Vector2(3, 3)
var zoom_speed: float = 6.0


func _ready() -> void:
	SaveManager.game_loaded.connect(_on_game_loaded)
	SaveManager.game_closed.connect(_on_game_closed)

	GameManager.active_character_changed.connect(_on_active_character_changed)


func register_camera(cam: Camera2D) -> void:
	camera = cam

	if camera != null:
		camera.make_current()
		default_zoom = camera.zoom
		target_zoom = default_zoom

		if target != null:
			camera.global_position = target.global_position


func unregister_camera() -> void:
	camera = null


func _physics_process(delta: float) -> void:

	if !running:
		return

	if camera == null:
		return

	if target == null:
		return

	if !is_instance_valid(camera):
		return

	if !is_instance_valid(target):
		return

	camera.global_position = camera.global_position.lerp(
		target.global_position,
		1.0 - exp(-smooth_speed * delta)
	)
	
	camera.zoom = camera.zoom.lerp(
		target_zoom,
		1.0 - exp(-zoom_speed * delta)
	)

func _on_game_loaded() -> void:
	running = true

	target = GameManager.get_active_character()

	if camera != null and target != null:
		camera.global_position = target.global_position


func _on_game_closed() -> void:
	running = false
	target = null


func _on_active_character_changed(character: CharacterBody2D) -> void:

	target = character

	if camera == null:
		return

	if target == null:
		return

	camera.global_position = target.global_position


func get_camera() -> Camera2D:
	return camera


func get_target() -> CharacterBody2D:
	return target

func zoom_in(zoom_multiplier: float = 1.3) -> void:
	target_zoom = default_zoom * zoom_multiplier
	
func zoom_out() -> void:
	target_zoom = default_zoom
