extends Camera3D

@export var offset := Vector3(14, 14, 14)

var target: Node3D

func _ready() -> void:
	target = get_tree().get_first_node_in_group("player")

func _process(_delta: float) -> void:
	if target:
		global_position = target.global_position + offset
