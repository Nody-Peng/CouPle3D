extends Node3D

func _ready() -> void:
	HUD.hide_prompt()
	$ExitDoor.body_entered.connect(_on_exit_entered)
	$GameRoomDoor.body_entered.connect(_on_gameroom_entered)

	$KitchenDoor.body_entered.connect(func(body): _show_placeholder(body, "廚房（尚未實作）"))
	$KitchenDoor.body_exited.connect(func(body): _hide_placeholder(body))
	$BathroomDoor.body_entered.connect(func(body): _show_placeholder(body, "浴室（尚未實作）"))
	$BathroomDoor.body_exited.connect(func(body): _hide_placeholder(body))
	$BedroomDoor.body_entered.connect(func(body): _show_placeholder(body, "主臥室（尚未實作）"))
	$BedroomDoor.body_exited.connect(func(body): _hide_placeholder(body))

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.physical_keycode == KEY_E:
		HUD.show_prompt("一起看影片功能尚未實作")

func _show_placeholder(body: Node3D, text: String) -> void:
	if body.is_in_group("player"):
		HUD.show_prompt(text)

func _hide_placeholder(body: Node3D) -> void:
	if body.is_in_group("player"):
		HUD.hide_prompt()

func _on_exit_entered(body: Node3D) -> void:
	if body.is_in_group("player"):
		get_tree().change_scene_to_file("res://scenes/Hub.tscn")

func _on_gameroom_entered(body: Node3D) -> void:
	if body.is_in_group("player"):
		get_tree().change_scene_to_file("res://scenes/GameRoom.tscn")
