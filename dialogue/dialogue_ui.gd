extends CanvasLayer


const CONTINUE_CHOICE: DialogueChoice = preload("res://dialogue/defaults/dialogue_choice_continue.tres")
const GOODBYE_CHOICE: DialogueChoice = preload("res://dialogue/defaults/dialogue_choice_goodbye.tres")

@onready var line_text: Label = $Panel/MarginContainer/Columns/LineText
@onready var choices: VBoxContainer = $Panel/MarginContainer/Columns/Choices
@onready var name_label: Label = $Panel/MarginContainer/Columns/NpcInfo/NameLabel
@onready var portrait: TextureRect = $Panel/MarginContainer/Columns/NpcInfo/Portrait


var current_dialogue: Dialogue
var current_npc: NPC
var current_line_index: int

signal closed
signal choice_selected(choice: DialogueChoice)


func _ready() -> void:
	pass


func start(npc: NPC, dialogue: Dialogue) -> void:
	current_npc = npc
	current_dialogue = dialogue
	current_line_index = 0
	name_label.text = npc.display_name
	portrait.texture = npc.portrait
	portrait.visible = npc.portrait != null
	visible = true
	_show_current_line()


func close() -> void:
	if not visible:
		return
	
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
	print("choice pressed: ", choice.text, " action=", choice.action)
	choice_selected.emit(choice)
	match choice.action:
		"close":
			close()
		"continue":
			current_line_index += 1
			_show_current_line()
