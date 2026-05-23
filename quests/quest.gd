class_name Quest
extends Resource

@export var id: String = ""
@export var title: String = ""
@export_multiline var description: String = ""

@export var objectives: Array[Objective] = []

@export_group("Dialogue")
@export var offer_dialogue: Dialogue
@export var in_progress_dialogue: Dialogue
@export var turn_in_dialogue: Dialogue
@export var completed_dialogue: Dialogue

@export_group("Rewards")
@export var rewards: Array[Reward] = []


func activate() -> void:
	print("Quest.activate(" + id +")")
	for objective in objectives:
		objective.activate()
	
	
func deactivate() -> void:
	print("Quest.deactivate(" + id + ")")
	for objective in objectives:
		objective.deactivate()
