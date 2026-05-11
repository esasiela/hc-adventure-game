class_name InventoryUI
extends CanvasLayer


const INVENTORY_CELL_SCENE: PackedScene = preload("res://scenes/ui/inventory_cell.tscn")

@onready var item_grid: GridContainer = $Panel/Body/ItemGrid
@onready var item_name_label: Label = $Panel/Body/Details/ItemNameLabel
@onready var item_description_label: Label = $Panel/Body/Details/ItemDescriptionLabel


func _ready() -> void:
	visible = false


func toggle() -> void:
	visible = not visible
	get_tree().paused = visible
	if visible:
		refresh()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("inventory_toggle"):
		var dialogue_ui := get_tree().get_first_node_in_group("dialogue_ui") as DialogueUI
		if dialogue_ui and dialogue_ui.visible:
			return
		toggle()
		get_viewport().set_input_as_handled()


func refresh() -> void:
	# clear existing cells
	for child in item_grid.get_children():
		child.queue_free()
	
	# create a cell for each item in inventory
	var first_cell: InventoryCell = null
	for item in PlayerData.inventory:
		var cell := INVENTORY_CELL_SCENE.instantiate() as InventoryCell
		item_grid.add_child(cell)
		cell.set_item(item, PlayerData.inventory[item])
		cell.focus_gained.connect(_on_cell_focus_gained)
		if first_cell == null:
			first_cell = cell
	
	if first_cell:
		first_cell.grab_focus.call_deferred()


func _on_cell_focus_gained(item: Item) -> void:
	item_name_label.text = item.display_name
	item_description_label.text = item.description
