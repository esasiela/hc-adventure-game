class_name Door
extends Area2D

@export_file("*.tscn") var target_zone_path: String = ""
@export var target_spawn: String = "DefaultPlayerSpawn"

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
	print("door triggered, target path=", target_zone_path, " spawn=", target_spawn)
	if not body is Player:
		return
	if target_zone_path == "":
		push_warning("Door has no target_zone_path set")
		return
	var scene: PackedScene = load(target_zone_path)
	if not scene:
		push_warning("Failed to load: " + target_zone_path)
		return
	ZoneManager.change_zone.call_deferred(scene, target_spawn)
