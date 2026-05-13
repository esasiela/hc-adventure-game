@tool
class_name HarvestNodeMarker
extends Node2D


@export var spawn_profile: SpawnProfile = null:
	set(value):
		spawn_profile = value
		_update_editor_visual()

@onready var sprite_2d: Sprite2D = $Sprite2D
@onready var respawn_timer: Timer = $RespawnTimer


func _ready() -> void:
	if Engine.is_editor_hint():
		_update_editor_visual()
		return
	
	# uncomment next line to make the wheat sprite disappear
	#sprite_2d.visible = false
	respawn_timer.timeout.connect(_on_respawn_timer_timeout)
	call_deferred("spawn_node")


func _update_editor_visual() -> void:
	if not is_node_ready():
		return
	if not Engine.is_editor_hint():
		return
		
	if spawn_profile == null or spawn_profile.weights == null or spawn_profile.weights.is_empty() or spawn_profile.weights[0] == null or spawn_profile.weights[0].node_type == null:
		# fall back to default wheat icon - leave whatever's already set
		sprite_2d.modulate = Color(1, 1, 1, 0.5)
		return
	
	sprite_2d.texture = spawn_profile.weights[0].node_type.harvest_texture
	sprite_2d.modulate = Color(1, 1, 1, 0.5)


func spawn_node() -> void:
	var node_type := pick_node_type()
	if node_type == null:
		return
	
	# TODO get_zone()
	var zone = ZoneManager.current_zone
	var node = zone.spawn_harvest_node(node_type, global_position)
	node.harvested.connect(_on_node_harvested)


func _on_node_harvested() -> void:
	respawn_timer.start()


func _on_respawn_timer_timeout() -> void:
	spawn_node()


func pick_node_type() -> HarvestNodeType:
	if spawn_profile == null or spawn_profile.weights == null or spawn_profile.weights.is_empty():
		return null
	
	var total: float = 0.0
	for sw in spawn_profile.weights:
		total += sw.weight
	
	var roll := randf() * total
	var cumulative: float = 0.0
	for sw in spawn_profile.weights:
		cumulative += sw.weight
		if roll <= cumulative:
			return sw.node_type
	
	return spawn_profile.weights[-1].node_type  # fallback for floating point edge case


func get_zone() -> Zone:
	return ZoneManager.current_zone
