extends Node2D
## One grid owns terrain drawing and collision; buildings declare their entrances.
const ROOT := "res://assets/2d/packs/sunnyside_world_v2_1/Sunnyside_World_ASSET_PACK_V2.1/Sunnyside_World_Assets/"
const CELL := 48
const ORIGIN := Vector2(1440,0)
var atlas: Texture2D = preload(ROOT+"Tileset/spr_tileset_sunnysideworld_16px.png")
var roads: Dictionary = {}
var water: Dictionary = {}
var wave_time := 0.0
var wave_tick := 0.0
var buildings := [
	{"id":"entry","title":"共同之家","position":Vector2(1890,370),"corner":Vector2(1746,165),"width":5,"roof":0},
	{"id":"town_shop","title":"綜合商店","position":Vector2(2340,370),"corner":Vector2(2220,165),"width":4,"roof":384},
	{"id":"town_cafe","title":"咖啡與桌遊","position":Vector2(2610,730),"corner":Vector2(2466,525),"width":5,"roof":128},
	{"id":"town_post","title":"回憶郵局","position":Vector2(1910,730),"corner":Vector2(1790,525),"width":4,"roof":256},
	{"id":"town_station","title":"海風車站","position":Vector2(3260,370),"corner":Vector2(3116,165),"width":5,"roof":0}
]

func tile(region: Rect2, p: Vector2, factor := 3.0) -> void:
	draw_texture_rect_region(atlas,Rect2(p,region.size*factor),region)

func prop(region: Rect2, p: Vector2, foot: float, factor := 3.0) -> void:
	var sprite := Sprite2D.new()
	var texture := AtlasTexture.new()
	texture.atlas=atlas
	texture.region=region
	sprite.texture=texture
	sprite.centered=false
	sprite.position=p
	sprite.scale=Vector2.ONE*factor
	sprite.z_index=int(foot/10)
	add_child(sprite)

func body(rect: Rect2) -> void:
	get_parent()._add_wall_collision(rect)

func road_rect(rect: Rect2i) -> void:
	for y in range(rect.position.y,rect.end.y):
		for x in range(rect.position.x,rect.end.x): roads[Vector2i(x,y)]=true

func _ready() -> void:
	name="SunnysideTown"
	texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
	road_rect(Rect2i(0,8,45,2))
	road_rect(Rect2i(8,6,3,10))
	road_rect(Rect2i(17,6,3,8))
	road_rect(Rect2i(9,14,18,2))
	road_rect(Rect2i(24,9,3,7))
	road_rect(Rect2i(36,6,3,4))
	road_rect(Rect2i(40,10,4,5))
	for y in range(19):
		var edge: int = 46+[1,1,0,0,1,2,1,0,0,0,1,1,0,-1,-1,0,1,1,0][y]
		for x in range(edge,60):
			var cell := Vector2i(x,y)
			water[cell]=true
			if not (y in [8,9] and x<57): body(Rect2(ORIGIN+Vector2(cell)*CELL,Vector2.ONE*CELL))
	for rect in [Rect2(1440,100,2880,16),Rect2(1440,780,2880,16),Rect2(4176,384,144,96)]: body(rect)
	for building in buildings:
		make_building(building)
		get_parent().interactions.append({"id":building.id,"title":building.title,"hint":"","position":building.position})
	get_parent().interactions.append_array([
		{"id":"picnic","title":"一起野餐","hint":"今天的午后，留給我們。","position":Vector2(2200,640)},
		{"id":"coast","title":"坐下看海","hint":"聽一會海浪，也很好。","position":Vector2(3450,340)},
		{"id":"pier","title":"海邊合照","hint":"把這一刻留下來。","position":Vector2(4090,450)}])
	# Dense edge groves alternate with small gardens and open building forecourts.
	var rng := RandomNumberGenerator.new()
	rng.seed=17092
	for i in range(82):
		var p := Vector2(rng.randi_range(1465,3490),rng.randi_range(125,760))
		var cell := Vector2i((p-ORIGIN)/CELL)
		if roads.has(cell) or roads.has(cell+Vector2i(0,1)): continue
		var blocked := false
		for building in buildings:
			if Rect2(building.corner-Vector2(36,40),Vector2((building.width*16+16)*3+72,265)).has_point(p): blocked=true
		if Rect2(2070,510,330,220).has_point(p) or Rect2(1520,230,170,150).has_point(p): blocked=true
		if blocked: continue
		var tree := Sprite2D.new()
		tree.texture=load(ROOT+"Elements/Plants/spr_deco_tree_0"+str(1+i%2)+"_strip4.png")
		tree.hframes=4
		tree.position=p
		tree.scale=Vector2.ONE*3
		tree.z_index=int((p.y+25)/10)
		add_child(tree)
		body(Rect2(p+Vector2(-12,18),Vector2(24,20)))
	for p in [Vector2(2070,305),Vector2(2450,310),Vector2(1740,669),Vector2(2800,650),Vector2(3360,260)]:
		prop(Rect2(576,144,32,32),p,p.y+75,2)
	for x in [1540,1588,1636]:
		for y in [270,318]:
			prop(Rect2(864,256,16,32),Vector2(x,y-40),y+30,2)
	var boat := Sprite2D.new()
	boat.texture=load(ROOT+"Elements/Other/spr_deco_coracle_land.png")
	boat.position=Vector2(3530,650)
	boat.scale=Vector2.ONE*2
	boat.z_index=67
	add_child(boat)
	body(Rect2(3506,639,48,28))
	# Garden baskets, paired cafe tables and a station platform distinguish the plots.
	for p in [Vector2(2700,495),Vector2(2780,560)]:
		prop(Rect2(640,192,32,32),p,p.y+64,2)
	for p in [Vector2(2170,602),Vector2(2250,602)]:
		var meal := Sprite2D.new()
		meal.texture=load("res://assets/2d/props/pixel_platter/Pixel Platter/Burger.png")
		meal.position=p
		meal.scale=Vector2.ONE*2
		meal.z_index=62
		add_child(meal)

