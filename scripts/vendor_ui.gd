class_name VendorUI
extends CanvasLayer


const INVENTORY_CELL_SCENE: PackedScene = preload("res://scenes/ui/inventory_cell.tscn")

var current_vendor_inventory: VendorInventory

@onready var title_label: Label = $Panel/MarginContainer/Root/TitleLabel
@onready var body_label: Label = $Panel/MarginContainer/Root/BodyLabel
@onready var item_name_label: Label = $Panel/MarginContainer/Root/Header/ItemInfo/ItemNameLabel
@onready var item_icon: TextureRect = $Panel/MarginContainer/Root/Header/ItemInfo/ItemIcon
@onready var action_label: Label = $Panel/MarginContainer/Root/Header/TransactionInfo/ActionLabel
@onready var price_label: Label = $Panel/MarginContainer/Root/Header/TransactionInfo/PriceLabel
@onready var available_label: Label = $Panel/MarginContainer/Root/Header/TransactionInfo/AvailableLabel
@onready var transaction_qty_label: Label = $Panel/MarginContainer/Root/Header/TransactionInfo/TransactionQtyLabel
@onready var close_button: Button = $Panel/MarginContainer/Root/Footer/CloseButton
@onready var player_inventory_grid: GridContainer = $Panel/MarginContainer/Root/Grids/PlayerSide/PlayerInventoryGrid
@onready var vendor_stock_grid: GridContainer = $Panel/MarginContainer/Root/Grids/VendorSide/VendorStockGrid

signal opened
signal closed


func _ready() -> void:
	visible = false
	close_button.pressed.connect(close)

func open_for(npc: NPC) -> void:
	title_label.text = npc.display_name
	current_vendor_inventory = npc.vendor_inventory
	visible = true
	_populate_player_inventory()
	_populate_vendor_stock()
	opened.emit()
	

func _populate_player_inventory() -> void:
	for child in player_inventory_grid.get_children():
		child.queue_free()
	
	var first_cell: InventoryCell = null
	for item in PlayerData.inventory:
		var cell := INVENTORY_CELL_SCENE.instantiate() as InventoryCell
		player_inventory_grid.add_child(cell)
		cell.set_item(item, PlayerData.inventory[item])
		cell.focus_gained.connect(_on_player_cell_focused)
		cell.selected.connect(_on_player_cell_selected)
		if first_cell == null:
			first_cell = cell
	
	if first_cell:
		first_cell.grab_focus.call_deferred()
	else:
		close_button.grab_focus.call_deferred()


func _populate_vendor_stock() -> void:
	for child in vendor_stock_grid.get_children():
		child.queue_free()
	
	if not current_vendor_inventory:
		return
	
	for item in current_vendor_inventory.stock:
		var cell := INVENTORY_CELL_SCENE.instantiate() as InventoryCell
		vendor_stock_grid.add_child(cell)
		cell.set_item(item, 1)  # quantity 1 for display; really infinite
		cell.focus_gained.connect(_on_vendor_cell_focused)
		cell.selected.connect(_on_vendor_cell_selected)


func _on_vendor_cell_focused(item: Item) -> void:
	_update_header_for_buy(item)

func _on_vendor_cell_selected(item: Item) -> void:
	_buy_one(item)

func _update_header_for_buy(item: Item) -> void:
	item_name_label.text = item.display_name
	item_icon.texture = item.icon
	action_label.text = "Buying"
	price_label.text = "Price: %d gold" % item.value
	available_label.text = "Available: ∞"
	transaction_qty_label.text = "Quantity: 1"

func _buy_one(item: Item) -> void:
	if not PlayerData.spend_gold(item.value):
		# not enough gold; silent fail for MVP
		return
	PlayerData.add_item(item, 1)
	# vendor stock is infinite; no need to update vendor cell
	# but header's "available" stays at ∞, and player inventory has changed —
	# if you want the player grid to refresh to show the new item count, do that:
	_refresh_player_inventory_in_place(item)


