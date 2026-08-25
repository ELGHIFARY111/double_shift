extends CharacterBody2D

@export var character_id: String = ""
@export var move_speed: float = 100.0

var is_active: bool = false:
	set(value):
		is_active = value
		if interactable_node != null:
			if value:
				interactable_node.monitoring = false
				interactable_node.monitorable = false
				interactable_node.hide()
			else:
				interactable_node.monitoring = true
				interactable_node.monitorable = true
				interactable_node.show()
var _last_saved_tile: Vector2i = Vector2i(-99999, -99999)
var _was_moving: bool = false
var _needs_overlap_check: bool = false

var _target_position: Vector2 = Vector2.INF
var _queued_activity: String = ""
var _is_npc_moving: bool = false
var interactable_node: Area2D = null
var _follow_target: CharacterBody2D = null
var _last_direction: String = "bawah"

func set_follow_target(target: CharacterBody2D) -> void:
	_follow_target = target


func _ready() -> void:
	if character_id == "":
		push_error("character_id belum diisi.")
		return

	if !SaveManager.data.has("player"):
		push_error("Player tidak ditemukan")
		return

	if !SaveManager.data["player"].has("characters"):
		push_error("Characters tidak ditemukan")
		return

	if !SaveManager.data["player"]["characters"].has(character_id):
		push_error("Character ID tidak ditemukan : " + character_id)
		return

	# Setup Interactable untuk semua karakter
	interactable_node = preload("res://scripts/interactable/interactable.gd").new()
	interactable_node.id = "character_npc"
	interactable_node.prompt_text = get_data().get("name", "NPC")
	
	var collision = CollisionShape2D.new()
	var shape = CircleShape2D.new()
	shape.radius = 40.0
	collision.shape = shape
	
	interactable_node.add_child(collision)
	interactable_node.collision_layer = 1
	interactable_node.collision_mask = 1
	add_child(interactable_node)
	
	if get_data().get("is_player", false):
		is_active = true
	
	var active_char_id = SaveManager.data["player"].get("active_character", "")
	if GameManager.get_active_character() != null:
		active_char_id = GameManager.get_active_character().character_id
		
	if character_id == active_char_id:
		interactable_node.monitoring = false
		interactable_node.monitorable = false
		interactable_node.hide()


func _physics_process(_delta: float) -> void:
	if !is_active:
		if _follow_target != null:
			if is_instance_valid(_follow_target) and _follow_target.is_inside_tree():
				var distance = global_position.distance_to(_follow_target.global_position)
				if distance > 80.0 or (velocity.length() > 5.0 and distance > 50.0):
					var direction = global_position.direction_to(_follow_target.global_position)
					velocity = velocity.lerp(direction * (move_speed * 1.4), 8.0 * _delta)
				else:
					velocity = velocity.lerp(Vector2.ZERO, 15.0 * _delta)
					if velocity.length() < 5.0:
						velocity = Vector2.ZERO
				
				move_and_slide()
			else:
				_follow_target = null
		elif _target_position != Vector2.INF:
			_is_npc_moving = true
			var distance = global_position.distance_to(_target_position)
			if distance < 30.0:
				_target_position = Vector2.INF
				_is_npc_moving = false
				velocity = Vector2.ZERO
				if _queued_activity != "":
					var activity_to_start = _queued_activity
					_queued_activity = ""
					ActivityManager.start_activity(self, activity_to_start)
			else:
				var direction = global_position.direction_to(_target_position)
				velocity = direction * move_speed
				move_and_slide()
		else:
			_is_npc_moving = false
			
		_needs_overlap_check = true
		
		var is_moving: bool = velocity != Vector2.ZERO
		if is_moving:
			var current_tile: Vector2i = SpawnManager.world_to_tile(global_position)
			if current_tile != _last_saved_tile:
				_last_saved_tile = current_tile
				CharacterManager.set_tile(self, current_tile)
		elif _was_moving:
			SpawnManager.save_character_position(self)
		_was_moving = is_moving
		
		_update_animation()
		return
		
	if _needs_overlap_check:
		_needs_overlap_check = false
		if has_node("DetectionArea"):
			_check_overlapping_interactables()
			
	var activity: Dictionary = get_data().get("activity", {})
	var current_act = get_activity().get("current_activity", "")
	
	if UiManager.is_any_blocking_ui_open():
		velocity = Vector2.ZERO
		move_and_slide()
		return
		
	if current_act != "":
		velocity = Vector2.ZERO
		move_and_slide()
		
		# Still allow interaction if there's an activity, so we can cancel it
		if Input.is_action_just_pressed("interact"):
			InteractManager.interact()
		return

	var direction: Vector2 = Input.get_vector(
		"move_left",
		"move_right",
		"move_up",
		"move_down"
	)

	velocity = direction * move_speed

	move_and_slide()

	var is_moving: bool = velocity != Vector2.ZERO

	if is_moving:
		var current_tile: Vector2i = SpawnManager.world_to_tile(global_position)
		if current_tile != _last_saved_tile:
			_last_saved_tile = current_tile
			CharacterManager.set_tile(self, current_tile)
	elif _was_moving:
		SpawnManager.save_character_position(self)

	_was_moving = is_moving
	_update_animation()

	if Input.is_action_just_pressed("interact"):
		InteractManager.interact()


