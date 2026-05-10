# drop_entry.gd
class_name DropEntry
extends Resource

@export var item: Item
@export var chance: float = 1.0  # 0.0-1.0, probability of dropping
@export var min_quantity: int = 1
@export var max_quantity: int = 1
