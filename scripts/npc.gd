class_name NPC
extends Interactable


const SERVICE_MENU_DIALOGUE: Dialogue = preload("res://dialogue/defaults/service_menu_dialogue.tres")

const QUEST_OFFER_DIALOGUE: Dialogue = preload("res://dialogue/defaults/quest_offer_dialogue.tres")
const QUEST_IN_PROGRESS_DIALOGUE: Dialogue = preload("res://dialogue/defaults/quest_in_progress_dialogue.tres")
const QUEST_TURN_IN_DIALOGUE: Dialogue = preload("res://dialogue/defaults/quest_turn_in_dialogue.tres")
const QUEST_COMPLETED_DIALOGUE: Dialogue = preload("res://dialogue/defaults/quest_completed_dialogue.tres")


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
	return dialogue or quest or vendor_inventory


func talk_to(player: Player) -> void:
	var services := _available_services()
	if services.is_empty():
		push_error("NPC.talk_to() npc [%s] offers no services" % display_name)
		return
	
	DialogueUI.choice_selected.connect(_on_dialogue_choice)
	DialogueUI.closed.connect(_on_dialogue_closed)
	
	if services.size() == 1:
		_start_service(services[0])
	else:
		DialogueUI.start(self, _build_service_menu(services))


func _available_services() -> Array[String]:
	var services: Array[String] = []
	if dialogue:
		services.append("dialogue")
	if quest:
		services.append("quest")
	if vendor_inventory:
		services.append("vendor")
	return services


func _build_service_menu(services: Array[String]) -> Dialogue:
	var menu := SERVICE_MENU_DIALOGUE.duplicate(true) as Dialogue
	# Filter choices to only those matching available services
	var filtered: Array[DialogueChoice] = []
	for choice in menu.choices:
		var service_name := choice.action.trim_prefix("service_")
		if service_name in services:
			filtered.append(choice)
	menu.choices = filtered
	return menu


func _on_dialogue_choice(choice: DialogueChoice) -> void:
	var action := choice.action
	
	match action:
		"accept_quest":
			QuestLog.accept_quest(quest)
			DialogueUI.close()
		"turn_in_quest":
			QuestLog.turn_in_quest(quest.id)
			DialogueUI.close()
	
	if action.begins_with("service_"):
		var service := action.trim_prefix("service_")
		_start_service(service)


func _start_service(service: String) -> void:
	match service:
		"dialogue":
			DialogueUI.start(self, dialogue)
		"quest":
			var quest_dialogue = _pick_quest_dialogue()
			if quest_dialogue:
				DialogueUI.start(self, quest_dialogue)
			else:
				push_error("NPC._start_service() npc [%s] no quest dialogue for quest [%s] state [%s]" % display_name, quest.id, QuestLog.get_state(quest.id))
				DialogueUI.close()
		"vendor":
			var vendor_ui := get_tree().get_first_node_in_group("vendor_ui") as VendorUI
			vendor_ui.open_for(self)
			DialogueUI.close()


func _pick_quest_dialogue() -> Dialogue:
	if quest:
		match QuestLog.get_state(quest.id):
			Quest.QuestState.NOT_STARTED:
				return quest.offer_dialogue if quest.offer_dialogue else QUEST_OFFER_DIALOGUE
			Quest.QuestState.ACTIVE:
				return quest.in_progress_dialogue if quest.in_progress_dialogue else QUEST_IN_PROGRESS_DIALOGUE
			Quest.QuestState.READY:
				return quest.turn_in_dialogue if quest.turn_in_dialogue else QUEST_TURN_IN_DIALOGUE
			Quest.QuestState.TURNED_IN:
				return quest.completed_dialogue if quest.completed_dialogue else QUEST_COMPLETED_DIALOGUE
	return null


func _on_dialogue_closed() -> void:
	DialogueUI.choice_selected.disconnect(_on_dialogue_choice)
	DialogueUI.closed.disconnect(_on_dialogue_closed)
