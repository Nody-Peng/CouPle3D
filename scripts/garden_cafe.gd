extends Node3D
## Walk-in glass cafe, sharing the city world. Roof cuts away as visitors enter.
var host: Node3D
var roof: Node3D
const WOOD := Color("ad7143")
const SAGE := Color("3f896b")
const PAPER := Color("f1e7d5")
const DARK := Color("3f514c")

func box(p: Vector3, size: Vector3, color: Color, solid := false) -> MeshInstance3D:
	return host._box(self,p,size,color,solid)
func glass(p: Vector3, size: Vector3) -> void:
	var pane := box(p,size,Color("c3e0d8"))
	var mat := StandardMaterial3D.new()
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_color = Color(0.65,0.85,0.81,0.18)
	mat.roughness = 0.13
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	pane.material_override = mat
	pane.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
func plant(p: Vector3, tall := false) -> void:
	box(p+Vector3(0,0.65,0),Vector3(0.75,1.3,0.75),Color.TRANSPARENT,true).hide()
	host._cylinder(self,p+Vector3(0,0.3,0),0.35,0.6,Color("bd9b7e"),0.43)
	for i in range(5):
		var leaf: MeshInstance3D = host._ball(self,p+Vector3(sin(i*2)*0.22,0.9+(0.7 if tall else 0)+i*0.05,cos(i*2)*0.22),0.4,SAGE.lightened(i*0.035))
		leaf.scale = Vector3(0.7,1.6 if tall else 0.65,0.6)
func cup(p: Vector3) -> void:
	host._cylinder(self,p,0.19,0.04,PAPER)
	host._cylinder(self,p+Vector3(0,0.12,0),0.1,0.2,PAPER)
	host._cylinder(self,p+Vector3(0,0.225,0),0.08,0.01,Color("75513b"))
	var ring := TorusMesh.new()
	ring.inner_radius = 0.045
	ring.outer_radius = 0.075
	var handle: MeshInstance3D = host._mesh(self,ring,p+Vector3(0.11,0.12,0),PAPER)
	handle.rotation.x = PI/2
func chair(p: Vector3, angle := 0.0) -> void:
	var node := Node3D.new()
	add_child(node)
	node.position = p
	node.rotation.y = angle
	host._box(node,Vector3(0,0.55,0),Vector3(0.85,0.15,0.85),SAGE)
	host._box(node,Vector3(0,0.95,0.35),Vector3(0.85,0.8,0.14),WOOD)
	for x in [-0.3,0.3]:
		for z in [-0.3,0.3]: host._box(node,Vector3(x,0.26,z),Vector3(0.08,0.52,0.08),WOOD)
	# One smooth obstacle for the whole chair, rather than four snagging legs.
	var body := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	var collider := BoxShape3D.new()
	collider.size = Vector3(0.9,1.4,0.95)
	shape.shape = collider
	shape.position.y = 0.7
	body.add_child(shape)
	node.add_child(body)
func table(p: Vector3, outdoor := false) -> void:
	host._cylinder(self,p+Vector3(0,0.95,0),0.86,0.12,WOOD if outdoor else PAPER)
	host._cylinder(self,p+Vector3(0,0.5,0),0.12,0.9,DARK)
	box(p+Vector3(0,0.65,0),Vector3(1.45,1.3,1.45),Color.TRANSPARENT,true).hide()
	chair(p+Vector3(-1.35,0,0),PI/2)
	chair(p+Vector3(1.35,0,0),-PI/2)
	cup(p+Vector3(-0.32,1.04,0))
	cup(p+Vector3(0.32,1.04,0.12))
	host._cylinder(self,p+Vector3(0,1.18,-0.3),0.09,0.28,SAGE)
	host._ball(self,p+Vector3(0,1.42,-0.3),0.13,Color("d29a92"))

