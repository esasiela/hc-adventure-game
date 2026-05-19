class_name NPC
extends Interactable


@export var display_name: String = "Villager"
@export var dialogue: Dialogue
@export var portrait: Texture2D
@export var vendor_inventory: VendorInventory
@export var quest: Quest

@onready var interact_indicator: Sprite2D = $InteractIndicator


func _ready() -> void:
	super()
	interact_indicator.visible = false

func _on_interact_target_acquired() -> void:
	interact_indicator.visible = true

func _on_interact_target_lost() -> void:
	interact_indicator.visible = false


func has_interaction() -> bool:
	if _pick_dialogue() != null:
		return true
	if vendor_inventory != null:
		return true
	return false


func talk_to(player: Player) -> void:
	var dialogue_to_play := _pick_dialogue()
	if not dialogue_to_play:
		return
	
	var dialogue_ui := get_tree().get_first_node_in_group("dialogue_ui") as DialogueUI
	if not dialogue_ui.choice_selected.is_connected(_on_dialogue_choice):
		dialogue_ui.choice_selected.connect(_on_dialogue_choice)
	if not dialogue_ui.closed.is_connected(_on_dialogue_closed):
		dialogue_ui.closed.connect(_on_dialogue_closed)
	dialogue_ui.show_dialogue(dialogue_to_play, self)
	
func _pick_dialogue() -> Dialogue:
	# Quest-aware: if NPC has a quest, route based on its state
	if quest:
		var state := QuestLog.get_state(quest)
		match state:
			QuestLog.QuestState.NOT_STARTED:
				if quest.offer_dialogue:
					return quest.offer_dialogue
			QuestLog.QuestState.ACTIVE:
				if quest.in_progress_dialogue:
					return quest.in_progress_dialogue
			QuestLog.QuestState.READY:
				if quest.turn_in_dialogue:
					return quest.turn_in_dialogue
			QuestLog.QuestState.TURNED_IN:
				if quest.completed_dialogue:
					return quest.completed_dialogue
	# Fallback: NPC's own dialogue field
	if dialogue:
		return dialogue
	return null

func _on_dialogue_choice(action: String) -> void:
	match action:
		"open_vendor":
			_open_vendor()
		"accept_quest":
			if quest:
				QuestLog.accept_quest(quest)
		"turn_in_quest":
			if quest:
				for objective in quest.objectives:
					objective.consume()
				for reward in quest.rewards:
					reward.apply()
				QuestLog.turn_in_quest(quest)
				# rewards will be applied here later


func _on_dialogue_closed() -> void:
	var dialogue_ui := get_tree().get_first_node_in_group("dialogue_ui") as DialogueUI
	dialogue_ui.choice_selected.disconnect(_on_dialogue_choice)
	dialogue_ui.closed.disconnect(_on_dialogue_closed)


func _open_vendor() -> void:
	var vendor_ui := get_tree().get_first_node_in_group("vendor_ui") as VendorUI
	vendor_ui.open_for(self)
