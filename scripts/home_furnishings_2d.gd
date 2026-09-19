extends Node2D
## Bottom-anchored props share a depth key with the characters.
const PACK := "res://assets/2d/packs/pixelspaces_free/"
var activity := ""
var activity_time := 0.0
var effects: Node2D

func prop(file: String, x: float, y: float, factor := 4.0, depth := -1) -> void:
	var surfaces := {
		"Furniture/Living Room/Table_long.png":["table",144,66],
		"Furniture/Living Room/Coffee_table_1.png":["table",72,48],
		"Furniture/Living Room/Couch_large_green.png":["sofa",144,72],
		"Furniture/Living Room/Couch_small_2_green_side.png":["sofa",54,66],
		"Furniture/Bathroom/Bathtub.png":["bath",96,72]}
	if surfaces.has(file):
		var spec: Array=surfaces[file]
		var item=preload("res://scripts/pixel_furniture_2d.gd").new()
		item.kind=spec[0]
		item.width=spec[1]
		item.height=spec[2]
		item.position=Vector2(x-spec[1]/2.0,y-spec[2]).snapped(Vector2.ONE*3)
		item.z_index=int(y/10) if depth<0 else depth
		add_child(item)
		return
	factor=3.0
	var sprite := Sprite2D.new()
	sprite.texture = load(PACK + file)
	sprite.centered = false
	sprite.position = (Vector2(x, y) - Vector2(sprite.texture.get_width()*factor/2, sprite.texture.get_height()*factor)).snapped(Vector2.ONE*3)
	sprite.scale = Vector2.ONE * factor
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.z_index = int(y/10) if depth < 0 else depth
	add_child(sprite)

func plant(x: float, y: float, flower := "Flora_aloe.png") -> void:
	prop("Objects/Living Room/Flowerpot_medium_red.png",x,y)
	prop("Objects/Living Room/"+flower,x,y-9,4,int(y/10)+1)

func solid(area: Rect2) -> void:
	get_parent()._add_wall_collision(area)

