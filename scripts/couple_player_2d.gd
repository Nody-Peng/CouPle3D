class_name CouplePlayer2D
extends CharacterBody2D

const ASSET_ROOT := "res://assets/2d/packs/sunnyside_world_v2_1/Sunnyside_World_ASSET_PACK_V2.1/Sunnyside_World_Assets/Characters/Human/"

var player_name := "Player"
var player_color := Color.WHITE
var movement_keys: Array[int] = []
var interact_key := KEY_E
var can_move := true
var speed := 145.0

var _base := Sprite2D.new()
var _hair := Sprite2D.new()
var _name_label := Label.new()
var _walk_time := 0.0
var _moving := false
var _hair_style := "shorthair"


func setup(display_name: String, color: Color, keys: Array[int], action_key: int, hair_style: String) -> void:
	player_name = display_name
	player_color = color
	movement_keys = keys
	interact_key = action_key
	_hair_style = hair_style


func _ready() -> void:
	var collision := CollisionShape2D.new()
	var shape := CircleShape2D.new()
	shape.radius = 10.0
	collision.shape = shape
	collision.position = Vector2(0, 7)
	add_child(collision)
	add_child(_base)
	add_child(_hair)
	for sprite in [_base, _hair]:
		sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		sprite.scale = Vector2(3, 3)

	var shadow := Polygon2D.new()
	shadow.polygon = PackedVector2Array([Vector2(-15, 8), Vector2(-10, 4), Vector2(10, 4), Vector2(15, 8), Vector2(10, 12), Vector2(-10, 12)])
	shadow.color = Color(0.12, 0.16, 0.17, 0.3)
	shadow.z_index = -1
	add_child(shadow)

	_name_label.text = player_name
	_name_label.position = Vector2(-48, -47)
	_name_label.size = Vector2(96, 24)
	_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_name_label.add_theme_font_size_override("font_size", 15)
	_name_label.add_theme_color_override("font_color", player_color)
	_name_label.add_theme_color_override("font_shadow_color", Color(0.12, 0.13, 0.16, 0.9))
	_name_label.add_theme_constant_override("shadow_offset_x", 1)
	_name_label.add_theme_constant_override("shadow_offset_y", 2)
	add_child(_name_label)
	_set_animation(false)


func _physics_process(delta: float) -> void:
	z_index = int(position.y / 10.0)
	if not can_move or movement_keys.size() < 4:
		velocity = Vector2.ZERO
		return
	var direction := Vector2(
		float(Input.is_key_pressed(movement_keys[3])) - float(Input.is_key_pressed(movement_keys[2])),
		float(Input.is_key_pressed(movement_keys[1])) - float(Input.is_key_pressed(movement_keys[0]))
	).normalized()
	velocity = direction * speed
	move_and_slide()
	position.x = clampf(position.x, 70.0, 4250.0)
	position.y = clampf(position.y, 125.0, 790.0)

	var is_moving := direction.length_squared() > 0.0
	if is_moving != _moving:
		_moving = is_moving
		_set_animation(_moving)
	if _moving:
		_walk_time += delta
		var frame := int(_walk_time * 10.0) % 8
		_base.frame = frame
		_hair.frame = frame
		if absf(direction.x) > 0.05:
			_base.flip_h = direction.x < 0.0
			_hair.flip_h = direction.x < 0.0
	else:
		_walk_time += delta
		var frame := int(_walk_time * 4.0) % 9
		_base.frame = frame
		_hair.frame = frame


func _set_animation(walking: bool) -> void:
	var state := "WALKING" if walking else "IDLE"
	var suffix := "walk_strip8.png" if walking else "idle_strip9.png"
	_base.texture = load(ASSET_ROOT + state + "/base_" + suffix)
	_hair.texture = load(ASSET_ROOT + state + "/" + _hair_style + "_" + suffix)
	_base.hframes = 8 if walking else 9
	_hair.hframes = _base.hframes
	_base.frame = 0
	_hair.frame = 0
