extends Node
## Curved zoo landscaping and collision-aware pedestrians. Static props are sampled after physics sync.
var host: Node3D
var walkers: Array[Dictionary] = []
var animals: Array[Node3D] = []
var navigation := AStarGrid2D.new()
var navigation_ready := false
const HABITATS = preload("res://data/zoo.json")
const LOOKS = ["female-a","female-b","female-c","female-d","female-e","female-f","male-a","male-b","male-c","male-d","male-e","male-f"]

func build(source: Node3D) -> void:
	host = source
	host._path(Vector3(-101,0,5),Vector2(96,8))
	host._path(Vector3(-100,0,0),Vector2(7,76))
	for side in [-1,1]:
		for z in [-37,-18,37]:
			for x in [61,94,148]:
				host._tree(Vector3(side*x,0,z),Color("94b384") if side>0 else Color("d5a7b0"))
		for x in range(61,145,12):
			if side<0: host._lamp(Vector3(side*x,0,10))
	zoo()
	city()
	street_details()
	if not host.low_detail:
		for i in range(4):
			npc(Vector3(-3,0,17-i*10),"約會旅人",LOOKS[i+3],Vector3(0,0,3))
		call_deferred("prepare_navigation")

func ribbon(points: PackedVector3Array, width: float, color: Color) -> void:
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	var left := PackedVector3Array()
	var right := PackedVector3Array()
	var closed := points[0].distance_to(points[points.size()-1])<0.01
	for i in range(points.size()):
		var before := points[points.size()-2] if closed and i==0 else points[maxi(0,i-1)]
		var after := points[1] if closed and i==points.size()-1 else points[mini(points.size()-1,i+1)]
		var tangent := (after-before).normalized()
		var local_width := width
		if absf(points[0].x-48.0)<0.1 and absf(points[0].z-5.0)<0.1:
			local_width += 2.5*(1.0-smoothstep(54.0,68.0,points[i].x))
		var normal := Vector3(-tangent.z,0,tangent.x)*local_width/2
		left.append(points[i]+normal)
		right.append(points[i]-normal)
	for i in range(points.size()-1):
		var a := left[i]
		var b := right[i]
		var c := left[i+1]
		var d := right[i+1]
		for v in [a,b,c,b,d,c]:
			surface.set_normal(Vector3.UP)
			surface.add_vertex(v)
	var mesh: MeshInstance3D = host._mesh(host.world,surface.commit(),Vector3.ZERO,color)
	# Walking paths are flat decoration; the world floor supplies collision.
	mesh.material_override = host._material(color).duplicate()
	mesh.material_override.cull_mode = BaseMaterial3D.CULL_DISABLED
	mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	if color==Color("eedfd0") or color==Color("d7c5b0"):
		var paving := ShaderMaterial.new()
		paving.shader = preload("res://scripts/nordic_path.gdshader")
		mesh.material_override = paving

func curve_path(points: Array, width := 4.0) -> void:
	var curve := Curve3D.new()
	curve.bake_interval = 0.65
	for i in range(points.size()):
		var previous: Vector3 = points[maxi(0,i-1)]
		var next: Vector3 = points[mini(points.size()-1,i+1)]
		var tangent := (next-previous)*0.16
		curve.add_point(points[i]+Vector3(0,0.06,0),-tangent,tangent)
	var baked := curve.get_baked_points()
	ribbon(baked,width+0.4,Color("eee0c6"))
	for i in range(baked.size()): baked[i].y = 0.09
	ribbon(baked,width,Color("d7c5b0"))

