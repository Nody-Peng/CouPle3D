extends CharacterBody3D
var enabled := true
var spawn_position := Vector3(0,1,34)
var touch_input := Vector2.ZERO
var touch_sprint := false
var model: Node3D
var riding := false
var cycle_speed := 0.0

func toggle_bicycle() -> void:
	if not enabled or get_parent().get_parent().inside: return
	riding = not riding
	cycle_speed = 0.0
	model.set_riding(riding)

func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.physical_keycode==KEY_B:
		toggle_bicycle()

func _ready() -> void:
	safe_margin = 0.03
	max_slides = 6
	add_to_group("player")
	var shape := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.3
	capsule.height = 1.6
	shape.shape = capsule
	shape.position.y = 0.8
	add_child(shape)
	model = Node3D.new()
	model.set_script(load("res://scripts/couple_avatar.gd"))
	add_child(model)

func _physics_process(delta: float) -> void:
	var input := Vector2.ZERO
	if enabled:
		input.x = float(Input.is_physical_key_pressed(KEY_D) or Input.is_physical_key_pressed(KEY_RIGHT)) - float(Input.is_physical_key_pressed(KEY_A) or Input.is_physical_key_pressed(KEY_LEFT))
		input.y = float(Input.is_physical_key_pressed(KEY_S) or Input.is_physical_key_pressed(KEY_DOWN)) - float(Input.is_physical_key_pressed(KEY_W) or Input.is_physical_key_pressed(KEY_UP))
		input += touch_input
	var cam := get_viewport().get_camera_3d()
	var right := cam.global_basis.x
	var forward := cam.global_basis.z
	right.y = 0
	forward.y = 0
	var direction := (right.normalized() * input.x + forward.normalized() * input.y).limit_length(1.0)
	var speed := 8.0 if Input.is_physical_key_pressed(KEY_SHIFT) or touch_sprint else 5.0
	if riding:
		var target_speed := 9.0*minf(input.length(),1.0)
		if direction.length()>0.1:
			var target_yaw := atan2(direction.x,direction.z)
			var difference := angle_difference(model.rotation.y,target_yaw)
			model.rotation.y += clampf(difference,-delta*2.6,delta*2.6)
			target_speed *= lerpf(1.0,0.25,minf(absf(difference)/PI,1.0))
		cycle_speed = move_toward(cycle_speed,target_speed,delta*(7.0 if target_speed>cycle_speed else 15.0))
		if not enabled: cycle_speed = 0.0
		velocity.x = sin(model.rotation.y)*cycle_speed
		velocity.z = cos(model.rotation.y)*cycle_speed
	else:
		velocity.x = direction.x * speed
		velocity.z = direction.z * speed
	velocity.y = -0.5 if is_on_floor() else maxf(velocity.y-20.0*delta,-30.0)
	move_and_slide()
	if not riding and direction.length() > 0.1:
		model.rotation.y = lerp_angle(model.rotation.y,atan2(direction.x,direction.z),delta*12)
	if position.y < -8:
		position = spawn_position
	if riding:
		model.ride_speed = Vector2(get_real_velocity().x,get_real_velocity().z).length()
		if model.ride_speed<cycle_speed*0.4: cycle_speed = model.ride_speed
	model.play_animation("idle" if direction.length() < 0.1 else ("sprint" if speed > 5 else "walk"))

