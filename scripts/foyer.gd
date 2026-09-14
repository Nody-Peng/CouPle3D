extends Node3D

func _ready() -> void:
	HUD.hide_prompt()
	$LivingRoomDoor.body_entered.connect(func(body): _enter_room(body, "res://scenes/MovieRoom.tscn"))
	$GameRoomDoor.body_entered.connect(func(body): _enter_room(body, "res://scenes/GameRoom.tscn"))
	$ExitDoor.body_entered.connect(func(body): _enter_room(body, "res://scenes/Hub.tscn"))

	$KitchenDoor.body_entered.connect(func(body): _show_placeholder(body, "廚房（尚未實作）"))
	$KitchenDoor.body_exited.connect(func(body): _hide_placeholder(body))
	$BathroomDoor.body_entered.connect(func(body): _show_placeholder(body, "浴室（尚未實作）"))
	$BathroomDoor.body_exited.connect(func(body): _hide_placeholder(body))
	$BedroomDoor.body_entered.connect(func(body): _show_placeholder(body, "主臥室（尚未實作）"))
	$BedroomDoor.body_exited.connect(func(body): _hide_placeholder(body))

func _enter_room(body: Node3D, scene_path: String) -> void:
	if body.is_in_group("player"):
		get_tree().change_scene_to_file(scene_path)

func _show_placeholder(body: Node3D, text: String) -> void:
	if body.is_in_group("player"):
		HUD.show_prompt(text)

func _hide_placeholder(body: Node3D) -> void:
	if body.is_in_group("player"):
		HUD.hide_prompt()
