class_name TalkToObjective
extends Objective

@export var target_npc_id: String = ""

var _satisfied: bool = false


func is_satisfied() -> bool:
	return _satisfied


func get_progress_text() -> String:
	if _satisfied:
		return "%s ✓" % description
	return description


func activate() -> void:
	DialogueUI.dialogue_started.connect(_on_dialogue_started)


func deactivate() -> void:
	if DialogueUI.dialogue_started.is_connected(_on_dialogue_started):
		DialogueUI.dialogue_started.disconnect(_on_dialogue_started)


func _on_dialogue_started(npc: NPC, _dialogue: Dialogue, _quest: Quest) -> void:
	if _satisfied:
		return
	if npc.id != target_npc_id:
		return
	_satisfied = true
	progress_changed.emit()
	satisfied_changed.emit()
