extends Node


var gold: int = 0
var inventory: Dictionary = {}  # Item -> int quantity

signal gold_changed(new_amount: int)
signal gold_added(amount: int)
signal gold_spent(amount: int)

signal item_added(item: Item, quantity: int)
signal item_removed(item: Item, quantity: int)


func add_gold(amount: int) -> void:
	if amount <= 0:
		return
	gold += amount
	gold_changed.emit(gold)


func spend_gold(amount: int) -> bool:
	if amount <= 0:
		return false
	if gold < amount:
		return false
	gold -= amount
	gold_changed.emit(gold)
	return true


func add_item(item: Item, quantity: int) -> void:
	inventory[item] = inventory.get(item, 0) + quantity
	#print("PlayerData.add_item(", item.id, ",", quantity, "), emitting signal")
	item_added.emit(item, quantity)


func remove_item(item: Item, quantity: int) -> bool:
	if inventory.get(item, 0) < quantity:
		return false
	inventory[item] -= quantity
	if inventory[item] <= 0:
		inventory.erase(item)
	
	#print("PlayerData.remove_item(", item.id, ",", quantity, "), emitting signal")
	item_removed.emit(item, quantity)
	return true


func print_inventory() -> void:
	print("--- Inventory ---")
	for item in inventory:
		print("  %3d : %s" % [inventory[item], item.id])
