extends SceneTree
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	var viewport := SubViewport.new()
	viewport.size = Vector2i(360,440)
	viewport.transparent_bg = true
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	viewport.own_world_3d = true
	root.add_child(viewport)
	var environment := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_CLEAR_COLOR
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color.WHITE
	env.ambient_light_energy = 0.7
	environment.environment = env
	viewport.add_child(environment)
	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-30,-25,0)
	light.light_energy = 0.8
	viewport.add_child(light)
	var avatar := Node3D.new()
	avatar.set_script(load("res://scripts/couple_avatar.gd"))
	viewport.add_child(avatar)
	avatar.rotation_degrees.y = -15
	var camera := Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 2.25
	viewport.add_child(camera)
	camera.position = Vector3(0,1,4)
	camera.look_at(Vector3(0,0.85,0))
	DirAccess.make_dir_recursive_absolute("res://web/previews")
	for base in ["female-a","female-b","female-c","female-d","female-e","female-f","male-a","male-b","male-c","male-d","male-e","male-f"]:
		avatar.apply_appearance({"base":base,"hat":"none","glasses":"none","bag":"none"})
		await create_timer(0.15).timeout
		await RenderingServer.frame_post_draw
		viewport.get_texture().get_image().save_png("res://web/previews/"+base+".png")
	camera.size = 3.2
	camera.look_at(Vector3(0,1.25,0))
	for item in ["hat_beret","hat_bunny","glasses_round","bag_daypack","hat_bow","hat_flower","bag_satchel","outfit_cream","outfit_rose","outfit_sailor","outfit_mint","outfit_lilac","outfit_cocoa"]:
		var slot: String = "outfit" if item.begins_with("outfit") else "hat" if item.begins_with("hat") else ("bag" if item.begins_with("bag") else "glasses")
		var appearance := {"base":"female-b","hat":"none","glasses":"none","bag":"none"}
		appearance[slot] = item
		avatar.apply_appearance(appearance)
		avatar.rotation_degrees.y = 165 if item=="bag_daypack" else -15
		await create_timer(0.15).timeout
		await RenderingServer.frame_post_draw
		viewport.get_texture().get_image().save_png("res://web/previews/"+item+".png")
	quit()