func zoo() -> void:
	host._label(host.world,"心 森 · 愛 心 動 物 園",Vector3(105,6,7),56)
	# A continuous mathematical heart promenade, with meandering branches to the habitats.
	var heart := PackedVector3Array()
	for i in range(145):
		var t := TAU*float(i)/144
		var p := Vector3(105+pow(sin(t),3)*40.8,0.055,-(13*cos(t)-5*cos(2*t)-2*cos(3*t)-cos(4*t))*2)
		heart.append(p)
	ribbon(heart,4.8,Color("edc9c5"))
	for i in range(heart.size()): heart[i].y = 0.09
	ribbon(heart,3.8,Color("eedfd0"))
	for i in range(0,144,6):
		var p: Vector3 = heart[i]
		var side := (p-Vector3(105,0,0)).normalized()
		p += side*3
		for j in range(3):
			host._ball(host.world,p+Vector3(j*0.3,0.25,0),0.2,Color("cf8a94") if j%2 else Color("92ab77"))
	curve_path([Vector3(48,0,5),Vector3(58,0,5),Vector3(69,0,4),Vector3(84,0,-2),Vector3(99,0,6),Vector3(112,0,7),Vector3(126,0,-2),Vector3(141,0,5)],4.5)
	curve_path([Vector3(47,0,-14),Vector3(55,0,-13),Vector3(59,0,-5),Vector3(62,0,5)],4.5)
	# Broad arrival court joins the avenue and zoo loop without narrow pointed wedges.
	var court: MeshInstance3D = host._cylinder(host.world,Vector3(61,0.044,5),5.0,0.02,Color("eee0c6"))
	var paving: MeshInstance3D = host._cylinder(host.world,Vector3(61,0.077,5),4.8,0.02,Color("d7c5b0"))
	var mat := ShaderMaterial.new()
	mat.shader = preload("res://scripts/nordic_path.gdshader")
	paving.material_override = mat
	curve_path([Vector3(68,0,4),Vector3(71,0,10),Vector3(76,0,14)],3.5)
	curve_path([Vector3(111,0,7),Vector3(110,0,10),Vector3(105,0,12)],3.0)
	curve_path([Vector3(126,0,-2),Vector3(134,0,3),Vector3(140,0,9)],3.5)
	curve_path([Vector3(99,0,6),Vector3(103,0,4),Vector3(105,0,1)],3.0)
	for h in HABITATS.data:
		habitat(h)
		habitat_details(h)
	host._signpost(Vector3(60,0,10),"愛心環道 →  六種動物，六個小世界")
	if not host.low_detail:
		npc(Vector3(91,0,8),"米米 · 動物園嚮導","female-e",Vector3(3,0,0))
	host._activity("guide_zoo","米米 · 動物園嚮導","歡迎來到心森愛心動物園！沿著愛心環道拜訪六個棲地，每天任選三種動物收集印章，就能獲得 30 金幣。",Vector3(91,0,11))
	for p in [Vector3(63,0,14),Vector3(93,0,28),Vector3(118,0,33)]:
		host._bench(p,0)
		host._lamp(p+Vector3(2,0,0))
	# A heart sculpture at the inner plaza, built with the same curve family as the promenade.
	var sculpture := Node3D.new()
	host.world.add_child(sculpture)
	for i in range(40):
		var t := TAU*float(i)/40
		var p := Vector3(94+pow(sin(t),3)*1.6,2.8+(13*cos(t)-5*cos(2*t)-2*cos(3*t)-cos(4*t))*0.1,17)
		host._ball(sculpture,p,0.18,Color("cf8293"))
	host._cylinder(host.world,Vector3(94,0.15,17),2,0.3,host.CREAM)

