extends Node3D
## Landmark entry with a clear central arrival route, layered masonry and illuminated heart crest.
func build(host: Node3D) -> void:
	position = Vector3(0,0,39)
	var stone := Color("ebddc5")
	var green := Color("416f69")
	var brass := Color("cfa967")
	for r in [9.8,8.8,7.9]:
		host._cylinder(self,Vector3(0,0.028+(10-r)*0.006,-4),r,0.018,stone if r!=8.8 else brass)
	for side in [-1,1]:
		var x: float = side*7.3
		host._box(self,Vector3(x,0.25,0),Vector3(2.5,0.5,2.5),stone,true)
		host._box(self,Vector3(x,2.9,0),Vector3(1.65,5.4,1.65),stone,true)
		for y in [0.6,1.1,4.9,5.4]: host._box(self,Vector3(x,y,0),Vector3(1.95,0.2,1.95),brass)
		for dx in [-0.53,0.53]: host._box(self,Vector3(x+dx,3,0.85),Vector3(0.1,3.4,0.1),brass)
		host._box(self,Vector3(x,5.9,0),Vector3(2.3,0.7,2.3),green)
		host._cylinder(self,Vector3(x,6.5,0),0.72,0.5,brass,0.3)
		host._ball(self,Vector3(x,7,0),0.35,Color("ffe0a0")).material_override = host._material(Color("ffe0a0"),true)
		# Lanterns on either face make the entrance welcoming from both directions.
		for z in [-1.1,1.1]:
			host._box(self,Vector3(x,3.3,z),Vector3(0.5,0.8,0.35),green)
			host._box(self,Vector3(x,3.3,z+signf(z)*0.19),Vector3(0.3,0.55,0.04),Color("ffe3a4")).material_override=host._material(Color("ffe3a4"),true)
		for i in range(5):
			var px: float = side*(9+i*0.7)
			host._cylinder(self,Vector3(px,0.9,0),0.045,1.8,green)
			host._ball(self,Vector3(px,1.83,0),0.09,brass)
		for y in [0.4,1.35]: host._beam(self,Vector3(side*8.5,y,0),Vector3(side*12,y,0),0.07,green)
		host._collider(Vector3(side*10.4,1.1,39),Vector3(3.4,2.2,0.3))
		host._flowerbed(Vector3(side*11,0,36.5),Vector2(3,2.2))
		# Layered topiary rather than extra obstacles in the arrival corridor.
		host._cylinder(self,Vector3(side*11,0.45,-0.9),0.6,0.9,stone)
		for y in [1.2,1.75,2.2]: host._ball(self,Vector3(side*11,y,-0.9),0.65-(y-1.2)*0.25,Color("7d9c79"))
	# Swept arch: the lowest structural element is well above character height.
	for i in range(48):
		var x1 := -7.3+14.6*i/48
		var x2 := -7.3+14.6*(i+1)/48
		var a := Vector3(x1,5.5+2.1*(1-pow(x1/7.3,2)),0)
		var b := Vector3(x2,5.5+2.1*(1-pow(x2/7.3,2)),0)
		host._beam(self,a,b,0.42,green)
		host._beam(self,a+Vector3(0,0.28,0),b+Vector3(0,0.28,0),0.1,brass)
		if i%4==0: host._ball(self,a+Vector3(0,-0.22,0.24),0.085,Color("ffdda0")).material_override=host._material(Color("ffdda0"),true)
	host._box(self,Vector3(0,5.4,0),Vector3(10.2,1.35,0.55),green)
	for y in [4.72,6.08]: host._box(self,Vector3(0,y,0),Vector3(10.4,0.09,0.65),brass)
	for side in [-1,1]:
		var label := Label3D.new()
		label.font = host.font
		label.text = "心 動 之 城"
		label.font_size = 96
		label.pixel_size = 0.014
		label.modulate = stone
		label.outline_size = 2
		label.outline_modulate = green
		label.position = Vector3(0,5.55,side*0.31)
		label.rotation.y = PI if side<0 else 0.0
		add_child(label)
		var sub := label.duplicate()
		sub.text = "T O G E T H E R   C I T Y"
		sub.font_size = 28
		sub.position.y = 4.99
		add_child(sub)
	for i in range(48):
		var t := TAU*i/48
		var p := Vector3(pow(sin(t),3)*0.95,8.7+(13*cos(t)-5*cos(2*t)-2*cos(3*t)-cos(4*t))*0.06,0)
		host._ball(self,p,0.1,Color("d49698"))