func get_data() -> Dictionary:
	return SaveManager.data["player"]["characters"][character_id]


func get_stats() -> Dictionary:
	return get_data()["stats"]


func get_skills() -> Dictionary:
	return get_data()["skills"]


func get_job() -> Dictionary:
	return get_data()["job"]


func get_activity() -> Dictionary:
	return get_data()["activity"]


func add_energy(value: int) -> void:
	var stats: Dictionary = get_stats()
	stats["energy"] = clampi(
		int(stats["energy"]) + value,
		0,
		100
	)


func add_hunger(value: int) -> void:
	var stats: Dictionary = get_stats()
	stats["hunger"] = clampi(
		int(stats["hunger"]) + value,
		0,
		100
	)


func add_stress(value: int) -> void:
	var stats: Dictionary = get_stats()
	stats["stress"] = clampi(
		int(stats["stress"]) + value,
		0,
		100
	)





func add_skill(skill: String, amount: int) -> void:
	var skills: Dictionary = get_skills()

	if !skills.has(skill):
		return

	skills[skill] = int(skills[skill]) + amount


func _on_detection_area_area_entered(area: Area2D) -> void:
	if !area.visible:
		return
	if area is Interactable:
		InteractManager.enter(self, area)

func _check_overlapping_interactables() -> void:
	if !is_active:
		return
	if not has_node("DetectionArea"):
		return
	for area in $DetectionArea.get_overlapping_areas():
		if area is Interactable and area.visible:
			InteractManager.enter(self, area)
			break


func _on_detection_area_area_exited(area: Area2D) -> void:

	if area is Interactable:
		InteractManager.exit(self, area)

func command_activity(action_id: String) -> void:
	if action_id == "talk":
		print("Pasangan: Halo sayang!")
		return
		
	_queued_activity = action_id
	var target_object_name = ""
	
	match action_id:
		"sleep": target_object_name = "kasur"
		"cook": target_object_name = "kompor"
		"wash_clothes": target_object_name = "mesin_cuci"
		"wash_dishes": target_object_name = "wastafel"
		
	if target_object_name != "":
		var world = WorldManager.get_current_world()
		if world != null and world.has_node("objects/" + target_object_name):
			var obj = world.get_node("objects/" + target_object_name)
			_target_position = obj.global_position
			return
			
	# Jika objek tidak ditemukan atau aksi tidak butuh pindah, langsung jalankan
	_target_position = Vector2.INF
	ActivityManager.start_activity(self, action_id)

func _update_animation() -> void:
	var anim_sprite = get_node_or_null("AnimatedSprite2D")
	if not anim_sprite or anim_sprite.sprite_frames == null: return
	
	var is_moving = velocity.length() > 5.0
	var prefix = "walk-" if is_moving else "idle-"
	
	var dir_str = _last_direction
	if is_moving:
		var angle = velocity.angle()
		var degrees = rad_to_deg(angle)
		if degrees < 0: degrees += 360
		
		if degrees >= 337.5 or degrees < 22.5: dir_str = "kanan"
		elif degrees >= 22.5 and degrees < 67.5: dir_str = "serong-kanan-bawah"
		elif degrees >= 67.5 and degrees < 112.5: dir_str = "bawah"
		elif degrees >= 112.5 and degrees < 157.5: dir_str = "serong-kiri-bawah"
		elif degrees >= 157.5 and degrees < 202.5: dir_str = "kiri"
		elif degrees >= 202.5 and degrees < 247.5: dir_str = "serong-kiri-atas"
		elif degrees >= 247.5 and degrees < 292.5: dir_str = "atas"
		elif degrees >= 292.5 and degrees < 337.5: dir_str = "serong-kanan-atas"
		
		_last_direction = dir_str
	
	var anim_name = prefix + dir_str
	if anim_sprite.sprite_frames.has_animation(anim_name):
		anim_sprite.play(anim_name)
	elif anim_sprite.sprite_frames.has_animation(prefix + "bawah"):
		anim_sprite.play(prefix + "bawah")
