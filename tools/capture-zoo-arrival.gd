extends SceneTree
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var scene=load("res://scenes/Hub.tscn").instantiate()
	root.add_child(scene)
	await create_timer(0.5).timeout
	scene.player.position = Vector3(58,0.1,1)
	scene.camera_zoom = 1.1
	await create_timer(1.0).timeout
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://screenshots/zoo-arrival.png")
	quit()
