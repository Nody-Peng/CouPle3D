extends SceneTree


func _initialize() -> void:
	call_deferred("capture")


func capture() -> void:
	var scene: Node = load("res://scenes/CoupleHome2D.tscn").instantiate()
	root.add_child(scene)
	await create_timer(2.0).timeout
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://screenshots/couple-home-2d-scene.png")
	root.size = Vector2i(960,600)
	await create_timer(0.3).timeout
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://screenshots/home-interior-small.png")
	root.size = Vector2i(1440,900)
	for station in [["stove",946],["sink",1044]]:
		scene.players[0].position=Vector2(station[1],300)
		scene._try_interact(scene.players[0])
		await create_timer(0.4).timeout
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://screenshots/kitchen-"+station[0]+".png")
	scene.toast_label.hide()
	for area in [1,2]:
		scene.players[0].position=Vector2(area*1440+660,445)
		scene.players[1].position=Vector2(area*1440+710,455)
		await create_timer(0.5).timeout
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://screenshots/coast-area-"+str(area)+".png")
	root.size = Vector2i(960,600)
	await create_timer(0.5).timeout
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://screenshots/couple-home-2d-small.png")
	quit()
