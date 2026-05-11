@tool
class_name HarvestNode
extends Interactable


signal harvested


@export var node_type: HarvestNodeType:
	set(value):
		node_type = value
		_update_visual()

@onready var sprite_2d: Sprite2D = $Sprite2D


func _ready() -> void:
	super()
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
	
	for drop in roll_drops():
		var world_item := get_zone().spawn_world_item(drop.item, drop_pos, drop.quantity)
		world_item.drop_from(global_position)
		
	harvested.emit()
	queue_free()


func roll_drops() -> Array:
	var drops := []
	for entry in node_type.drop_table:
		if randf() <= entry.chance:
			var qty := randi_range(entry.min_quantity, entry.max_quantity)
			if qty > 0:
				drops.append({"item": entry.item, "quantity": qty})
	return drops


func _on_interact_target_acquired() -> void:
	sprite_2d.material.set_shader_parameter("active", true)


func _on_interact_target_lost() -> void:
	sprite_2d.material.set_shader_parameter("active", false)


func get_zone() -> Zone:
	return get_tree().get_first_node_in_group("zone") as Zone
