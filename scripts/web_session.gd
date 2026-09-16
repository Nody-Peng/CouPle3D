extends Node
## The browser shell owns networking; Godot owns the 3D world and input.
var host: Node3D
var bridge: JavaScriptObject
var remote: Node3D
var remote_target := Vector3.ZERO
var remote_yaw := 0.0
var furnishings: Node3D
var paused := false
var last_state: Dictionary = {}
var furniture_signature := ""
var timer := 0.0
var local_id := ""
var preview_container: SubViewportContainer
var preview_avatar: Node3D
var preview_viewport: SubViewport

func _ready() -> void:
	host = get_parent()
	if OS.has_feature("web"):
		var window := JavaScriptBridge.get_interface("window")
		bridge = window.parent.togetherBridge
		if bridge:
			bridge.ready()

func _process(delta: float) -> void:
	if not is_instance_valid(host.player):
		return
	if bridge:
		var input = JSON.parse_string(bridge.input())
		if input is Dictionary:
			host.player.touch_input = Vector2(input.get("x",0),input.get("y",0))
			host.player.touch_sprint = bool(input.get("sprint",false))
		var list = JSON.parse_string(bridge.commands())
		if list is Array:
			for command in list:
				_handle(command)
		if paused:
			host.player.enabled = false
		timer += delta
		if timer >= 0.2:
			timer = 0
			bridge.position(JSON.stringify({"x":host.player.position.x,"z":host.player.position.z,"yaw":host.player.model.rotation.y,"scene":"home" if host.inside else "park","activity":host.current.get("title",""),"riding":host.player.riding,"night":host.night,"overview":host.overview}))
	if is_instance_valid(remote):
		var distance := remote.position.distance_to(remote_target)
		remote.position = remote.position.lerp(remote_target,minf(delta*10,1))
		remote.rotation.y = lerp_angle(remote.rotation.y,remote_yaw,delta*10)
		remote.ride_speed = minf(distance*10.0,9.0)
		remote.play_animation("walk" if distance>0.05 else "idle")

func activity(id: String, title: String, description: String) -> bool:
	if bridge:
		bridge.activity(id,title,description)
		return true
	return false

func rebuilt() -> void:
	furniture_signature = ""
	if not last_state.is_empty():
		_apply_state(last_state)

func _handle(command: Dictionary) -> void:
	match command.get("type",""):
		"state":
			last_state = command
			_apply_state(command)
		"avatar":
			host.player.model.apply_appearance(command.avatar)
			if is_instance_valid(preview_avatar):
				preview_avatar.apply_appearance(command.avatar)
		"wardrobe": _preview(command.value)
		"preview_turn":
			if is_instance_valid(preview_avatar): preview_avatar.rotation.y += float(command.angle)
		"recover":
			host.player.position = host.player.spawn_position
			host.player.velocity = Vector3.ZERO
		"layout": _furniture(command.layout,command.inventory)
		"pause":
			paused = command.value
			host.player.enabled = not paused
		"bicycle": host.player.toggle_bicycle()
		"map": host._action("map")
		"night": host._action("night")
		"camera_reset":
			host.camera_yaw = 0.45
			host.camera_zoom = 1.0
			host.overview = false
		"rotate_left": host.camera_yaw -= 0.3
		"rotate_right": host.camera_yaw += 0.3
		"zoom_in": host.camera_zoom = maxf(0.65,host.camera_zoom-0.1)
		"zoom_out": host.camera_zoom = minf(1.5,host.camera_zoom+0.1)
		"interact":
			var event := InputEventKey.new()
			event.physical_keycode = KEY_E
			event.pressed = true
			host._unhandled_input(event)
		"home":
			if not host.inside:
				host._travel(true)

func _apply_state(data: Dictionary) -> void:
	if data.has("user_id") and local_id != data.user_id:
		local_id = data.user_id
		host.player.position.x = -1.3 if local_id == "a" else 1.3
	host.player.model.apply_appearance(data.avatar)
	if is_instance_valid(preview_avatar):
		preview_avatar.apply_appearance(data.avatar)
	var partner: Dictionary = data.partner
	var p = partner.get("position")
	var should_show: bool = partner.get("online",false) and p is Dictionary
	if should_show:
		should_show = p.scene == ("home" if host.inside else "park")
	if should_show:
		if not is_instance_valid(remote):
			remote = Node3D.new()
			remote.set_script(load("res://scripts/couple_avatar.gd"))
			host.world.add_child(remote)
			remote.position = Vector3(p.x,0.05,p.z)
		remote.set_riding(p.get("riding",false))
		remote.visible = true
		remote.apply_appearance(partner.avatar)
		remote_target = Vector3(p.x,0.05,p.z)
		remote_yaw = p.get("yaw",0)
	elif is_instance_valid(remote):
		remote.hide()
	_furniture(data.layout,data.inventory)

