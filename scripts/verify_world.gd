extends SceneTree

var scene: Node3D
var failures := 0

func _initialize() -> void:
	call_deferred("run")

func check(value: bool, message: String) -> void:
	if not value:
		failures += 1
		push_error("FAIL: " + message)

func wait_scene() -> void:
	await create_timer(0.85).timeout

func capture(name: String) -> void:
	await create_timer(0.6).timeout
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://screenshots/"+name+".png")

func check_routes(extent: Vector2i) -> void:
	var grid := AStarGrid2D.new()
	grid.region = Rect2i(-extent,extent*2+Vector2i.ONE)
	grid.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_NEVER
	grid.update()
	var shape := CapsuleShape3D.new()
	shape.radius = 0.33
	shape.height = 1.6
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = shape
	query.exclude = [scene.player.get_rid()]
	var space = scene.world.get_world_3d().direct_space_state
	for x in range(-extent.x,extent.x+1):
		for z in range(-extent.y,extent.y+1):
			query.transform = Transform3D(Basis.IDENTITY,Vector3(x,0.91,z))
			if not space.intersect_shape(query,1).is_empty():
				grid.set_point_solid(Vector2i(x,z))
	var origin := Vector2i(roundi(scene.player.position.x),roundi(scene.player.position.z))
	for activity in scene.activities:
		var target := Vector2i(roundi(activity.position.x),roundi(activity.position.z))
		check(not grid.get_id_path(origin,target).is_empty(),"walkable route to "+activity.id)
	print("Checked collision-clear routes to ",scene.activities.size()," entrances")

func run() -> void:
	scene = load("res://scenes/Hub.tscn").instantiate()
	root.add_child(scene)
	await wait_scene()
	check(scene.activities.size() == 26,"twenty-six entrances across three districts")
	check_routes(Vector2i(150,42))
	scene.overview = true
	await capture("park")
	scene.overview = false
	scene.camera_zoom = 2.8
	scene.player.position = Vector3(105,0.2,5)
	await capture("zoo_district")
	scene.camera_zoom = 0.35
	scene.player.position = Vector3(84,0.2,-9)
	await capture("animal_panda")
	scene.player.position = Vector3(126,0.2,-9)
	await capture("animal_giraffe")
	scene.camera_zoom = 1.0
	scene.player.position = Vector3(-100,0.2,5)
	await capture("city_district")
	scene.overview = false
	scene.player.position = Vector3(-30,0.2,30)
	await capture("house_exterior")
	scene.player.position = Vector3(-30,0.2,27.5)
	await create_timer(0.1).timeout
	check(scene.current.get("id","") == "home","home proximity")
	var event := InputEventKey.new()
	event.physical_keycode = KEY_E
	event.pressed = true
	scene._unhandled_input(event)
	check(scene.transitioning,"fade transition starts")
	await wait_scene()
	check(scene.inside,"entered house")
	check(not scene.transitioning,"transition finishes")
	check(scene.activities.size() == 7,"six rooms and exit")
	check_routes(Vector2i(20,17))
	scene.overview = true
	await capture("home")
	scene.overview = false
	scene.player.position = Vector3(-14,0.2,6)
	await capture("living_room")
	scene.player.position = Vector3(0,0.2,4.5)
	await create_timer(0.1).timeout
	scene._unhandled_input(event)
	check(scene.panel.visible,"activity panel opens")
	check(not scene.player.enabled,"movement disabled in panel")
	scene._close_panel()
	check(scene.player.enabled,"movement restored")
	scene.player.position = Vector3(0,0.2,16)
	await create_timer(0.1).timeout
	scene._unhandled_input(event)
	await wait_scene()
	check(not scene.inside,"returned to park")
	check(scene.player.position.distance_to(Vector3(-30,0,30.5)) < 1,"returns to same front door")
	scene._action("night")
	check(scene.night,"night toggle")
	await capture("portal_night")
	scene._action("night")
	scene.player.position = Vector3(30,0.2,9)
	await capture("game_street")
	print("VERIFICATION: ","PASS" if failures == 0 else "FAIL", " / failures=",failures)
	quit(0 if failures == 0 else 1)




