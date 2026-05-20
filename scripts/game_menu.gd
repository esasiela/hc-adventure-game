class_name GameMenu
extends CanvasLayer

enum Tab { INVENTORY, QUESTS }

@onready var inventory_tab: InventoryTab = $Panel/MarginContainer/Body/ContentArea/InventoryTab
@onready var quest_tab: QuestTab = $Panel/MarginContainer/Body/ContentArea/QuestTab

var current_tab: Tab = Tab.INVENTORY
var tabs: Array[Tab] = [Tab.INVENTORY, Tab.QUESTS]

signal opened
signal closed

func _ready() -> void:
	visible = false

func open() -> void:
	current_tab = Tab.INVENTORY
	_show_current_tab()
	visible = true
	get_tree().paused = true
	get_viewport().gui_release_focus()
	inventory_tab.refresh()
	quest_tab.refresh()
	opened.emit()


func close() -> void:
	visible = false
	get_tree().paused = false
	get_viewport().gui_release_focus()
	closed.emit()

func _show_current_tab() -> void:
	inventory_tab.visible = (current_tab == Tab.INVENTORY)
	quest_tab.visible = (current_tab == Tab.QUESTS)
	if current_tab == Tab.INVENTORY:
		inventory_tab.focus_first_cell.call_deferred()
	elif current_tab == Tab.QUESTS:
		quest_tab.focus_first_entry.call_deferred()


func _cycle_tab(direction: int) -> void:
	var idx := tabs.find(current_tab)
	idx = (idx + direction + tabs.size()) % tabs.size()
	current_tab = tabs[idx]
	_show_current_tab()

func _input(event: InputEvent) -> void:
	if not visible:
		return
	
	if event.is_action_pressed("ui_cancel"):
		close()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("inventory_toggle"):
		close()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_tab_left"):
		_cycle_tab(-1)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_tab_right"):
		_cycle_tab(1)
		get_viewport().set_input_as_handled()
	elif _is_ui_navigation(event) or _is_ui_accept(event):
		# let focus system handle these
		pass
	else:
		# consume everything else so gameplay handlers don't see it
		get_viewport().set_input_as_handled()

func _is_ui_navigation(event: InputEvent) -> bool:
	return (
		event.is_action("ui_up") or
		event.is_action("ui_down") or
		event.is_action("ui_left") or
		event.is_action("ui_right")
	)

func _is_ui_accept(event: InputEvent) -> bool:
	return event.is_action("ui_accept")

func _unhandled_input(event: InputEvent) -> void:
	if visible:
		return
	if event.is_action_pressed("inventory_toggle"):
		# Don't open if another modal is up
		var dialogue_ui := get_tree().get_first_node_in_group("dialogue_ui") as DialogueUI
		if dialogue_ui and dialogue_ui.visible:
			return
		var vendor_ui := get_tree().get_first_node_in_group("vendor_ui") as VendorUI
		if vendor_ui and vendor_ui.visible:
			return
		open()
		get_viewport().set_input_as_handled()
