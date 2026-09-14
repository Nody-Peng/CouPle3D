extends Node3D
## Walkable scene prototype. Activity records are the extension points for future games.
signal activity_requested(activity_id: String)
@export var start_inside := false

const CREAM := Color("f4e7d3")
const TEAL := Color("368b89")
const CORAL := Color("dc8177")
const GOLD := Color("edc572")
const INK := Color("344c59")
var transitioning := false
var guiding := false
var camera_yaw := 0.45
var camera_zoom := 1.0
var fade: ColorRect
var navigation: Label
var material_cache: Dictionary = {}
var world: Node3D
var player: CharacterBody3D
var camera: Camera3D
var train: Node3D
var wheel: Node3D
var carousel: Node3D
var cabins: Array[Node3D] = []
var activities: Array[Dictionary] = []
var current: Dictionary = {}
var inside := false
var overview := false
var night := false
var elapsed := 0.0
var heading: Label
var prompt: Label
var status: Label
var panel: PanelContainer
var detail_title: Label
var detail_text: Label
var sun: DirectionalLight3D
var environment: Environment
var font: Font = preload("res://assets/fonts/NotoSansTC.ttf")
var web_session: Node

func _ready() -> void:
	HUD.hide()
	
	RenderingServer.set_default_clear_color(Color("bed8df"))
	_setup_lighting()
	_build_ui()
	_build(start_inside)
	web_session = Node.new()
	web_session.set_script(load("res://scripts/web_session.gd"))
	add_child(web_session)

func _exit_tree() -> void:
	HUD.show()

func _material(color: Color, glow := false) -> StandardMaterial3D:
	var key := str(color.to_rgba32()) + str(glow)
	if material_cache.has(key):
		return material_cache[key]
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.8
	if glow:
		mat.emission_enabled = true
		mat.emission = color
		mat.emission_energy_multiplier = 1.5
	material_cache[key] = mat
	return mat

func _mesh(parent: Node3D, mesh: Mesh, pos: Vector3, color: Color) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	node.mesh = mesh
	node.material_override = _material(color)
	parent.add_child(node)
	node.position = pos
	return node

func _box(parent: Node3D, pos: Vector3, size: Vector3, color: Color, solid := false) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = size
	var node := _mesh(parent, mesh, pos, color)
	if solid:
		var body := StaticBody3D.new()
		var shape := CollisionShape3D.new()
		var box := BoxShape3D.new()
		box.size = size
		shape.shape = box
		body.add_child(shape)
		node.add_child(body)
	return node

func _cylinder(parent: Node3D, pos: Vector3, radius: float, height: float, color: Color, top := -1.0) -> MeshInstance3D:
	var mesh := CylinderMesh.new()
	mesh.bottom_radius = radius
	mesh.top_radius = radius if top < 0 else top
	mesh.height = height
	mesh.radial_segments = 24
	return _mesh(parent, mesh, pos, color)

func _ball(parent: Node3D, pos: Vector3, radius: float, color: Color) -> MeshInstance3D:
	var mesh := SphereMesh.new()
	mesh.radius = radius
	mesh.height = radius * 2
	return _mesh(parent, mesh, pos, color)

func _beam(parent: Node3D, a: Vector3, b: Vector3, width: float, color: Color) -> void:
	var node := _box(parent, (a+b)*0.5, Vector3(width, a.distance_to(b), width), color)
	var direction := (b-a).normalized()
	node.quaternion = Quaternion(Vector3.UP, direction)

func _label(parent: Node3D, text: String, pos: Vector3, size := 36) -> void:
	var label := Label3D.new()
	label.text = text
	label.font = font
	label.font_size = maxi(size,48)
	label.pixel_size = 0.014
	label.outline_size = 3
	label.no_depth_test = true
	label.modulate = INK
	label.outline_modulate = CREAM
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	parent.add_child(label)
	label.position = pos

func _setup_lighting() -> void:
	var env := WorldEnvironment.new()
	environment = Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color("b9d5dd")
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color("d8e5ed")
	environment.ambient_light_energy = 0.35
	environment.tonemap_mode = Environment.TONE_MAPPER_LINEAR
	env.environment = environment
	add_child(env)
	sun = DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-48, -32, 0)
	sun.light_color = Color("ffe1b6")
	sun.light_energy = 0.6
	sun.shadow_enabled = true
	add_child(sun)

func _build(home: bool) -> void:
	var returning := inside and not home
	if is_instance_valid(world):
		remove_child(world)
		world.queue_free()
	inside = home
	activities.clear()
	cabins.clear()
	wheel = null
	train = null
	carousel = null
	current = {}
	world = Node3D.new()
	add_child(world)
	if home:
		_home()
	else:
		_park()
	player = CharacterBody3D.new()
	player.set_script(load("res://scripts/explore_player.gd"))
	world.add_child(player)
	player.position = Vector3(0,0.2,13.5) if home else (Vector3(-30,0.2,30.5) if returning else Vector3(0,0.2,29))
	player.spawn_position = player.position
	camera = Camera3D.new()
	world.add_child(camera)
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 24 if home else 32
	camera.far = 600
	camera.current = true
	_update_camera(1.0)
	heading.text = "我們的家  /  OUR HOME" if home else "心動之城  /  TOGETHER CITY"
	status.text = "六個房間，收藏兩個人的日常" if home else "沿著花園大道，發現下一個約會"
	if is_instance_valid(web_session):
		web_session.rebuilt()

func _tree(pos: Vector3, color := Color("719e87")) -> void:
	_round_barrier(pos+Vector3(0,1.2,0),0.45,2.4)
	_cylinder(world, pos + Vector3(0,1,0), 0.18, 2.0, Color("8a7160"))
	_ball(world, pos + Vector3(0,2.5,0), 1.2, color)
	_ball(world, pos + Vector3(0.55,3.2,0), 0.85, color.lightened(0.1))
	for i in range(5):
		var a := i*TAU/5+pos.x
		var crown := pos+Vector3(cos(a)*0.8,2.8+sin(i*1.7)*0.35,sin(a)*0.7)
		_beam(world,pos+Vector3(0,1.65,0),crown,0.065,Color("8a7160"))
		_ball(world,crown,0.62,color.lightened(0.025*(i%3)))
	_cylinder(world, pos + Vector3(0,0.12,0), 1.3, 0.24, CREAM)

func _lamp(pos: Vector3) -> void:
	_round_barrier(pos+Vector3(0,1.5,0),0.14,3.0)
	_cylinder(world, pos + Vector3(0,1.7,0), 0.07, 3.4, INK)
	_ball(world, pos + Vector3(0,3.45,0), 0.26, GOLD).material_override = _material(GOLD, true)

func _activity(id: String, title: String, description: String, pos: Vector3, destination := "") -> void:
	var portal := Node3D.new()
	portal.set_script(load("res://scripts/entrance_portal.gd"))
	portal.tint = Color("82efdf") if destination != "" else GOLD
	world.add_child(portal)
	portal.position = pos
	activities.append({"id": id, "title": title, "description": description, "position": pos, "destination": destination, "portal": portal})
	_label(world,title,pos+Vector3(0,2.8,0),36)

