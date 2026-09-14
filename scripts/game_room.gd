extends Node3D

@onready var trivia_minigame := $TriviaMinigame

var near_desk := false

func _ready() -> void:
	$DeskTrigger.body_entered.connect(_on_desk_entered)
	$DeskTrigger.body_exited.connect(_on_desk_exited)
	$ExitDoor.body_entered.connect(_on_exit_entered)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.physical_keycode == KEY_E:
		if near_desk and not trivia_minigame.visible:
			trivia_minigame.show_minigame()

func _on_desk_entered(body: Node3D) -> void:
	if body.is_in_group("player"):
		near_desk = true
		HUD.show_prompt("書桌（按 E 玩默契問答）")

func _on_desk_exited(body: Node3D) -> void:
	if body.is_in_group("player"):
		near_desk = false
		HUD.hide_prompt()

func _on_exit_entered(body: Node3D) -> void:
	if body.is_in_group("player"):
		get_tree().change_scene_to_file("res://scenes/MovieRoom.tscn")
