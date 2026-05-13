extends Node

# the container in the main scene where zones live
var zone_container: Node = null

# the persistent player
var player: Node = null

# current zone instance
var current_zone: Node = null

signal zone_changed(new_zone: Node)

func _ready() -> void:
	print("ZoneManager autoload ready")

func register_zone_container(container: Node) -> void:
	zone_container = container

func register_player(p: Node) -> void:
	player = p

func change_zone(scene_path: String, spawn_point_name: String) -> void:
	# free the old zone
	if current_zone:
		current_zone.queue_free()
		current_zone = null
	
	# load and instantiate the new zone
	var scene: PackedScene = load(scene_path)
	var new_zone := scene.instantiate()
	zone_container.add_child(new_zone)
	current_zone = new_zone
	
	# position the player at the spawn point
	await get_tree().process_frame  # wait for zone _ready
	_place_player_at_spawn(spawn_point_name)
	
	zone_changed.emit(new_zone)

func _place_player_at_spawn(spawn_point_name: String) -> void:
	if not current_zone:
		return
	var spawn := current_zone.find_child(spawn_point_name, true, false)
	if spawn:
		player.global_position = spawn.global_position
	else:
		push_warning("Spawn point not found: " + spawn_point_name)