func _park() -> void:
	_box(world, Vector3(0,-0.45,0), Vector3(304,0.9,88), Color("91a38a"), true)
	# A connected promenade, with generous pedestrian clearances between districts.
	_path(Vector3(0,0,0),Vector2(9,84))
	_path(Vector3(21,0,5),Vector2(66,7))
	preload("res://scripts/nordic_scenery.gd").garden_path(self,[Vector3(-54,0,5),Vector3(-46,0,4),Vector3(-39,0,4),Vector3(-28,0,5),Vector3(-12,0,5)],4.2)
	_path(Vector3(18.75,0,-14),Vector2(61.5,5))
	preload("res://scripts/nordic_scenery.gd").garden_path(self,[Vector3(-49.5,0,-14),Vector3(-44,0,-17),Vector3(-37,0,-17),Vector3(-27,0,-14),Vector3(-12,0,-14)],3.6)
	_path(Vector3(0,0,34),Vector2(102,5))
	_path(Vector3(-30,0,25),Vector2(5,20))
	_path(Vector3(31,0,17),Vector2(36,25))
	for x in [-151.5,151.5]:
		_box(world,Vector3(x,0.55,0),Vector3(0.5,3,88),Color("b5b7aa"),true)
	for z in [-43.5,43.5]:
		if z<0:
			_box(world,Vector3(0,0.55,z),Vector3(304,3,0.5),Color("b5b7aa"),true)
		else:
			for side in [-1,1]: _box(world,Vector3(side*84,0.55,z),Vector3(136,1.1,0.5),Color("b5b7aa"),true)
	_box(world,Vector3(0,-0.45,50),Vector3(32,0.9,12),Color("d6c4a6"),true)
	for side in [-1,1]:
		_box(world,Vector3(side*15.8,0.55,50),Vector3(0.4,1.1,12),Color("b5b7aa"),true)
		_flowerbed(Vector3(side*12,0,52),Vector2(4,3))
		_bench(Vector3(side*8,0,53),0)
	_box(world,Vector3(0,0.55,55.8),Vector3(32,1.1,0.4),Color("b5b7aa"),true)
	for x in range(-52,53,4):
		_box(world,Vector3(x,1,-43.5),Vector3(0.25,1.8,0.25),CREAM)
	# Varied city silhouette with shopfronts, stepped towers and roof gardens.
	for i in range(19):
		var x := -60.0+i*6.7
		var h := 8.0+float((i*7)%15)
		var color: Color = [Color("a9b6b1"),Color("c9b5a4"),Color("bdc3b2"),Color("c9c6ba")][i%4]
		_box(world,Vector3(x,h/2,-52),Vector3(5.7,h,6.5),color)
		_box(world,Vector3(x,h+0.2,-52),Vector3(6,0.4,6.8),INK)

		for y in range(2,int(h)-1,3):
			for dx in [-1.8,-0.6,0.6,1.8]:
				_box(world,Vector3(x+dx,y,-48.72),Vector3(0.55,1.1,0.04),GOLD if (y+i)%3 else INK)
	var gateway := Node3D.new()
	gateway.set_script(load("res://scripts/city_gateway.gd"))
	world.add_child(gateway)
	gateway.build(self)
	# Central fountain: scalloped basins, raised bowls and visible water arcs.
	_cylinder(world,Vector3(0,0.08,-5),6.2,0.16,Color("d4c4ad"))
	_cylinder(world,Vector3(0,0.25,-5),4.5,0.5,CREAM)
	_cylinder(world,Vector3(0,0.53,-5),4.05,0.08,Color("63b4bd"))
	_round_barrier(Vector3(0,1.5,-5),4.5,3.0)
	_cylinder(world,Vector3(0,1.1,-5),0.7,1.3,CREAM)
	_cylinder(world,Vector3(0,1.65,-5),2,0.28,CREAM)
	_cylinder(world,Vector3(0,1.81,-5),1.8,0.04,Color("6ec5cf"))
	_cylinder(world,Vector3(0,2.25,-5),0.3,1,GOLD)
	_ball(world,Vector3(0,2.9,-5),0.45,GOLD)
	for i in range(8):
		var angle := TAU*i/8
		for j in range(8):
			var t := float(j)/7
			_ball(world,Vector3(cos(angle)*(0.5+t*2.8),2.5+sin(t*PI)*0.8-t*1.9,-5+sin(angle)*(0.5+t*2.8)),0.065,Color("a7e9e5"))
	_sky_train()
	# Signature attractions on their own landscaped courts.
	_ferris(Vector3(-25,0,-28))
	wheel.scale = Vector3.ONE*1.3
	wheel.position.y = 9
	for x in [-4.5,4.5]:
		_beam(world,Vector3(-25+x,0,-27),Vector3(-25,9,-27),0.4,TEAL)
	_collider(Vector3(-25,0.6,-28),Vector3(10,1.2,5))
	_path(Vector3(-25,0,-17),Vector2(5,9))
	_activity("ferris","摩天輪 · 心動問答","在城市上空，輪流抽取關於彼此的問題。\n預定玩法：雙人輪流回答／輕鬆聊天。",Vector3(-25,0,-17))
	_carousel(Vector3(12,0,-28))
	_collider(Vector3(12,0.6,-28),Vector3(7.4,1.2,7.4))
	_activity("carousel","旋轉木馬 · 默契節拍","跟著音樂一起按下節拍，累積雙人的連擊。\n預定玩法：即時合作／節奏挑戰。",Vector3(12,0,-20))
	_gazebo(Vector3(37,0,-28))
	_activity("stargazing","星光亭 · 約會相簿","在花園觀景亭收藏合照與約會回憶。\n預定玩法：合照／紀念日收藏。",Vector3(37,0,-20))
	# A pond garden occupies the quiet side of the park.


	_round_barrier(Vector3(-40,1.5,-6),7.65,3.0)
	for i in range(7):
		var p := Vector3(-43+(i%3)*2,0.11,-9+(i/3)*2)
		_cylinder(world,p,0.42,0.025,TEAL)
		_ball(world,p+Vector3(0,0.08,0),0.12,CORAL)
	_bench(Vector3(-49,0,4),0)
	# The home is a real, collidable landmark in the amusement park.
	_mansion(Vector3(-30,0,17))
	_activity("home","我們的家 · 進入","回到花園裡的家。",Vector3(-30,0,27.5),"home")
	# Tabletop activities get readable thematic pavilions rather than oversized rides.
	_pavilion(Vector3(20,0,-3),TEAL,"01  海戰俱樂部","battleship")
	_activity("battleship","海戰棋","兩張海圖，一場心理戰。\n預定玩法：雙人對戰／輪流行動／各自部署艦隊。",Vector3(20,0,3))
	_pavilion(Vector3(40,0,-3),CORAL,"02  默契研究所","trivia")
	_activity("trivia","默契問答","先回答自己的選擇，再猜猜對方的答案。\n預定玩法：雙人問答／輕鬆合作。",Vector3(40,0,3))
	_pavilion(Vector3(20,0,19),Color("788eae"),"03  色彩工作室","ink")
	_activity("ink","墨水大戰","在同一張畫布上，合作塗色或一較高下。\n預定玩法：即時雙人／塗色挑戰。",Vector3(20,0,25))
	_pavilion(Vector3(40,0,19),Color("c89460"),"04  桌遊沙龍","tabletop")
	_activity("tabletop","雙人桌遊","棋盤、卡牌與數字遊戲的共同入口。\n預定玩法：輪流制／短局對戰；後續可增加遊戲目錄。",Vector3(40,0,25))
	_label(world,"雙 人 遊 戲 街",Vector3(31,5,11),48)
	_string_lights(Vector3(12,4.8,10),Vector3(49,4.8,10))
	_string_lights(Vector3(12,4.8,29),Vector3(49,4.8,29))
	# Landscape rhythm along the boulevards; no planting blocks a portal.
	for x in [-51,-9,8,51]:
		for z in [-37,-17,13,36]:
			_tree(Vector3(x,0,z),Color("d6a2a6") if int(x)%2 else Color("749786"))
	for x in [-44,-36,-16,22,31,43]:
		_tree(Vector3(x,0,-39))
	for z in [-35,-17,10,25,36]:
		for x in [-5.8,5.8]:
			_lamp(Vector3(x,0,z))
	for p in [Vector3(-11,0,10),Vector3(8,0,16),Vector3(-11,0,-13),Vector3(8,0,-13)]:
		_bench(p,0)
	for x in [-20,-10,12,27,43]:
		_flowerbed(Vector3(x,0,36.8),Vector2(5,1.6))
	_flowerbed(Vector3(-17,0,11),Vector2(2,9))
	for i in range(3):
		var x: float = [-20,-10,12][i]
		_activity("garden_%d" % i,"花園委託 · 澆水 %d" % (i+1),"替花園澆水，收集今天的小小獎勵。",Vector3(x,0,35))
	_signpost(Vector3(-7,0,20),"← 我們的家    遊戲街 →")
	_signpost(Vector3(7,0,-15),"摩天輪 ←    星光花園 →")
	var districts := Node.new()
	districts.set_script(load("res://scripts/world_districts.gd"))
	world.add_child(districts)
	districts.build(self)
	var scenery := Node3D.new()
	scenery.set_script(load("res://scripts/nordic_scenery.gd"))
	world.add_child(scenery)
	scenery.build(self)

