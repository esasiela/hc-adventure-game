extends CanvasLayer

@onready var sub_viewport: SubViewport = $Frame/MarginContainer/SubViewportContainer/SubViewport
@onready var minimap_camera: Camera2D = $Frame/MarginContainer/SubViewportContainer/SubViewport/MinimapCamera

func _ready() -> void:
	ZoneManager.register_minimap(self)
	sub_viewport.world_2d = get_tree().root.world_2d
	
	# make the main camera NOT show layer 2 (which is reserved for mini-map icons)
	get_tree().root.canvas_cull_mask &= ~(1 << 1)

	# make the minimap camera NOT show layer 3 (reserved for world-only)
	sub_viewport.canvas_cull_mask &= ~(1 << 2)


func _process(_delta: float) -> void:
	if ZoneManager.player:
		minimap_camera.global_position = ZoneManager.player.global_position


func get_camera() -> Camera2D:
	return minimap_camera