func build(source: Node3D, p: Vector3) -> void:
	host = source
	position = p
	# Pale stone terrace and level entry: no step can trap a walking character.
	box(Vector3(0,0.025,0),Vector3(22,0.05,16),Color("d6ad7d"))
	box(Vector3(0,0.02,-10.5),Vector3(24,0.04,5),Color("e1b783"))
	box(Vector3(0,0.025,-14.2),Vector3(3.2,0.05,3),Color("e1b783"))
	for x in range(-10,11,2): box(Vector3(x,0.058,0),Vector3(0.025,0.008,16),Color("bba88e"))
	# Floor-to-ceiling glass walls with a generous open double-door entrance.
	for x in [-11.0,11.0]:
		glass(Vector3(x,2.1,0),Vector3(0.07,4.2,16))
		box(Vector3(x,2.1,0),Vector3(0.16,4.2,16),Color.TRANSPARENT,true).hide()
		for z in [-8,-4,0,4,8]: box(Vector3(x,2.1,z),Vector3(0.16,4.2,0.16),DARK)
	for side in [-1,1]:
		glass(Vector3(side*6.3,2.1,-8),Vector3(9.4,4.2,0.07))
		box(Vector3(side*6.3,2.1,-8),Vector3(9.4,4.2,0.16),Color.TRANSPARENT,true).hide()
		for x in [1.6,6.3,11.0]: box(Vector3(side*x,2.1,-8),Vector3(0.16,4.2,0.16),DARK)
	glass(Vector3(0,2.1,8),Vector3(22,4.2,0.07))
	box(Vector3(0,2.1,8),Vector3(22,4.2,0.16),Color.TRANSPARENT,true).hide()
	for x in [-11,-6,0,6,11]: box(Vector3(x,2.1,8),Vector3(0.16,4.2,0.16),DARK)
	for z in [-8,8]:
		box(Vector3(0,4.25,z),Vector3(22.4,0.3,0.3),PAPER)
		if z>0: box(Vector3(0,0.17,z),Vector3(22,0.14,0.18),WOOD)
	# Shallow sage canopy, warm timber soffit and a permanent street-facing wordmark.
	box(Vector3(0,4.45,-8.8),Vector3(23,0.28,2.6),SAGE)
	for x in range(-11,12): box(Vector3(x,4.28,-8.8),Vector3(0.09,0.08,2.5),WOOD)
	var sign := Label3D.new()
	sign.font = host.font
	sign.text = "花 園 咖 啡  ·  GARDEN CAFÉ"
	sign.font_size = 68
	sign.pixel_size = 0.012
	sign.modulate = PAPER
	sign.outline_size = 0
	sign.position = Vector3(0,4.7,-10.16)
	sign.rotation.y = PI
	add_child(sign)
	box(Vector3(0,4.7,-10.08),Vector3(12,0.85,0.12),SAGE)
	roof = Node3D.new()
	add_child(roof)
	host._box(roof,Vector3(0,4.5,0),Vector3(22.7,0.32,16.8),PAPER)
	# Skylight and roof garden, visible from the city's isometric camera.
	host._box(roof,Vector3(-3,4.72,0),Vector3(9,0.15,8),DARK)
	for x in [-6,-3,0]:
		host._box(roof,Vector3(x,4.82,0),Vector3(2.85,0.08,7.7),Color("5bbca9"))
	for z in [-5,5]:
		host._box(roof,Vector3(7,4.85,z),Vector3(5,0.4,1),WOOD)
		for x in [5,6,7,8,9]: host._ball(roof,Vector3(x,5.2,z),0.42,SAGE)
	# Back bar: wood slats, espresso station, open shelving and a glass pastry vitrine.
	box(Vector3(0,1.0,4.2),Vector3(11,2,1.5),WOOD,true)
	box(Vector3(0,2.08,4.2),Vector3(11.4,0.16,1.8),PAPER)
	for x in range(-26,27): box(Vector3(x*0.2,0.96,3.43),Vector3(0.06,1.8,0.04),Color("cca17a"))
	box(Vector3(-2.7,2.52,4.2),Vector3(2.2,0.8,0.85),DARK)
	box(Vector3(-2.7,2.87,4.1),Vector3(2.3,0.16,1),Color("b9beb5"))
	for x in [-3.2,-2.6]:
		host._cylinder(self,Vector3(x,2.66,3.7),0.075,0.35,Color("b9beb5"))
		cup(Vector3(x,2.2,3.68))
	glass(Vector3(2.5,2.56,3.65),Vector3(3.3,0.9,0.05))
	glass(Vector3(2.5,3.01,4.15),Vector3(3.3,0.05,1.05))
	for x in [0.85,4.15]: glass(Vector3(x,2.56,4.15),Vector3(0.05,0.9,1.05))
	for x in [1.4,2.5,3.6]:
		host._cylinder(self,Vector3(x,2.2,4.1),0.33,0.05,PAPER)
		host._cylinder(self,Vector3(x,2.4,4.1),0.26,0.35,Color("dda69b"))
		host._ball(self,Vector3(x,2.62,4.1),0.09,Color("bb6e74"))
	for y in [2.5,3.5]:
		box(Vector3(0,y,7.4),Vector3(12,0.1,0.6),WOOD)
		for x in [-4,-2,0,2,4]:
			host._cylinder(self,Vector3(x,y+0.22,7.4),0.18,0.4,SAGE if x%4==0 else PAPER)
	# Four inside two-person tables and a quieter street terrace.
	for p_table in [Vector3(-6.8,0,-3.8),Vector3(6.8,0,-3.8),Vector3(-7.2,0,1),Vector3(7.2,0,1)]: table(p_table)
	for x in [-7,7]: table(Vector3(x,0,-11),true)
	for p_plant in [Vector3(-9.8,0,6.7),Vector3(9.8,0,6.7),Vector3(-10,0,-7),Vector3(10,0,-7),Vector3(-11.3,0,-11.8),Vector3(11.3,0,-11.8)]: plant(p_plant,true)
	# Pendant shades remain visible when the roof cuts away.
	for x in [-3.5,0,3.5]:
		host._cylinder(self,Vector3(x,3.4,3.9),0.4,0.35,Color("caab71"),0.15)
		host._ball(self,Vector3(x,3.2,3.9),0.12,Color("f1d3a0"))
	host._activity("city_cafe","花園咖啡 · 聊聊今天","走進落地窗旁的咖啡廳，挑一個喜歡的座位，分享今天的小事。",p+Vector3(0,0,-2))
	host._label(self,"自由入座 · 沿中央入口走進來",Vector3(0,2.5,-10),24)

func _process(_delta: float) -> void:
	if not is_instance_valid(host.player): return
	var local := to_local(host.player.global_position)
	roof.visible = not (absf(local.x)<12.5 and absf(local.z)<9.7)

