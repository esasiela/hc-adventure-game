class_name NPC
extends Interactable


@export var display_name: String = "Villager"

@onready var interact_indicator: Sprite2D = $InteractIndicator


func _ready() -> void:
	super()
	interact_indicator.visible = false

func _on_interact_target_acquired() -> void:
	interact_indicator.visible = true

func _on_interact_target_lost() -> void:
	interact_indicator.visible = false

func talk_to(player: Player) -> void:
	print("You're talking to ", display_name)
