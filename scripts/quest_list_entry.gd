class_name QuestListEntry
extends Panel

const STYLE_NORMAL: StyleBox = preload("res://scenes/ui/cell_normal.tres")
const STYLE_FOCUSED: StyleBox = preload("res://scenes/ui/cell_focused.tres")

@onready var title_label: Label = $MarginContainer/HBoxContainer/TitleLabel
@onready var state_label: Label = $MarginContainer/HBoxContainer/StateLabel

var quest: Quest

signal focus_gained(quest: Quest)

var pending_quest: Quest

func _ready() -> void:
	focus_entered.connect(_on_focus_entered)
	focus_exited.connect(_on_focus_exited)
	add_theme_stylebox_override("panel", STYLE_NORMAL)
	_apply()

func set_quest(q: Quest) -> void:
	pending_quest = q
	if is_node_ready():
		_apply()

func _apply() -> void:
	if not pending_quest:
		return
	quest = pending_quest
	title_label.text = quest.title
	state_label.text = _state_text()

func _state_text() -> String:
	match quest.state:
		Quest.QuestState.ACTIVE:
			return "Active"
		Quest.QuestState.READY:
			return "Ready to turn in!"
		Quest.QuestState.TURNED_IN:
			return "Complete"
		_:
			return ""

func _on_focus_entered() -> void:
	add_theme_stylebox_override("panel", STYLE_FOCUSED)
	if quest:
		focus_gained.emit(quest)

func _on_focus_exited() -> void:
	add_theme_stylebox_override("panel", STYLE_NORMAL)
