extends Node

enum Style { LOOT, GOLD, CELEBRATION }

const SCENE: PackedScene = preload("res://floating_text/floating_text.tscn")

# Style configuration: color, font_size
const STYLES := {
	Style.LOOT:        { "color": Color.WHITE,  "font_size": 28 },
	Style.GOLD:        { "color": Color.GOLD,   "font_size": 32 },
	Style.CELEBRATION: { "color": Color.GOLD,   "font_size": 48 },
}


func spawn(text: String, world_pos: Vector2, style: Style = Style.LOOT) -> void:
	var instance: Label = SCENE.instantiate()
	instance.text = text
	var cfg: Dictionary = STYLES[style]
	instance.add_theme_color_override("font_color", cfg.color)
	instance.add_theme_font_size_override("font_size", cfg.font_size)
	instance.global_position = world_pos
	# Add to the current scene root so it lives in world space
	get_tree().current_scene.add_child(instance)
