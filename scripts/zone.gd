extends Node2D
class_name Zone


const DEFAULT_SPAWN: String = "DefaultPlayerSpawn"

const WORLD_ITEM_SCENE: PackedScene = preload("res://scenes/world_item.tscn")
const HARVEST_NODE_SCENE: PackedScene = preload("res://scenes/harvest_node.tscn")

@onready var harvest_nodes: Node2D = $HarvestNodes
@onready var world_items: Node2D = $WorldItems
@onready var tilemap: TileMapLayer = $TileMapLayer


func _ready() -> void:
	var test_type: HarvestNodeType = preload("res://harvest_nodes/copper_vein.tres")
	spawn_harvest_node(test_type, Vector2(100, 100))


func get_camera_bounds() -> Rect2:
	var used_rect := tilemap.get_used_rect()
	var tile_size := tilemap.tile_set.tile_size
	return Rect2(
		used_rect.position * tile_size,
		used_rect.size * tile_size
	)


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
