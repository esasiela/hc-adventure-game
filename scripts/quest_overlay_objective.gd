class_name QuestOverlayObjective
extends HBoxContainer


@onready var progress_label: Label = $ProgressLabel
@onready var description_label: Label = $DescriptionLabel

var objective: Objective


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


func set_objective(o: Objective) -> void:
	objective = o
	objective.progress_changed.connect(_progress_changed)
	# intialize
	_progress_changed()


func _progress_changed() -> void:
	progress_label.text = objective.get_progress_text()
