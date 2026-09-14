extends Node3D

enum Zone { NONE, TV, DESK }

@onready var room_label: Label = $UI/RoomLabel
@onready var coin_label: Label = $UI/CoinLabel
@onready var trivia_minigame := $TriviaMinigame

var current_zone: Zone = Zone.NONE

func _ready() -> void:
	$VideoRoomFurniture/TVTrigger.body_entered.connect(_on_tv_entered)
	$VideoRoomFurniture/TVTrigger.body_exited.connect(_on_tv_exited)
	$MinigameRoomFurniture/DeskTrigger.body_entered.connect(_on_desk_entered)
	$MinigameRoomFurniture/DeskTrigger.body_exited.connect(_on_desk_exited)

	Currency.coins_changed.connect(_on_coins_changed)
	_on_coins_changed(Currency.coins)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.physical_keycode == KEY_E:
		match current_zone:
			Zone.DESK:
				if not trivia_minigame.visible:
					trivia_minigame.show_minigame()
			Zone.TV:
				room_label.text = "電視（一起看影片功能尚未實作）"

func _on_tv_entered(body: Node3D) -> void:
	if body.is_in_group("player"):
		current_zone = Zone.TV
		room_label.text = "電視（按 E 一起看影片）"
		room_label.visible = true

func _on_tv_exited(body: Node3D) -> void:
	if body.is_in_group("player"):
		current_zone = Zone.NONE
		room_label.visible = false

func _on_desk_entered(body: Node3D) -> void:
	if body.is_in_group("player"):
		current_zone = Zone.DESK
		room_label.text = "書桌（按 E 玩默契問答）"
		room_label.visible = true

func _on_desk_exited(body: Node3D) -> void:
	if body.is_in_group("player"):
		current_zone = Zone.NONE
		room_label.visible = false

func _on_coins_changed(amount: int) -> void:
	coin_label.text = "金幣：%d" % amount
