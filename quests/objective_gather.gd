class_name GatherObjective
extends Objective

@export var item: Item
@export var required_qty: int = 1

var progress_qty: int = 0
var _satisfied: bool = false


func is_complete() -> bool:
	if not item:
		printerr("GatherObjective.is_complete() - null item needs configuration")
		return false
	#return PlayerData.inventory.get(item, 0) >= required_qty
	return progress_qty >= required_qty

func get_progress_text() -> String:
	if not item:
		return ""
	var have: int = PlayerData.inventory.get(item, 0)
	return "%s: %d/%d" % [item.display_name, min(have, required_qty), required_qty]

func activate() -> void:
	print("GatherObjective.activate() connecting to signals")
	PlayerData.item_added.connect(_player_inventory_changed)
	PlayerData.item_removed.connect(_player_inventory_changed)
	
	# set initial properties
	_player_inventory_changed(item, 0)


func deactivate() -> void:
	PlayerData.item_added.disconnect(_player_inventory_changed)
	PlayerData.item_removed.disconnect(_player_inventory_changed)

func _player_inventory_changed(signal_item: Item, signal_qty: int) -> void:
	if item != signal_item:
		return

	var old_satisfied := _satisfied
	var old_qty:= progress_qty
	
	progress_qty = min(PlayerData.inventory.get(item, 0), required_qty)
	
	if progress_qty != old_qty:
		print("GatherObjective - emit progress_changed new=" + str(progress_qty) + " old=" + str(old_qty))
		progress_changed.emit()
	
	if is_complete() != old_satisfied:
		_satisfied = is_complete()
		print("GatherObjective - emit satisfied_changed new=" + str(is_complete()) + " old=" + str(old_satisfied))
		satisfied_changed.emit()


func consume() -> void:
	if item:
		# make sure you deactivate() before this, or a circle of pain!
		PlayerData.remove_item(item, required_qty)
	else:
		printerr("GatherObjective.consume() - null item needs configuration")
