extends CanvasLayer

@onready var coin_label: Label = $CoinLabel
@onready var room_label: Label = $RoomLabel

func _ready() -> void:
	Currency.coins_changed.connect(_on_coins_changed)
	_on_coins_changed(Currency.coins)

func show_prompt(text: String) -> void:
	room_label.text = text
	room_label.visible = true

func hide_prompt() -> void:
	room_label.visible = false

func _on_coins_changed(amount: int) -> void:
	coin_label.text = "金幣：%d" % amount
