extends Node

enum QuestState {
	NOT_STARTED,  # default; player hasn't seen this quest
	ACTIVE,       # player accepted, objectives in progress
	READY,        # all objectives complete, awaiting turn-in
	TURNED_IN     # complete and rewarded
}

# quest_id (string) -> QuestState
var quest_states: Dictionary = {}

signal quest_accepted(quest: Quest)
signal quest_state_changed(quest: Quest, new_state: QuestState)


func _ready() -> void:
	PlayerData.item_added.connect(_on_inventory_changed)
	PlayerData.item_removed.connect(_on_inventory_changed)

func _on_inventory_changed(_item: Item, _quantity: int) -> void:
	check_quest_progress()

func get_state(quest: Quest) -> QuestState:
	if not quest:
		return QuestState.NOT_STARTED
	return quest_states.get(quest.id, QuestState.NOT_STARTED)

func accept_quest(quest: Quest) -> void:
	if get_state(quest) != QuestState.NOT_STARTED:
		return
	quest_states[quest.id] = QuestState.ACTIVE
	quest_accepted.emit(quest)
	quest_state_changed.emit(quest, QuestState.ACTIVE)
	check_quest_progress()


func turn_in_quest(quest: Quest) -> void:
	if get_state(quest) != QuestState.READY:
		return
	quest_states[quest.id] = QuestState.TURNED_IN
	quest_state_changed.emit(quest, QuestState.TURNED_IN)

func get_active_quests() -> Array:
	var result: Array = []
	for quest_id in quest_states:
		if quest_states[quest_id] == QuestState.ACTIVE:
			result.append(quest_id)
	return result

func is_quest_ready(quest: Quest) -> bool:
	if get_state(quest) != QuestState.ACTIVE:
		return false
	for obj in quest.objectives:
		if not obj.is_complete():
			return false
	return true

# Called periodically (or on inventory changes) to promote ACTIVE quests to READY
func check_quest_progress() -> void:
	for quest_id in quest_states:
		if quest_states[quest_id] != QuestState.ACTIVE:
			continue
		var quest: Quest = _get_quest_by_id(quest_id)
		if quest and is_quest_ready(quest):
			quest_states[quest_id] = QuestState.READY
			quest_state_changed.emit(quest, QuestState.READY)

# Helper to find a Quest resource by id (you'd build a registry later; for now load by path)
var _quest_registry: Dictionary = {}

func register_quest(quest: Quest) -> void:
	_quest_registry[quest.id] = quest

func _get_quest_by_id(quest_id: String) -> Quest:
	return _quest_registry.get(quest_id)
