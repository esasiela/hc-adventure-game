class_name FloatingTextInstance
extends Label


const DRIFT_DISTANCE := 40.0   # pixels to drift upward
const DURATION := 1.2          # seconds before freeing


func _ready() -> void:
	# Center the label on its spawn position by offsetting half its size
	pivot_offset = size / 2
	position -= size / 2
	
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "position:y", position.y - DRIFT_DISTANCE, DURATION)
	tween.tween_property(self, "modulate:a", 0.0, DURATION).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.chain().tween_callback(queue_free)
