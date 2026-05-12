class_name VendorUI
extends CanvasLayer

@onready var title_label: Label = $Panel/MarginContainer/Root/TitleLabel
@onready var body_label: Label = $Panel/MarginContainer/Root/BodyLabel
@onready var close_button: Button = $Panel/MarginContainer/Root/Footer/CloseButton

signal opened
signal closed

func _ready() -> void:
	visible = false
	close_button.pressed.connect(close)

func open_for(npc: NPC) -> void:
	title_label.text = npc.display_name
	body_label.text = "Welcome to %s's shop!" % npc.display_name
	visible = true
	close_button.grab_focus.call_deferred()
	opened.emit()

func close() -> void:
	visible = false
	closed.emit()

func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return

	if event.is_action_pressed("ui_cancel"):
		close()
		get_viewport().set_input_as_handled()
		return
	
	if event.is_action_pressed("interact"):
		get_viewport().set_input_as_handled()
