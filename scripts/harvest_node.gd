@tool
class_name HarvestNode
extends Area2D

signal harvested


@export var node_type: HarvestNodeType:
	set(value):
		node_type = value
		_update_visual()

@onready var sprite_2d: Sprite2D = $Sprite2D


func _ready() -> void:
	sprite_2d.material = sprite_2d.material.duplicate()
	sprite_2d.material.set_shader_parameter("active", false)
	_update_visual()

func _update_visual() -> void:
	if not is_node_ready():
		return
	if node_type:
		sprite_2d.texture = node_type.harvest_texture


func harvest() -> void:
	var drop_pos := global_position
	var drop_item := node_type.drop_item
	var drop_qty := node_type.drop_quantity
	
	var world_item := get_zone().spawn_world_item(drop_item, drop_pos, drop_qty)
	world_item.drop_from(drop_pos)
	
	harvested.emit()	
	queue_free()


func _on_body_entered(body: Node2D) -> void:
	if not body is Player:
		return
	var player: Player = body
	
	sprite_2d.material.set_shader_parameter("active", true)
	player.interact_target = self


func _on_body_exited(body: Node2D) -> void:
	if not body is Player:
		return
	var player: Player = body
	
	sprite_2d.material.set_shader_parameter("active", false)
	if player.interact_target == self:
		player.interact_target = null

func get_zone() -> Zone:
	return get_tree().get_first_node_in_group("zone") as Zone
