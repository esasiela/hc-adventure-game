class_name Objective
extends Resource

@export var description: String = ""

# Subclasses override these
func is_complete() -> bool:
	return false

func get_progress_text() -> String:
	return ""

# Subclasses override if they need to take something from the player on turn-in
func consume() -> void:
	pass
