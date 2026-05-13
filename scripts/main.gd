extends Node2D

@onready var zone_container: Node2D = $ZoneContainer
@onready var player: CharacterBody2D = $Player

func _ready() -> void:
	ZoneManager.register_zone_container(zone_container)
	ZoneManager.register_player(player)
	# set the current zone reference
	if zone_container.get_child_count() > 0:
		ZoneManager.current_zone = zone_container.get_child(0)
	# apply camera bounds for the initial zone
	await get_tree().process_frame
	ZoneManager._place_player_at_spawn("DefaultPlayerSpawn")
	ZoneManager._apply_camera_bounds()
