@tool
class_name HarvestNodeMarker
extends Node2D


@export var spawn_weights: Array[SpawnWeight] = []

@onready var sprite_2d: Sprite2D = $Sprite2D
@onready var respawn_timer: Timer = $RespawnTimer


func _ready() -> void:
	if Engine.is_editor_hint():
		return
	
	# uncomment next line to make the wheat sprite disappear
	#sprite_2d.visible = false
	respawn_timer.timeout.connect(_on_respawn_timer_timeout)
	call_deferred("spawn_node")


func spawn_node() -> void:
	var node_type := pick_node_type()
	if node_type == null:
		return
	
	var zone := get_zone()
	var node := zone.spawn_harvest_node(node_type, global_position)
	node.harvested.connect(_on_node_harvested)


func _on_node_harvested() -> void:
	print("marker: my node was harvested")
	respawn_timer.start()


func _on_respawn_timer_timeout() -> void:
	spawn_node()


func pick_node_type() -> HarvestNodeType:
	if spawn_weights.is_empty():
		return null
	
	var total: float = 0.0
	for sw in spawn_weights:
		total += sw.weight
	
	var roll := randf() * total
	var cumulative: float = 0.0
	for sw in spawn_weights:
		cumulative += sw.weight
		if roll <= cumulative:
			return sw.node_type
	
	return spawn_weights[-1].node_type  # fallback for floating point edge case


func get_zone() -> Zone:
	return get_tree().get_first_node_in_group("zone") as Zone
