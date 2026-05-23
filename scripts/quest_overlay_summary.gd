class_name QuestOverlaySummary
extends VBoxContainer


const QuestOverlayObjectiveScene := preload("res://scenes/ui/quest_overlay_objective.tscn")

@onready var quest_title: Label = $VBoxContainer/QuestTitle
@onready var objectives_container: VBoxContainer = $VBoxContainer/ObjectivesContainer

var quest: Quest


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


func set_quest(q: Quest) -> void:
	quest = q
	quest_title.text = q.title
	
	for objective in quest.objectives:
		var obj_scene := QuestOverlayObjectiveScene.instantiate()
		objectives_container.add_child(obj_scene)
		obj_scene.set_objective(objective)
