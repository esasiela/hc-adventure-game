class_name GoldReward
extends Reward

@export var amount: int = 0

func apply() -> void:
	PlayerData.add_gold(amount)
