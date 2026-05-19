class_name GatherObjective
extends Objective

@export var item: Item
@export var required_quantity: int = 1

func is_complete() -> bool:
	if not item:
		return false
	return PlayerData.inventory.get(item, 0) >= required_quantity

func get_progress_text() -> String:
	if not item:
		return ""
	var have: int = PlayerData.inventory.get(item, 0)
	var capped: int = min(have, required_quantity)
	return "%s: %d/%d" % [item.display_name, capped, required_quantity]

func consume() -> void:
	if item:
		PlayerData.remove_item(item, required_quantity)
