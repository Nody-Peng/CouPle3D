extends Node3D
## Reusable entrance VFX. Geometry and CPU particles work in Compatibility mode.
var tint := Color("7de8d6")
var rings: Array[MeshInstance3D] = []
var motes: Array[MeshInstance3D] = []
var time := 0.0
var active := false

func glow(alpha := 1.0) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(tint, alpha)
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.emission_enabled = true
	material.emission = tint
	return material

func _ready() -> void:
	for i in range(3):
		var ring := MeshInstance3D.new()
		var mesh := TorusMesh.new()
		mesh.inner_radius = 1.02 + i * 0.25
		mesh.outer_radius = mesh.inner_radius + (0.09 if i == 0 else 0.035)
		mesh.rings = 40
		mesh.ring_segments = 8
		ring.mesh = mesh
		ring.material_override = glow(0.8)
		ring.position.y = 0.1 + i * 0.025
		add_child(ring)
		rings.append(ring)
	for i in range(12):
		var mote := MeshInstance3D.new()
		var mesh := SphereMesh.new()
		mesh.radius = 0.055
		mesh.height = 0.11
		mesh.radial_segments = 6
		mesh.rings = 4
		mote.mesh = mesh
		mote.material_override = glow()
		add_child(mote)
		motes.append(mote)
	var particles := CPUParticles3D.new()
	particles.amount = 28
	particles.lifetime = 2.2
	particles.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	particles.emission_sphere_radius = 1.0
	particles.direction = Vector3.UP
	particles.spread = 8
	particles.gravity = Vector3(0,0.12,0)
	particles.initial_velocity_min = 0.5
	particles.initial_velocity_max = 1.3
	particles.scale_amount_min = 0.025
	particles.scale_amount_max = 0.055
	var particle_mesh := SphereMesh.new()
	particle_mesh.radius = 1
	particle_mesh.height = 2
	particle_mesh.radial_segments = 6
	particle_mesh.rings = 4
	particle_mesh.material = glow(0.65)
	particles.mesh = particle_mesh
	add_child(particles)
	var light := OmniLight3D.new()
	light.position.y = 1
	light.light_color = tint
	light.light_energy = 0.65
	light.omni_range = 4
	add_child(light)

func _process(delta: float) -> void:
	time += delta
	for i in rings.size():
		var pulse := 1.0 + sin(time*2.5-i*0.9)*0.045
		rings[i].scale = Vector3(pulse,1,pulse)
	for i in motes.size():
		var angle := time*(0.55 if active else 0.25) + TAU*i/motes.size()
		motes[i].position = Vector3(cos(angle)*1.35,0.2+fmod(time*0.45+i*0.16,1.8),sin(angle)*1.35)
