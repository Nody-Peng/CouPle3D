extends Node3D
## Nordic garden materials and accents. Small paving stones are instanced, never individual physics bodies.
var host: Node3D
var ripples: Array[Node3D] = []
var water_time := 0.0
var spray: Array[Node3D] = []
const STONE := Color("a8b4ae")
const CAP := Color("ebc796")
const SLATE := Color("387f83")
const TIMBER := Color("b57d49")
static func pave(parent: Node3D, center: Vector3, size: Vector2) -> void:
	var areas: Array = parent.get_meta("stone_areas",[])
	var region := Rect2(Vector2(center.x-size.x/2,center.z-size.y/2),size)
	var mesh := BoxMesh.new()
	mesh.size = Vector3(0.72,0.025,0.43)
	var placements: Array[Vector3] = []
	for row in range(int(size.y/0.48)):
		for column in range(int(size.x/0.78)):
			var p := center+Vector3(-size.x/2+0.48+column*0.78+(0.39 if row%2 else 0.0),0.048,-size.y/2+0.34+row*0.48)
			if p.x+0.37>region.end.x-0.12: continue
			var occupied := false
			for previous in areas:
				if previous.intersects(Rect2(Vector2(p.x-0.38,p.z-0.23),Vector2(0.76,0.46))):
					occupied = true
					break
			if not occupied: placements.append(p)
	var multi := MultiMesh.new()
	multi.transform_format = MultiMesh.TRANSFORM_3D
	multi.use_colors = true
	multi.mesh = mesh
	multi.instance_count = placements.size()
	for i in range(placements.size()):
		multi.set_instance_transform(i,Transform3D(Basis.IDENTITY,placements[i]))
		var t := fmod(absf(sin(i*13.71+center.x)*917.3),1.0)
		multi.set_instance_color(i,Color("c28f5f").lerp(Color("dba774"),t))
	var node := MultiMeshInstance3D.new()
	node.multimesh = multi
	var material := StandardMaterial3D.new()
	material.vertex_color_use_as_albedo = true
	material.roughness = 0.95
	node.material_override = material
	node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(node)
	areas.append(region)
	parent.set_meta("stone_areas",areas)
func build(source: Node3D) -> void:
	host = source
	pave(host.world,Vector3(0,0,50),Vector2(31,11))
	surface_materials()
	water_details()
	rides()
	perimeter()
	skyline()
func surface_materials() -> void:
	for child in host.world.get_children():
		if not child is MeshInstance3D or not child.material_override is StandardMaterial3D: continue
		var color: Color = child.material_override.albedo_color
		if color in [Color("63b4bd"),Color("67acb8"),Color("6ec5cf")]:
			var mat := ShaderMaterial.new()
			mat.shader = preload("res://scripts/nordic_water.gdshader")
			mat.set_shader_parameter("water_color",Color("0a94c9"))
			child.material_override = mat
		elif color==Color("91a38a"):
			var mat := ShaderMaterial.new()
			mat.shader = preload("res://scripts/nordic_lawn.gdshader")
			child.material_override = mat
func jet_point(t: float, angle: float) -> Vector3:
	return Vector3(cos(angle)*(0.5+t*2.8),2.5+sin(t*PI)*0.8-t*1.9,-5+sin(angle)*(0.5+t*2.8))
func arc_stones(center: Vector3, radius: float, y: float, count: int, stone_color: Color) -> void:
	for i in range(count):
		var t := TAU*i/count
		var block: MeshInstance3D = host._box(self,center+Vector3(sin(t)*radius,y,cos(t)*radius),Vector3(radius*TAU/count*0.92,0.2,0.4),stone_color.lightened((i%4)*0.015))
		block.rotation.y = t
