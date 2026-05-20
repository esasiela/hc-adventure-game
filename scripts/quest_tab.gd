class_name QuestTab
extends Control

const QUEST_LIST_ENTRY_SCENE: PackedScene = preload("res://scenes/ui/quest_list_entry.tscn")

@onready var quest_list: VBoxContainer = $Body/ListPanel/ScrollContainer/QuestList
@onready var empty_label: Label = $Body/ListPanel/EmptyLabel
@onready var title_label: Label = $Body/Details/TitleLabel
@onready var description_label: Label = $Body/Details/DescriptionLabel
@onready var objectives_container: VBoxContainer = $Body/Details/ObjectivesContainer
@onready var rewards_container: VBoxContainer = $Body/Details/RewardsContainer

func refresh() -> void:
	# clear list
	for child in quest_list.get_children():
		child.queue_free()
	
	# gather quests to show: any state except NOT_STARTED
	var quests_to_show: Array[Quest] = []
	for quest_id in QuestLog.quest_states:
		var state = QuestLog.quest_states[quest_id]
		if state == QuestLog.QuestState.NOT_STARTED:
			continue
		var q: Quest = QuestLog._get_quest_by_id(quest_id)
		if q:
			quests_to_show.append(q)
	
	if quests_to_show.is_empty():
		empty_label.visible = true
		_clear_details()
		return
	
	empty_label.visible = false
	
	var first_entry: QuestListEntry = null
	for q in quests_to_show:
		var entry := QUEST_LIST_ENTRY_SCENE.instantiate() as QuestListEntry
		quest_list.add_child(entry)
		entry.set_quest(q)
		entry.focus_gained.connect(_on_quest_focused)
		if first_entry == null:
			first_entry = entry
	
	if first_entry:
		first_entry.grab_focus.call_deferred()

func focus_first_entry() -> void:
	if quest_list.get_child_count() > 0:
		quest_list.get_child(0).grab_focus()

func _on_quest_focused(quest: Quest) -> void:
	title_label.text = quest.title
	description_label.text = quest.description
	_populate_objectives(quest)
	_populate_rewards(quest)

func _populate_objectives(quest: Quest) -> void:
	for child in objectives_container.get_children():
		child.queue_free()
	for obj in quest.objectives:
		var label := Label.new()
		label.text = "• " + obj.get_progress_text()
		label.add_theme_font_size_override("font_size", 22)
		objectives_container.add_child(label)

func _populate_rewards(quest: Quest) -> void:
	for child in rewards_container.get_children():
		child.queue_free()
	for reward in quest.rewards:
		var label := Label.new()
		label.text = "• " + reward.description
		label.add_theme_font_size_override("font_size", 22)
		rewards_container.add_child(label)

func _clear_details() -> void:
	title_label.text = "—"
	description_label.text = ""
	for child in objectives_container.get_children():
		child.queue_free()
	for child in rewards_container.get_children():
		child.queue_free()
