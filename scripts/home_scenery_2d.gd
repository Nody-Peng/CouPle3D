extends Node2D
## Atlas regions stay in source pixels; the room is composed at integer scales.
const ROOT := "res://assets/2d/packs/sunnyside_world_v2_1/Sunnyside_World_ASSET_PACK_V2.1/Sunnyside_World_Assets/"
var world: Texture2D = preload(ROOT + "Tileset/spr_tileset_sunnysideworld_16px.png")

func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST

func tile(texture: Texture2D, source: Rect2, area: Rect2, factor := 3.0) -> void:
	var step := source.size * factor
	for y in range(int(area.position.y), int(area.end.y), int(step.y)):
		for x in range(int(area.position.x), int(area.end.x), int(step.x)):
			var size := Vector2(minf(step.x, area.end.x - x), minf(step.y, area.end.y - y))
			draw_texture_rect_region(texture, Rect2(Vector2(x,y),size), Rect2(source.position,size/factor))

func wall(area: Rect2, tint := Color("a9c9bc")) -> void:
	draw_rect(area, Color("435559"))
	draw_rect(Rect2(area.position + Vector2(4,4), area.size - Vector2(8,8)),tint)
	for x in range(int(area.position.x)+8,int(area.end.x)-4,24):
		draw_line(Vector2(x,area.position.y+6),Vector2(x,area.end.y-9),tint.darkened(0.09),2)
	draw_rect(Rect2(area.position+Vector2(3,area.size.y-10),Vector2(area.size.x-6,7)),Color("756453"))
	draw_rect(Rect2(area.position+Vector2(3,3),Vector2(area.size.x-6,4)),Color("e3e9cf"))

func window_at(pos: Vector2) -> void:
	draw_rect(Rect2(pos+Vector2(5,7),Vector2(100,61)),Color("75938b"))
	draw_rect(Rect2(pos,Vector2(100,60)),Color("485b62"))
	draw_rect(Rect2(pos+Vector2(5,5),Vector2(90,49)),Color("8dcddd"))
	draw_rect(Rect2(pos+Vector2(5,39),Vector2(90,15)),Color("6ca36e"))
	for offset in [Vector2(15,14),Vector2(66,23)]:
		draw_rect(Rect2(pos+offset,Vector2(20,4)),Color("e5f2e9"))
	draw_rect(Rect2(pos+Vector2(47,3),Vector2(6,52)),Color("f1edcf"))
	draw_rect(Rect2(pos+Vector2(-5,55),Vector2(110,7)),Color("f1edcf"))
	for x in [-8,88]:
		draw_rect(Rect2(pos+Vector2(x,-3),Vector2(20,48)),Color("d67473"))
		draw_rect(Rect2(pos+Vector2(x+5,0),Vector2(4,43)),Color("efaaa0"))

func rug(area: Rect2, color: Color) -> void:
	draw_rect(Rect2(area.position+Vector2(4,5),area.size),Color("00000018"))
	draw_rect(area,color.darkened(0.3))
	draw_rect(area.grow(-4),Color("e9d9b6"))
	draw_rect(area.grow(-8),color)
	for x in range(int(area.position.x)+16,int(area.end.x)-8,20):
		draw_rect(Rect2(x,area.position.y+12,6,3),Color("e9d9b6"))
		draw_rect(Rect2(x,area.end.y-15,6,3),Color("e9d9b6"))

func _draw() -> void:
	draw_rect(Rect2(0,0,1440,900),Color("82ae70"))
	# Grass tufts and a winding stone route give the exterior a readable scale.
	for i in range(140):
		var p := Vector2((i*137+17)%1440,(i*79+103)%900)
		draw_rect(Rect2(p,Vector2(3,6)),Color("4c9a48"))
		draw_rect(Rect2(p+Vector2(4,3),Vector2(3,4)),Color("a3d768"))
	tile(world,Rect2(80,16,16,16),Rect2(1164,396,222,96))
	tile(world,Rect2(80,16,16,16),Rect2(1250,190,64,550))
	draw_rect(Rect2(62,116,1120,704),Color("233d4440"))
	draw_rect(Rect2(55,105,1110,705),Color("455455"))
	wood_floor(Rect2(73,185,537,319))
	ceramic_floor(Rect2(626,185,521,319),Color("e1dfc7"),Color("ced9cb"))
	wood_floor(Rect2(73,558,537,234))
	wood_floor(Rect2(626,558,288,234))
	ceramic_floor(Rect2(930,558,217,234),Color("b5d1c9"),Color("d9e3d6"))
	# Door thresholds bridge the room floors without gaps.
	for area in [Rect2(610,410,16,75),Rect2(255,504,115,54),Rect2(760,504,115,54),Rect2(970,504,110,54)]:
		wood_floor(area)
	wall(Rect2(55,105,1110,80))
	wall(Rect2(73,504,182,54))
	wall(Rect2(370,504,390,54))
	wall(Rect2(875,504,95,54))
	wall(Rect2(1080,504,67,54))
	for area in [Rect2(55,185,18,625),Rect2(610,185,16,225),Rect2(610,485,16,307),Rect2(914,558,16,234),Rect2(1147,185,18,215),Rect2(1147,490,18,320)]:
		wall(area)
	wall(Rect2(55,792,1110,18))
	window_at(Vector2(186,117))
	window_at(Vector2(455,117))
	window_at(Vector2(690,117))
	window_at(Vector2(1000,117))
	rug(Rect2(236,266,269,139),Color("588b91"))
	rug(Rect2(673,374,161,108),Color("b98488"))
	rug(Rect2(289,606,190,118),Color("728fa6"))
	rug(Rect2(753,694,133,58),Color("bc6a79"))
	rug(Rect2(1030,711,96,45),Color("6f9ca2"))
	rug(Rect2(1082,409,63,76),Color("b98958"))
	# Low garden fence, with a gate aligned with the home's east door.
	for y in range(196,700,48):
		if y>=388 and y<500: continue
		draw_texture_rect_region(world,Rect2(1390,y,24,48),Rect2(592,16,8,16))
	for x in range(1170,1390,48):
		draw_texture_rect_region(world,Rect2(x,190,48,48),Rect2(624,32,16,16))
		draw_texture_rect_region(world,Rect2(x,682,48,48),Rect2(624,32,16,16))
	for area in [Rect2(1190,285,60,96),Rect2(1318,285,60,96),Rect2(1200,536,164,96)]:
		draw_rect(area,Color("654c43"))
		tile(world,Rect2(160,64,16,16),area.grow(-4),2)
	for x in [1203,1233,1331,1361]:
		for y in [311,351]:
			draw_texture_rect_region(world,Rect2(x-12,y-20,24,32),Rect2(928,272,12,16))

func wood_floor(area: Rect2) -> void:
	draw_rect(area,Color("a38165"))
	var row := 0
	for y in range(int(area.position.y),int(area.end.y),48):
		for x in range(int(area.position.x)-48*(row%2),int(area.end.x),96):
			var board := Rect2(x+3,y+3,93,45).intersection(area)
			draw_rect(board,Color("c8aa82") if (row+x/120)%3 else Color("c1a17d"))
		row += 1

func ceramic_floor(area: Rect2, a: Color, b: Color) -> void:
	draw_rect(area,Color("a6b6aa"))
	for y in range(int(area.position.y),int(area.end.y),48):
		for x in range(int(area.position.x),int(area.end.x),48):
			draw_rect(Rect2(x+3,y+3,45,45).intersection(area),a if (x/48+y/48)%2 else b)
