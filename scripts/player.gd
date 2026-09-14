extends CharacterBody3D

const WALK_SPEED := 4.0
const SPRINT_SPEED := 7.5
const GRAVITY := 9.8

@onready var anim_player: AnimationPlayer = find_child("AnimationPlayer", true, false)

var current_anim := ""

func _ready() -> void:
	if anim_player:
		for loop_anim in ["idle", "walk", "sprint"]:
			if anim_player.has_animation(loop_anim):
				anim_player.get_animation(loop_anim).loop_mode = Animation.LOOP_LINEAR
	_play_anim("idle")

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= GRAVITY * delta

	var input_dir := Vector2.ZERO
	if Input.is_physical_key_pressed(KEY_W) or Input.is_physical_key_pressed(KEY_UP):
		input_dir.y -= 1
	if Input.is_physical_key_pressed(KEY_S) or Input.is_physical_key_pressed(KEY_DOWN):
		input_dir.y += 1
	if Input.is_physical_key_pressed(KEY_A) or Input.is_physical_key_pressed(KEY_LEFT):
		input_dir.x -= 1
	if Input.is_physical_key_pressed(KEY_D) or Input.is_physical_key_pressed(KEY_RIGHT):
		input_dir.x += 1
	input_dir = input_dir.normalized()

	var direction := Vector3(input_dir.x, 0, input_dir.y)
	var is_sprinting := Input.is_physical_key_pressed(KEY_SHIFT)

	if direction.length() > 0.01:
		var speed := SPRINT_SPEED if is_sprinting else WALK_SPEED
		velocity.x = direction.x * speed
		velocity.z = direction.z * speed
		look_at(global_position + direction, Vector3.UP)
		_play_anim("sprint" if is_sprinting else "walk")
	else:
		velocity.x = move_toward(velocity.x, 0, WALK_SPEED)
		velocity.z = move_toward(velocity.z, 0, WALK_SPEED)
		_play_anim("idle")

	move_and_slide()

func _play_anim(anim_name: String) -> void:
	if current_anim == anim_name:
		return
	if anim_player and anim_player.has_animation(anim_name):
		anim_player.play(anim_name)
		current_anim = anim_name
