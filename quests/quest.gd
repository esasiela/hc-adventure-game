class_name Quest
extends Resource


enum QuestState {
	NOT_STARTED,  # default; player hasn't seen this quest
	ACTIVE,       # player accepted, objectives in progress
	READY,        # all objectives complete, awaiting turn-in
	TURNED_IN     # complete and rewarded
}

var state: QuestState = QuestState.NOT_STARTED

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
	if state == QuestState.NOT_STARTED or state == QuestState.TURNED_IN:
		return
	
	var new_state: QuestState = state
	var all_satisfied: bool = true
	for objective in objectives:
		if not objective.is_satisfied():
			all_satisfied = false
			break
	
	if all_satisfied and state == QuestState.ACTIVE:
		print("Quest._recompute_state() transition to READY")
		state = QuestState.READY
		state_changed.emit(self, state)
	elif not all_satisfied and state == QuestState.READY:
		print("Quest._recompute_state() transition to ACTIVE")
		state = QuestState.ACTIVE
		state_changed.emit(self, state)


func _on_objective_satisfied_changed() -> void:
	print("Quest._on_objective_satisfied_changed()")
	_recompute_state()


func activate() -> void:
	print("Quest.activate(" + id +")")
	
	if state != QuestState.NOT_STARTED:
		printerr("Quest.activate(" + id + ") - expect NOT_STARTED but have " + str(state))
	
	state = QuestState.ACTIVE
	
	for objective in objectives:
		objective.activate()
		objective.satisfied_changed.connect(_on_objective_satisfied_changed)
		
	_recompute_state()


func turn_in() -> void:
	print("Quest.turn_in()")
	
	if state != QuestState.READY:
		printerr("Quest.turn_in() cannot turn in when state is:", state)
		return
	
	for objective in objectives:
		objective.consume()
	for reward in rewards:
		reward.apply()
	
	# set state
	state = QuestState.TURNED_IN
	
	# deactivate
	deactivate()
	
	# emit state change signal
	state_changed.emit(self, state)


func deactivate() -> void:
	print("Quest.deactivate(" + id + ")")
	for objective in objectives:
		objective.deactivate()
		objective.satisfied_changed.disconnect(_on_objective_satisfied_changed)
