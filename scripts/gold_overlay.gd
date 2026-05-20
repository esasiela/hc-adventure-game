extends CanvasLayer


@onready var quantity_label: Label = $HBoxContainer/QuantityLabel


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	PlayerData.gold_changed.connect(_on_gold_changed)
	# call the hook to initialize to players init gold
	_on_gold_changed(PlayerData.gold)


func _on_gold_changed(amount: int) -> void:
	quantity_label.text = str(amount)