func habitat(h: Dictionary) -> void:
	var p := Vector3(h.x,0,h.z)
	var patch: MeshInstance3D = host._cylinder(host.world,p+Vector3(0,0.04,0),1,0.08,Color(h.color))
	patch.scale = Vector3(h.rx,1,h.rz)
	# Convex ellipsoid matches the curved fence; no square invisible corners remain.
	var body := StaticBody3D.new()
	var collision := CollisionShape3D.new()
	var shape := ConvexPolygonShape3D.new()
	var vertices := PackedVector3Array()
	for i in range(48):
		var t := TAU*float(i)/48
		for y in [0.0,3.0]: vertices.append(Vector3(cos(t)*h.rx,y,sin(t)*h.rz))
	shape.points = vertices
	collision.shape = shape
	body.add_child(collision)
	host.world.add_child(body)
	body.position = p
	for i in range(48):
		var t := TAU*float(i)/48
		var next := TAU*float(i+1)/48
		var a := p+Vector3(cos(t)*h.rx,0,sin(t)*h.rz)
		var b := p+Vector3(cos(next)*h.rx,0,sin(next)*h.rz)
		for y in [0.55,1.05]: host._beam(host.world,a+Vector3(0,y,0),b+Vector3(0,y,0),0.09,Color("bb784a"))
		if i%3==0:
			host._cylinder(host.world,a+Vector3(0,0.65,0),0.1,1.3,host.CREAM)
			host._ball(host.world,a+Vector3(0,1.34,0),0.14,Color("e8b27a"))
	var animal_count := 1 if host.low_detail else 3
	for i in range(animal_count):
		var animal := Node3D.new()
		animal.set_script(load("res://scripts/zoo_animal.gd"))
		host.world.add_child(animal)
		animal.roaming = 0.65
		animal.build(host,h.id,p+Vector3((i-1)*3.3,0,0),i)
		animals.append(animal)
	# Different planting, shelters and water features give each habitat its own silhouette.
	if h.id in ["capybara","penguin"]:
		var pond: MeshInstance3D = host._cylinder(host.world,p+Vector3(0,0.095,-h.rz*0.48),1,0.045,Color("139bcb"))
		pond.scale = Vector3(h.rx*0.68,1,h.rz*0.32)
		for i in range(5):
			var rock: MeshInstance3D = host._ball(host.world,p+Vector3(-h.rx*0.6+i*h.rx*0.3,0.4,-h.rz*0.76),0.65,Color("e6e8df") if h.id=="penguin" else Color("8fa3a0"))
			rock.scale = Vector3(1,0.5+0.1*i,0.7)
	elif h.id=="panda":
		var bamboo_count := 7 if host.low_detail else 15
		for i in range(bamboo_count):
			var q := p+Vector3(-6.5+i*(13.0/maxf(1,bamboo_count-1)),0,-5.3+sin(i*2.1)*0.55)
			var height := 2.5+0.8*(1.0+sin(i*1.7))
			host._cylinder(host.world,q+Vector3(0,height/2,0),0.065,height,Color("3e853e"))
			for joint in range(1,int(height/0.45)):
				host._cylinder(host.world,q+Vector3(0,joint*0.45,0),0.083,0.045,Color("8dbc54"))
			for branch in range(3):
				var angle := i*2.4+branch*2.1
				var origin := q+Vector3(0,height-0.35-branch*0.45,0)
				var tip := origin+Vector3(cos(angle)*0.65,0.25,sin(angle)*0.65)
				host._beam(host.world,origin,tip,0.023,Color("367845"))
				for leaf_index in range(4):
					var leaf: MeshInstance3D = host._ball(host.world,origin.lerp(tip,0.35+leaf_index*0.2),0.24,Color("559a45").lightened((leaf_index%2)*0.08))
					leaf.scale = Vector3(0.28,0.12,1.25)
					leaf.rotation.y = angle+leaf_index*0.8
			if i%3==0:
				var rock: MeshInstance3D = host._ball(host.world,q+Vector3(0.2,0.18,0.3),0.45,Color("969b83"))
				rock.scale = Vector3(1.3,0.55,0.8)
	else:
		for i in range(3): host._tree(p+Vector3((i-1)*h.rx*0.6,0,-h.rz*0.65),Color("c4a582") if h.id=="fox" else Color("91ac75"))
	if h.id=="rabbit":
		for i in range(12): host._ball(host.world,p+Vector3(sin(i*3)*5,0.3,cos(i*3)*3.4),0.22,[host.CORAL,host.GOLD,host.CREAM][i%3])
	if h.id in ["fox","rabbit"]:
		host._box(host.world,p+Vector3(0,0.7,-h.rz*0.55),Vector3(2.2,1.4,1.5),Color("b79470"))
		var roof: MeshInstance3D = host._cylinder(host.world,p+Vector3(0,1.6,-h.rz*0.55),1.6,0.7,Color("7b8d72"),0.1)
		host._ball(host.world,p+Vector3(0,0.65,-h.rz*0.55+0.76),0.45,Color("594e43"))
	host._activity("zoo_"+h.id,h.name+" · 觀察手帳",h.description,Vector3(h.entryX,0,h.entryZ))
