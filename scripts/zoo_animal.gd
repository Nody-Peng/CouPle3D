extends Node3D
## Articulated toy animals: jointed gait, pauses, grazing, blinking and species-specific motion.
var host: Node3D
var kind := "panda"
var phase := 0.0
var clock := 0.0
var origin := Vector3.ZERO
var body: Node3D
var head: Node3D
var tail: Node3D
var legs: Array[Node3D] = []
var ears: Array[Node3D] = []
var eyes: Array[Node3D] = []
var route_angle := 0.0
var speed := 0.0
var roaming := 1.3

func blob(parent: Node3D, p: Vector3, size: Vector3, color: Color) -> MeshInstance3D:
	var mesh: MeshInstance3D = host._ball(parent,p,1.0,color)
	mesh.scale = size
	return mesh

func joint(parent: Node3D, p: Vector3) -> Node3D:
	var node := Node3D.new()
	parent.add_child(node)
	node.position = p
	return node

func build(source: Node3D, species: String, start: Vector3, index: int) -> void:
	host = source
	kind = species
	origin = start
	position = start
	phase = index*2.1
	route_angle = phase
	scale = Vector3.ONE*(0.78 if index==2 else 1.0)
	body = joint(self,Vector3.ZERO)
	var coat: Color = {"panda":Color("f0e8d8"),"giraffe":Color("e6bc70"),"rabbit":Color("ebdfcf"),"capybara":Color("a17c58"),"penguin":Color("334756"),"fox":Color("c9804c")}[kind]
	var height := 1.0
	var head_y := 1.6
	var head_z := 0.75
	if kind=="giraffe":
		height = 1.65
		head_y = 3.75
		head_z = 0.7
	elif kind=="capybara":
		height = 0.7
		head_y = 0.95
		head_z = 0.95
	elif kind=="penguin":
		height = 0.9
		head_y = 1.75
		head_z = 0.08
	elif kind=="fox":
		height = 0.8
		head_y = 1.25
	var size := Vector3(0.68,0.65,0.92)
	if kind=="capybara": size = Vector3(0.7,0.55,1.0)
	if kind=="penguin": size = Vector3(0.54,0.86,0.48)
	if kind=="fox": size = Vector3(0.48,0.46,0.82)
	blob(body,Vector3(0,height,0),size,coat)
	if kind=="panda":
		blob(body,Vector3(0,1.12,0.44),Vector3(0.7,0.57,0.3),Color("34404a"))
		blob(body,Vector3(0,0.98,0.73),Vector3(0.48,0.48,0.13),coat)
	if kind=="penguin": blob(body,Vector3(0,0.96,0.37),Vector3(0.4,0.65,0.15),Color("f7f0d8"))
	if kind=="giraffe":
		blob(body,Vector3(0,2.6,0.52),Vector3(0.26,1.16,0.3),coat).rotation.x = 0.12
		for side in [-1,1]:
			for i in range(7):
				blob(body,Vector3(side*(0.55+0.03*sin(i)),1.45+(i%2)*0.3,-0.6+i*0.18),Vector3(0.1,0.16,0.13),Color("a87540"))
			for i in range(4):
				blob(body,Vector3(side*0.24,2.15+i*0.35,0.56),Vector3(0.04,0.13,0.12),Color("a87540"))
	# Head and face rotate around the neck, keeping muzzle and ears together.
	head = joint(body,Vector3(0,head_y,head_z))
	var face := Vector3(0.53,0.5,0.48)
	if kind=="capybara": face = Vector3(0.49,0.38,0.65)
	if kind=="giraffe": face = Vector3(0.42,0.41,0.58)
	if kind=="fox": face = Vector3(0.46,0.43,0.47)
	blob(head,Vector3.ZERO,face,coat)
	var muzzle := Vector3(0, -0.16,face.z*0.9)
	blob(head,muzzle,Vector3(0.29,0.21,0.25),Color("d1b594") if kind=="capybara" else Color("f3e6ce"))
	if kind=="penguin":
		blob(head,Vector3(0,-0.08,0.5),Vector3(0.22,0.1,0.32),Color("d9a851"))
	else:
		blob(head,muzzle+Vector3(0,0.05,0.2),Vector3(0.11,0.075,0.08),Color("423e40"))
		for side in [-1,1]:
			blob(head,muzzle+Vector3(side*0.11,-0.055,0.21),Vector3(0.07,0.018,0.018),Color("9d7c72"))
	for side in [-1,1]:
		var eye_position := Vector3(side*0.25,0.04,face.z*0.91)
		if kind=="panda":
			var patch := blob(head,eye_position,Vector3(0.19,0.22,0.085),Color("303d47"))
			patch.rotation.z = side*0.25
		var eye := joint(head,eye_position+Vector3(0,0,0.08))
		blob(eye,Vector3.ZERO,Vector3(0.06,0.085,0.04),Color("202e35"))
		blob(eye,Vector3(-0.014,0.026,0.032),Vector3(0.02,0.025,0.012),Color.WHITE)
		eyes.append(eye)
		if kind!="penguin":
			var ear := joint(head,Vector3(side*face.x*0.78,face.y*0.75,0))
			var ear_size := Vector3(0.2,0.21,0.12)
			if kind=="rabbit": ear_size = Vector3(0.14,0.65,0.11)
			if kind=="fox": ear_size = Vector3(0.18,0.35,0.12)
			if kind=="giraffe": ear_size = Vector3(0.25,0.13,0.13)
			if kind=="fox":
				var outer: MeshInstance3D = host._cylinder(ear,Vector3(0,0.25,0),0.23,0.65,coat,0.0)
				outer.scale.z = 0.55
				var inner: MeshInstance3D = host._cylinder(ear,Vector3(0,0.26,0.09),0.14,0.45,Color("edd1b9"),0.0)
				inner.scale.z = 0.22
			else:
				blob(ear,Vector3(0,ear_size.y*0.6,0),ear_size,Color("35414b") if kind=="panda" else coat)
			if kind not in ["panda","fox"]: blob(ear,Vector3(0,ear_size.y*0.65,0.095),ear_size*Vector3(0.55,0.65,0.25),Color("d3a09a"))
			ear.rotation.z = -side*0.2
			ears.append(ear)
		if kind=="giraffe":
			host._cylinder(head,Vector3(side*0.17,0.58,-0.12),0.05,0.38,coat)
			blob(head,Vector3(side*0.17,0.78,-0.12),Vector3(0.08,0.08,0.08),Color("885f40"))
	# Each limb has a hip pivot and a foot; penguin flippers are articulated separately.
	for side in [-1,1]:
		for front in [-1,1]:
			if kind=="penguin" and front<0: continue
			var length := 1.35 if kind=="giraffe" else (0.45 if kind=="capybara" else 0.62)
			var leg := joint(body,Vector3(side*size.x*0.7,length,front*0.57 if kind!="penguin" else 0))
			var foot_color := Color("36434b") if kind=="panda" else coat
			if kind=="penguin": foot_color = Color("d9a851")
			blob(leg,Vector3(0,-length*0.44,0),Vector3(0.13 if kind=="giraffe" else 0.2,length*0.52,0.2),foot_color)
			blob(leg,Vector3(0,-length+0.12,0.12),Vector3(0.18 if kind=="giraffe" else 0.24,0.12,0.3),foot_color.darkened(0.1))
			legs.append(leg)
		if kind=="penguin":
			var wing := joint(body,Vector3(side*0.48,1.25,0))
			blob(wing,Vector3(side*0.12,-0.34,0),Vector3(0.12,0.46,0.24),coat)
			ears.append(wing)
	tail = joint(body,Vector3(0,height,-size.z*0.85))
	if kind=="fox":
		blob(tail,Vector3(0,0,-0.6),Vector3(0.33,0.32,0.7),coat)
		blob(tail,Vector3(0,0,-1.1),Vector3(0.24,0.25,0.32),Color("f4e6cb"))
	elif kind=="giraffe":
		blob(tail,Vector3(0,-0.25,-0.3),Vector3(0.06,0.4,0.06),coat)
		blob(tail,Vector3(0,-0.6,-0.3),Vector3(0.12,0.15,0.1),Color("885f40"))
	elif kind!="capybara": blob(tail,Vector3(0,0,-0.17),Vector3(0.22,0.22,0.23),coat)
	refine_features(coat)
	set_process(true)