func _round_barrier(pos: Vector3, radius: float, height: float) -> void:
	var body := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	var cylinder := CylinderShape3D.new()
	cylinder.radius = radius
	cylinder.height = height
	shape.shape = cylinder
	body.add_child(shape)
	world.add_child(body)
	body.position = pos

func _ferris(pos: Vector3) -> void:
	_cylinder(world, pos+Vector3(0,0.12,0), 6, 0.24, Color("d6c7b7"))
	for z in [-0.8,0.8]:
		for x in [-3,3]:
			_beam(world, pos+Vector3(x,0,z), pos+Vector3(0,7,z), 0.3, CREAM)
	wheel = Node3D.new()
	world.add_child(wheel)
	wheel.position = pos+Vector3(0,7,0)
	for i in range(48):
		var a := TAU*i/48
		var b := TAU*(i+1)/48
		_beam(wheel, Vector3(cos(a)*5.8,sin(a)*5.8,0), Vector3(cos(b)*5.8,sin(b)*5.8,0), 0.15, CORAL)
	for i in range(10):
		var a := TAU*i/10
		var p := Vector3(cos(a)*5.8,sin(a)*5.8,0)
		_beam(wheel, Vector3.ZERO, p, 0.09, CREAM)
		var cabin := Node3D.new()
		wheel.add_child(cabin)
		cabin.position = p
		cabins.append(cabin)
		_box(cabin, Vector3(0,-0.55,0), Vector3(1.05,0.7,0.9), TEAL if i%2 == 0 else CORAL)
		_box(cabin, Vector3(0,0.15,0), Vector3(1.15,0.12,1), GOLD)
		for x in [-0.45,0.45]:
			_box(cabin, Vector3(x,-0.1,0), Vector3(0.06,0.6,0.8), CREAM)
	_ball(wheel, Vector3.ZERO, 0.5, GOLD)

func _carousel(pos: Vector3) -> void:
	_cylinder(world, pos+Vector3(0,0.15,0), 4.5, 0.3, CREAM)
	carousel = Node3D.new()
	world.add_child(carousel)
	carousel.position = pos
	_cylinder(carousel, Vector3(0,0.4,0), 4, 0.35, CORAL)
	_cylinder(carousel, Vector3(0,2.2,0), 0.3, 4, GOLD)
	_cylinder(carousel, Vector3(0,4.5,0), 4.5, 1.8, TEAL, 0.15)
	_ball(carousel, Vector3(0,5.5,0), 0.3, GOLD)
	for i in range(8):
		var a := TAU*i/8
		var p := Vector3(cos(a)*2.9,0,sin(a)*2.9)
		_cylinder(carousel, p+Vector3(0,2.2,0), 0.045, 3.6, GOLD)
		var horse := _ball(carousel, p+Vector3(0,1.4,0), 0.5, CREAM)
		horse.scale = Vector3(0.6,0.65,1.4)
		_ball(carousel, p+Vector3(0,1.9,-0.4), 0.27, CREAM)
		_box(carousel, p+Vector3(0,1.65,0.05), Vector3(0.45,0.15,0.5), CORAL)