func city() -> void:
	host._label(host.world,"花 漾 都 市 · CITY WALK",Vector3(-104,7,5),54)
	var names := ["花漾百貨","一起銀行","花園咖啡","生活選物"]
	var ids := ["city_shop","city_bank","city_cafe","city_home"]
	for i in range(4):
		var p := Vector3(-76 if i%2==0 else -126,0,-22 if i<2 else 25)
		if i==2:
			var cafe := Node3D.new()
			cafe.set_script(load("res://scripts/garden_cafe.gd"))
			host.world.add_child(cafe)
			cafe.build(host,p)
			continue
		var building := Node3D.new()
		building.set_script(load("res://scripts/city_venues.gd"))
		host.world.add_child(building)
		building.build(host,p,"bank" if i==1 else ("shop" if i==0 else "home"))
	if not host.low_detail:
		for i in range(5):
			npc(Vector3(-65-i*16,0,8 if i%2==0 else 1),["小悠","阿樂","花店店長","攝影師","散步旅人"][i],LOOKS[7+i],Vector3(5,0,0))
	host._activity("city_neighbor","小悠 · 城市散步","今天也要留一點時間給彼此！百貨可以買配件，銀行可以存共同金幣，生活選物能布置你們的家。",Vector3(-61,0,14))
	for x in [-86,-112]:
		if x==-112: host._bench(Vector3(x,0,14),0)
		host._string_lights(Vector3(x-5,5,11),Vector3(x+5,5,11))


func npc(p: Vector3, label: String, base: String, roam: Vector3) -> void:
	var actor := CharacterBody3D.new()
	actor.collision_layer = 2
	actor.collision_mask = 3
	actor.safe_margin = 0.04
	var collision := CollisionShape3D.new()
	var shape := CapsuleShape3D.new()
	shape.radius = 0.42
	shape.height = 1.8
	collision.shape = shape
	collision.position.y = 0.9
	actor.add_child(collision)
	host.world.add_child(actor)
	actor.position = p+Vector3(0,0.1,0)
	var person := Node3D.new()
	person.set_script(load("res://scripts/couple_avatar.gd"))
	actor.add_child(person)
	var index := walkers.size()
	person.apply_appearance({"base":base,"hat":"hat_beret" if index%4==1 else "none","glasses":"glasses_round" if index%4==2 else "none","bag":"bag_daypack" if index%4==3 else "none"})
	host._label(actor,label,Vector3(0,2.3,0),24)
	walkers.append({"node":actor,"model":person,"origin":p,"range":roam,"goal":0,"path":PackedVector3Array(),"point":0,"wait":float(index)*0.2,"stuck":0.0})

func nearest_open(p: Vector3) -> Vector2i:
	var cell := Vector2i(roundi(p.x),roundi(p.z))
	for radius in range(12):
		for x in range(-radius,radius+1):
			for z in range(-radius,radius+1):
				var candidate := cell+Vector2i(x,z)
				if navigation.is_in_boundsv(candidate) and not navigation.is_point_solid(candidate): return candidate
	return Vector2i.ZERO

func prepare_navigation() -> void:
	await get_tree().physics_frame
	await get_tree().physics_frame
	navigation.region = Rect2i(-151,-43,303,87)
	navigation.cell_size = Vector2.ONE
	navigation.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES
	navigation.update()
	var query := PhysicsShapeQueryParameters3D.new()
	var shape := CapsuleShape3D.new()
	shape.radius = 0.7 # Includes visual body / accessory clearance, not just the collision capsule.
	shape.height = 1.8
	query.shape = shape
	query.collision_mask = 1
	var space: PhysicsDirectSpaceState3D = host.world.get_world_3d().direct_space_state
	for x in range(-151,152):
		for z in range(-43,44):
			query.transform = Transform3D(Basis.IDENTITY,Vector3(x,1.01,z))
			if not space.intersect_shape(query,1).is_empty(): navigation.set_point_solid(Vector2i(x,z))
	for w in walkers:
		var start := nearest_open(w.origin)
		w.node.position = Vector3(start.x,0.1,start.y)
		plan_route(w)
	navigation_ready = true

