extends Node2D

@export_file("*.tscn") var initial_zone_path: String = ""
@export var initial_spawn_name: String = ""

@onready var zone_container: Node2D = $ZoneContainer
@onready var player: CharacterBody2D = $Player

func _ready() -> void:
	ZoneManager.register_zone_container(zone_container)
	ZoneManager.register_player(player)
	
	# TODO replace quest registry with something dynamic
	QuestLog.register_quest(preload("res://quests/gather_copper/gather_copper.tres"))
	
	if initial_zone_path == "":
		push_error("No initial_zone_path set on Main")
		return
	var scene: PackedScene = load(initial_zone_path)
	ZoneManager.change_zone(scene, initial_spawn_name)
