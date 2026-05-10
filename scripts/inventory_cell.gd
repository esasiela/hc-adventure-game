class_name InventoryCell
extends Panel


const STYLE_NORMAL: StyleBox = preload("res://scenes/ui/cell_normal.tres")
const STYLE_FOCUSED: StyleBox = preload("res://scenes/ui/cell_focused.tres")

@onready var icon_texture: TextureRect = $IconTexture
@onready var quantity_label: Label = $QuantityLabel


signal focus_gained(item: Item)


var item: Item
var pending_item: Item
var pending_quantity: int = 1


func set_item(item: Item, quantity: int) -> void:
	pending_item = item
	pending_quantity = quantity
	if is_node_ready():
		_apply()

func _ready() -> void:
	focus_entered.connect(_on_focus_entered)
	focus_exited.connect(_on_focus_exited)
	_apply()

func _apply() -> void:
	if pending_item:
		item = pending_item
		icon_texture.texture = pending_item.icon
		quantity_label.text = str(pending_quantity) if pending_quantity > 1 else ""


func _on_focus_entered() -> void:
	add_theme_stylebox_override("panel", STYLE_FOCUSED)
	focus_gained.emit(item)


func _on_focus_exited() -> void:
	add_theme_stylebox_override("panel", STYLE_NORMAL)
