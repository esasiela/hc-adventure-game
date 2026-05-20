class_name InventoryTab
extends Control

const INVENTORY_CELL_SCENE: PackedScene = preload("res://scenes/ui/inventory_cell.tscn")

@onready var item_grid: GridContainer = $Body/ItemGrid
@onready var item_name_label: Label = $Body/Details/ItemNameLabel
@onready var item_description_label: Label = $Body/Details/ItemDescriptionLabel


func refresh() -> void:
	for child in item_grid.get_children():
		child.queue_free()
	
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

func focus_first_cell() -> void:
	if item_grid.get_child_count() > 0:
		item_grid.get_child(0).grab_focus()
