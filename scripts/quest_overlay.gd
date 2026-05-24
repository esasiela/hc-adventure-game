extends CanvasLayer


const QuestOverlaySummaryScene := preload("res://scenes/ui/quest_overlay_summary.tscn")

@onready var quest_container: VBoxContainer = $VBoxContainer/QuestContainer


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	QuestLog.quest_accepted.connect(_on_quest_accepted)
	QuestLog.quest_turned_in.connect(_on_quest_completed)


func _on_quest_accepted(quest: Quest) -> void:
	var quest_summary := QuestOverlaySummaryScene.instantiate()
	quest_container.add_child(quest_summary)
	quest_summary.set_quest(quest)


func _on_quest_completed(quest: Quest) -> void:
	for child in quest_container.get_children():
		if child is QuestOverlaySummary and child.quest.id == quest.id:
			quest_container.remove_child(child)
			child.queue_free()
			break
