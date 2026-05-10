@tool
extends Area2D
class_name WorldItem


@export var item: Item:
	set(value):
		item = value
		_update_visual()

@export var quantity: int = 1:
	set(value):
		quantity = value
		_update_visual()

@onready var sprite_2d: Sprite2D = $Sprite2D
@onready var quantity_label: Label = $QuantityLabel


func _ready() -> void:
	_update_visual()

func _update_visual() -> void:
	if not is_node_ready():
		return
	if item:
		sprite_2d.texture = item.world_texture
		sprite_2d.scale = Vector2.ONE * item.world_scale
	quantity_label.text = str(quantity) if quantity > 1 else ""


func drop_from(origin: Vector2) -> void:
	global_position = origin
	$CollisionShape2D.disabled = true
	var offset := Vector2(randf_range(-12, 12), randf_range(-12, 12))
	var target := origin + offset
	var tween := create_tween()
	tween.tween_property(self, "global_position", target, 0.3)
	tween.tween_callback(func(): $CollisionShape2D.disabled = false)