func _process(delta: float) -> void:
	wave_tick+=delta
	if wave_tick>=0.16:
		wave_time+=wave_tick
		wave_tick=0
		queue_redraw()

func make_building(data: Dictionary) -> void:
	var p: Vector2=data.corner
	var n: int=data.width
	var shift: int=data.roof
	var width := (n*16+16)*3
	# Modular roof: preserve the original pixel scale rather than stretching a crop.
	for row in range(2):
		prop(Rect2(248,160+shift,8,16),p+Vector2(0,24+row*48),p.y+183)
		for column in range(n):
			prop(Rect2(256,192+shift,16,16),p+Vector2(24+column*48,24+row*48),p.y+183)
		prop(Rect2(272,160+shift,8,16),p+Vector2(width-24,24+row*48),p.y+183)
	for column in range(n):
		prop(Rect2(256,152+shift,16,8),p+Vector2(24+column*48,0),p.y+183)
		for row in range(2):
			prop(Rect2(16,144,16,16),p+Vector2(24+column*48,108+row*39),p.y+183)
	prop(Rect2(248,152+shift,8,8),p,p.y+183)
	prop(Rect2(272,152+shift,8,8),p+Vector2(width-24,0),p.y+183)
	# Original dormer and door modules establish a readable front entrance.
	prop(Rect2(472,192+shift,32,32),p+Vector2(width/2-32,27),p.y+184,2)
	prop(Rect2(256,240+shift,16,16),p+Vector2(width/2-24,153),p.y+186,3)
	for x in [36,width-84]: prop(Rect2(256,224+shift,16,16),p+Vector2(x,116),p.y+185,3)
	body(Rect2(p+Vector2(6,18),Vector2(width-12,165)))
	var label := Label.new()
	label.text=data.title
	label.position=Vector2(data.position.x-86,data.position.y+9)
	label.size=Vector2(172,26)
	label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size",17)
	label.add_theme_color_override("font_color",Color("fff2cb"))
	label.add_theme_color_override("font_shadow_color",Color("304335"))
	label.add_theme_constant_override("shadow_outline_size",5)
	label.z_index=95
	add_child(label)

