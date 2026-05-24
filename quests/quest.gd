class_name Quest
extends Resource


enum QuestState {
	NOT_STARTED,  # default; player hasn't seen this quest
	ACTIVE,       # player accepted, objectives in progress
	READY,        # all objectives complete, awaiting turn-in
	TURNED_IN     # complete and rewarded
}

var _state: QuestState = QuestState.NOT_STARTED

signal state_changed(quest: Quest, new_state: QuestState)

@export var id: String = ""
@export var title: String = ""
@export_multiline var description: String = ""

@export var objectives: Array[Objective] = []

@export_group("Dialogue")
@export var offer_dialogue: Dialogue
@export var in_progress_dialogue: Dialogue
@export var turn_in_dialogue: Dialogue
@export var completed_dialogue: Dialogue

@export_group("Rewards")
@export var rewards: Array[Reward] = []


func _recompute_state() -> void:
	print("Quest._recompute_state()")
	if _state == QuestState.NOT_STARTED or _state == QuestState.TURNED_IN:
		return
	
	var new_state: QuestState = _state
	var all_satisfied: bool = true
	for objective in objectives:
		if not objective.is_satisfied():
			all_satisfied = false
			break
	
	if all_satisfied and _state == QuestState.ACTIVE:
		print("Quest._recompute_state() transition to READY")
		_state = QuestState.READY
		state_changed.emit(self, _state)
	elif not all_satisfied and _state == QuestState.READY:
		print("Quest._recompute_state() transition to ACTIVE")
		_state = QuestState.ACTIVE
		state_changed.emit(self, _state)


func _on_objective_satisfied_changed() -> void:
	print("Quest._on_objective_satisfied_changed()")
	_recompute_state()


func activate() -> void:
	print("Quest.activate(" + id +")")
	
	if _state != QuestState.NOT_STARTED:
		printerr("Quest.activate(" + id + ") - expect NOT_STARTED but have " + str(_state))
	
	_state = QuestState.ACTIVE
	
	for objective in objectives:
		objective.activate()
		objective.satisfied_changed.connect(_on_objective_satisfied_changed)
		
	_recompute_state()


func turn_in() -> void:
	print("Quest.turn_in()")
	
	if _state != QuestState.READY:
		printerr("Quest.turn_in() cannot turn in when state is:", _state)
		return
	
	for objective in objectives:
		objective.consume()
	for reward in rewards:
		reward.apply()
	
	# set state
	_state = QuestState.TURNED_IN
	
	# deactivate
	deactivate()
	
	# emit state change signal
	state_changed.emit(self, _state)


func deactivate() -> void:
	print("Quest.deactivate(" + id + ")")
	for objective in objectives:
		objective.deactivate()
		objective.satisfied_changed.disconnect(_on_objective_satisfied_changed)
