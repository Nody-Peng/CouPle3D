extends SceneTree
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var scene = load("res://scenes/Hub.tscn").instantiate()
	root.add_child(scene)
	await create_timer(0.8).timeout
	for entry in [["nordic-fountain",Vector3(0,0.1,3),0.8],["nordic-pond",Vector3(-40,0.1,3),0.75],["nordic-rides",Vector3(0,0.1,-20),1.7],["nordic-street",Vector3(-100,0.1,5),1.4]]:
		scene.player.position = entry[1]
		scene.camera_zoom = entry[2]
		await create_timer(0.8).timeout
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://screenshots/"+entry[0]+".png")
	quit()
