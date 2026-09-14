extends Node3D
## Shared rig: complete looks plus bone-bound accessories.
var appearance: Dictionary = {}
var character: Node3D
var animation_player: AnimationPlayer
var attachments: Array[Node3D] = []
var current_animation := ""
var riding := false
var bicycle: Node3D
var wheels: Array[Node3D] = []
var pedal_time := 0.0
var ride_moving := false
var ride_speed := 0.0
var pedals: Array[Node3D] = []
const BASE_PATH := "res://assets/characters/kenney_mini-characters/Models/GLB format/character-"

func _ready() -> void:
	apply_appearance({"base":"female-a","hat":"none","glasses":"none","bag":"none"})

func apply_appearance(config: Dictionary) -> void:
	if config == appearance:
		return
	var base: String = config.get("base","female-a")
	if base not in ["female-a","female-b","female-c","female-d","female-e","female-f","male-a","male-b","male-c","male-d","male-e","male-f"]:
		base = "female-a"
	if not is_instance_valid(character) or appearance.get("base") != base:
		if is_instance_valid(character):
			remove_child(character)
			character.queue_free()
		attachments.clear()
		character = load(BASE_PATH+base+".glb").instantiate()
		add_child(character)
		character.scale = Vector3.ONE*2.0
		animation_player = character.find_child("AnimationPlayer",true,false)
		current_animation = ""
		if animation_player:
			for animation_name in ["idle","walk","sprint"]:
				if animation_player.has_animation(animation_name):
					animation_player.get_animation(animation_name).loop_mode = Animation.LOOP_LINEAR
	for node in attachments:
		if is_instance_valid(node):
			node.get_parent().remove_child(node)
			node.queue_free()
	attachments.clear()
	appearance = config.duplicate()
	var skeleton: Skeleton3D = character.find_child("Skeleton3D",true,false)
	if not skeleton:
		for candidate in character.find_children("*","Skeleton3D",true,false):
			skeleton = candidate
			break
	if skeleton:
		var head := _attach(skeleton,"head")
		_build_outfit(skeleton, str(config.get("outfit", "none")))
		_build_new_accessories(skeleton, head, config)
		if config.get("hat") == "hat_beret":
			_sphere(head,Vector3(0,0.39,0),Vector3(0.3,0.11,0.27),Color("d58088"))
			_sphere(head,Vector3(0.04,0.49,0),Vector3(0.04,0.035,0.04),Color("b56571"))
			for i in range(12):
				var angle := TAU*i/12
				_sphere(head,Vector3(cos(angle)*0.275,0.365,sin(angle)*0.24),Vector3(0.012,0.008,0.012),Color("efd4bb"))
			_sphere(head,Vector3(0.2,0.39,0.18),Vector3(0.035,0.035,0.012),Color("d8bb77"))
		elif config.get("hat") == "hat_bunny":
			_sphere(head,Vector3(0,0.36,0),Vector3(0.3,0.13,0.26),Color("eedfca"))
			for x in [-0.14,0.14]:
				_sphere(head,Vector3(x,0.64,0),Vector3(0.08,0.24,0.065),Color("eedfca"))
				_sphere(head,Vector3(x,0.64,0.055),Vector3(0.045,0.17,0.02),Color("d58088"))
		if config.get("glasses") == "glasses_round":
			for x in [-0.12,0.12]:
				var ring := TorusMesh.new()
				ring.inner_radius = 0.085
				ring.outer_radius = 0.104
				var glasses := _mesh(head,ring,Vector3(x,0.18,0.24),Color("d4af5e"))
				glasses.rotation.x = PI/2
			_box(head,Vector3(0,0.18,0.24),Vector3(0.055,0.018,0.02),Color("d4af5e"))
			for x in [-0.22,0.22]:
				_box(head,Vector3(x,0.18,0.12),Vector3(0.014,0.018,0.24),Color("d4af5e"))
		if config.get("bag") == "bag_daypack":
			var torso := _attach(skeleton,"torso")
			_box(torso,Vector3(0,0.05,-0.2),Vector3(0.32,0.33,0.18),Color("69a99e"))
			_box(torso,Vector3(0,-0.03,-0.3),Vector3(0.24,0.12,0.06),Color("3f8078"))
			for x in [-0.12,0.12]:
				_box(torso,Vector3(x,0.05,-0.305),Vector3(0.025,0.29,0.015),Color("b9d5c6"))
			_box(torso,Vector3(0,0.02,-0.336),Vector3(0.2,0.012,0.008),Color("d8bb77"))
			_box(torso,Vector3(0.065,0.005,-0.343),Vector3(0.015,0.035,0.012),Color("d8bb77"))
			_box(torso,Vector3(0,0.145,-0.296),Vector3(0.065,0.035,0.014),Color("efdfbf"))
			var handle := TorusMesh.new()
			handle.inner_radius = 0.036
			handle.outer_radius = 0.052
			_mesh(torso,handle,Vector3(0,0.235,-0.2),Color("3f8078")).rotation.x = PI/2
	play_animation("idle")
	if riding:
		character.position.y = 0.62
		if animation_player: animation_player.pause()