func water_details() -> void:
	for i in range(8):
		var angle := TAU*i/8
		for segment in range(14):
			host._beam(self,jet_point(float(segment)/14,angle),jet_point(float(segment+1)/14,angle),0.025,Color("a7def5"))
		var droplet: MeshInstance3D = host._ball(self,jet_point(0,angle),0.065,Color("e1f1e8"))
		droplet.set_meta("angle",angle)
		spray.append(droplet)
	# Segmented coping and concentric stone aprons follow the existing round collision boundaries.
	arc_stones(Vector3(0,0,-5),4.28,0.58,48,CAP)
	arc_stones(Vector3(0,0,-5),5.7,0.17,64,STONE)
	natural_pond()
	for center in [Vector3(0,0.585,-5)]:
		for i in range(4):
			var ring := TorusMesh.new()
			ring.inner_radius = 0.63+i*0.5
			ring.outer_radius = ring.inner_radius+0.025
			var ripple: MeshInstance3D = host._mesh(self,ring,center,Color("bce8fa"))
			ripple.set_meta("phase",float(i))
			ripples.append(ripple)
	# Tall irises, rushes and shore rocks live within the pond barrier.
	for i in range(16):
		var t := PI+float(i)*PI/17
		var p := Vector3(-40+cos(t)*6.7,0,-6+sin(t)*6.7)
		for j in range(3):
			host._beam(self,p+Vector3(j*0.12,0.15,0),p+Vector3(j*0.12,0.85+0.15*j,0.08),0.035,Color("7f986e"))
			if i%3==0: host._ball(self,p+Vector3(j*0.12,1.0+0.15*j,0.08),0.09,Color("b7a6bc"))
		if i%2==0:
			var rock: MeshInstance3D = host._ball(self,p+Vector3(0,0.16,0.4),0.48,Color("8dada8"))
			rock.scale = Vector3(1.2,0.6,0.8)
	# Mallard silhouettes, kept inside the water and away from the walking edge.
	for i in range(3):
		var p := Vector3(-43+i*2.1,0.16,-5+i*0.4)
		var duck: MeshInstance3D = host._ball(self,p,0.25,Color("ac9574"))
		duck.scale = Vector3(0.7,0.6,1.4)
		host._ball(self,p+Vector3(0,0.22,0.2),0.13,Color("507c69"))
		host._box(self,p+Vector3(0,0.2,0.36),Vector3(0.1,0.055,0.14),Color("d3b161"))
	# Fountain bowl rim and brass water nozzles.
	arc_stones(Vector3(0,0,-5),1.92,1.84,28,CAP)
	for i in range(8):
		var t := TAU*i/8
		host._cylinder(self,Vector3(sin(t)*3.65,0.68,-5+cos(t)*3.65),0.055,0.22,TIMBER)
func rides() -> void:
	# Material layers add craftsmanship to platforms without narrowing their approaches.
	arc_stones(Vector3(12,0,-28),4.4,0.34,48,CAP)
	arc_stones(Vector3(-25,0,-28),5.9,0.25,56,STONE)
	if is_instance_valid(host.carousel):
		for i in range(32):
			var t := TAU*i/32
			host._ball(host.carousel,Vector3(sin(t)*4.1,4.25,cos(t)*4.1),0.07,Color("eed9ae")).material_override=host._material(Color("eed9ae"),true)
		for i in range(8):
			var t := TAU*i/8
			host._beam(host.carousel,Vector3(0,5.4,0),Vector3(sin(t)*4.2,4.4,cos(t)*4.2),0.055,CAP)
	if is_instance_valid(host.wheel):
		for cabin in host.cabins:
			for x in [-0.48,0.48]: host._box(cabin,Vector3(x,-0.08,0.1),Vector3(0.05,0.65,0.65),CAP)
			host._box(cabin,Vector3(0,-0.3,0.25),Vector3(0.85,0.18,0.25),TIMBER)
			host._ball(cabin,Vector3(0,0.27,0),0.07,Color("f0dca8"))
func wall_course(a: Vector3, b: Vector3, height: float) -> void:
	var length := a.distance_to(b)
	var direction := (b-a).normalized()
	var transforms: Array[Transform3D] = []
	for row in range(int(height/0.38)):
		for i in range(int(length/1.9)):
			var p := a+direction*(0.95+i*1.9+(0.45 if row%2 else 0.0))
			if p.distance_to(a)>length-0.4: continue
			transforms.append(Transform3D(Basis(Vector3.UP,atan2(-direction.z,direction.x)),p+Vector3(0,0.2+row*0.38,0)))
	var mesh := BoxMesh.new()
	mesh.size = Vector3(1.82,0.34,0.56)
	var multi := MultiMesh.new()
	multi.transform_format = MultiMesh.TRANSFORM_3D
	multi.mesh = mesh
	multi.use_colors = true
	multi.instance_count = transforms.size()
	for i in range(transforms.size()):
		multi.set_instance_transform(i,transforms[i])
		multi.set_instance_color(i,STONE.lightened((i%3)*0.025))
	var node := MultiMeshInstance3D.new()
	node.multimesh = multi
	var mat := StandardMaterial3D.new()
	mat.vertex_color_use_as_albedo = true
	mat.roughness = 0.95
	node.material_override = mat
	add_child(node)
	host._beam(self,a+Vector3(0,height,0),b+Vector3(0,height,0),0.2,CAP)
func perimeter() -> void:
	# Existing physics walls remain in place; masonry joints are purely visual.
	wall_course(Vector3(-151.5,0,-43),Vector3(-151.5,0,43),1.9)
	wall_course(Vector3(151.5,0,-43),Vector3(151.5,0,43),1.9)
	wall_course(Vector3(-151,0,-43.5),Vector3(151,0,-43.5),1.9)
	wall_course(Vector3(-151,0,43.5),Vector3(-16,0,43.5),1.0)
	wall_course(Vector3(16,0,43.5),Vector3(151,0,43.5),1.0)
