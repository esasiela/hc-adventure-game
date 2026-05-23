class_name Objective
extends Resource

@export var description: String = ""

signal satisfied_changed()
signal progress_changed()


# Subclasses override these
func is_complete() -> bool:
	return false

func get_progress_text() -> String:
	return ""

func activate() -> void:
	pass  # subclasses override

func deactivate() -> void:
	pass  # subclasses override

# Subclasses override if they need to take something from the player on turn-in
func consume() -> void:
	pass
