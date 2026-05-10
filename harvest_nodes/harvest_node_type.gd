class_name HarvestNodeType
extends Resource


@export var id: String                      # "copper_vein", "rich_copper_vein"
@export var display_name: String            # "Copper Vein"
@export var harvest_texture: Texture2D      # the visual in the world
@export var drop_table: Array[DropEntry] = []
@export var harvest_duration: float = 3.0   # how long mining takes
# later: required_tool_tier, respawn_time, particle_effect, etc.
