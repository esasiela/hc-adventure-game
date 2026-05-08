extends Node


var inventory: Dictionary = {}  # Item -> int quantity

signal item_added(item: Item, quantity: int)
signal item_removed(item: Item, quantity: int)

	
func add_item(item: Item, quantity: int) -> void:
	inventory[item] = inventory.get(item, 0) + quantity
	print_inventory()
	item_added.emit(item, quantity)


func remove_item(item: Item, quantity: int) -> bool:
	if inventory.get(item, 0) < quantity:
		return false
	inventory[item] -= quantity
	if inventory[item] <= 0:
		inventory.erase(item)
	item_removed.emit(item, quantity)
	return true


func print_inventory() -> void:
	print("--- Inventory ---")
	for item in inventory:
		print("  %3d : %s" % [inventory[item], item.id])
