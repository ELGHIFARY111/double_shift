extends Node

signal inventory_changed

var running := false

func _ready():
	SaveManager.game_loaded.connect(_on_game_loaded)
	SaveManager.game_closed.connect(_on_game_closed)

func _on_game_loaded():
	running = true
	inventory_changed.emit()

func _on_game_closed():
	running = false

func add_item(item_id: String, amount: int = 1):
	if !running:
		return
	var inventory = get_inventory()
	for slot in inventory:
		if slot["item_id"] == item_id:
			slot["amount"] += amount
			inventory_changed.emit()
			SaveManager.save_game()
			return
	inventory.append({"item_id": item_id, "amount": amount})
	inventory_changed.emit()
	SaveManager.save_game()

func remove_item(item_id: String, amount: int = 1) -> bool:
	if !running:
		return false
	var inventory = get_inventory()
	for slot in inventory:
		if slot["item_id"] != item_id:
			continue
		if slot["amount"] < amount:
			return false
		slot["amount"] -= amount
		if slot["amount"] <= 0:
			inventory.erase(slot)
		inventory_changed.emit()
		SaveManager.save_game()
		return true
	return false

func sell_item(item_id: String):
	if !running:
		return
	if get_amount(item_id) <= 0:
		return
	var item = DataManager.get_item(item_id)
	if item.is_empty():
		return
	if !item["sellable"]:
		return
	SaveManager.add_money(item["sell_price"])
	remove_item(item_id)

func use_item(character, item_id: String):
	if !running:
		return
	var item = DataManager.get_item(item_id)
	if item.is_empty():
		return
	if !item["consumable"]:
		return
	character.add_energy(item["effects"]["energy"])
	character.add_hunger(item["effects"]["hunger"])
	character.add_stress(item["effects"]["stress"])

	
	if int(item["effects"].get("hunger", 0)) > 0:
		var player = SaveManager.get_player()
		player["dirty_dishes"] = mini(int(player.get("dirty_dishes", 0)) + 1, 20)
		
	remove_item(item_id)

func has_item(item_id: String, amount: int = 1) -> bool:
	if !running:
		return false
	for slot in get_inventory():
		if slot["item_id"] == item_id:
			return slot["amount"] >= amount
	return false

func get_amount(item_id: String) -> int:
	if !running:
		return 0
	for slot in get_inventory():
		if slot["item_id"] == item_id:
			return slot["amount"]
	return 0

func get_slots() -> Array:
	if !running:
		return []
	return get_inventory()

func clear():
	if !running:
		return
	get_inventory().clear()
	inventory_changed.emit()
	SaveManager.save_game()

func can_craft(recipe: Dictionary) -> bool:
	if !running:
		return false
	if recipe.is_empty():
		return false
	for ingredient in recipe["ingredients"]:
		if !has_item(ingredient["item_id"], ingredient["amount"]):
			return false
	return true

func craft(recipe_id: String) -> bool:
	if !running:
		return false
	var recipe = DataManager.get_recipe(recipe_id)
	if recipe.is_empty():
		return false
	if !can_craft(recipe):
		return false
	for ingredient in recipe["ingredients"]:
		remove_item(ingredient["item_id"], ingredient["amount"])
	add_item(recipe["result"]["item_id"], recipe["result"]["amount"])
	return true

func get_inventory():
	return SaveManager.get_inventory()