func _ready() -> void:
	name = "HomeFurnishings"
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	effects = Node2D.new()
	effects.z_index = 33
	effects.draw.connect(_draw_activity)
	add_child(effects)
	# Living room: media wall, conversation seating and a stocked reading corner.
	prop("Furniture/Living Room/Couch_large_green.png",330,310,5)
	prop("Furniture/Living Room/Couch_small_2_green_side.png",469,364,5)
	prop("Furniture/Living Room/Coffee_table_1.png",340,385,5)
	prop("Objects/Living Room/Books_outside_5.png",338,351,3,39)
	prop("Objects/Kitchen/Glass_water.png",369,353,3,39)
	prop("Furniture/Bedroom/Lamp_stand_2.png",515,309,4)
	prop("Furniture/Living Room/Table_long.png",160,300,4)
	get_parent()._add_furniture("Television.png",Vector2(160,252),4)
	prop("Furniture/Living Room/Bookshelf_1.png",550,270,4)
	for y in [216,237,258]:
		prop("Objects/Living Room/Books_inside_1.png",550,y,4,28)
	plant(104,244,"Flora_daisy_4.png")
	plant(554,462)
	prop("Furniture/Living Room/Shelf_large.png",355,209,4)
	prop("Objects/Bedroom/Clock_1_red.png",338,190,3,22)
	prop("Objects/Living Room/Books_outside_1.png",383,190,3,22)
	prop("Objects/Living Room/Vase_red.png",315,190,3,22)
	# Kitchen appliances sit on a continuous, purpose-built cabinet run.
	prop("Furniture/Kitchen/Refrigerator_large_white.png",844,281,4)
	prop("Objects/Kitchen/Refrigerator_sticky_notes_1.png",848,220,4,29)
	prop("Furniture/Kitchen/Sink_connecting.png",1044,242,4,30)
	prop("Objects/Kitchen/Oven_connecting.png",946,239,4,30)
	prop("Objects/Kitchen/Cooking_pan.png",946,216,3,31)
	prop("Objects/Kitchen/Microwave_white.png",710,228,4,30)
	prop("Objects/Kitchen/Blender_blue.png",781,228,3,30)
	prop("Furniture/Kitchen/Magnet_knife_holder.png",938,196,4,31)
	prop("Objects/Kitchen/Hanging_cooking_pans.png",1092,193,3,31)
	prop("Objects/Kitchen/Glass_pitcher_water.png",1105,231,3,31)
	plant(672,230,"Flora_daisy.png")
	prop("Furniture/Living Room/Table_long.png",751,447,5)
	get_parent()._add_furniture("Chair.png",Vector2(704,384),4)
	get_parent()._add_furniture("Chair.png",Vector2(837,438),4,true)
	prop("Objects/Kitchen/Glass_water.png",712,414,3,46)
	prop("Objects/Kitchen/Glass_water.png",786,414,3,46)
	prop("Objects/Living Room/Vase_red.png",749,411,3,46)
	for x in [715,784]:
		var meal := Sprite2D.new()
		meal.texture = load("res://assets/2d/props/pixel_platter/Pixel Platter/Burger.png")
		meal.position = Vector2(x,423)
		meal.z_index = 46
		add_child(meal)
	plant(1108,365,"Flora_daisy_4.png")
	prop("Furniture/Living Room/Bookshelf_small.png",996,366,4)
	prop("Objects/Bedroom/Box_green_large.png",995,342,3,38)
	prop("Objects/Kitchen/Glass_pitcher.png",975,318,3,38)
	# A two-person workspace, with lighting, books, bags and storage.
	for x in [143,201]:
		prop("Furniture/Living Room/Bookshelf_1.png",x,673,4)
		for y in [615,636,657]:
			prop("Objects/Living Room/Books_inside_1.png",x,y,4,68)
	prop("Furniture/Living Room/Table_long.png",389,645,5)
	prop("Furniture/Bedroom/Laptop.png",354,611,4,66)
	prop("Objects/Living Room/Books_outside_5.png",410,611,3,66)
	prop("Furniture/Bedroom/Lamp_bedroom_3.png",444,611,3,66)
	for x in [347,419]: get_parent()._add_furniture("Chair.png",Vector2(x,681),4)
	prop("Objects/Bedroom/Backpack_blue.png",465,704,3)
	prop("Objects/Bedroom/Backpack_red.png",303,704,3)
	prop("Furniture/Bedroom/Drawer_medium_1_c.png",543,660,4)
	plant(543,607,"Flora_daisy_4.png")
	prop("Objects/Bedroom/Calendar_2.png",434,549,3,56)
	prop("Objects/Bedroom/Poster_1.png",184,551,3,56)
	plant(106,752)
	# Bedroom: a real double bed, bedside storage and a wardrobe.
	prop("Furniture/Bedroom/Cabinet_1.png",671,680,4)
	prop("Furniture/Bedroom/Drawer_medium_1_a.png",688,766,4)
	prop("Objects/Bedroom/Alarm_clock_red.png",689,714,3,78)
	prop("Furniture/Bedroom/Lamp_bedroom_3.png",886,613,3,67)
	prop("Objects/Bedroom/Box_blue_large.png",873,761,3)
	# Bathroom: tub, vanity, toilet, mirror, towels and washing supplies.
	prop("Furniture/Bathroom/Bathtub.png",1070,674,5)
	prop("Objects/Bathroom/Bathtub_towel_blue.png",1096,656,4,69)
	prop("Furniture/Bathroom/Toilet.png",962,636,4)
	prop("Furniture/Bathroom/Sink_bathroom.png",970,770,4)
	prop("Furniture/Bathroom/Mirror.png",1111,600,3,65)
	prop("Furniture/Bathroom/Towel_rail.png",1077,583,3,65)
	prop("Objects/Bathroom/Bath_towel_long_blue.png",1066,608,3,65)
	prop("Objects/Bathroom/Bath_towel_long_green.png",1090,608,3,65)
	plant(1113,777)
	for area in [Rect2(257,287,146,24),Rect2(446,334,45,30),Rect2(132,280,56,20),Rect2(525,244,50,25),Rect2(650,235,150,47),Rect2(815,245,58,37),Rect2(898,235,236,47),Rect2(957,341,76,25),Rect2(691,422,120,24),Rect2(116,641,111,31),Rect2(326,619,125,26),Rect2(649,650,44,30),Rect2(758,615,104,69),Rect2(1030,650,86,25),Rect2(946,613,32,23),Rect2(946,747,48,24)]:
		solid(area)
	for area in [Rect2(308,359,64,24),Rect2(527,638,33,22),Rect2(670,741,36,25),Rect2(693,384,23,14),Rect2(827,437,22,14),Rect2(337,682,21,14),Rect2(409,682,21,14)]:
		solid(area)

