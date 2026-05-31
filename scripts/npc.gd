class_name NPC
extends Interactable


const SERVICE_MENU_DIALOGUE: Dialogue = preload("res://dialogue/defaults/service_menu_dialogue.tres")
const QUEST_MENU_DIALOGUE: Dialogue = preload("res://dialogue/defaults/quest_menu_dialogue.tres")

const QUEST_OFFER_DIALOGUE: Dialogue = preload("res://dialogue/defaults/quest_offer_dialogue.tres")
const QUEST_IN_PROGRESS_DIALOGUE: Dialogue = preload("res://dialogue/defaults/quest_in_progress_dialogue.tres")
const QUEST_TURN_IN_DIALOGUE: Dialogue = preload("res://dialogue/defaults/quest_turn_in_dialogue.tres")
const QUEST_COMPLETED_DIALOGUE: Dialogue = preload("res://dialogue/defaults/quest_completed_dialogue.tres")


@export var id: String = ""
@export var display_name: String = "Villager"
@export var dialogue: Dialogue
@export var portrait: Texture2D
@export var vendor_inventory: VendorInventory
@export var quest_templates: Array[Quest] = []

var focused_quest_idx: int = -1

@onready var interact_indicator: Sprite2D = $InteractIndicator

func _ready() -> void:
	super()
	interact_indicator.visible = false

func _on_interact_target_acquired() -> void:
	if has_interaction():
		interact_indicator.visible = true


func _on_interact_target_lost() -> void:
	interact_indicator.visible = false


func has_interaction() -> bool:
	return dialogue or _has_quest_interaction() or vendor_inventory


func _has_quest_interaction() -> bool:
	return _get_quest_interactable_count() > 0


func _get_quest_interactable_count() -> int:
	if not quest_templates:
		return 0

	var count := 0
	for quest_template in quest_templates:
		if _is_quest_interactable(quest_template):
			count += 1
	
	return count


func _is_quest_interactable(quest: Quest) -> bool:
	var quest_state := QuestLog.get_state(quest.id)
	return quest_state != Quest.QuestState.NOT_STARTED or quest.are_preconditions_met()


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
	if _has_quest_interaction():
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
	var action_tokens := choice.action.split(":")
	var action_cmd := action_tokens[0]
	var action_index: int = action_tokens[1].to_int() if len(action_tokens) > 1 else -1
	
	match action_cmd:
		"focus_quest":
			var template_quest := quest_templates[action_index]
			focused_quest_idx = action_index

			var quest_dialogue = _pick_quest_dialogue(template_quest)
			if quest_dialogue:
				var runtime_quest = QuestLog.get_active_quest(template_quest.id)
				var quest_for_ui = runtime_quest if runtime_quest else template_quest
				DialogueUI.start(self, quest_dialogue, quest_for_ui)
			else:
				push_error("NPC._start_service() npc [%s] no quest dialogue for quest [%s] state [%s]" % display_name, template_quest.id, QuestLog.get_state(template_quest.id))
				DialogueUI.close()

		"accept_quest":
			QuestLog.accept_quest(quest_templates[focused_quest_idx])
			DialogueUI.close()
		"turn_in_quest":
			QuestLog.turn_in_quest(quest_templates[focused_quest_idx].id)
			DialogueUI.close()
	
	if action_cmd.begins_with("service_"):
		var service := action_cmd.trim_prefix("service_")
		_start_service(service)


func _start_service(service: String) -> void:
	match service:
		"dialogue":
			DialogueUI.start(self, dialogue)
		"quest":
			var count := _get_quest_interactable_count()
			if count == 1:
				for quest_idx in quest_templates.size():
					var template_quest := quest_templates[quest_idx]
					if _is_quest_interactable(template_quest):
						# we know there's only one so short-circuit here
						var focus_quest_choice := DialogueChoice.new()
						focus_quest_choice.action = "focus_quest:" + str(quest_idx)
						_on_dialogue_choice(focus_quest_choice)
						return
				# you're not gonna make it here but just in case
				return
			
			# generate a menu of quests to choose
			var quest_menu := QUEST_MENU_DIALOGUE.duplicate(true) as Dialogue
			
			for quest_idx in quest_templates.size():
				var template_quest := quest_templates[quest_idx]
				if not _is_quest_interactable(template_quest):
					continue
				
				var choice := DialogueChoice.new()
				choice.action = "focus_quest:" + str(quest_idx)
				choice.text = template_quest.title
				quest_menu.choices.append(choice)
				
			DialogueUI.start(self, quest_menu)
		"vendor":
			var vendor_ui := get_tree().get_first_node_in_group("vendor_ui") as VendorUI
			vendor_ui.open_for(self)
			DialogueUI.close()


func _pick_quest_dialogue(quest: Quest) -> Dialogue:
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
	focused_quest_idx = -1
	DialogueUI.choice_selected.disconnect(_on_dialogue_choice)
	DialogueUI.closed.disconnect(_on_dialogue_closed)
