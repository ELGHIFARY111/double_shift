extends Node

signal item_purchased(item_id: String)


func get_shop_items(shop_id: String) -> Array:
	var result: Array = []

	for item_id: String in DataManager.items.keys():
		var item: Dictionary = DataManager.items[item_id]
		if String(item.get("shop", "")) == shop_id:
			result.append(item)

	return result


func get_shop_books(shop_id: String) -> Array:
	var result: Array = []

	for book_id: String in DataManager.books.keys():
		var book: Dictionary = DataManager.books[book_id]
		if String(book.get("shop", "")) == shop_id:
			result.append(book)

	return result


func get_shop_furniture(shop_id: String) -> Array:
	var result: Array = []

	for furniture_id: String in DataManager.furniture.keys():
		var furn: Dictionary = DataManager.furniture[furniture_id]
		if String(furn.get("shop", "")) == shop_id:
			result.append(furn)

	return result


func buy_item(item_id: String, amount: int = 1) -> bool:
	var item: Dictionary = DataManager.get_item(item_id)

	if item.is_empty():
		return false

	var price: int = int(item.get("buy_price", 0)) * amount

	if price <= 0:
		return false

	if SaveManager.get_money() < price:
		return false

	SaveManager.add_money(-price)
	InventoryManager.add_item(item_id, amount)

	item_purchased.emit(item_id)

	return true


func buy_book(book_id: String) -> bool:
	var book: Dictionary = DataManager.get_book(book_id)

	if book.is_empty():
		return false

	var price: int = int(book.get("buy_price", 0))

	if price <= 0:
		return false

	if SaveManager.get_money() < price:
		return false

	if InventoryManager.has_item(book_id):
		return false

	SaveManager.add_money(-price)
	InventoryManager.add_item(book_id, 1)

	item_purchased.emit(book_id)

	return true


func buy_furniture(furniture_id: String) -> bool:
	var furn: Dictionary = DataManager.get_furniture(furniture_id)

	if furn.is_empty():
		return false

	var owned: Dictionary = SaveManager.get_furniture()
	var level: int = int(owned.get(furniture_id, 0))

	var price: int = 0
	
	if level == 0:
		price = int(furn.get("buy_price", 0))
	else:
		if not furn.get("upgradeable", false):
			return false
		var levels = furn.get("levels", [])
		if level >= levels.size():
			return false
		price = int(levels[level].get("upgrade_price", 0))

	if SaveManager.get_money() < price:
		return false

	SaveManager.add_money(-price)
	owned[furniture_id] = level + 1
	SaveManager.save_game()
	FurnitureManager.refresh()

	item_purchased.emit(furniture_id)

	return true