func _attach(skeleton: Skeleton3D, bone: String) -> BoneAttachment3D:
	var attachment := BoneAttachment3D.new()
	skeleton.add_child(attachment)
	attachment.bone_name = bone
	attachments.append(attachment)
	return attachment

func _mesh(parent: Node3D, mesh: Mesh, pos: Vector3, color: Color) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	node.mesh = mesh
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.8
	node.material_override = material
	parent.add_child(node)
	node.position = pos
	return node

func _box(parent: Node3D, pos: Vector3, size: Vector3, color: Color) -> void:
	var mesh := BoxMesh.new()
	mesh.size = size
	_mesh(parent,mesh,pos,color)

func _sphere(parent: Node3D, pos: Vector3, size: Vector3, color: Color) -> void:
	var mesh := SphereMesh.new()
	mesh.radial_segments = 12
	mesh.rings = 6
	mesh.radius = 1
	mesh.height = 2
	_mesh(parent,mesh,pos,color).scale = size

func play_animation(animation_name: String) -> void:
	ride_moving = animation_name != "idle"
	if riding: return
	if animation_player and current_animation != animation_name and animation_player.has_animation(animation_name):
		animation_player.play(animation_name,0.15)
		current_animation = animation_name


func set_riding(value: bool) -> void:
	if riding==value: return
	riding = value
	if value and not is_instance_valid(bicycle): _build_bicycle()
	if is_instance_valid(bicycle): bicycle.visible = value
	character.position.y = 0.62 if value else 0.0
	if animation_player:
		animation_player.play("idle")
		animation_player.advance(0)
		if value: animation_player.pause()
	current_animation = "idle"

func _tube(parent: Node3D, a: Vector3, b: Vector3, radius: float, color: Color) -> void:
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = a.distance_to(b)
	var node := _mesh(parent,mesh,(a+b)/2,color)
	node.quaternion = Quaternion(Vector3.UP,(b-a).normalized())

func _build_bicycle() -> void:
	bicycle = Node3D.new()
	add_child(bicycle)
	for z in [-0.67,0.67]:
		var wheel := Node3D.new()
		bicycle.add_child(wheel)
		wheel.position = Vector3(0,0.36,z)
		wheels.append(wheel)
		var tire := TorusMesh.new()
		tire.inner_radius = 0.28
		tire.outer_radius = 0.35
		_mesh(wheel,tire,Vector3.ZERO,Color("384344")).rotation.z = PI/2
		for i in range(10):
			var a := TAU*i/10
			_tube(wheel,Vector3.ZERO,Vector3(0,cos(a)*0.29,sin(a)*0.29),0.009,Color("c9c7b5"))
	var back := Vector3(0,0.36,-0.67)
	var crank := Vector3(0,0.36,-0.03)
	var seat := Vector3(0,0.88,-0.22)
	var neck := Vector3(0,0.88,0.42)
	var front := Vector3(0,0.36,0.67)
	for pair in [[back,seat],[seat,crank],[crank,back],[seat,neck],[neck,crank],[neck,front]]:
		_tube(bicycle,pair[0],pair[1],0.035,Color("73a99d"))
	_tube(bicycle,seat,seat+Vector3(0,0.13,0),0.025,Color("d6c7a6"))
	_box(bicycle,seat+Vector3(0,0.15,0),Vector3(0.31,0.09,0.28),Color("805f49"))
	_tube(bicycle,neck,Vector3(0,1.15,0.47),0.025,Color("d6c7a6"))
	_tube(bicycle,Vector3(-0.34,1.15,0.47),Vector3(0.34,1.15,0.47),0.03,Color("805f49"))
	for x in [-0.21,0.21]:
		var pedal := Node3D.new()
		bicycle.add_child(pedal)
		pedal.position = Vector3(x,0.36,-0.03)
		pedals.append(pedal)
		_tube(pedal,Vector3.ZERO,Vector3(0,-0.13,0),0.018,Color("d6c7a6"))
		_box(pedal,Vector3(0,-0.13,0),Vector3(0.19,0.05,0.15),Color("384344"))