func plan_route(w: Dictionary) -> void:
	var sign_value := 1.0 if w.goal%2==0 else -1.0
	var start := nearest_open(w.node.position)
	var goal := nearest_open(w.origin+w.range*sign_value)
	var cells := navigation.get_id_path(start,goal)
	w.path = PackedVector3Array()
	for cell in cells: w.path.append(Vector3(cell.x,0,cell.y))
	w.point = 0
	w.goal += 1
	w.stuck = 0.0

func _physics_process(delta: float) -> void:
	if not navigation_ready: return
	for w in walkers:
		var actor: CharacterBody3D = w.node
		var previous := actor.position
		var direction := Vector3.ZERO
		if w.wait>0:
			w.wait -= delta
		elif w.point<w.path.size():
			direction = w.path[w.point]-actor.position
			direction.y = 0
			if direction.length()<0.18:
				w.point += 1
				direction = Vector3.ZERO
			else: direction = direction.normalized()
		else:
			w.wait = 1.7+fmod(float(w.goal),2.0)
			plan_route(w)
		actor.velocity.x = direction.x*1.15
		actor.velocity.z = direction.z*1.15
		actor.velocity.y = -0.5 if actor.is_on_floor() else maxf(actor.velocity.y-delta*20,-20)
		actor.move_and_slide()
		var distance := Vector2(actor.position.x-previous.x,actor.position.z-previous.z).length()
		if direction.length()>0 and distance<delta*0.15:
			w.stuck += delta
			if w.stuck>1.5:
				plan_route(w)
				w.wait = 1.0
		else: w.stuck = 0.0
		w.model.play_animation("walk" if distance>delta*0.2 else "idle")
		if distance>delta*0.2:
			w.model.rotation.y = lerp_angle(w.model.rotation.y,atan2(direction.x,direction.z),minf(delta*5,1))









func street_details() -> void:
	# Contrasting stone crossings at the city junction; these do not obstruct pedestrians.
	for z in [-3,-1,1,3,5,7,9,11]:
		host._box(host.world,Vector3(-100,0.075,z),Vector3(5.6,0.02,0.65),Color("f3e6cf"))
	for x in [-145,-106,-58]:
		var p := Vector3(x,0,12)
		# Paired recycling bins, with hinged lids and narrow collection openings.
		for side in [-1,1]:
			var q := p+Vector3(side*0.45,0,0)
			host._box(host.world,q+Vector3(0,0.5,0),Vector3(0.65,1,0.65),Color("68887c") if side<0 else Color("a6997c"),true)
			host._box(host.world,q+Vector3(0,1.05,0),Vector3(0.72,0.12,0.72),host.CREAM)
			host._box(host.world,q+Vector3(0,1.12,0),Vector3(0.38,0.03,0.2),host.INK)
	# A freestanding district information kiosk.
	var kiosk := Vector3(-101,0,20)
	host._box(host.world,kiosk+Vector3(0,1.35,0),Vector3(2.4,2.7,0.45),host.TEAL,true)
	host._box(host.world,kiosk+Vector3(0,1.6,0.25),Vector3(2.05,1.65,0.06),host.CREAM)
	host._label(host.world,"CITY WALK\n銀行・百貨\n咖啡・生活選物",kiosk+Vector3(0,2,0.32),24)
	# Parked bicycles: tyres, spokes, triangular frames, saddle and handlebars.
	for i in range(3):
		var p := Vector3(-111+i*2.5,0,-5)
		for x in [-0.65,0.65]:
			var tyre := TorusMesh.new()
			tyre.inner_radius = 0.32
			tyre.outer_radius = 0.4
			var wheel: MeshInstance3D = host._mesh(host.world,tyre,p+Vector3(x,0.45,0),host.INK)
			wheel.rotation.x = PI/2
			for j in range(6):
				var t := TAU*j/6
				host._beam(host.world,p+Vector3(x,0.45,0),p+Vector3(x+cos(t)*0.34,0.45+sin(t)*0.34,0),0.015,host.CREAM)
		var a := p+Vector3(-0.65,0.45,0)
		var b := p+Vector3(0,0.45,0)
		var c := p+Vector3(-0.25,1,0)
		var d := p+Vector3(0.45,1.05,0)
		for pair in [[a,b],[b,c],[c,a],[c,d],[b,d],[d,p+Vector3(0.65,0.45,0)]]:
			host._beam(host.world,pair[0],pair[1],0.06,host.CORAL if i%2==0 else host.TEAL)
		host._box(host.world,c+Vector3(0,0.08,0),Vector3(0.35,0.08,0.22),host.INK)
		host._beam(host.world,d,d+Vector3(0,0.25,0),0.06,host.INK)
		host._beam(host.world,d+Vector3(0,0.25,-0.2),d+Vector3(0,0.25,0.2),0.055,host.INK)
		host._collider(p+Vector3(0,0.7,0),Vector3(2.1,1.4,0.7))


