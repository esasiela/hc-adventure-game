class_name DialogueUI
extends CanvasLayer

@onready var speaker_label: Label = $Panel/MarginContainer/Root/SpeakerLabel
@onready var text_label: Label = $Panel/MarginContainer/Root/Body/TextLabel
@onready var portrait_texture: TextureRect = $Panel/MarginContainer/Root/Body/PortraitTexture
@onready var choices_container: VBoxContainer = $Panel/MarginContainer/Root/Footer/ChoicesContainer
@onready var continue_hint: Label = $Panel/MarginContainer/Root/Footer/ContinueHint
@onready var rewards_panel: HBoxContainer = $Panel/MarginContainer/Root/RewardsPanel
@onready var rewards_list: VBoxContainer = $Panel/MarginContainer/Root/RewardsPanel/RewardsList

var current_dialogue: Dialogue
var current_line_index: int = 0

signal closed
signal choice_selected(action: String)

func _ready() -> void:
	visible = false

func show_dialogue(dialogue: Dialogue, npc: NPC = null, rewards: Array = []) -> void:
	current_dialogue = dialogue
	current_line_index = 0
	
	if npc and npc.portrait:
		portrait_texture.texture = npc.portrait
		portrait_texture.visible = true
	else:
		portrait_texture.visible = false
	
	visible = true
	_show_current_line()
	show_rewards(rewards)


func show_rewards(rewards: Array) -> void:
	for child in rewards_list.get_children():
		rewards_list.remove_child(child)
		child.queue_free()
	
	if rewards.is_empty():
		rewards_panel.visible = false
		return
	
	for reward in rewards:
		var label := Label.new()
		label.text = "• " + reward.description
		label.add_theme_font_size_override("font_size", 20)
		rewards_list.add_child(label)
	
	rewards_panel.visible = true


func clear_rewards() -> void:
	rewards_panel.visible = false


func _show_current_line() -> void:
	var line: DialogueLine = current_dialogue.lines[current_line_index]
	speaker_label.text = line.speaker
	text_label.text = line.text
	
	var is_last_line := current_line_index == current_dialogue.lines.size() - 1
	
	if is_last_line:
		continue_hint.visible = false
		_show_choices()
	else:
		continue_hint.visible = true
		_clear_choices()

func _show_choices() -> void:
	_clear_choices()
	for choice in current_dialogue.choices:
		var button := Button.new()
		button.add_theme_font_size_override("font_size", 40)
		button.text = choice.text
		button.pressed.connect(_on_choice_pressed.bind(choice.action))
		choices_container.add_child(button)
	
	# focus the first choice for controller nav
	if choices_container.get_child_count() > 0:
		print("dialogue showing choices, count=", choices_container.get_child_count(), " grabbing focus on first")
		choices_container.get_child(0).grab_focus.call_deferred()
	else:
		print("dialogue showing zero or fewer choices")


func _clear_choices() -> void:
	for child in choices_container.get_children():
		choices_container.remove_child(child)
		child.queue_free()


func _on_choice_pressed(action: String) -> void:
	choice_selected.emit(action)
	if action in ["close", "open_vendor", "accept_quest", "turn_in_quest"]:
		close()


func close() -> void:
	visible = false
	_clear_choices()
	get_viewport().gui_release_focus()
	closed.emit()


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	
	if event.is_action_pressed("ui_cancel"):
		close()
		get_viewport().set_input_as_handled()
		return
	
	if event.is_action_pressed("interact"):
		# advance to next line, or do nothing if on last line (choices handle it)
		if current_line_index < current_dialogue.lines.size() - 1:
			current_line_index += 1
			_show_current_line()
		get_viewport().set_input_as_handled()
