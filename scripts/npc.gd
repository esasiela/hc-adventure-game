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
	dialogue_ui.choice_selected.connect(_on_dialogue_choice)
	dialogue_ui.closed.connect(_on_dialogue_closed)
	dialogue_ui.show_dialogue(dialogue, self)


func _on_dialogue_choice(action: String) -> void:
	match action:
		"open_vendor":
			_open_vendor()


func _on_dialogue_closed() -> void:
	var dialogue_ui := get_tree().get_first_node_in_group("dialogue_ui") as DialogueUI
	dialogue_ui.choice_selected.disconnect(_on_dialogue_choice)
	dialogue_ui.closed.disconnect(_on_dialogue_closed)


func _open_vendor() -> void:
	var vendor_ui := get_tree().get_first_node_in_group("vendor_ui") as VendorUI
	vendor_ui.open_for(self)
