extends Control
## Actual world coordinates projected onto a compact, always-visible park map.
var source: Node3D

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func _process(_delta: float) -> void:
	queue_redraw()

func _draw() -> void:
	if not is_instance_valid(source) or not is_instance_valid(source.player):
		return
	var extent := Vector2(42,36) if source.inside else Vector2(304,112)
	var rect := Rect2(Vector2(12,12),size-Vector2(24,24))
	draw_style_box(_background(), Rect2(Vector2.ZERO,size))
	draw_rect(rect,Color("5c7e76"))
	var center := rect.get_center()
	if not source.inside:
		draw_line(Vector2(center.x,rect.position.y),Vector2(center.x,rect.end.y),Color("dbcdb4"),9)
		draw_line(Vector2(rect.position.x,center.y+7),Vector2(rect.end.x,center.y+7),Color("dbcdb4"),7)
	if source.inside:
		for x in [-14,0,14]:
			for z in [-10,10]:
				var room_pos := center+Vector2(x-6.5,z-7.5)/extent*rect.size
				draw_rect(Rect2(room_pos,Vector2(13,15)/extent*rect.size),Color("baa88d"),false,1.5)
	else:
		var house_pos := center+Vector2(-30,17)/extent*rect.size
		draw_rect(Rect2(house_pos-Vector2(8,6),Vector2(16,12)),Color("88d9cb"))
	for activity in source.activities:
		var p := center+Vector2(activity.position.x,activity.position.z)/extent*rect.size
		draw_circle(p,3.5,Color("f4d48b") if activity.destination == "" else Color("88f5e1"))
	var player_pos := center+Vector2(source.player.position.x,source.player.position.z)/extent*rect.size
	draw_circle(player_pos,5,Color.WHITE)
	draw_arc(player_pos,7,0,TAU,20,Color("263e49"),2)

func _background() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color("263e49")
	style.set_corner_radius_all(12)
	return style