func _home() -> void:
	# Six spacious rooms around one continuous central gallery.
	_box(world,Vector3(0,-0.22,0),Vector3(42,0.44,36),CREAM,true)
	for x in [-14,0,14]:
		for z in [-10,10]:
			_box(world,Vector3(x,0.02,z),Vector3(13.8,0.04,15.7),Color("c9aa8d") if z>0 else Color("d6bd9d"))
	for z in range(-17,18):
		for x in range(-18,19,4):
			_box(world,Vector3(x,0.045,z),Vector3(3.95,0.015,0.035),Color("b99a7d"))
	_path(Vector3.ZERO,Vector2(41,3.8))
	# Outer back wall has tall windows; foreground stays cut away.
	_box(world,Vector3(0,2,-17.8),Vector3(42,4,0.3),CREAM,true)
	_box(world,Vector3(0,0.48,17.8),Vector3(42,0.96,0.3),CREAM,true)
	for x in [-20.8,20.8]:
		_box(world,Vector3(x,0.65,0),Vector3(0.3,1.3,36),CREAM,true)
	for x in [-7,7]:
		for z in [-10,10]:
			_box(world,Vector3(x,0.7,z),Vector3(0.22,1.4,15.6),CREAM,true)
	for center in [-14,0,14]:
		for z in [-2,2]:
			for side in [-1,1]:
				_box(world,Vector3(center+side*4.4,0.7,z),Vector3(5.2,1.4,0.22),CREAM,true)
		for dx in [-3.5,3.5]:
			_window(world,Vector3(center+dx,2.4,-17.6),Vector2(2.5,2.3))
			for side in [-1,1]:
				_box(world,Vector3(center+dx+side*1.5,2.4,-17.35),Vector3(0.5,2.7,0.16),CORAL.lightened(0.15))
	# Living room / private cinema.
	_rug(Vector3(-14,0,10),Vector2(10,9),Color("ba8c83"))
	_sofa(Vector3(-14,0,13),TEAL)
	_box(world,Vector3(-18,0.55,10.5),Vector3(1.7,1,4.5),TEAL,true)
	_box(world,Vector3(-18.65,1.15,10.5),Vector3(0.3,1.2,4.5),TEAL)
	_table(Vector3(-14,0,9),Vector2(3.6,2),0.75)
	_cylinder(world,Vector3(-14,0.9,9),0.32,0.1,GOLD)
	for x in [-14.6,-13.4]:
		_cylinder(world,Vector3(x,0.95,9),0.13,0.2,CREAM)
	_box(world,Vector3(-17,0.55,3),Vector3(7,1,0.8),Color("99775e"),true)
	_box(world,Vector3(-17,2,3),Vector3(5.8,2.7,0.18),INK)
	_box(world,Vector3(-17,2,3.12),Vector3(5.45,2.35,0.04),Color("668e9c"))
	# A miniature landscape on the television screen.
	_ball(world,Vector3(-15.5,2.5,3.18),0.32,GOLD)
	_box(world,Vector3(-17,1.2,3.18),Vector3(5.3,0.6,0.05),TEAL)
	_floor_lamp(Vector3(-19,0,14))
	_plant(Vector3(-9,0,15))
	_activity("movie","客廳 · 雙人電影院","大沙發、茶點與私人銀幕。\n未來可在這裡一起播放影片，收藏共同片單。",Vector3(-14,0,5.2))
	# Kitchen with island, cupboards, cooker and a four-seat dining table.
	for i in range(5):
		var x := -18.5+i*2.2
		_box(world,Vector3(x,0.7,-15.8),Vector3(2.1,1.4,1.6),TEAL,true)
		_box(world,Vector3(x,1.46,-15.8),Vector3(2.2,0.12,1.8),CREAM)
		_box(world,Vector3(x,0.8,-14.94),Vector3(0.65,0.06,0.06),GOLD)
		_box(world,Vector3(x,2.9,-17),Vector3(2.05,1.15,0.75),CREAM)
	_box(world,Vector3(-18.7,1.7,-12.7),Vector3(1.7,3.4,1.8),Color("dde1d7"),true)
	_box(world,Vector3(-18.7,2,-11.75),Vector3(1.5,0.07,0.04),INK)
	for x in [-17,-16]:
		for z in [-16.1,-15.5]:
			_cylinder(world,Vector3(x,1.55,z),0.24,0.04,INK)
	_box(world,Vector3(-12,1.54,-15.7),Vector3(1.5,0.08,0.9),INK)
	_beam(world,Vector3(-12,1.5,-16.2),Vector3(-12,2,-16.2),0.07,GOLD)
	_beam(world,Vector3(-12,2,-16.2),Vector3(-12,2,-15.8),0.07,GOLD)
	_box(world,Vector3(-13,0.75,-11.5),Vector3(4.8,1.5,1.8),TEAL,true)
	_box(world,Vector3(-13,1.55,-11.5),Vector3(5,0.14,2),CREAM)
	_cylinder(world,Vector3(-13,1.7,-11.5),0.45,0.14,CORAL)
	_table(Vector3(-13,0,-7),Vector2(4,2.4),1.1)
	for x in [-14.2,-11.8]:
		for z in [-9,-5]:
			_chair(world,Vector3(x,0,z),PI if z == -9 else 0,CORAL)
			_collider(Vector3(x,0.5,z),Vector3(0.9,1,0.9))
	for x in [-14,-12]:
		_cylinder(world,Vector3(x,1.25,-7),0.32,0.05,CREAM)
	_plant(Vector3(-19,0,-4))
	_activity("cooking","廚房 · 料理合作社","備料、烹調、擺盤，兩個人分工完成。\n預定玩法：雙人合作料理。",Vector3(-14,0,-3.8))
	# Master bedroom with bedside lights, wardrobe and dressing bench.
	_rug(Vector3(0,0,-10),Vector2(10,11),Color("b7b6a0"))
	_box(world,Vector3(0,0.45,-12),Vector3(5.7,0.9,6.5),Color("96725c"),true)
	_box(world,Vector3(0,0.98,-11.8),Vector3(5.5,0.5,6),CREAM)
	_box(world,Vector3(0,1.3,-10.8),Vector3(5.5,0.16,3.8),CORAL)
	_box(world,Vector3(0,1.2,-15.2),Vector3(6,2.4,0.3),TEAL)
	for x in [-1.45,1.45]:
		_box(world,Vector3(x,1.35,-13.8),Vector3(2.1,0.3,1.1),CREAM)
	for x in [-4,4]:
		_box(world,Vector3(x,0.6,-14),Vector3(1.5,1.2,1.3),Color("a8886e"),true)
		_cylinder(world,Vector3(x,1.45,-14),0.06,0.5,GOLD)
		_cylinder(world,Vector3(x,1.85,-14),0.4,0.5,CREAM,0.25)
	_box(world,Vector3(4.8,1.8,-7),Vector3(2.2,3.6,3),CREAM,true)
	for z in [-7.8,-6.2]:
		_box(world,Vector3(3.65,1.8,z),Vector3(0.08,0.8,0.07),GOLD)
	_bench(Vector3(0,0,-6),0)
	_plant(Vector3(-5,0,-5))
	_activity("memories","臥室 · 回憶收藏","睡前聊聊今天，把合照與紀念日收藏進回憶冊。\n預定功能：相簿／紀念日／每日話題。",Vector3(0,0,-3.8))
	# Spa bathroom, tiled floor, tub, shower and double vanity.
	for x in range(8,21,2):
		for z in range(-17,-2,2):
			_box(world,Vector3(x,0.055,z),Vector3(1.94,0.04,1.94),Color("b1ceca") if (x+z)%4 else CREAM)
	_box(world,Vector3(12,0.6,-13),Vector3(5,1.2,3),CREAM,true)
	_box(world,Vector3(12,1.22,-13),Vector3(4.4,0.06,2.4),Color("8bc9ce"))
	for x in [9.7,14.3]:
		_box(world,Vector3(x,1.25,-13),Vector3(0.3,0.2,3),CREAM)
	_box(world,Vector3(18.5,0.65,-9),Vector3(2,1.3,6),TEAL,true)
	for z in [-10.5,-7.5]:
		_cylinder(world,Vector3(18.5,1.42,z),0.65,0.18,CREAM)
		_box(world,Vector3(19.6,2.4,z),Vector3(0.08,1.5,1.6),Color("a3c6cf"))
	_box(world,Vector3(10,0.4,-6),Vector3(2,0.8,1),Color("b19272"),true)
	for i in range(3):
		_box(world,Vector3(10,0.86+i*0.11,-6),Vector3(1.4,0.1,0.65),CREAM)
	_plant(Vector3(19,0,-15))
	_activity("spa","浴室 · 放鬆時光","留一段不趕時間的雙人日常。\n此區先提供完整場景，互動內容待後續擴充。",Vector3(14,0,-3.8))
	# Shared games room.
	_rug(Vector3(0,0,9),Vector2(11,10),Color("8caaa2"))
	_table(Vector3(0,0,8),Vector2(4.8,3.2),1.1)
	for x in [-3.3,3.3]:
		_chair(world,Vector3(x,0,8),-signf(x)*PI/2,CORAL)
		_collider(Vector3(x,0.5,8),Vector3(1,1,1))
	for x in range(6):
		for z in range(4):
			_box(world,Vector3(-1.5+x*0.6,1.24,7.1+z*0.6),Vector3(0.57,0.05,0.57),TEAL if (x+z)%2 else CREAM)
	_bookcase(Vector3(-5,0,13),2.2)
	_bookcase(Vector3(5,0,13),2.2)
	_activity("tabletop","遊戲室 · 桌遊時光","同一張桌子，裝得下海戰棋、卡牌和更多雙人遊戲。\n預定玩法：私人雙人桌遊房。",Vector3(0,0,4.5))
	# Creative studio / reading lounge.
	_rug(Vector3(14,0,10),Vector2(10,11),Color("c1a994"))
	_bookcase(Vector3(10,0,15.8),3)
	_bookcase(Vector3(14,0,15.8),3)
	_table(Vector3(14,0,7),Vector2(5,2),1.05)
	for x in [12.5,15.5]:
		_chair(world,Vector3(x,0,8.8),0,TEAL)
		_box(world,Vector3(x,1.2,7),Vector3(1.1,0.05,0.8),CREAM)
		_box(world,Vector3(x+0.2,1.25,7),Vector3(0.7,0.04,0.5),CORAL)
	_floor_lamp(Vector3(19,0,13))
	_plant(Vector3(19,0,4))
	for i in range(3):
		_box(world,Vector3(18.8,1.6,9+i*1.5),Vector3(0.16,1.3,1),GOLD)
		_box(world,Vector3(18.7,1.6,9+i*1.5),Vector3(0.04,1.1,0.8),[TEAL,CORAL,CREAM][i])
	_activity("studio","書房 · 共同創作","一起畫畫、寫下一張給對方的明信片。\n預定玩法：雙人畫布／留言收藏。",Vector3(14,0,4.5))
	_activity("park","出門 · 回到遊樂場","穿過光環，回到我們的花園門口。",Vector3(0,0,16),"park")
	for x in [-5,5]:
		_plant(Vector3(x,0,16))
	_label(world,"HOME, SWEET HOME",Vector3(0,3,16.8),38)

