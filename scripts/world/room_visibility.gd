extends Area2D

@export var max_darkness: float = 0.6
@export var fade_duration: float = 0.5

@export var polygon: Polygon2D
var original_color: Color

func _ready() -> void:
	# Jika polygon belum diatur via Inspector, cari otomatis
	if not polygon:
		# 1. Cari di dalam Area2D ini (sebagai child)
		for child in get_children():
			if child is Polygon2D:
				polygon = child
				break
				
		# 2. Jika tidak ketemu, cari di sebelahnya (sebagai sibling di dalam parent)
		if not polygon and get_parent():
			for sibling in get_parent().get_children():
				if sibling is Polygon2D:
					polygon = sibling
					break
			
	if polygon:
		# Simpan warna aslinya dan paksakan alpha ke max_darkness saat mulai
		original_color = polygon.color
		polygon.color.a = max_darkness
	else:
		push_error("Polygon2D tidak ditemukan untuk RoomVisibility di: " + name)
	
	# Hubungkan sinyal
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _on_body_entered(body: Node2D) -> void:
	if not polygon: return
	
	# Hanya merespon jika yang masuk adalah karakter aktif (pemain)
	if body is CharacterBody2D and body.get("is_active"):
		_fade_polygon(0.0)

func _on_body_exited(body: Node2D) -> void:
	if not polygon: return
	
	# Jika karakter aktif keluar, gelapkan lagi
	if body is CharacterBody2D and body.get("is_active"):
		_fade_polygon(max_darkness)

func _fade_polygon(target_alpha: float) -> void:
	var tween = create_tween()
	tween.tween_property(polygon, "color:a", target_alpha, fade_duration).set_trans(Tween.TRANS_SINE)
