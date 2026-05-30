extends CanvasLayer

@onready var sub_viewport: SubViewport = $Frame/MarginContainer/SubViewportContainer/SubViewport
@onready var minimap_camera: Camera2D = $Frame/MarginContainer/SubViewportContainer/SubViewport/MinimapCamera

func _ready() -> void:
	ZoneManager.register_minimap(self)
	sub_viewport.world_2d = get_tree().root.world_2d

func _process(_delta: float) -> void:
	if ZoneManager.player:
		minimap_camera.global_position = ZoneManager.player.global_position


func get_camera() -> Camera2D:
	return minimap_camera