func _rug(pos: Vector3, size: Vector2, color: Color) -> void:
	_box(world,pos+Vector3(0,0.07,0),Vector3(size.x,0.04,size.y),color)
	_box(world,pos+Vector3(0,0.095,0),Vector3(size.x-0.5,0.012,size.y-0.5),color.lightened(0.08))
	for x in range(int(-size.x/2)+1,int(size.x/2)):
		for side in [-1,1]:
			_box(world,pos+Vector3(x,0.09,side*size.y/2),Vector3(0.08,0.015,0.35),CREAM)

func _table(pos: Vector3, size: Vector2, height: float) -> void:
	_box(world,pos+Vector3(0,height,0),Vector3(size.x,0.18,size.y),Color("af8a69"),true)
	for x in [-1,1]:
		for z in [-1,1]:
			_box(world,pos+Vector3(x*(size.x/2-0.2),height/2,z*(size.y/2-0.2)),Vector3(0.14,height,0.14),Color("8f6e55"))

func _sofa(pos: Vector3, color: Color) -> void:
	_box(world,pos+Vector3(0,0.55,0),Vector3(6,1,1.9),color,true)
	_box(world,pos+Vector3(0,1.2,0.8),Vector3(6,1.5,0.35),color)
	for x in [-2.8,2.8]:
		_box(world,pos+Vector3(x,0.95,0),Vector3(0.4,0.7,1.8),color)
	for x in [-1.9,0,1.9]:
		_box(world,pos+Vector3(x,1.06,0),Vector3(1.7,0.15,1.4),color.lightened(0.08))
		var pillow := _box(world,pos+Vector3(x,1.38,0.45),Vector3(0.75,0.65,0.25),CORAL if x else GOLD)
		pillow.rotation.z = x*0.09

func _plant(pos: Vector3) -> void:
	_cylinder(world,pos+Vector3(0,0.35,0),0.48,0.7,Color("c69075"),0.58)
	for i in range(5):
		var angle := TAU*i/5
		var leaf := _ball(world,pos+Vector3(cos(angle)*0.35,1.1+(i%2)*0.35,sin(angle)*0.35),0.35,TEAL.lightened(i*0.035))
		leaf.scale = Vector3(0.6,1.7,0.8)

func _floor_lamp(pos: Vector3) -> void:
	_cylinder(world,pos+Vector3(0,0.06,0),0.45,0.12,INK)
	_cylinder(world,pos+Vector3(0,1.3,0),0.045,2.6,GOLD)
	_cylinder(world,pos+Vector3(0,2.6,0),0.7,0.7,CREAM,0.4)

func _bookcase(pos: Vector3, width: float) -> void:
	_box(world,pos+Vector3(0,1.5,0),Vector3(width,3,0.7),Color("9c7b61"),true)
	for y in [0.4,1.2,2.0,2.8]:
		_box(world,pos+Vector3(0,y,0.15),Vector3(width-0.15,0.08,0.6),CREAM)
		for i in range(int(width*4)):
			_box(world,pos+Vector3(-width/2+0.2+i*0.23,y+0.3,0.4),Vector3(0.16,0.42+(i%3)*0.06,0.35),[TEAL,CORAL,GOLD,INK][i%4])

func _ui_label(text: String, size: int) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_override("font", font)
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", CREAM)
	return label

func _style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.10,0.18,0.22,0.94)
	style.corner_radius_top_left = 12
	style.corner_radius_top_right = 12
	style.corner_radius_bottom_left = 12
	style.corner_radius_bottom_right = 12
	style.content_margin_left = 24
	style.content_margin_right = 24
	style.content_margin_top = 18
	style.content_margin_bottom = 18
	return style

