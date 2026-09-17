extends SceneTree
## Render the actual 3D scene in both desktop and Web detail profiles.
func _initialize() -> void:
	call_deferred("run")

func capture(scene: Node3D, label: String, position: Vector3, zoom: float) -> void:
	scene.player.position = position
	scene.camera_zoom = zoom
	await create_timer(0.8).timeout
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://screenshots/retro-" + label + ".png")

func run() -> void:
	var scene = load("res://scenes/Hub.tscn").instantiate()
	root.add_child(scene)
	await create_timer(1.0).timeout
	await capture(scene, "pond", Vector3(-40,0.1,3), 0.75)
	await capture(scene, "square", Vector3(0,0.1,3), 1.1)
	await capture(scene, "zoo", Vector3(75,0.1,3), 1.0)
	scene._build(true)
	await capture(scene, "home", Vector3(-14,0.1,6), 0.9)
	scene._action("night")
	await capture(scene, "night", Vector3(-14,0.1,6), 0.9)
	scene._action("night")
	scene.low_detail = true
	scene.sun.shadow_enabled = false
	scene.sun.light_energy = 0.85
	scene._build(false)
	await capture(scene, "web", Vector3(-40,0.1,3), 0.75)
	quit()