func terrain_cell(cell: Vector2i, cells: Dictionary, ocean: bool) -> void:
	var p := ORIGIN+Vector2(cell)*CELL
	if ocean:
		tile(Rect2(176+16*(cell.x%2),288+16*(cell.y%2),16,16),p)
	else:
		tile(Rect2(144,112,16,16) if (cell.x+cell.y)%3==0 else Rect2(48,16,16,16),p)
	var border := Color("69ac46") if not ocean else Color("e8d3aa")
	var edge := Color("b37654") if not ocean else Color("ac785a")
	if ocean:
		if not cells.has(cell+Vector2i.UP):
			draw_rect(Rect2(p,Vector2(48,18)),Color("b87b59"))
			draw_rect(Rect2(p+Vector2(0,15),Vector2(48,3)),Color("f7e9d0"))
			draw_rect(Rect2(p+Vector2(0,18),Vector2(48,6)),Color("287dc4"))
		if not cells.has(cell+Vector2i.LEFT):
			draw_rect(Rect2(p,Vector2(9,48)),Color("b87b59"))
			draw_rect(Rect2(p+Vector2(9,0),Vector2(3,48)),Color("f7e9d0"))
			draw_rect(Rect2(p+Vector2(12,0),Vector2(6,48)),Color("287dc4"))
	for side in [Vector2i.LEFT,Vector2i.RIGHT,Vector2i.UP,Vector2i.DOWN]:
		if cells.has(cell+side): continue
		for i in range(16):
			var tooth := 3 if (i+cell.x*3+cell.y)%5<2 else 0
			var pos := p
			var size := Vector2(3,3+tooth)
			if side==Vector2i.UP: pos+=Vector2(i*3,0)
			elif side==Vector2i.DOWN: pos+=Vector2(i*3,45-tooth)
			elif side==Vector2i.LEFT:
				pos+=Vector2(0,i*3)
				size=Vector2(3+tooth,3)
			else:
				pos+=Vector2(45-tooth,i*3)
				size=Vector2(3+tooth,3)
			draw_rect(Rect2(pos,size),border)
			if ocean: draw_rect(Rect2(pos+Vector2(0,3),Vector2(size.x,6)),edge)
	# Cut exposed outer corners in source-pixel steps.
	for sx in [-1,1]:
		for sy in [-1,1]:
			if not cells.has(cell+Vector2i(sx,0)) and not cells.has(cell+Vector2i(0,sy)):
				var corner := p+Vector2(0 if sx<0 else 39,0 if sy<0 else 39)
				tile(Rect2(16,16,3,3),corner)

func _draw() -> void:
	for y in range(19):
		for x in range(60):
			var cell := Vector2i(x,y)
			var source := Vector2(16,16)
			if (x*7+y*13)%9==0: source=Vector2(16,32)
			elif (x*11+y*7)%13==0: source=Vector2(32,32)
			tile(Rect2(source,Vector2(16,16)),ORIGIN+Vector2(cell)*CELL)
	for cell in roads: terrain_cell(cell,roads,false)
	for cell in water: terrain_cell(cell,water,true)
	for i in range(32):
		var cell := Vector2i(49+i%10,2+(i*7)%15)
		if not water.has(cell) or cell.y in [8,9]: continue
		var p := ORIGIN+Vector2(cell)*CELL+Vector2(int(sin(wave_time+i)*3)*3,15)
		draw_rect(Rect2(p,Vector2(15,3)),Color("71cde1"))
	# Curated low plants, flowers and stones occupy grass, never the roads.
	for i in range(260):
		var cell := Vector2i((i*17+3)%44,(i*11+2)%17+2)
		if roads.has(cell): continue
		var p := ORIGIN+Vector2(cell)*CELL+Vector2(i%3*6,0)
		var region := Rect2(496,48,16,16) if i%4==0 else Rect2(432+16*(i%4),48,16,16)
		tile(region,p,2)
	# All timber elements come from the supplied pier and fence atlas.
	for x in range(3552,4176,48):
		for y in [384,432]: tile(Rect2(640,96,16,16),Vector2(x,y))
	for x in range(3504,4176,96):
		for y in [375,474]: tile(Rect2(624,48,16,16),Vector2(x,y),2)
	for x in range(1490,2810,48):
		if x>1760 and x<1980: continue
		tile(Rect2(624,32,16,16),Vector2(x,750))
	for x in range(1510,1680,48): tile(Rect2(624,32,16,16),Vector2(x,360))
	# Small garden and picnic court remain part of the residential district.
	for x in range(1536,1680,48):
		for y in range(240,336,48): tile(Rect2(144,112,16,16),Vector2(x,y))
	tile(Rect2(640,560,48,48),Vector2(2130,565),3)
	tile(Rect2(640,192,32,32),Vector2(3385,275),2)