func _furniture(layout: Array, inventory: Array) -> void:
	if not host.inside:
		return
	var signature := JSON.stringify([layout,inventory])
	if furniture_signature == signature and is_instance_valid(furnishings):
		return
	furniture_signature = signature
	if is_instance_valid(furnishings):
		furnishings.get_parent().remove_child(furnishings)
		furnishings.queue_free()
	furnishings = Node3D.new()
	host.world.add_child(furnishings)
	for placement in layout:
		var item := ""
		for entry in inventory:
			if entry.instance == placement.instance:
				item = entry.item
		var parent := Node3D.new()
		furnishings.add_child(parent)
		parent.position = Vector3(placement.x,0.12,placement.z)
		parent.rotation_degrees.y = -placement.rotation
		match item:
			"sofa_rose":
				host._box(parent,Vector3(0,0.5,0),Vector3(3,0.8,1.6),Color("d58088"),true)
				host._box(parent,Vector3(0,1.1,0.6),Vector3(3,1.2,0.25),Color("bb6c78"))
				for x in [-1.35,1.35]:
					host._box(parent,Vector3(x,0.9,0),Vector3(0.25,0.5,1.5),Color("bb6c78"))
			"table_oak":
				host._box(parent,Vector3(0,0.7,0),Vector3(1.5,0.2,1.5),Color("bc9670"),true)
				for x in [-0.5,0.5]:
					for z in [-0.5,0.5]:
						host._box(parent,Vector3(x,0.35,z),Vector3(0.12,0.7,0.12),Color("8e6c4d"))
			"plant_leaf":
				host._cylinder(parent,Vector3(0,0.3,0),0.35,0.6,Color("c7927a"))
				host._ball(parent,Vector3(0,0.9,0),0.4,Color("69a99e"))


func _preview(show_preview: bool) -> void:
	if not is_instance_valid(preview_container):
		var layer := CanvasLayer.new()
		layer.layer = 4
		add_child(layer)
		var root := Control.new()
		root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		root.mouse_filter = Control.MOUSE_FILTER_IGNORE
		layer.add_child(root)
		preview_container = SubViewportContainer.new()
		root.add_child(preview_container)
		preview_container.anchor_left = 0.05
		preview_container.anchor_right = 0.52
		preview_container.anchor_top = 0.16
		preview_container.anchor_bottom = 0.94
		preview_container.stretch = true
		preview_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
		preview_viewport = SubViewport.new()
		preview_viewport.transparent_bg = true
		preview_viewport.own_world_3d = true
		preview_container.add_child(preview_viewport)
		var environment := WorldEnvironment.new()
		var env := Environment.new()
		env.background_mode = Environment.BG_CLEAR_COLOR
		env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
		env.ambient_light_color = Color.WHITE
		env.ambient_light_energy = 0.65
		environment.environment = env
		preview_viewport.add_child(environment)
		var sun := DirectionalLight3D.new()
		sun.rotation_degrees = Vector3(-30,-30,0)
		sun.light_energy = 0.65
		preview_viewport.add_child(sun)
		preview_avatar = Node3D.new()
		preview_avatar.set_script(load("res://scripts/couple_avatar.gd"))
		preview_viewport.add_child(preview_avatar)
		preview_avatar.rotation_degrees.y = -15
		var camera := Camera3D.new()
		camera.projection = Camera3D.PROJECTION_ORTHOGONAL
		camera.size = 2.7
		preview_viewport.add_child(camera)
		camera.position = Vector3(0,1.2,4)
		camera.look_at(Vector3(0,0.85,0))
	preview_container.visible = show_preview
	preview_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS if show_preview else SubViewport.UPDATE_DISABLED
	if show_preview:
		preview_avatar.apply_appearance(host.player.model.appearance)