func _build_ui() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(root)

	var top := PanelContainer.new()
	root.add_child(top)
	top.position = Vector2(24,24)
	top.add_theme_stylebox_override("panel", _style())
	var stack := VBoxContainer.new()
	top.add_child(stack)
	heading = _ui_label("", 25)
	stack.add_child(heading)
	status = _ui_label("", 15)
	stack.add_child(status)
	var buttons := HBoxContainer.new()
	stack.add_child(buttons)
	for entry in [["家門指引", "guide"],["全景 M", "map"],["日夜 N", "night"]]:
		var button := Button.new()
		button.text = entry[0]
		button.add_theme_font_override("font", font)
		button.custom_minimum_size = Vector2(115,36)
		button.pressed.connect(_action.bind(entry[1]))
		buttons.add_child(button)
	var bottom := PanelContainer.new()
	root.add_child(bottom)
	bottom.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	bottom.offset_left = 24
	bottom.offset_right = -24
	bottom.offset_top = -105
	bottom.offset_bottom = -24
	bottom.add_theme_stylebox_override("panel", _style())
	var info := VBoxContainer.new()
	bottom.add_child(info)
	prompt = _ui_label("靠近發光傳送點，按 E 互動 · 青綠色通往家，金色通往遊戲", 19)
	info.add_child(prompt)
	info.add_child(_ui_label("WASD 移動   Shift 快走   E 互動   Q / R 轉視角   滾輪縮放   M 全景   N 日夜   Esc 關閉", 14))
	panel = PanelContainer.new()
	root.add_child(panel)
	panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	panel.offset_left = -270
	panel.offset_right = 270
	panel.offset_top = -145
	panel.offset_bottom = 145
	panel.add_theme_stylebox_override("panel", _style())
	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 18)
	panel.add_child(content)
	content.add_child(_ui_label("兩個人的下一段冒險", 14))
	detail_title = _ui_label("", 26)
	content.add_child(detail_title)
	detail_text = _ui_label("", 18)
	detail_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	detail_text.custom_minimum_size = Vector2(480,80)
	content.add_child(detail_text)
	content.add_child(_ui_label("場景入口已就緒 · 小遊戲將於後續開發", 14))
	var close := Button.new()
	close.text = "繼續散步"
	close.add_theme_font_override("font", font)
	close.custom_minimum_size.y = 40
	close.pressed.connect(_close_panel)
	content.add_child(close)
	panel.hide()
	var minimap := Control.new()
	minimap.set_script(load("res://scripts/world_minimap.gd"))
	minimap.source = self
	root.add_child(minimap)
	minimap.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	minimap.offset_left = -244
	minimap.offset_right = -24
	minimap.offset_top = 24
	minimap.offset_bottom = 198
	navigation = _ui_label("園區導覽",14)
	root.add_child(navigation)
	navigation.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	navigation.offset_left = -244
	navigation.offset_right = -24
	navigation.offset_top = 204
	navigation.add_theme_color_override("font_color",INK)
	fade = ColorRect.new()
	root.add_child(fade)
	fade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	fade.color = Color(0.07,0.12,0.16,0)
	fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if OS.has_feature("web"):
		top.hide()
		bottom.hide()
		minimap.hide()
		navigation.hide()

func _action(action: String) -> void:
	if transitioning:
		return
	match action:
		"guide":
			guiding = not guiding
		"map":
			overview = not overview
		"night":
			night = not night
			sun.light_energy = 0.2 if night else 0.6
			environment.background_color = Color("27374c") if night else Color("b9d5dd")
			environment.ambient_light_color = Color("8498bd") if night else Color("d8e5ed")

func _travel(home: bool) -> void:
	if transitioning:
		return
	transitioning = true
	player.enabled = false
	fade.mouse_filter = Control.MOUSE_FILTER_STOP
	var tween := create_tween()
	tween.tween_property(fade,"color:a",1.0,0.25)
	await tween.finished
	_build(home)
	player.enabled = false
	tween = create_tween()
	tween.tween_property(fade,"color:a",0.0,0.35)
	await tween.finished
	player.enabled = true
	fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	transitioning = false

func _close_panel() -> void:
	panel.hide()
	if is_instance_valid(player):
		player.enabled = true

func _unhandled_input(event: InputEvent) -> void:
	if transitioning:
		return
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			camera_zoom = maxf(0.65,camera_zoom-0.1)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			camera_zoom = minf(1.5,camera_zoom+0.1)
	if event is InputEventKey and event.pressed and not event.echo:
		match event.physical_keycode:
			KEY_ESCAPE: _close_panel()
			KEY_M: _action("map")
			KEY_N: _action("night")
			KEY_E:
				if panel.visible or current.is_empty():
					return
				if current.destination != "":
					_travel(current.destination == "home")
				else:
					if is_instance_valid(web_session) and web_session.activity(current.id,current.title,current.description):
						return
					detail_title.text = current.title
					detail_text.text = current.description
					panel.show()
					player.enabled = false
					activity_requested.emit(current.id)

func _update_camera(delta: float) -> void:
	var focus := player.position + Vector3(0,0.7,0)
	if overview:
		focus = Vector3.ZERO
	if not panel.visible and not transitioning:
		camera_yaw += (float(Input.is_physical_key_pressed(KEY_R))-float(Input.is_physical_key_pressed(KEY_Q)))*delta
	var distance := 190.0 if overview and not inside else 38.0
	var offset := Vector3(sin(camera_yaw)*distance,distance*0.84,cos(camera_yaw)*distance)
	camera.position = camera.position.lerp(focus+offset, minf(delta*6,1))
	camera.look_at(focus)
	var target_size := (56.0 if inside else 320.0) if overview else ((25.0 if inside else 34.0)*camera_zoom)
	camera.size = lerpf(camera.size,target_size,minf(delta*6,1))

func _process(delta: float) -> void:
	if not is_instance_valid(player):
		return
	elapsed += delta
	_update_camera(delta)
	if is_instance_valid(train):
		var t := elapsed*0.075
		train.position = _rail_point(t)
		train.look_at(_rail_point(t+0.02))
	if is_instance_valid(wheel):
		wheel.rotation.z += delta*0.1
		for cabin in cabins:
			cabin.rotation.z = -wheel.rotation.z
	if is_instance_valid(carousel):
		carousel.rotation.y += delta*0.22
	current = {}
	var nearest := 2.2
	for activity in activities:
		activity.portal.active = false
		var distance := Vector2(player.position.x-activity.position.x,player.position.z-activity.position.z).length()
		if distance < nearest:
			nearest = distance
			current = activity
	if not current.is_empty():
		current.portal.active = true
	var goal_pos := Vector3(0,0,16) if inside else Vector3(-30,0,27.5)
	var goal_distance := Vector2(player.position.x-goal_pos.x,player.position.z-goal_pos.z).length()
	navigation.text = ("出門傳送點" if inside else "我們的家 · 西側庭院") + "  %d m" % goal_distance if guiding else ("室內導覽" if inside else "園區導覽")
	prompt.text = "E  ·  " + current.title if not current.is_empty() else "靠近發光傳送點，按 E 互動 · 青綠色通往家，金色通往遊戲"



func _collider(pos: Vector3, size: Vector3) -> void:
	var body := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = size
	shape.shape = box
	body.add_child(shape)
	world.add_child(body)
	body.position = pos

