extends Node2D
## One source pixel = three world pixels. Horizontal surfaces have visible depth.
var kind := "table"
var width := 144.0
var height := 66.0
const INK := Color("4b4654")
const WOOD := Color("bd8d68")
const LIGHT := Color("e2bb87")
const SHADE := Color("8b675a")

func box(x: float,y: float,w: float,h: float,color: Color) -> void:
	draw_rect(Rect2(x,y,w,h),color)

func _draw() -> void:
	box(6,height-9,width-6,12,Color("304d4938"))
	match kind:
		"table":
			for x in [9,width-18]:
				box(x,height-27,9,27,INK)
				box(x+3,height-24,3,21,SHADE)
			box(0,0,width,height-18,INK)
			box(3,3,width-6,height-30,LIGHT)
			box(3,height-27,width-6,6,WOOD)
			for x in range(15,int(width)-6,24): box(x,6,3,height-36,WOOD)
		"sofa":
			box(0,0,width,height-6,INK)
			box(6,3,width-12,21,Color("91bd95"))
			box(9,24,width-18,height-45,Color("699d84"))
			box(width/2,27,3,height-48,Color("47766e"))
			box(6,height-21,width-12,12,Color("47766e"))
			for x in [3,width-15]:
				box(x,18,12,height-27,Color("b0c69b"))
				box(x+3,height-9,6,9,INK)
		"chair":
			box(0,0,width,18,INK)
			box(3,3,width-6,9,LIGHT)
			box(0,18,width,15,INK)
			box(3,18,width-6,9,WOOD)
			for x in [3,width-9]: box(x,33,6,height-33,SHADE)
		"bath":
			box(6,0,width-12,height-9,INK)
			box(0,9,width,height-27,INK)
			box(6,6,width-12,height-21,Color("e5dec1"))
			box(12,12,width-24,height-33,Color("6b9da0"))
			box(18,18,width-36,height-42,Color("a5c6b4"))
			box(12,height-21,width-24,9,Color("b6b9a7"))
			box(width-24,6,6,18,INK)
			box(width-30,6,12,6,Color("c6d2c6"))
