extends SceneTree
var failures := 0
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var scene = load("res://scenes/Hub.tscn").instantiate()
	root.add_child(scene)
	await create_timer(0.8).timeout
	var cafe: Node3D
	for child in scene.world.get_children():
		if child.get_script()==load("res://scripts/garden_cafe.gd"): cafe = child
	scene.camera_yaw = PI+0.4
	scene.camera_zoom = 1.15
	scene.player.position = Vector3(-76,0.15,8)
	await create_timer(1).timeout
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://screenshots/cafe-exterior.png")
	# Walk through the three-metre opening into the cafe, using the real player controller.
	scene.player.position = Vector3(-76,0.15,14)
	for frame in range(150):
		var right: Vector3 = scene.camera.global_basis.x
		var forward: Vector3 = scene.camera.global_basis.z
		right.y = 0
		forward.y = 0
		scene.player.touch_input = Vector2(Vector3.BACK.dot(right.normalized()),Vector3.BACK.dot(forward.normalized()))
		await physics_frame
	scene.player.touch_input = Vector2.ZERO
	if scene.player.position.z<23:
		push_error("Cafe entry is blocked")
		failures += 1
	if cafe.roof.visible:
		push_error("Roof did not cut away inside")
		failures += 1
	scene.player.position = Vector3(-76,0.1,22)
	scene.camera_zoom = 0.75
	await create_timer(1).timeout
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://screenshots/cafe-interior.png")
	# Full-height glass must block lateral movement.
	scene.player.position = Vector3(-66,0.1,25)
	for frame in range(90):
		var right: Vector3 = scene.camera.global_basis.x
		var forward: Vector3 = scene.camera.global_basis.z
		right.y = 0
		forward.y = 0
		scene.player.touch_input = Vector2(Vector3.RIGHT.dot(right.normalized()),Vector3.RIGHT.dot(forward.normalized()))
		await physics_frame
	scene.player.touch_input = Vector2.ZERO
	if scene.player.position.x>-65.3:
		push_error("Glass wall did not block movement")
		failures += 1
	print("CAFE VERIFICATION: ","PASS" if failures==0 else "FAIL")
	quit(failures)
