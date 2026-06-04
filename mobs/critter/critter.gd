extends CharacterBody2D


@export var speed: float = 60.0

var target: Node2D = null
var in_attack_range: bool = false
var home_position: Vector2

@onready var world_sprite: Sprite2D = $WorldSprite
@onready var agro_box: Area2D = $AgroBox
@onready var attack_box: Area2D = $AttackBox
@onready var attack_timer: Timer = $AttackTimer
@onready var stunned_timer: Timer = $StunnedTimer


func _ready() -> void:
	agro_box.area_entered.connect(_on_agro_box_entered)
	agro_box.area_exited.connect(_on_agro_box_exited)
	
	attack_box.area_entered.connect(_on_attack_box_entered)
	attack_box.area_exited.connect(_on_attack_box_exited)
	
	attack_timer.timeout.connect(_on_attack_timer_timeout)
	stunned_timer.timeout.connect(_on_stunned_timer_timeout)
	
	world_sprite.material = world_sprite.material.duplicate()
	world_sprite.material.set_shader_parameter("active", false)
	
	home_position = global_position


func _physics_process(_delta: float) -> void:
	if not stunned_timer.is_stopped():
		velocity = Vector2.ZERO
	elif target and not in_attack_range:
		velocity = global_position.direction_to(target.global_position) * speed
	elif not target and not home_position.is_equal_approx(global_position):
		velocity = global_position.direction_to(home_position) * speed
	else:
		velocity = Vector2.ZERO
	move_and_slide()


func _on_agro_box_entered(area: Area2D) -> void:
	if not area.owner is Player:
		return
	var player := area.owner as Player
	target = player


func _on_agro_box_exited(area: Area2D) -> void:
	if not area.owner is Player:
		return
	var player := area.owner as Player
	target = null


func _attack_if_ready() -> void:
	if stunned_timer.is_stopped() and attack_timer.is_stopped() and in_attack_range and target is Player:
		var player := target as Player
		print("CRITTER - attack!!!")
		player.take_damage(0)
		attack_timer.start()


func _on_attack_timer_timeout() -> void:
	_attack_if_ready()


func _on_attack_box_entered(area: Area2D) -> void:
	if not area.owner is Player:
		return
	var player := area.owner as Player
	in_attack_range = true
	_attack_if_ready()


func _on_attack_box_exited(area: Area2D) -> void:
	if not area.owner is Player:
		return
	var player := area.owner as Player
	in_attack_range = false


func stun() -> void:
	world_sprite.material.set_shader_parameter("active", true)
	stunned_timer.start()

func _on_stunned_timer_timeout() -> void:
	world_sprite.material.set_shader_parameter("active", false)
	_attack_if_ready()
