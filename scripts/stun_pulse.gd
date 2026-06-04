class_name StunPulse
extends Node2D

var radius: float = 0.0
var color: Color = Color(1, 1, 1, 0.6)

func _draw() -> void:
	draw_circle(Vector2.ZERO, radius, color)

func play(min_radius: float, max_radius: float, duration: float = 0.25) -> void:
	radius = min_radius
	var t := create_tween().set_parallel()
	t.tween_method(_set_radius, min_radius, max_radius, duration)
	t.tween_property(self, "modulate:a", 0.0, duration)   # fade as it grows
	t.chain().tween_callback(queue_free)                  # clean up after both finish

func _set_radius(r: float) -> void:
	radius = r
	queue_redraw()
