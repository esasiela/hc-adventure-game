extends CanvasLayer


const CONTINUE_CHOICE: DialogueChoice = preload("res://dialogue/defaults/dialogue_choice_continue.tres")
const GOODBYE_CHOICE: DialogueChoice = preload("res://dialogue/defaults/dialogue_choice_goodbye.tres")

@onready var line_text: Label = $DialoguePanel/MarginContainer/Columns/LineText
@onready var choices: VBoxContainer = $DialoguePanel/MarginContainer/Columns/Choices
@onready var name_label: Label = $DialoguePanel/MarginContainer/Columns/NpcInfo/NameLabel
@onready var portrait: TextureRect = $DialoguePanel/MarginContainer/Columns/NpcInfo/Portrait

@onready var quest_info: Panel = $QuestInfoPanel
@onready var quest_title_label: Label = $QuestInfoPanel/MarginContainer/VBoxContainer/QuestTitleLabel
@onready var quest_description_label: Label = $QuestInfoPanel/MarginContainer/VBoxContainer/QuestDescriptionLabel

@onready var quest_objectives_container: VBoxContainer = $QuestInfoPanel/MarginContainer/VBoxContainer/HBoxContainer/ObjectivesColumn/ObjectivesContainer
@onready var quest_rewards_container: VBoxContainer = $QuestInfoPanel/MarginContainer/VBoxContainer/HBoxContainer/RewardsColumn/RewardsContainer

var current_dialogue: Dialogue
var current_npc: NPC
var current_line_index: int

# ui-specific signals
signal closed
signal choice_selected(choice: DialogueChoice)

# dialogue manager signals
signal dialogue_started(npc: NPC, dialogue: Dialogue, quest: Quest)


func _ready() -> void:
	pass


func start(npc: NPC, dialogue: Dialogue, quest: Quest = null) -> void:
	current_npc = npc
	current_dialogue = dialogue
	current_line_index = 0

	name_label.text = npc.display_name
	portrait.texture = npc.portrait
	portrait.visible = npc.portrait != null

	quest_info.visible = quest != null
	if quest_info.visible:
		quest_title_label.text = quest.title
		quest_description_label.text = quest.description
		
		for objective in quest.objectives:
			var objective_label := Label.new()
			objective_label.add_theme_font_size_override("font_size", 32)
			objective_label.text = "  •  " + objective.get_progress_text()
			quest_objectives_container.add_child(objective_label)

		for reward in quest.rewards:
			var reward_label := Label.new()
			reward_label.add_theme_font_size_override("font_size", 32)
			reward_label.text = "  •  " + reward.description
			quest_rewards_container.add_child(reward_label)

	visible = true
	_show_current_line()
	
	dialogue_started.emit(npc, dialogue, quest)


func close() -> void:
	if not visible:
		return
	
	for objective in quest_objectives_container.get_children():
		objective.queue_free()
	
	for reward in quest_rewards_container.get_children():
		reward.queue_free()
	
	visible = false
	closed.emit()


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("ui_cancel"):
		close()
		get_viewport().set_input_as_handled()


func _show_current_line() -> void:
	var line: DialogueLine = current_dialogue.lines[current_line_index]
	line_text.text = line.text
	
	var is_last_line := current_line_index == current_dialogue.lines.size() - 1
	if is_last_line:
		var final_choices: Array[DialogueChoice] = []
		if current_dialogue.choices:
			final_choices.append_array(current_dialogue.choices)
		final_choices.append(GOODBYE_CHOICE)
		_render_choices(final_choices)
	else:
		_render_choices([CONTINUE_CHOICE, GOODBYE_CHOICE])


func _render_choices(choice_list: Array[DialogueChoice]) -> void:
	# clear existing
	for child in choices.get_children():
		choices.remove_child(child)
		child.queue_free()
	
	# build new
	var first_button: Button = null
	for choice in choice_list:
		var button := Button.new()
		button.text = choice.text
		button.add_theme_font_size_override("font_size", 40)
		button.pressed.connect(_on_choice_pressed.bind(choice))
		choices.add_child(button)
		
		if first_button == null:
			first_button = button
	if first_button:
		first_button.grab_focus.call_deferred()


func _on_choice_pressed(choice: DialogueChoice) -> void:
	choice_selected.emit(choice)
	match choice.action:
		"close":
			close()
		"continue":
			current_line_index += 1
			_show_current_line()
