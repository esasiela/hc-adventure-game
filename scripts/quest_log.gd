extends Node


# quest_id (string) -> Quest (deep duplicate)
var _active_quests: Dictionary = {}

# quest_id (string) -> Quest.QuestState (just the state)
var _quest_history: Dictionary = {}

signal quest_accepted(quest: Quest)
signal quest_turned_in(quest: Quest)


func get_state(id: String) -> Quest.QuestState:
	if _active_quests.has(id):
		return _active_quests[id]._state
	return _quest_history.get(id, Quest.QuestState.NOT_STARTED)


func get_state_str(id: String) -> String:
	return Quest.QuestState.find_key(get_state(id))


func accept_quest(quest_template: Quest) -> void:
	if not quest_template.are_preconditions_met():
		push_error("QuestLog.accept_quest(", quest_template.id, " preconditions not met")
		return
	
	if quest_template._state != Quest.QuestState.NOT_STARTED:
		printerr("QuestLog.accept_quest(", quest_template.id, ") cannot accept quest in state: ", str(quest_template.state))
		return
	
	# make a duplicate of the quest resource so we can mutate the data
	var runtime_quest := quest_template.duplicate(true) as Quest
	_active_quests[quest_template.id] = runtime_quest
	runtime_quest.activate()
	
	quest_accepted.emit(runtime_quest)


func turn_in_quest(quest_id: String) -> void:
	var quest = _active_quests.get(quest_id)
	if not quest:
		printerr("QuestLog.turn_in_quest(", quest_id, ") quest not found in _active_quests")
		return
	
	if quest._state != Quest.QuestState.READY:
		printerr("QuestLog.turn_in_quest(" + quest.id + ") cannot turn in quest in state: " + str(quest.state))
		return
	
	quest.turn_in()
	_active_quests.erase(quest.id)
	_quest_history[quest.id] = Quest.QuestState.TURNED_IN
	quest_turned_in.emit(quest)


func active_quests() -> Array:
	return _active_quests.values()


func get_active_quest(quest_id: String) -> Quest:
	return _active_quests.get(quest_id)
