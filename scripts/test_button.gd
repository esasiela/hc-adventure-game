extends Control

func _ready() -> void:
	$Button.pressed.connect(func(): print("TEST BUTTON PRESSED"))
	$Button.grab_focus()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"):
		print("test_button._unhandled_input: ui_accept")
	
	if event.is_action_pressed("interact"):
		print("test_button._unhandled_input: interact")
	
	if event is InputEventKey and event.pressed and not event.echo:
		print("test_button._unhandled_input: ", event.as_text())