func _path(pos: Vector3, size: Vector2) -> void:
	if not inside: preload("res://scripts/nordic_scenery.gd").pave(world,pos,size)
	_box(world,pos+Vector3(0,0.015,0),Vector3(size.x,0.03,size.y),Color("aaa99d"))
	for side in [-1,1]:
		_box(world,pos+Vector3(side*(size.x/2-0.12),0.045,0),Vector3(0.12,0.04,size.y),CREAM)
		_box(world,pos+Vector3(0,0.045,side*(size.y/2-0.12)),Vector3(size.x,0.04,0.12),CREAM)
	if size.y > size.x:
		for z in range(int(-size.y/2)+2,int(size.y/2),3):
			_box(world,pos+Vector3(0,0.037,z),Vector3(size.x-0.5,0.01,0.025),Color("c2b198"))

func _flowerbed(pos: Vector3, size: Vector2) -> void:
	_box(world,pos+Vector3(0,0.15,0),Vector3(size.x,0.3,size.y),CREAM)
	_collider(pos+Vector3(0,1.5,0),Vector3(size.x,3.0,size.y))
	_box(world,pos+Vector3(0,0.32,0),Vector3(size.x-0.15,0.1,size.y-0.15),Color("67896b"))
	var count := maxi(3,int(size.x*size.y*1.2))
	for i in count:
		var x := sin(i*17.3)*(size.x*0.42)
		var z := cos(i*9.7)*(size.y*0.38)
		var flower_color: Color = [CORAL,GOLD,CREAM][i%3]
		var flower := pos+Vector3(x,0.64+(i%3)*0.045,z)
		_beam(world,pos+Vector3(x,0.35,z),flower,0.022,Color("53765a"))
		var leaf := _ball(world,flower+Vector3(0.07,-0.14,0),0.1,Color("7c9e76"))
		leaf.scale = Vector3(1,0.3,0.55)
		for petal in range(5):
			var a := TAU*petal/5
			var bloom := _ball(world,flower+Vector3(cos(a)*0.085,0,sin(a)*0.085),0.085,flower_color)
			bloom.scale.y = 0.48
		_ball(world,flower+Vector3(0,0.025,0),0.05,Color("dfb665"))

func _bench(pos: Vector3, angle: float) -> void:
	if not inside:
		_path(pos,Vector2(3.8,1.8))
	var parent := Node3D.new()
	world.add_child(parent)
	parent.position = pos
	parent.rotation.y = angle
	for i in range(4):
		_box(parent,Vector3(0,0.6,-0.36+i*0.24),Vector3(3,0.12,0.18),Color("a17c60"))
	for i in range(3):
		_box(parent,Vector3(0,0.95+i*0.22,0.48),Vector3(3,0.16,0.13),Color("a17c60"))
	for x in [-1.15,1.15]:
		_box(parent,Vector3(x,0.3,0),Vector3(0.15,0.6,0.8),INK)
		_box(parent,Vector3(x,0.82,0),Vector3(0.085,0.5,0.08),INK)
		_box(parent,Vector3(x,1.06,0),Vector3(0.16,0.08,0.85),Color("bd9a77"))
		for y in [0.95,1.17,1.39]:
			_ball(parent,Vector3(x,y,0.405),0.027,Color("d5c2a1"))
	_box(parent,Vector3(0,1.17,0.4),Vector3(0.38,0.13,0.025),Color("c8af7c"))
	_collider(pos+Vector3(0,0.5,0),Vector3(3,1,1))

func _signpost(pos: Vector3, text: String) -> void:
	_round_barrier(pos+Vector3(0,1.4,0),0.18,2.8)
	_box(world,pos+Vector3(0,1.4,0),Vector3(0.12,2.8,0.12),INK)
	_box(world,pos+Vector3(0,2.5,0),Vector3(4.8,0.65,0.15),TEAL)
	_label(world,text,pos+Vector3(0,2.6,0.15),30)

func _string_lights(a: Vector3, b: Vector3) -> void:
	for p in [a,b]:
		_round_barrier(Vector3(p.x,1.5,p.z),0.14,3.0)
		_beam(world,Vector3(p.x,0,p.z),p,0.08,INK)
	var previous := a
	for i in range(1,25):
		var t := float(i)/24
		var p := a.lerp(b,t)-Vector3(0,sin(t*PI)*0.7,0)
		_beam(world,previous,p,0.025,INK)
		if i%2 == 0:
			_ball(world,p-Vector3(0,0.12,0),0.1,GOLD).material_override = _material(GOLD,true)
		previous = p

func _roof(parent: Node3D, pos: Vector3, width: float, depth: float, height: float, color: Color) -> void:
	var points := [Vector3(-width/2,0,-depth/2),Vector3(width/2,0,-depth/2),Vector3(-width/2,0,depth/2),Vector3(width/2,0,depth/2),Vector3(0,height,-depth/2),Vector3(0,height,depth/2)]
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for face in [[0,4,2],[2,4,5],[1,3,4],[3,5,4],[0,1,4],[2,5,3]]:
		for index in face:
			surface.add_vertex(points[index])
	surface.generate_normals()
	var node := _mesh(parent,surface.commit(),pos,color)
	var material := _material(color).duplicate() as StandardMaterial3D
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	node.material_override = material
	for side in [-1,1]:
		_beam(parent,pos+Vector3(side*width/2,0,depth/2),pos+Vector3(0,height,depth/2),0.16,CREAM)
	_beam(parent,pos+Vector3(0,height,-depth/2),pos+Vector3(0,height,depth/2),0.18,color.lightened(0.12))

func _window(parent: Node3D, pos: Vector3, size := Vector2(2,2)) -> void:
	_box(parent,pos,Vector3(size.x+0.25,size.y+0.25,0.16),CREAM)
	_box(parent,pos+Vector3(0,0,0.1),Vector3(size.x,size.y,0.08),Color("759daa"))
	_box(parent,pos+Vector3(0,0,0.16),Vector3(0.08,size.y,0.07),CREAM)
	_box(parent,pos+Vector3(0,0,0.16),Vector3(size.x,0.08,0.07),CREAM)
	for x in [-1,1]:
		_box(parent,pos+Vector3(x*(size.x/2+0.35),0,0),Vector3(0.4,size.y+0.2,0.14),TEAL)