func _process(delta: float) -> void:
	clock += delta
	var cycle := fmod(clock+phase,13.0)
	var moving := cycle<7.0
	speed = move_toward(speed,0.5 if moving else 0.0,delta*1.4)
	route_angle += speed*delta/roaming
	var target := origin+Vector3(sin(route_angle)*roaming,0,cos(route_angle)*roaming*0.5)
	var direction := target-position
	position = target
	if moving and direction.length()>0.001:
		rotation.y = lerp_angle(rotation.y,atan2(direction.x,direction.z),minf(delta*2.5,1.0))
	var gait := sin(clock*(7.0 if kind=="rabbit" else 4.0)+phase)
	body.position.y = absf(gait)*speed*(0.6 if kind=="rabbit" else 0.1)
	body.rotation.z = gait*speed*(0.16 if kind=="penguin" else 0.025)
	for i in range(legs.size()):
		legs[i].rotation.x = gait*speed*(0.9 if i%2==0 else -0.9)
	var eating := not moving and cycle>9.0
	head.rotation.x = lerpf(head.rotation.x,0.35+sin(clock*2)*0.05 if eating else sin(clock*0.9+phase)*0.05,delta*3)
	head.rotation.y = sin(clock*0.6+phase)*(0.2 if not moving else 0.07)
	tail.rotation.y = sin(clock*2+phase)*0.25
	for i in range(ears.size()):
		ears[i].rotation.z = (1 if i%2==0 else -1)*(0.2+sin(clock*(4 if kind=="penguin" else 1.8)+phase)*0.12)
	var blink := fmod(clock+phase,4.3)<0.13
	for eye in eyes: eye.scale.y = 0.12 if blink else 1.0


