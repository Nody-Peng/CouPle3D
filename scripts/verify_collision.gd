extends SceneTree
var scene: Node3D
var failures := 0
func _initialize() -> void: call_deferred("run")
func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)
func walk(start: Vector3, direction: Vector3, seconds: float) -> Vector3:
	scene.player.position = start
	scene.player.velocity = Vector3.ZERO
	var frames := int(seconds*60)
	for i in range(frames):
		var right: Vector3 = scene.camera.global_basis.x
		var forward: Vector3 = scene.camera.global_basis.z
		right.y = 0
		forward.y = 0
		scene.player.touch_input = Vector2(direction.dot(right.normalized()),direction.dot(forward.normalized()))
		await physics_frame
	scene.player.touch_input = Vector2.ZERO
	return scene.player.position
func run() -> void:
	scene = load("res://scenes/Hub.tscn").instantiate()
	root.add_child(scene)
	await create_timer(0.5).timeout
	var p := await walk(Vector3(-20,0.2,34),Vector3(0,0,1),1.2)
	check(p.z<35.75,"Flowerbed must block before the visible rim")
	p = await walk(p,Vector3(1,0,1).normalized(),1.4)
	check(p.x>-17.5,"Player must slide along flowerbed without snagging")
	p = await walk(Vector3(-29,0.2,-6),Vector3(-1,0,0),1.3)
	check(p.x>-32.6,"Round pond barrier must keep player out of water")
	p = await walk(p,Vector3(0,0,1),1.0)
	check(p.z>-2,"Player can leave pond edge")
	for side in [-1,1]:
		p = await walk(Vector3(side*149,0.2,5),Vector3(side,0,0),1.0)
		check(absf(p.x)<151.1,"World perimeter blocks outward movement")
	p = await walk(Vector3(84,0.2,-2),Vector3(0,0,-1),1.0)
	check(p.z>-4.85,"Habitat fence stops player outside enclosure")
	print("COLLISION REGRESSION: ","PASS" if failures==0 else "FAIL")
	quit(failures)

