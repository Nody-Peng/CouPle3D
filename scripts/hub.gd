extends Node3D

func _ready() -> void:
	HUD.hide_prompt()
	$MovieRoomDoor.body_entered.connect(_on_house_entered)
	$ShopDoor.body_entered.connect(_on_shop_entered)
	$ShopDoor.body_exited.connect(_on_shop_exited)

	$BattleshipDoor.body_entered.connect(func(body): _show_placeholder(body, "海戰棋（尚未實作）"))
	$BattleshipDoor.body_exited.connect(func(body): _hide_placeholder(body))
	$InkBattleDoor.body_entered.connect(func(body): _show_placeholder(body, "墨水大戰（尚未實作）"))
	$InkBattleDoor.body_exited.connect(func(body): _hide_placeholder(body))
	$NumberRushDoor.body_entered.connect(func(body): _show_placeholder(body, "數字快跑（尚未實作）"))
	$NumberRushDoor.body_exited.connect(func(body): _hide_placeholder(body))

func _on_house_entered(body: Node3D) -> void:
	if body.is_in_group("player"):
		get_tree().change_scene_to_file("res://scenes/MovieRoom.tscn")

func _on_shop_entered(body: Node3D) -> void:
	if body.is_in_group("player"):
		HUD.show_prompt("商店（尚未實作）")

func _on_shop_exited(body: Node3D) -> void:
	if body.is_in_group("player"):
		HUD.hide_prompt()

func _show_placeholder(body: Node3D, text: String) -> void:
	if body.is_in_group("player"):
		HUD.show_prompt(text)

func _hide_placeholder(body: Node3D) -> void:
	if body.is_in_group("player"):
		HUD.hide_prompt()
