extends CharacterBody2D
class_name Player


enum State { IDLE, WALKING, MINING }
var state: State = State.IDLE

enum Facing { DOWN, UP, LEFT, RIGHT }
var facing: Facing = Facing.DOWN

const SPEED = 100.0
var last_direction: Vector2 = Vector2.RIGHT
var interact_target = null

@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@onready var tilemap: TileMapLayer = $"../TileMapLayer"
@onready var camera_2d: Camera2D = $Camera2D
@onready var mining_timer: Timer = $MiningTimer


func _ready() -> void:
	var used_rect = tilemap.get_used_rect()
	var tile_size = tilemap.tile_set.tile_size
	
	# Calculate limits in pixels
	camera_2d.limit_left = int(used_rect.position.x * tile_size.x)
	camera_2d.limit_top = int(used_rect.position.y * tile_size.y)
	camera_2d.limit_right = int(used_rect.end.x * tile_size.x)
	camera_2d.limit_bottom = int(used_rect.end.y * tile_size.y)
	
	change_state(State.IDLE)


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
	if event.is_action_pressed("interact"):
		if interact_target:
			if interact_target is HarvestNode:
				change_state(State.MINING)


func change_state(new_state: State, clobber_same_state: bool = true) -> void:
	if not clobber_same_state and new_state == state:
		return
		
	_exit_state(state)
	state = new_state
	_enter_state(state)


func _exit_state(old_state: State) -> void:
	match old_state:
		State.MINING: _exit_state_mining()
		State.WALKING: pass
		State.IDLE: pass


func _enter_state(new_state: State) -> void:
	match new_state:
		State.MINING: _enter_state_mining()
		State.WALKING: pass
		State.IDLE: _enter_state_idle()


func _enter_state_idle() -> void:
	play_directional_animation("idle")


func _enter_state_mining() -> void:
	mining_timer.start()
	play_directional_animation("mining")


func _exit_state_mining() -> void:
	mining_timer.stop()


func _on_mining_timer_timeout() -> void:
	if interact_target and interact_target is HarvestNode:
		var harvest_node: HarvestNode = interact_target

		var drop_pos := harvest_node.global_position
		var drop_item := harvest_node.node_type.drop_item
		var drop_qty := harvest_node.node_type.drop_quantity
		
		var world_item := get_zone().spawn_world_item(drop_item, drop_pos, drop_qty)
		world_item.drop_from(drop_pos)
		
		interact_target.queue_free()
		interact_target = null
	
	change_state(State.IDLE)


func _on_lootbox_area_entered(area: Area2D) -> void:
	if not area is WorldItem:
		return
	var world_item := area as WorldItem
	print("lootbox - item:", world_item.item.id, " qty:", world_item.quantity)
	PlayerData.add_item(world_item.item, world_item.quantity)
	world_item.queue_free()


func get_zone() -> Zone:
	return get_tree().get_first_node_in_group("zone") as Zone
