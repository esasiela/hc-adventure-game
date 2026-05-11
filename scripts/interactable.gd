class_name Interactable
extends Area2D

func _ready() -> void:
	area_entered.connect(_on_area_entered)
	area_exited.connect(_on_area_exited)

func _on_area_entered(area: Area2D) -> void:
	if not area.get_parent() is Player:
		return
	var player := area.get_parent() as Player
	player.interact_target = self
	_on_interact_target_acquired()

func _on_area_exited(area: Area2D) -> void:
	if not area.get_parent() is Player:
		return
	var player := area.get_parent() as Player
	if player.interact_target == self:
		player.interact_target = null
	_on_interact_target_lost()

# Subclasses override these to show/hide their indicator
func _on_interact_target_acquired() -> void:
	pass

func _on_interact_target_lost() -> void:
	pass

# Subclasses override this to define what happens on interact
func interact() -> void:
	pass