func _process(delta: float) -> void:
	if not riding: return
	if ride_speed>0.05:
		pedal_time += delta*ride_speed*1.3
		for wheel in wheels: wheel.rotation.x += delta*ride_speed/0.35
	for i in range(pedals.size()): pedals[i].rotation.x = pedal_time+i*PI
	var skeleton: Skeleton3D = character.find_child("Skeleton3D",true,false)
	if not skeleton:
		for candidate in character.find_children("*","Skeleton3D",true,false):
			skeleton = candidate
			break
	if skeleton:
		for bone in ["leg-left","leg-right","arm-left","arm-right"]:
			var index := skeleton.find_bone(bone)
			if index<0: continue
			var angle := -0.8
			if bone.begins_with("leg"):
				angle = -0.65+sin(pedal_time+(PI if bone=="leg-left" else 0))*0.35
			if bone.begins_with("arm"):
				var side := 1.0 if bone=="arm-left" else -1.0
				skeleton.set_bone_pose_rotation(index,Quaternion(Vector3.UP,-side*1.1)*Quaternion(Vector3.BACK,-side*0.55))
			else:
				skeleton.set_bone_pose_rotation(index,Quaternion(Vector3.RIGHT,angle))

# Garments follow the existing torso rig and leave the legs free for cycling.
func _build_outfit(skeleton: Skeleton3D, outfit: String) -> void:
	var palettes := {"outfit_cream":"ead9b9", "outfit_rose":"c87989", "outfit_sailor":"f1e9d8", "outfit_mint":"d9ceb4", "outfit_lilac":"a293bb", "outfit_cocoa":"92725e"}
	if not palettes.has(outfit): return
	var torso := _attach(skeleton, "torso")
	var color := Color(palettes[outfit])
	var trim := Color("f6ead5")
	var garment := CylinderMesh.new()
	garment.top_radius = 0.19
	garment.bottom_radius = 0.21
	garment.height = 0.23
	garment.radial_segments = 12
	_mesh(torso, garment, Vector3(0,0.065,0.012), color).scale.z = 0.83
	for x in [-0.047,0.047]:
		_box(torso,Vector3(x,0.16,0.16),Vector3(0.067,0.028,0.022),Color("526984") if outfit == "outfit_sailor" else trim)
		_box(torso,Vector3(x,0.018,0.181),Vector3(0.048,0.036,0.012),color.lightened(0.15))
	for y in [0.035,0.075,0.11]:
		_sphere(torso,Vector3(0,y,0.183),Vector3(0.009,0.009,0.006),Color("d6b56f"))
	if outfit == "outfit_mint":
		_box(torso,Vector3(0,0.18,0.14),Vector3(0.20,0.044,0.085),Color("78aaa0"))
		_box(torso,Vector3(0.055,0.082,0.188),Vector3(0.045,0.13,0.022),Color("78aaa0"))
	if outfit in ["outfit_lilac","outfit_sailor"]:
		_bow(torso,Vector3(0,0.116,0.193),Color("526984") if outfit == "outfit_sailor" else Color("f6ead5"),0.45)

func _bow(parent: Node3D, pos: Vector3, color: Color, size: float) -> void:
	for side in [-1,1]:
		_sphere(parent,pos+Vector3(side*0.052*size,0,0),Vector3(0.058,0.038,0.02)*size,color)
		_box(parent,pos+Vector3(side*0.035*size,-0.04*size,-0.005),Vector3(0.03,0.065,0.016)*size,color)
	_sphere(parent,pos,Vector3(0.023,0.023,0.025)*size,color.lightened(0.15))

func _build_new_accessories(skeleton: Skeleton3D, head: Node3D, config: Dictionary) -> void:
	if config.get("hat") == "hat_bow":
		_bow(head,Vector3(0.16,0.35,0.15),Color("c87989"),1.0)
	if config.get("hat") == "hat_flower":
		for i in range(7):
			var angle := PI*float(i)/6.0
			var center := Vector3(cos(angle)*0.2,0.34+sin(angle)*0.055,0.14)
			_sphere(head,center+Vector3(0,-0.018,-0.01),Vector3(0.04,0.012,0.02),Color("78aaa0"))
			for petal in range(5):
				var a := TAU*float(petal)/5.0
				_sphere(head,center+Vector3(cos(a)*0.023,sin(a)*0.023,0),Vector3(0.018,0.018,0.009),Color("fff3d9"))
			_sphere(head,center+Vector3(0,0,0.008),Vector3(0.012,0.012,0.009),Color("d8b562"))
	if config.get("bag") == "bag_satchel":
		var torso := _attach(skeleton,"torso")
		_tube(torso,Vector3(-0.08,0.15,0.14),Vector3(0.16,-0.015,0.14),0.009,Color("775b48"))
		_box(torso,Vector3(0.16,-0.018,0.09),Vector3(0.12,0.10,0.08),Color("b58a64"))
		_box(torso,Vector3(0.16,0.005,0.135),Vector3(0.125,0.045,0.015),Color("92725e"))
		_sphere(torso,Vector3(0.16,-0.012,0.148),Vector3(0.012,0.012,0.006),Color("d8b562"))
