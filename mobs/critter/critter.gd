extends CharacterBody2D


@export var speed: float = 60.0
var target: Node2D = null
var in_attack_range: bool = false
var home_position: Vector2

@onready var agro_box: Area2D = $AgroBox
@onready var attack_box: Area2D = $AttackBox


func _ready() -> void:
	agro_box.area_entered.connect(_on_agro_box_entered)
	agro_box.area_exited.connect(_on_agro_box_exited)
	
	attack_box.area_entered.connect(_on_attack_box_entered)
	attack_box.area_exited.connect(_on_attack_box_exited)
	
	home_position = global_position


func _physics_process(_delta: float) -> void:
	if target and not in_attack_range:
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
	print("agro box entered")
	target = player


func _on_agro_box_exited(area: Area2D) -> void:
	if not area.owner is Player:
		return
	var player := area.owner as Player
	print("agro box exited")
	target = null


func _on_attack_box_entered(area: Area2D) -> void:
	if not area.owner is Player:
		return
	var player := area.owner as Player
	print("attack box entered")
	in_attack_range = true


func _on_attack_box_exited(area: Area2D) -> void:
	if not area.owner is Player:
		return
	var player := area.owner as Player
	print("agro box exited")
	in_attack_range = false
