extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var scene = load("res://scenes/CoupleHome2D.tscn").instantiate()
	root.add_child(scene)
	await physics_frame
	await physics_frame
	var player = scene.players[0]
	player.can_move = false
	scene.players[1].position = Vector2(100,750)
	# All doors must be traversable, while their adjacent wall blocks the same motion.
	for route in [[Vector2(580,440),Vector2(80,0)], [Vector2(310,475),Vector2(0,115)], [Vector2(810,475),Vector2(0,115)], [Vector2(1020,475),Vector2(0,115)], [Vector2(1100,440),Vector2(180,0)]]:
		player.position = route[0]
		assert(player.move_and_collide(route[1]) == null, "Blocked doorway: " + str(route[0]))
	player.position = Vector2(580,330)
	assert(player.move_and_collide(Vector2(80,0)) != null, "Wall is not solid")
	player.position = Vector2(1275,470)
	assert(player.position.distance_to(scene.interactions[6].position) < 80)
	scene._open_note("test","test")
	assert(not player.can_move and scene.note_panel.visible)
	scene._close_note()
	assert(player.can_move and not scene.note_panel.visible)
	player.can_move=false
	player.position=Vector2(1280,444)
	for destination in [Vector2(1500,444),Vector2(2100,444),Vector2(2900,444),Vector2(3550,444),Vector2(4100,444)]:
		assert(player.move_and_collide(destination-player.position)==null,"Coast route blocked")
	assert(player.move_and_collide(Vector2(0,180))!=null,"Pier must block entry into water")
	player.position=Vector2(3600,300)
	assert(player.move_and_collide(Vector2(200,0))!=null,"Shore must block entry into water")
	player.position=Vector2(1890,370)
	scene._try_interact(player)
	assert(player.position.distance_to(Vector2(1100,448))<1,"Home entrance failed")
	# Both new kitchen stations are approachable and have a solid worktop.
	for x in [946,1044]:
		player.position=Vector2(x,330)
		assert(player.move_and_collide(Vector2(0,-30))==null,"Kitchen station is inaccessible")
		assert(player.move_and_collide(Vector2(0,-90))!=null,"Kitchen counter is not solid")
		player.position=Vector2(x,300)
		scene._try_interact(player)
		assert(scene.get_node("HomeFurnishings").activity==("stove" if x==946 else "sink"),"Wrong kitchen action")
	# Major new furniture and outdoor fixtures cannot be walked through.
	for probe in [[Vector2(340,414),Vector2(0,-70)],[Vector2(810,725),Vector2(0,-70)],[Vector2(1910,760),Vector2(0,-80)],[Vector2(3260,410),Vector2(0,-80)]]:
		player.position=probe[0]
		assert(player.move_and_collide(probe[1])!=null,"Missing furniture footprint: "+str(probe[0]))
	player.position=Vector2(3500,445)
	await process_frame
	await process_frame
	assert(not scene.note_preview.get_parent().visible,"Indoor note obstructs beach")
	player.position=Vector2(500,430)
	await process_frame
	await process_frame
	assert(scene.note_preview.get_parent().visible,"Indoor note did not return")
	assert(is_equal_approx(scene.area_camera.zoom.x,2.0),"Indoor close view missing")
	scene._set_view_zoom(1.0)
	await process_frame
	await process_frame
	assert(is_equal_approx(scene.area_camera.zoom.x,1.0),"Overview failed")
	scene._set_view_zoom(3.0)
	assert(is_equal_approx(scene.view_zoom,2.0),"Zoom limit failed")
	scene._set_view_zoom(0.0)
	player.position=Vector2(845,310)
	await process_frame
	await process_frame
	assert(scene.action_button.visible and scene.action_button.text=="冰箱便條","Context action missing")
	scene.action_button.pressed.emit()
	assert(scene.note_panel.visible,"Click action did not open note")
	scene._close_note()
	for entrance in [Vector2(2340,370),Vector2(2610,730),Vector2(1910,730)]:
		player.position=entrance+Vector2(0,30)
		assert(player.move_and_collide(Vector2(0,-30))==null,"Town doorway inaccessible")
		scene._try_interact(player)
		assert(scene.social.panel.visible,"Town doorway did not open its activity")
		scene.social.panel.hide()
		scene.social._set_input()
		player.can_move=false
	print("PASS: town shop, cafe and post entrances")
	print("PASS: close camera, overview, zoom limits and clickable furniture action")
	print("PASS: five doors; coast/pier boundaries; note modal; kitchen access/actions; furniture footprints; area HUD")
	quit()