func habitat_details(h: Dictionary) -> void:
	var p := Vector3(h.x,0,h.z)
	# Flush observation decks and small illustrated species boards, outside the walking approach.
	var entry := Vector3(h.entryX,0,h.entryZ)

	var sign_pos := entry+Vector3(2.7,0,0)
	host._box(host.world,sign_pos+Vector3(0,0.7,0),Vector3(0.13,1.4,0.13),host.TEAL,true)
	host._box(host.world,sign_pos+Vector3(0,1.5,0),Vector3(1.5,0.85,0.12),Color("eaddc4"))
	host._label(host.world,h.name,sign_pos+Vector3(0,1.62,0.12),22)
	# Fern clusters follow the back edge; large rocks have a darker base and lighter top.
	for i in range(5):
		var a := PI*1.15+i*PI*0.17
		var q := p+Vector3(cos(a)*h.rx*0.77,0,sin(a)*h.rz*0.77)
		for j in range(4):
			var leaf: MeshInstance3D = host._ball(host.world,q+Vector3(sin(j*1.7)*0.18,0.25,cos(j*1.7)*0.18),0.35,Color("4a903f"))
			leaf.scale = Vector3(0.28,0.3,1.4)
			leaf.rotation.y = j*1.7
	if h.id in ["panda","fox","giraffe"]:
		# Shaded wooden habitat shelter: posts, beams, slatted roof.
		var q := p+Vector3(h.rx*0.5,0,-h.rz*0.55)
		for x in [-1.2,1.2]:
			for z in [-0.7,0.7]: host._box(host.world,q+Vector3(x,1.25,z),Vector3(0.12,2.5,0.12),Color("a66b41"))
		for i in range(7): host._box(host.world,q+Vector3(-1.3+i*0.43,2.55,0),Vector3(0.35,0.15,2),Color("c38951"))
		if h.id=="giraffe":
			host._cylinder(host.world,p+Vector3(-5,1.8,3.5),0.12,3.6,Color("a66b41"))
			host._box(host.world,p+Vector3(-5,3.5,3.5),Vector3(1.3,0.5,1),Color("c98c50"))
			for i in range(4): host._ball(host.world,p+Vector3(-5+i*0.13,3.8,3.5),0.2,Color("92a778"))
	if h.id=="rabbit":
		for i in range(5):
			var q := p+Vector3(-2+i,0,3.5)
			host._cylinder(host.world,q+Vector3(0,0.19,0),0.1,0.35,Color("d99555"),0.04)
			host._ball(host.world,q+Vector3(0,0.4,0),0.13,Color("418749"))
	if h.id in ["capybara","penguin"]:
		for i in range(3):
			var q := p+Vector3(-2+i*2,0.16,-h.rz*0.48)
			var ripple := TorusMesh.new()
			ripple.inner_radius = 0.42
			ripple.outer_radius = 0.46
			host._mesh(host.world,ripple,q,Color("c0dfdc"))
		if h.id=="capybara":
			for i in range(3): host._ball(host.world,p+Vector3(-2+i*2,0.23,-h.rz*0.48),0.17,Color("dfb353"))
		else:
			for i in range(3):
				var ice: MeshInstance3D = host._ball(host.world,p+Vector3((i-1)*3,0.7,-h.rz*0.65),1,Color("d9e6e0"))
				ice.scale = Vector3(0.8,0.6+i*0.3,0.65)


