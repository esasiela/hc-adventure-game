class_name NPC
extends Interactable


@export var display_name: String = "Villager"
@export var dialogue: Dialogue
@export var portrait: Texture2D

@onready var interact_indicator: Sprite2D = $InteractIndicator


func _ready() -> void:
	super()
	interact_indicator.visible = false

func _on_interact_target_acquired() -> void:
	interact_indicator.visible = true

func _on_interact_target_lost() -> void:
	interact_indicator.visible = false

func talk_to(player: Player) -> void:
	if not dialogue:
		return
	var dialogue_ui := get_tree().get_first_node_in_group("dialogue_ui") as DialogueUI
	dialogue_ui.show_dialogue(dialogue, self)
