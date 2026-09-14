extends SceneTree
var failures := 0
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var scene = load("res://scenes/Hub.tscn").instantiate()
	root.add_child(scene)
	await create_timer(0.8).timeout
	for child in scene.world.get_children():
		if child.get_script()!=load("res://scripts/city_venues.gd"): continue
		scene.camera_yaw = 0.35 if child.position.z<0 else PI+0.35
		scene.camera_zoom = 1.1
		scene.player.position = child.to_global(Vector3(0,0.1,-17))
		await create_timer(0.8).timeout
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://screenshots/"+child.venue+"-exterior.png")
		scene.player.position = child.to_global(Vector3(0,0.1,-11))
		var direction: Vector3 = child.global_basis*Vector3.BACK
		for i in range(140):
			var right: Vector3 = scene.camera.global_basis.x
			var forward: Vector3 = scene.camera.global_basis.z
			right.y = 0
			forward.y = 0
			scene.player.touch_input = Vector2(direction.dot(right.normalized()),direction.dot(forward.normalized()))
			await physics_frame
		scene.player.touch_input = Vector2.ZERO
		if child.to_local(scene.player.global_position).z< -1.5 or child.roof.visible:
			failures += 1
			push_error(child.venue+" entry or roof cutaway failed")
		scene.player.position = child.to_global(Vector3(0,0.1,-1))
		scene.camera_zoom = 0.82
		await create_timer(0.8).timeout
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://screenshots/"+child.venue+"-interior.png")
	print("VENUE WALK-IN: ","PASS" if failures==0 else "FAIL")
	quit(failures)
