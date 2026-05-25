extends CharacterBody2D
class_name Player


enum State { IDLE, WALKING, TALKING, VENDORING, MINING }
var state: State = State.IDLE

enum Facing { DOWN, UP, LEFT, RIGHT }
var facing: Facing = Facing.DOWN

const SPEED = 100.0
var last_direction: Vector2 = Vector2.RIGHT
var interact_target = null

@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@onready var camera_2d: Camera2D = $Camera2D
@onready var mining_timer: Timer = $MiningTimer


func _ready() -> void:
	# connect to vendor signals
	var vendor_ui := get_tree().get_first_node_in_group("vendor_ui") as VendorUI
	vendor_ui.opened.connect(_on_vendor_opened)
	vendor_ui.closed.connect(_on_vendor_closed)
	
	DialogueUI.closed.connect(_on_dialogue_closed)
	
	if OS.is_debug_build():
		_seed_test_inventory()
	
	change_state(State.IDLE)


func _seed_test_inventory() -> void:
	PlayerData.add_item(preload("res://items/copper.tres"), 25)
	PlayerData.add_item(preload("res://items/stone.tres"), 15)
	PlayerData.add_gold(500)


func _physics_process(delta: float) -> void:
	update_movement()

	process_animation()
	move_and_slide()


func update_facing(dir: Vector2) -> void:
	if dir == Vector2.ZERO:
		return
	# prioritize horizontal so diagonals favor left/right
	if abs(dir.x) >= abs(dir.y):
		facing = Facing.RIGHT if dir.x > 0 else Facing.LEFT
	else:
		facing = Facing.DOWN if dir.y > 0 else Facing.UP


func update_movement() -> void:
	# exit early for immobile states
	if state == State.TALKING or state == State.VENDORING:
		velocity = Vector2.ZERO
		return
	
	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var direction := Input.get_vector("left", "right", "up", "down")	
	update_facing(direction)
	
	if direction != Vector2.ZERO:
		velocity = direction * SPEED
		last_direction = direction
		# TODO update_hitbox_offset()
		
		# interrupt any existing state on movement input
		change_state(State.WALKING, false)
	else:
		velocity = Vector2.ZERO
		if state == State.WALKING:
			change_state(State.IDLE)


func process_animation() -> void:
	if state == State.WALKING:
		update_facing(velocity)
		play_directional_animation("walking")
	# other states don't touch animation here — they set it on enter


func play_directional_animation(prefix: String) -> void:
	match facing:
		Facing.LEFT:
			animated_sprite_2d.flip_h = true
			animated_sprite_2d.play(prefix + "_right")
		Facing.RIGHT:
			animated_sprite_2d.flip_h = false
			animated_sprite_2d.play(prefix + "_right")
		Facing.UP:
			animated_sprite_2d.flip_h = false
			animated_sprite_2d.play(prefix + "_up")
		Facing.DOWN:
			animated_sprite_2d.flip_h = false
			animated_sprite_2d.play(prefix + "_down")


func _unhandled_input(event: InputEvent) -> void:
	if DialogueUI.visible:
		return
	
	if event.is_action_pressed("interact"):
		if interact_target:
			if interact_target is HarvestNode:
				change_state(State.MINING)
			elif interact_target is NPC:
				var npc := interact_target as NPC
				if npc.has_interaction():
					change_state(State.TALKING)
		
	if event.is_action_pressed("gold_debug"):
		PlayerData.add_gold(1)


func change_state(new_state: State, clobber_same_state: bool = true) -> void:
	if not clobber_same_state and new_state == state:
		return
		
	_exit_state(state)
	state = new_state
	_enter_state(state)


func _exit_state(old_state: State) -> void:
	match old_state:
		State.MINING: _exit_state_mining()
		State.VENDORING: pass
		State.TALKING: pass
		State.WALKING: pass
		State.IDLE: pass


func _enter_state(new_state: State) -> void:
	match new_state:
		State.MINING: _enter_state_mining()
		State.TALKING: _enter_state_talking()
		State.WALKING: pass
		State.IDLE: _enter_state_idle()


func _enter_state_idle() -> void:
	play_directional_animation("idle")


func _enter_state_talking() -> void:
	play_directional_animation("idle")
	(interact_target as NPC).talk_to(self)


func _on_dialogue_closed() -> void:
	if state == State.TALKING:
		change_state(State.IDLE)


func _enter_state_vendoring() -> void:
	play_directional_animation("idle")


func _enter_state_mining() -> void:
	mining_timer.start()
	play_directional_animation("mining")


func _exit_state_mining() -> void:
	mining_timer.stop()


func _on_mining_timer_timeout() -> void:
	if interact_target and interact_target is HarvestNode:
		var harvest_node: HarvestNode = interact_target
		harvest_node.harvest()
		
		interact_target = null
	
	change_state(State.IDLE)


func _on_lootbox_area_entered(area: Area2D) -> void:
	if not area is WorldItem:
		return
	var world_item := area as WorldItem
	
	if world_item.item is Currency:
		PlayerData.add_gold(world_item.quantity)
	else:
		PlayerData.add_item(world_item.item, world_item.quantity)
	world_item.queue_free()


func _on_vendor_opened() -> void:
	change_state(State.VENDORING)

func _on_vendor_closed() -> void:
	change_state(State.IDLE)


func get_zone() -> Zone:
	return ZoneManager.current_zone
