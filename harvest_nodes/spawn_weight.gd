class_name SpawnWeight
extends Resource

@export var node_type: HarvestNodeType
@export var weight: float = 1.0


func _init() -> void:
	resource_local_to_scene = true
