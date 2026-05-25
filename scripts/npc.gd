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
	var services := _available_services()
	if services.is_empty():
		push_error("NPC.talk_to() npc [", display_name, "] offers no services, exiting conversation")
		return

	var dialogue_ui := get_tree().get_first_node_in_group("dialogue_ui") as DialogueUI
	
	if not dialogue_ui.choice_selected.is_connected(_on_dialogue_choice):
		dialogue_ui.choice_selected.connect(_on_dialogue_choice)
	
	if not dialogue_ui.closed.is_connected(_on_dialogue_closed):
		dialogue_ui.closed.connect(_on_dialogue_closed)

	if services.size() == 1:
		_start_service(services[0])
		return

	# multiple — show generated menu
	var menu := _build_service_menu()
	dialogue_ui.show_dialogue(menu, self)


func _build_service_menu() -> Dialogue:
	var menu := Dialogue.new()
	var line := DialogueLine.new()
	line.speaker = display_name
	line.text = "What can I help you with?"
	menu.lines = [line]
	
	menu.choices = []
	if quest and _pick_quest_dialogue() != null:
		var c := DialogueChoice.new()
		c.text = "About that work..."
		c.action = "open_quest"
		menu.choices.append(c)
	if vendor_inventory:
		var c := DialogueChoice.new()
		c.text = "Show me your wares"
		c.action = "open_vendor"
		menu.choices.append(c)
	if dialogue:
		var c := DialogueChoice.new()
		c.text = "Let's talk"
		c.action = "open_chat"
		menu.choices.append(c)
	var goodbye := DialogueChoice.new()
	goodbye.text = "Goodbye"
	goodbye.action = "close"
	menu.choices.append(goodbye)
	
	return menu


func _start_service(service: String) -> void:
	match service:
		"quest": _open_quest()
		"vendor": _open_vendor()
		"chat": _open_chat()


func _available_services() -> Array:
	var result: Array = []
	if quest and _pick_quest_dialogue() != null:
		result.append("quest")
	if vendor_inventory:
		result.append("vendor")
	if dialogue:
		result.append("chat")
	return result


func _pick_dialogue() -> Dialogue:
	# Quest-aware: if NPC has a quest, route based on its state
	if quest:
		match QuestLog.get_state(quest.id):
			Quest.QuestState.NOT_STARTED:
				if quest.offer_dialogue:
					return quest.offer_dialogue
			Quest.QuestState.ACTIVE:
				if quest.in_progress_dialogue:
					return quest.in_progress_dialogue
			Quest.QuestState.READY:
				if quest.turn_in_dialogue:
					return quest.turn_in_dialogue
			Quest.QuestState.TURNED_IN:
				if quest.completed_dialogue:
					return quest.completed_dialogue
	# Fallback: NPC's own dialogue field
	if dialogue:
		return dialogue
	return null

func _on_dialogue_choice(action: String) -> void:
	match action:
		"open_chat":
			_open_chat()
		"open_vendor":
			_open_vendor()
		"open_quest":
			_open_quest()
		"accept_quest":
			if quest:
				QuestLog.accept_quest(quest)
		"turn_in_quest":
			if quest and QuestLog.get_state(quest.id) == Quest.QuestState.READY:
				QuestLog.turn_in_quest(quest.id)
			else:
				push_error("NPC._on_dialogue_choice(", action, ") cannot turn in quest in state:", QuestLog.get_state_str(quest.id))
		"close":
			pass
		_:
			push_error("dialogue choice - action case did not match")


func _on_dialogue_closed() -> void:
	var dialogue_ui := get_tree().get_first_node_in_group("dialogue_ui") as DialogueUI
	dialogue_ui.choice_selected.disconnect(_on_dialogue_choice)
	dialogue_ui.closed.disconnect(_on_dialogue_closed)


func _open_chat() -> void:
	if not dialogue:
		return
	var dialogue_ui := get_tree().get_first_node_in_group("dialogue_ui") as DialogueUI
	dialogue_ui.show_dialogue.call_deferred(dialogue, self)


func _open_vendor() -> void:
	var vendor_ui := get_tree().get_first_node_in_group("vendor_ui") as VendorUI
	vendor_ui.open_for(self)


func _open_quest() -> void:
	if not quest:
		return
	var dialogue_to_play := _pick_quest_dialogue()
	if not dialogue_to_play:
		return
	var dialogue_ui := get_tree().get_first_node_in_group("dialogue_ui") as DialogueUI
	dialogue_ui.show_dialogue.call_deferred(dialogue_to_play, self, quest.rewards)


func _pick_quest_dialogue() -> Dialogue:
	if not quest:
		return null
	match QuestLog.get_state(quest.id):
		Quest.QuestState.NOT_STARTED:
			return quest.offer_dialogue
		Quest.QuestState.ACTIVE:
			return quest.in_progress_dialogue
		Quest.QuestState.READY:
			return quest.turn_in_dialogue
		Quest.QuestState.TURNED_IN:
			return quest.completed_dialogue
	return null
