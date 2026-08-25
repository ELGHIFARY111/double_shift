extends Node

signal minute_changed(hour, minute)
signal day_changed(day)
signal morning_arrived(day)

@export var real_seconds_per_game_minute := 1.0

const SPEEDS := [1, 2, 4, 8, 16]

var timer := 0.0
var time_speed := 1
var speed_index := 0
var running := false

func _ready():
	SaveManager.game_loaded.connect(_on_game_loaded)
	SaveManager.game_closed.connect(_on_game_closed)

func _on_game_loaded():
	running = true
	timer = 0.0

func _on_game_closed():
	running = false
	timer = 0.0

func cycle_speed():
	speed_index = (speed_index + 1) % SPEEDS.size()
	time_speed = SPEEDS[speed_index]

func get_speed() -> int:
	return time_speed

func get_day():
	return SaveManager.get_day()

func get_hour():
	return SaveManager.get_hour()

func get_minute():
	return SaveManager.get_minute()

func _process(delta):
	if !running:
		return
	timer += delta * time_speed
	while timer >= real_seconds_per_game_minute:
		timer -= real_seconds_per_game_minute
		var minute = SaveManager.get_minute() + 1
		var hour = SaveManager.get_hour()
		var day = SaveManager.get_day()
		if minute >= 60:
			minute = 0
			hour += 1
			if hour >= 24:
				hour = 0
				day += 1
				SaveManager.set_day(day)
				day_changed.emit(day)
		SaveManager.set_hour(hour)
		SaveManager.set_minute(minute)
		minute_changed.emit(hour, minute)

func skip_to_next_morning() -> void:
	var current_day = SaveManager.get_day()
	var next_day = current_day + 1
	
	SaveManager.set_day(next_day)
	SaveManager.set_hour(6)
	SaveManager.set_minute(0)
	
	day_changed.emit(next_day)
	minute_changed.emit(6, 0)
	morning_arrived.emit(next_day)