func refine_features(coat: Color) -> void:
	if kind=="giraffe":
		# A short mane follows the back of the neck; nostrils and split hooves clarify the silhouette.
		for i in range(9): blob(body,Vector3(0,1.9+i*0.18,0.19),Vector3(0.13,0.13,0.13),Color("97704a"))
		for side in [-1,1]: blob(head,Vector3(side*0.14,-0.14,0.68),Vector3(0.035,0.025,0.018),Color("745443"))
		for leg in legs:
			for side in [-1,1]: blob(leg,Vector3(side*0.07,-1.22,0.18),Vector3(0.07,0.085,0.17),Color("715a49"))
	elif kind=="fox":
		# Pale cheek ruffs, tapered muzzle and a fuller, tipped brush tail.
		for side in [-1,1]:
			for i in range(3): blob(head,Vector3(side*(0.26+i*0.065),-0.18-i*0.03,0.31),Vector3(0.12,0.09,0.15),Color("f3e7d2"))
		blob(body,Vector3(0,0.95,0.65),Vector3(0.3,0.31,0.14),Color("f3e7d2"))
	elif kind=="capybara":
		blob(head,Vector3(0,-0.1,0.57),Vector3(0.4,0.26,0.24),coat.lightened(0.06))
		for side in [-1,1]:
			blob(head,Vector3(side*0.2,0.02,0.76),Vector3(0.045,0.027,0.018),Color("614c3c"))
			for i in range(3): host._beam(head,Vector3(side*0.3,-0.12+i*0.035,0.65),Vector3(side*0.51,-0.15+i*0.07,0.7),0.012,Color("ddc4a3"))
	elif kind=="rabbit":
		for side in [-1,1]:
			blob(head,Vector3(side*0.2,-0.17,0.46),Vector3(0.18,0.16,0.12),Color("f7efe0"))
			for i in range(3): host._beam(head,Vector3(side*0.22,-0.13,0.54),Vector3(side*0.57,-0.2+i*0.09,0.57),0.012,Color("ae9789"))
		blob(head,Vector3(0,-0.22,0.68),Vector3(0.06,0.045,0.035),Color("d4a29f"))
	elif kind=="penguin":
		for side in [-1,1]:
			blob(head,Vector3(side*0.31,-0.1,0.34),Vector3(0.1,0.22,0.1),Color("f4edda"))
			for i in range(3): blob(body,Vector3(side*(0.35+i*0.07),1.18-i*0.07,-0.1),Vector3(0.13,0.2,0.16),coat.lightened(0.02*i))
	# Small toe divisions and brows add detail without changing the toy-like proportions.
	for leg in legs:
		if kind=="giraffe": continue
		var length := 0.45 if kind=="capybara" else 0.62
		for i in range(3): blob(leg,Vector3((i-1)*0.1,-length+0.13,0.36),Vector3(0.035,0.025,0.035),Color("ddcbbb") if kind=="panda" else coat.darkened(0.2))
	for side in [-1,1]: blob(head,Vector3(side*0.25,0.2,0.44),Vector3(0.09,0.025,0.025),coat.darkened(0.16))

