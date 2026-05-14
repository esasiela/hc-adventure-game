extends Node

# the container in the main scene where zones live
var zone_container: Node = null

# the persistent player
var player: Node = null

# current zone instance
var current_zone: Node = null

signal zone_changed(new_zone: Node)


func register_zone_container(container: Node) -> void:
	zone_container = container

func register_player(p: Node) -> void:
	player = p


func change_zone(scene: PackedScene, spawn_point_name: String) -> void:
	# clean up old zone(s)
	if current_zone:
		current_zone.queue_free()
		current_zone = null
	# also clear any pre-placed children that we don't track
	for child in zone_container.get_children():
		child.queue_free()
	
	var new_zone := scene.instantiate()
	zone_container.add_child(new_zone)
	current_zone = new_zone
	
	await get_tree().process_frame
	_place_player_at_spawn(spawn_point_name)
	_apply_camera_bounds()
	
	zone_changed.emit(new_zone)


func _place_player_at_spawn(spawn_point_name: String) -> void:
	if not current_zone:
		return
	var name_to_use := spawn_point_name if spawn_point_name != "" else Zone.DEFAULT_SPAWN
	var spawn := current_zone.find_child(name_to_use, true, false)
	if spawn:
		player.global_position = spawn.global_position
	else:
		push_warning("Spawn point not found: " + name_to_use)


func _apply_camera_bounds() -> void:
	if not current_zone or not player:
		return
	if not current_zone.has_method("get_camera_bounds"):
		return
	var bounds: Rect2 = current_zone.get_camera_bounds()
	var camera: Camera2D = player.get_node("Camera2D")
	if camera:
		camera.limit_left = int(bounds.position.x)
		camera.limit_top = int(bounds.position.y)
		camera.limit_right = int(bounds.position.x + bounds.size.x)
		camera.limit_bottom = int(bounds.position.y + bounds.size.y)