func skyline() -> void:
	# Warm Scandinavian townhouses, steep slate roofs, chimneys and framed windows.
	for i in range(19):
		var x := -60.0+i*6.7
		var h := 8.0+float((i*7)%15)
		var roof_color := SLATE.lightened((i%3)*0.035)
		for side in [-1,1]:
			var roof: MeshInstance3D = host._box(self,Vector3(x+side*1.5,h+1.1,-52),Vector3(3.6,0.22,7),roof_color)
			roof.rotation.z = -side*0.58
		host._box(self,Vector3(x+1.6,h+2.4,-53.5),Vector3(0.65,2.3,0.8),Color("c1aea0"))
		host._box(self,Vector3(x+1.6,h+3.6,-53.5),Vector3(0.85,0.18,1),CAP)
		for y in range(2,int(h)-1,3):
			for dx in [-1.8,-0.6,0.6,1.8]:
				host._box(self,Vector3(x+dx,y-0.63,-48.64),Vector3(0.75,0.1,0.18),CAP)
				host._box(self,Vector3(x+dx,y,-48.67),Vector3(0.035,1.15,0.08),CAP)
			if y==2:
				host._box(self,Vector3(x,1.1,-48.55),Vector3(1.3,2.2,0.18),SLATE)
				for side in [-1,1]: host._box(self,Vector3(x+side*1.6,0.38,-48.4),Vector3(1.2,0.55,0.7),TIMBER)
func _process(delta: float) -> void:
	water_time += delta
	for i in range(spray.size()):
		spray[i].position = jet_point(fmod(water_time*0.55+float(i)/8,1.0),spray[i].get_meta("angle"))
	for ripple in ripples:
		var phase: float = ripple.get_meta("phase")
		var s := 1.0+sin(water_time*0.65+phase)*0.045
		ripple.scale = Vector3(s,1,s)



func natural_pond() -> void:
	var center := Vector3(-40,0,-6)
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in range(96):
		var a := TAU*i/96
		var b := TAU*(i+1)/96
		var ra := 6.95+sin(a*3)*0.32+cos(a*5)*0.18
		var rb := 6.95+sin(b*3)*0.32+cos(b*5)*0.18
		for vertex in [center+Vector3(0,0.09,0),center+Vector3(cos(a)*ra,0.09,sin(a)*ra),center+Vector3(cos(b)*rb,0.09,sin(b)*rb)]: surface.add_vertex(vertex)
		if i%2==0:
			var rock: MeshInstance3D = host._ball(self,center+Vector3(cos(a)*(ra+0.1),0.13,sin(a)*(ra+0.1)),0.4,STONE.darkened((i%5)*0.025))
			rock.scale = Vector3(1.2,0.45+(i%3)*0.1,0.85)
			rock.rotation.y = a
	surface.generate_normals()
	var water: MeshInstance3D = host._mesh(self,surface.commit(),Vector3.ZERO,Color("078fc7"))
	var mat := ShaderMaterial.new()
	mat.shader = preload("res://scripts/nordic_water.gdshader")
	mat.set_shader_parameter("water_color",Color("078fc7"))
	water.material_override = mat

static func garden_path(source: Node3D, points: Array[Vector3], width: float) -> void:
	var curve := Curve3D.new()
	for i in range(points.size()):
		var tangent := (points[mini(i+1,points.size()-1)]-points[maxi(i-1,0)]).normalized()*2.0
		curve.add_point(points[i],-tangent,tangent)
	var length := curve.get_baked_length()
	for layer in range(2):
		var surface := SurfaceTool.new()
		surface.begin(Mesh.PRIMITIVE_TRIANGLES)
		var count := int(length/0.35)
		for i in range(count):
			var t := length*i/count
			var t2 := length*(i+1)/count
			var a := curve.sample_baked(t)
			var b := curve.sample_baked(t2)
			var end_width := 7.0 if width>4.0 else 5.0
			var blend := smoothstep(0.0,6.0,minf(t,length-t))
			var normal := Vector3(-(b-a).z,0,(b-a).x).normalized()*(lerpf(end_width,width,blend)/2+0.12*(1-layer))
			var up := Vector3(0,0.04+layer*0.012,0)
			for v in [a-normal,b+normal,a+normal,a-normal,b-normal,b+normal]: surface.add_vertex(v+up)
		surface.generate_normals()
		var node: MeshInstance3D = source._mesh(source.world,surface.commit(),Vector3.ZERO,CAP)
		if layer==1:
			var mat := ShaderMaterial.new()
			mat.shader = preload("res://scripts/nordic_path.gdshader")
			node.material_override = mat