func _mansion(pos: Vector3) -> void:
	var house := Node3D.new()
	world.add_child(house)
	house.position = pos
	_box(house,Vector3(0,2.5,0),Vector3(17,5,11),CREAM,true)
	
	_roof(house,Vector3(0,5.1,0),18.5,12.5,3.5,CORAL.darkened(0.15))
	# Exterior cladding, dormer, chimney and entrance veranda.
	for y in range(1,10):
		_box(house,Vector3(0,y*0.48,5.53),Vector3(17,0.035,0.06),Color("cfc0aa"))
	_box(house,Vector3(4.8,6.2,-2.8),Vector3(1,3,1.1),Color("9e7868"))
	_box(house,Vector3(4.8,7.8,-2.8),Vector3(1.3,0.25,1.4),CREAM)
	_box(house,Vector3(0,7.4,4.5),Vector3(3,1.6,2),CREAM)
	_roof(house,Vector3(0,8.2,4.5),3.5,2.6,1.2,CORAL)
	_window(house,Vector3(0,7.5,5.55),Vector2(1.5,1.1))
	for x in [-5,5]:
		_window(house,Vector3(x,2.7,5.6),Vector2(2.4,2.2))
		_box(house,Vector3(x,1.3,5.85),Vector3(3,0.45,0.7),TEAL)
		for dx in [-0.9,-0.3,0.3,0.9]:
			_ball(house,Vector3(x+dx,1.65,5.9),0.22,CORAL)
	_box(house,Vector3(0,1.65,5.65),Vector3(2.1,3.3,0.2),TEAL)
	_window(house,Vector3(0,2.25,5.8),Vector2(1.1,1.1))
	_ball(house,Vector3(0.65,1.25,5.85),0.07,GOLD)
	_box(house,Vector3(0,0.045,7.2),Vector3(8,0.09,3.4),Color("bfaa8b"))
	for x in [-3.5,3.5]:
		_box(house,Vector3(x,1.7,7.8),Vector3(0.2,3.4,0.2),CREAM)
	_roof(house,Vector3(0,3.5,7),8,3.5,0.8,TEAL)
	_label(world,"OUR HOME",pos+Vector3(0,4.3,8.4),40)
	for x in [-10.5,10.5]:
		_flowerbed(pos+Vector3(x,0,3),Vector2(1.8,9))
		_tree(pos+Vector3(x,0,-5),Color("d6a2a6"))
	# Short picket fences leave the front path open.
	for side in [-1,1]:
		for i in range(8):
			var x: float = side*(4.8+i*0.9)
			_box(house,Vector3(x,0.65,11),Vector3(0.13,1.3,0.13),CREAM)
		_box(house,Vector3(side*8,0.55,11),Vector3(7,0.12,0.12),CREAM)
	_lamp(pos+Vector3(-3,0,10.8))
	_lamp(pos+Vector3(3,0,10.8))

func _pavilion(pos: Vector3, color: Color, title: String, type: String) -> void:
	var pavilion := Node3D.new()
	world.add_child(pavilion)
	pavilion.position = pos
	_box(pavilion,Vector3(0,0.055,0),Vector3(12,0.11,9),Color("d0bda3"))
	_box(pavilion,Vector3(0,1.8,-3.5),Vector3(11,3.6,0.25),color,true)
	for x in [-5.3,5.3]:
		_box(pavilion,Vector3(x,0.65,0),Vector3(0.25,1.3,7),color,true)
		_box(pavilion,Vector3(x,2,3.6),Vector3(0.22,4,0.22),CREAM)
	_box(pavilion,Vector3(0,4,-2.7),Vector3(12,0.28,3.6),color)
	for i in range(12):
		_box(pavilion,Vector3(-5.5+i,3.8,-0.8),Vector3(0.5,0.4,1),CREAM)
	_box(pavilion,Vector3(0,4.55,-2.7),Vector3(10,0.8,0.4),INK)
	_label(world,title,pos+Vector3(0,4.65,-2.3),36)
	_box(pavilion,Vector3(0,1.1,0),Vector3(4.4,0.2,2.6),CREAM,true)
	for x in [-1.7,1.7]:
		_box(pavilion,Vector3(x,0.5,0),Vector3(0.18,1,2),color)
		_chair(pavilion,Vector3(x*1.7,0,0),-signf(x)*PI/2,color)
	if type == "battleship":
		for x in range(7):
			for z in range(4):
				_box(pavilion,Vector3(-1.7+x*0.55,1.24,-0.9+z*0.55),Vector3(0.5,0.06,0.5),TEAL if (x+z)%2 else Color("78bdc9"))
		for p in [Vector3(-1,1.38,0),Vector3(1,1.38,-0.5)]:
			_box(pavilion,p,Vector3(1,0.15,0.3),INK)
			_box(pavilion,p+Vector3(0,0.2,0),Vector3(0.3,0.3,0.2),CREAM)
	elif type == "ink":
		for i in range(8):
			_cylinder(pavilion,Vector3(-1.5+i*0.4,1.3,0),0.15,0.3,[TEAL,CORAL,GOLD][i%3])
	else:
		for i in range(6):
			_box(pavilion,Vector3(-1.3+i*0.5,1.24,0),Vector3(0.35,0.05,0.65),CORAL if i%2 else TEAL)
		for x in [-1,1]:
			_box(pavilion,Vector3(x,1.4,-0.7),Vector3(0.28,0.28,0.28),GOLD)

func _gazebo(pos: Vector3) -> void:
	_cylinder(world,pos+Vector3(0,0.06,0),5.6,0.12,Color("d4bfa4"))
	for i in range(6):
		var a := TAU*i/6
		_box(world,pos+Vector3(cos(a)*4.5,2,sin(a)*4.5),Vector3(0.2,4,0.2),CREAM)
	_cylinder(world,pos+Vector3(0,4.7,0),5.3,1.6,TEAL,0.3)
	_ball(world,pos+Vector3(0,5.7,0),0.2,GOLD)
	_bench(pos+Vector3(0,0,-2),0)
	_string_lights(pos+Vector3(-4,3.6,2),pos+Vector3(4,3.6,2))

func _chair(parent: Node3D, pos: Vector3, angle: float, color: Color) -> void:
	var chair := Node3D.new()
	parent.add_child(chair)
	chair.position = pos
	chair.rotation.y = angle
	_box(chair,Vector3(0,0.62,0),Vector3(1,0.18,1),color)
	_box(chair,Vector3(0,1.15,0.43),Vector3(1,0.95,0.15),color)
	for x in [-0.36,0.36]:
		for z in [-0.36,0.36]:
			_box(chair,Vector3(x,0.28,z),Vector3(0.1,0.55,0.1),Color("947660"))








func _rail_point(t: float) -> Vector3:
	return Vector3(-3+cos(t)*46,4.8+sin(t*2)*1.2,-28+sin(t)*11)

func _sky_train() -> void:
	for i in range(96):
		var a := TAU*i/96
		var b := TAU*(i+1)/96
		var p := _rail_point(a)
		var next := _rail_point(b)
		var right := (next-p).normalized().cross(Vector3.UP)*0.38
		_beam(world,p+right,next+right,0.1,CORAL)
		_beam(world,p-right,next-right,0.1,CORAL)
		_beam(world,p+right*1.3,p-right*1.3,0.09,CREAM)
		if i%8 == 0:
			_beam(world,Vector3(p.x,0,p.z),p,0.17,TEAL)
			_cylinder(world,Vector3(p.x,0.1,p.z),0.4,0.2,CREAM)
	train = Node3D.new()
	world.add_child(train)
	for z in [0,1.5,3]:
		_box(train,Vector3(0,0.4,z),Vector3(1.2,0.65,1.3),CORAL if z == 0 else TEAL)
		_box(train,Vector3(0,0.8,z+0.25),Vector3(1,0.35,0.4),CREAM)
		for x in [-0.65,0.65]:
			for dz in [-0.4,0.4]:
				_ball(train,Vector3(x,0.1,z+dz),0.2,INK)
	_cylinder(train,Vector3(0,0.9,-0.3),0.16,0.7,GOLD)
	_ball(train,Vector3(0,1.35,-0.3),0.22,CREAM)













