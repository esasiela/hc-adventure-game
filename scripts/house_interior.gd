extends Node2D

@onready var tilemap: TileMapLayer = $TileMapLayer

func get_camera_bounds() -> Rect2:
	var used_rect := tilemap.get_used_rect()
	var tile_size := tilemap.tile_set.tile_size
	return Rect2(
		used_rect.position * tile_size,
		used_rect.size * tile_size
	)
