extends Interactable


@export_multiline var sign_text: String = "Sign Text"

@onready var world_sprite: Sprite2D = $WorldSprite
@onready var label_panel: PanelContainer = $LabelPanel
@onready var label: Label = $LabelPanel/Label


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	super()
	label.text = sign_text
	label_panel.visible = false
	
	await get_tree().process_frame
	label_panel.pivot_offset = Vector2(label_panel.size.x / 2, label_panel.size.y)
	label_panel.position = -label_panel.pivot_offset
	
	world_sprite.material = world_sprite.material.duplicate()
	world_sprite.material.set_shader_parameter("active", false)


func _on_interact_target_acquired() -> void:
	label_panel.visible = true
	world_sprite.material.set_shader_parameter("active", true)


func _on_interact_target_lost() -> void:
	label_panel.visible = false
	world_sprite.material.set_shader_parameter("active", false)
