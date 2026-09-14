extends SceneTree
var failures := 0
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var scene = load("res://scenes/Hub.tscn").instantiate()
	root.add_child(scene)
	var district: Node
	for node in scene.world.get_children():
		if node.get_script()==load("res://scripts/world_districts.gd"): district = node
	while not district.navigation_ready: await physics_frame
	var starts: Array[Vector3] = []
	var distances: Array[float] = []
	for w in district.walkers:
		starts.append(w.node.position)
		distances.append(0.0)
	var query := PhysicsShapeQueryParameters3D.new()
	var shape := CapsuleShape3D.new()
	shape.radius = 0.4
	shape.height = 1.65
	query.shape = shape
	query.collision_mask = 1
	var space: PhysicsDirectSpaceState3D = scene.world.get_world_3d().direct_space_state
	for frame in range(900):
		await physics_frame
		for i in range(district.walkers.size()):
			var actor: CharacterBody3D = district.walkers[i].node
			distances[i] = maxf(distances[i],actor.position.distance_to(starts[i]))
			if frame%10==0:
				query.transform = Transform3D(Basis.IDENTITY,actor.position+Vector3(0,0.91,0))
				if not space.intersect_shape(query,1).is_empty():
					failures += 1
					push_error("NPC overlaps static geometry: "+str(i)+" at "+str(actor.position))
	for i in range(distances.size()):
		if distances[i]<0.5:
			failures += 1
			push_error("NPC did not patrol: "+str(i))
	for animal in district.animals:
		if animal.position.distance_to(animal.origin)>1.0:
			failures += 1
	print("NPC PATROL: ","PASS" if failures==0 else "FAIL", " / ",district.walkers.size()," pedestrians, 900 physics frames; animal routes bounded")
	quit(failures)
