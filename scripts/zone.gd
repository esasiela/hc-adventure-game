extends Node2D
class_name Zone


const WORLD_ITEM_SCENE: PackedScene = preload("res://scenes/world_item.tscn")
const HARVEST_NODE_SCENE: PackedScene = preload("res://scenes/harvest_node.tscn")

@onready var harvest_nodes: Node2D = $HarvestNodes
@onready var world_items: Node2D = $WorldItems


func _ready() -> void:
	var test_type: HarvestNodeType = preload("res://harvest_nodes/copper_vein.tres")
	spawn_harvest_node(test_type, Vector2(100, 100))


func spawn_world_item(item: Item, pos: Vector2, quantity: int) -> WorldItem:
	var instance := WORLD_ITEM_SCENE.instantiate() as WorldItem
	world_items.add_child(instance)
	instance.item = item
	instance.quantity = quantity
	instance.global_position = pos
	return instance


func spawn_harvest_node(node_type: HarvestNodeType, pos: Vector2) -> HarvestNode:
	var instance := HARVEST_NODE_SCENE.instantiate() as HarvestNode
	harvest_nodes.add_child(instance)
	instance.node_type = node_type
	instance.global_position = pos
	return instance
