extends Node

var items := {}
var recipes := {}
var furniture := {}
var books := {}
var jobs := {}
var skills := {}
var npcs := {}
var dialogues := {}
var activities := {}
var destinations = {}
var quests := {}

func _ready():
	load_all()

func load_all():
	items = load_database("res://resources/data/items.json", "items")
	recipes = load_database("res://resources/data/recipes.json", "recipes")
	furniture = load_database("res://resources/data/furniture.json", "furniture")
	books = load_database("res://resources/data/buku.json", "books")
	jobs = load_database("res://resources/data/jobs.json", "jobs")
	skills = load_database("res://resources/data/skills.json", "skills")
	npcs = load_database("res://resources/data/npc.json", "npcs")
	dialogues = load_database("res://resources/data/dialogue.json", "dialogues")
	activities = load_database("res://resources/data/activity.json", "activities")
	destinations = load_database("res://resources/data/destination.json", "destinations")
	quests = load_database("res://resources/data/quests.json", "quests")

func load_database(path: String, key: String) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("Tidak dapat membuka : " + path)
		return {}
	var json = JSON.parse_string(file.get_as_text())
	if json == null:
		push_error("JSON Error : " + path)
		return {}
	var result := {}
	for data in json[key]:
		result[data["id"]] = data
	return result

func get_item(id: String) -> Dictionary:
	return items.get(id, {})

func get_recipe(id: String) -> Dictionary:
	return recipes.get(id, {})

func get_book(id: String) -> Dictionary:
	return books.get(id, {})

func get_job(id: String) -> Dictionary:
	return jobs.get(id, {})

func get_skill(id: String) -> Dictionary:
	return skills.get(id, {})

func get_furniture(id: String) -> Dictionary:
	return furniture.get(id, {})

func get_quest(id: String) -> Dictionary:
	return quests.get(id, {})

func get_npc(id: String) -> Dictionary:
	return npcs.get(id, {})

func get_dialogue(id: String) -> Dictionary:
	return dialogues.get(id, {})

func get_activity(id: String) -> Dictionary:
	return activities.get(id, {})

func get_destination(id: String) -> Dictionary:
	return destinations.get(id, {})

func get_all_furniture() -> Dictionary:
	return furniture

func get_all_destination() -> Dictionary:
	return destinations

func get_all_recipes() -> Dictionary:
	return recipes

func get_all_jobs() -> Dictionary:
	return jobs
