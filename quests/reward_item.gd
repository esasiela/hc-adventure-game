class_name ItemReward
extends Reward

@export var item: Item
@export var quantity: int = 1

func apply() -> void:
	if item:
		PlayerData.add_item(item, quantity)
