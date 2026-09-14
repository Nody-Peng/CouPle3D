extends SceneTree
var scene: Node3D
var failures := 0
func _initialize() -> void: call_deferred("run")
func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)
func run() -> void:
	scene = load("res://scenes/Hub.tscn").instantiate()
	root.add_child(scene)
	await create_timer(0.6).timeout
	scene.player.position = Vector3(0,0.1,25)
	scene.player.toggle_bicycle()
	check(scene.player.riding and scene.player.model.bicycle.visible,"Bicycle mounts")
	scene.camera_zoom = 0.65
	await create_timer(0.8).timeout
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://screenshots/bicycle.png")
	var start: Vector3 = scene.player.position
	scene.player.touch_input = Vector2(0,-1)
	await physics_frame
	check(scene.player.cycle_speed<1.0,"Cycling accelerates gradually")
	for i in range(120): await physics_frame
	scene.player.touch_input = Vector2.ZERO
	check(scene.player.position.distance_to(start)>8,"Mounted movement is faster than walking")
	for i in range(45): await physics_frame
	check(scene.player.cycle_speed<0.1,"Cycling brakes to rest")
	scene.player.toggle_bicycle()
	check(not scene.player.riding and not scene.player.model.bicycle.visible,"Bicycle dismounts")
	scene.player.enabled = false
	scene.player.toggle_bicycle()
	check(not scene.player.riding,"Paused input cannot mount")
	scene.player.enabled = true
	scene.player.position = Vector3(84,0.1,-2)
	await create_timer(0.8).timeout
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://screenshots/panda-bamboo.png")
	scene._build(true)
	scene.player.toggle_bicycle()
	check(not scene.player.riding,"Indoor cycling disabled")
	print("BICYCLE: ","PASS" if failures==0 else "FAIL")
	quit(failures)
