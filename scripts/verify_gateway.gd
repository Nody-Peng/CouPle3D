extends SceneTree
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var scene = load("res://scenes/Hub.tscn").instantiate()
	root.add_child(scene)
	await create_timer(0.8).timeout
	scene.camera_yaw = 0.05
	scene.camera_zoom = 0.9
	scene.player.position = Vector3(0,0.1,34)
	await create_timer(0.9).timeout
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://screenshots/gateway-day.png")
	scene._action("night")
	await create_timer(0.2).timeout
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://screenshots/gateway-night.png")
	for frame in range(300):
		var right: Vector3 = scene.camera.global_basis.x
		var forward: Vector3 = scene.camera.global_basis.z
		right.y = 0
		forward.y = 0
		scene.player.touch_input = Vector2(Vector3.BACK.dot(right.normalized()),Vector3.BACK.dot(forward.normalized()))
		await physics_frame
	var success: bool = scene.player.position.z>53 and scene.player.position.z<55.5
	print("GATEWAY PASSAGE: ","PASS" if success else "FAIL")
	quit(0 if success else 1)