func _refresh_player_inventory_in_place(item: Item) -> void:
	# find existing cell for this item
	for child in player_inventory_grid.get_children():
		var cell := child as InventoryCell
		if cell and cell.item == item:
			cell.update_quantity(PlayerData.inventory[item])
			return
	
	# not found — player didn't have this item before. Add a new cell.
	var cell := INVENTORY_CELL_SCENE.instantiate() as InventoryCell
	player_inventory_grid.add_child(cell)
	cell.set_item(item, PlayerData.inventory[item])
	cell.focus_gained.connect(_on_player_cell_focused)
	cell.selected.connect(_on_player_cell_selected)


func _on_player_cell_selected(item: Item) -> void:
	_sell_one(item)


func _sell_one(item: Item) -> void:
	if not PlayerData.inventory.has(item):
		return
	
	var focused_cell := get_viewport().gui_get_focus_owner() as InventoryCell
	
	PlayerData.remove_item(item, 1)
	PlayerData.add_gold(item.value)
	
	# Update cell or remove it if out of stock
	if PlayerData.inventory.has(item):
		# still have some left — update the cell's display
		if focused_cell and focused_cell.item == item:
			focused_cell.update_quantity(PlayerData.inventory[item])
			_update_header_for(item)
	else:
		# sold the last one — remove the cell
		if focused_cell:
			# find next cell to focus before removing
			var next_focus := _find_neighbor_cell(focused_cell)
			focused_cell.queue_free()
			if next_focus:
				next_focus.grab_focus.call_deferred()
			else:
				close_button.grab_focus.call_deferred()
				_clear_header()


func _find_neighbor_cell(cell: Node) -> Node:
	var children := player_inventory_grid.get_children()
	var idx := children.find(cell)
	if idx == -1:
		return null
	# try next, then previous
	if idx + 1 < children.size():
		return children[idx + 1]
	if idx > 0:
		return children[idx - 1]
	return null


func _update_header_for(item: Item) -> void:
	item_name_label.text = item.display_name
	item_icon.texture = item.icon
	action_label.text = "Selling"
	price_label.text = "Price: %d gold" % item.value
	available_label.text = "Available: %d" % PlayerData.inventory[item]
	transaction_qty_label.text = "Quantity: 1"


func _clear_header() -> void:
	item_name_label.text = "—"
	item_icon.texture = null
	action_label.text = "—"
	price_label.text = "—"
	available_label.text = "—"
	transaction_qty_label.text = "—"


func _refresh_after_transaction(item: Item) -> void:
	# remember focused cell info so we can restore focus after rebuild
	var focused_was := get_viewport().gui_get_focus_owner()
	var focused_item: Item = null
	if focused_was is InventoryCell:
		focused_item = (focused_was as InventoryCell).item
	
	_populate_player_inventory()
	
	# try to restore focus to the same item; if it's gone, focus first cell
	_restore_focus(focused_item)

func _restore_focus(target_item: Item) -> void:
	for child in player_inventory_grid.get_children():
		var cell := child as InventoryCell
		if cell and cell.item == target_item:
			cell.grab_focus.call_deferred()
			return
	# fallback: first cell, or close button
	_focus_first_cell()


func _focus_first_cell() -> void:
	var first := player_inventory_grid.get_child(0) if player_inventory_grid.get_child_count() > 0 else null
	print("focusing: ", first, " current focus owner: ", get_viewport().gui_get_focus_owner())
	if first:
		first.grab_focus.call_deferred()
	
	
	#print("vendor_ui.focus_first_cell()")
	#if player_inventory_grid.get_child_count() > 0:
	#	print("vendor_ui.focus_first_cell() child(0) grabbing focus")
	#	player_inventory_grid.get_child(0).grab_focus.call_deferred()
	else:
		print("vendor_ui.focus_first_cell() close button grabbing focus")
		close_button.grab_focus.call_deferred()

func _on_player_cell_focused(item: Item) -> void:
	_update_header_for(item)


func close() -> void:
	visible = false
	get_viewport().gui_release_focus()
	closed.emit()


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return

	if event.is_action_pressed("ui_cancel"):
		close()
		get_viewport().set_input_as_handled()
		return
	
	if event.is_action_pressed("interact"):
		get_viewport().set_input_as_handled()
