extends Node2D
class_name Zone


const WORLD_ITEM_SCENE: PackedScene = preload("res://scenes/world_item.tscn")

@onready var harvest_nodes: Node2D = $HarvestNodes
@onready var world_items: Node2D = $WorldItems


func spawn_world_item_x(scene: PackedScene, pos: Vector2) -> Node:
	# TODO return type can be WorldItem, yes?
	var item := scene.instantiate()
	world_items.add_child(item)
	item.global_position = pos
	return item


func spawn_world_item(item: Item, pos: Vector2, quantity: int) -> WorldItem:
	var instance := WORLD_ITEM_SCENE.instantiate() as WorldItem
	world_items.add_child(instance)
	instance.item = item
	instance.quantity = quantity
	instance.global_position = pos
	return instance
