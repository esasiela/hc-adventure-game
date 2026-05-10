extends CanvasLayer


@onready var quantity_label: Label = $HBoxContainer/QuantityLabel


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	PlayerData.gold_changed.connect(_on_gold_changed)


func _on_gold_changed(amount: int) -> void:
	quantity_label.text = str(amount)