func cabinet(area: Rect2) -> void:
	draw_rect(Rect2(area.position+Vector2(3,5),area.size),Color("243e4830"))
	draw_rect(area,Color("465c61"))
	draw_rect(area.grow(-3),Color("76a49a"))
	for x in range(int(area.position.x)+4,int(area.end.x)-8,48):
		draw_rect(Rect2(x,area.position.y+13,42,area.size.y-18),Color("57877d"))
		draw_rect(Rect2(x+4,area.position.y+16,34,area.size.y-26),Color("89b5a4"))
		draw_rect(Rect2(x+15,area.position.y+20,12,3),Color("ead9aa"))
	draw_rect(Rect2(area.position,Vector2(area.size.x,13)),Color("f2ead6"))
	draw_rect(Rect2(area.position+Vector2(0,13),Vector2(area.size.x,4)),Color("abbfb5"))

func _draw() -> void:
	# Pale tiled backsplash and continuous counters include a clear prep surface.
	for x in range(898,1134,12):
		for y in range(188,225,12):
			draw_rect(Rect2(x,y,11,11),Color("dce4cd") if (x/12+y/12)%3 else Color("b2cdbd"))
	cabinet(Rect2(650,226,150,55))
	cabinet(Rect2(898,226,236,55))
	# Chopping board, vegetables, draining rack and folded dish towel.
	draw_rect(Rect2(984,220,29,14),Color("c69569"))
	for x in [988,996,1004]: draw_rect(Rect2(x,221,5,5),Color("75a45c"))
	for x in range(1079,1097,4): draw_rect(Rect2(x,218,2,13),Color("869f9a"))
	draw_rect(Rect2(1120,244,10,21),Color("f4debe"))
	draw_rect(Rect2(1123,247,3,18),Color("da8e89"))
	# Place settings lie on the tabletop; wall-mounted detail stays unobtrusive.
	for x in [713,779]:
		draw_circle(Vector2(x,417),11,Color("8aab9f"))
		draw_circle(Vector2(x,415),8,Color("f4ead6"))
	# Matching oak double bed with two pillows and a folded coral blanket.
	draw_rect(Rect2(749,605,122,88),Color("56494a"))
	draw_rect(Rect2(753,609,114,80),Color("b18b70"))
	draw_rect(Rect2(757,615,106,66),Color("e9e2ce"))
	for x in [762,815]:
		draw_rect(Rect2(x,618,42,19),Color("b4c7bf"))
		draw_rect(Rect2(x+3,618,36,15),Color("fff0d8"))
	draw_rect(Rect2(757,641,106,40),Color("7caaa4"))
	draw_rect(Rect2(757,665,106,16),Color("c47d84"))
	for x in range(762,860,12): draw_rect(Rect2(x,668,3,10),Color("e8b3a0"))
	for x in [718,872]:
		draw_rect(Rect2(x,608,25,25),Color("7d6557"))
		draw_rect(Rect2(x+3,611,19,16),Color("c09a73"))
		draw_rect(Rect2(x+10,614,6,3),Color("ecd8ac"))
	# Small bath shelf, rolled towels, and soap dispenser.
	draw_rect(Rect2(1014,746,56,7),Color("b78a68"))
	for x in [1018,1035,1052]:
		draw_rect(Rect2(x,734,13,12),Color("d2e3d6"))
		draw_rect(Rect2(x+3,737,7,3),Color("8bb7b0"))

func play_activity(id: String) -> void:
	activity = id
	activity_time = 3.0
	effects.queue_redraw()

func _process(delta: float) -> void:
	if activity_time <= 0: return
	activity_time = maxf(0,activity_time-delta)
	effects.queue_redraw()

func _draw_activity() -> void:
	if activity_time <= 0: return
	if activity == "sink":
		effects.draw_rect(Rect2(1041,211,3,17),Color("9dd9e3"))
		for i in range(4):
			var y := 227-int(fmod(activity_time*17+i*5,12))
			effects.draw_rect(Rect2(1034+i*5,y,3,3),Color("e2f3e6"))
	else:
		for i in range(3):
			var y := 213-int(fmod((3-activity_time)*14+i*9,30))
			effects.draw_rect(Rect2(939+i*6,y,6,4),Color("eef0dcaa"))
