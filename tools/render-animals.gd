extends SceneTree
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var viewport := SubViewport.new()
	viewport.size = Vector2i(440,440)
	viewport.transparent_bg = true
	viewport.own_world_3d = true
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(viewport)
	var host = load("res://scripts/couple_world.gd").new()
	host.world = Node3D.new()
	viewport.add_child(host.world)
	var environment := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_CLEAR_COLOR
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color.WHITE
	env.ambient_light_energy = 0.65
	environment.environment = env
	viewport.add_child(environment)
	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-35,-30,0)
	light.light_energy = 0.65
	viewport.add_child(light)
	var camera := Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	viewport.add_child(camera)
	for species in ["panda","giraffe","rabbit","capybara","penguin","fox"]:
		var animal := Node3D.new()
		animal.set_script(load("res://scripts/zoo_animal.gd"))
		host.world.add_child(animal)
		animal.build(host,species,Vector3.ZERO,0)
		animal.set_process(false)
		animal.rotation_degrees.y = -28
		camera.size = 5.2 if species=="giraffe" else 3.8
		var center := 2.1 if species=="giraffe" else 1.15
		camera.position = Vector3(0,center+1,6)
		camera.look_at(Vector3(0,center,0))
		await create_timer(0.2).timeout
		await RenderingServer.frame_post_draw
		viewport.get_texture().get_image().save_png("res://web/previews/animal-"+species+".png")
		animal.queue_free()
		await process_frame
	host.free()
	quit()
