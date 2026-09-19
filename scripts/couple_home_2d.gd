extends Node2D

const SAVE_PATH := "user://couple_home_2d.json"
const PLAYER_SCRIPT := preload("res://scripts/couple_player_2d.gd")
const FURNITURE_ROOT := "res://assets/2d/tilesets/house_interior/Furniture/"

const INK := Color("302f3f")
const CREAM := Color("fff4dc")
const PAPER := Color("f9e7bd")
const CORAL := Color("d96b67")
const TEAL := Color("4d9188")
const GOLD := Color("d8a84e")

var players: Array[Node] = []
var interactions := [
	{"id": "sofa", "title": "一起休息", "hint": "坐在沙發上，什麼都不做也很好。", "position": Vector2(330, 315)},
	{"id": "fridge", "title": "冰箱便條", "hint": "看看對方留下的話，或寫一張新的。", "position": Vector2(845, 280)},
	{"id": "table", "title": "一起吃飯", "hint": "把今天留一小段時間給彼此。", "position": Vector2(690, 470)},
	{"id": "desk", "title": "共享書桌", "hint": "在安靜的時候，也可以留一句話。", "position": Vector2(360, 650)},
	{"id": "bed", "title": "說晚安", "hint": "今天辛苦了，明天再一起玩。", "position": Vector2(810, 655)},
	{"id": "bath", "title": "泡個熱水澡", "hint": "休息也是今天重要的進度。", "position": Vector2(1060, 650)},
	{"id": "garden", "title": "照顧小庭院", "hint": "小花會等你們有空時再回來。", "position": Vector2(1275, 470)}
]

var shared_coins := 120
var saved_note := "歡迎回家。今天也很想你。"
var _note_author := ""
var _session_rewards: Dictionary = {}

var prompt_label: Label
var toast_label: Label
var coin_label: Label
var note_panel: PanelContainer
var note_text: TextEdit
var note_title: Label
var note_preview: Label
var social: Node
var editing_revision := 0
var area_camera: Camera2D
var current_area := 0
var view_zoom := 0.0
var action_button: Button
var action_player: Node

func _set_view_zoom(value: float) -> void:
	view_zoom = clampf(value,1.0,2.0) if value > 0 else 0.0

func _update_camera(local: Node, delta: float) -> void:
	var amount := view_zoom if view_zoom > 0 else (2.0 if current_area == 0 else 1.0)
	area_camera.zoom = Vector2.ONE*amount
	var half := Vector2(720,450)/amount
	var target := Vector2(clampf(local.position.x,current_area*1440+half.x,(current_area+1)*1440-half.x),clampf(local.position.y-25,half.y,900-half.y))
	if absf(area_camera.position.x-target.x)>720:
		area_camera.position=target
	else:
		area_camera.position=area_camera.position.lerp(target,1.0-exp(-10.0*delta))


func _ready() -> void:
	if has_node("/root/HUD"):
		get_node("/root/HUD").hide()
	_load_state()
	add_child(preload("res://scripts/home_scenery_2d.gd").new())
	_build_home()
	_build_players()
	_build_coast()
	interactions.append_array([
		{"id":"sink","title":"在流理台洗洗手","hint":"清水把一天的忙碌洗掉了。","position":Vector2(1044,300)},
		{"id":"stove","title":"煮一鍋熱湯","hint":"湯熱好了，留一碗給你。","position":Vector2(946,300)}])
	area_camera=Camera2D.new()
	area_camera.position=Vector2(720,450)
	add_child(area_camera)
	_build_ui()
	social=preload("res://scripts/home_social.gd").new()
	add_child(social)
	_update_note_preview()
	queue_redraw()




func _build_home() -> void:
	_add_wall_collision(Rect2(55, 105, 1110, 80))
	_add_wall_collision(Rect2(55, 792, 1110, 18))
	_add_wall_collision(Rect2(55, 105, 18, 705))
	_add_wall_collision(Rect2(1147, 105, 18, 295))
	_add_wall_collision(Rect2(1147, 490, 18, 320))
	_add_wall_collision(Rect2(610, 122, 16, 288))
	_add_wall_collision(Rect2(610, 485, 16, 307))
	_add_wall_collision(Rect2(72, 504, 183, 54))
	_add_wall_collision(Rect2(370, 504, 390, 54))
	_add_wall_collision(Rect2(875, 504, 95, 54))
	_add_wall_collision(Rect2(1080, 504, 68, 54))
	_add_wall_collision(Rect2(914, 520, 16, 272))
	_add_wall_collision(Rect2(1170,190,245,25))
	_add_wall_collision(Rect2(1390,190,24,207))
	_add_wall_collision(Rect2(1390,499,24,221))
	_add_wall_collision(Rect2(1170,682,245,25))
	for bed in [Rect2(1190,285,60,96),Rect2(1318,285,60,96),Rect2(1200,536,164,96)]:
		_add_wall_collision(bed)

	_add_room_label("客廳", Vector2(90, 130))
	_add_room_label("廚房", Vector2(635, 130))
	_add_room_label("書房", Vector2(90, 518))
	_add_room_label("臥室", Vector2(665, 518))
	_add_room_label("浴室", Vector2(1090, 518))

	add_child(preload("res://scripts/home_furnishings_2d.gd").new())
	_add_details()

func _build_coast() -> void:
	add_child(preload("res://scripts/sunnyside_town_2d.gd").new())



func _add_details() -> void:
	var root_path := "res://assets/2d/packs/sunnyside_world_v2_1/Sunnyside_World_ASSET_PACK_V2.1/Sunnyside_World_Assets/"
	for x in range(1218,1360,36):
		var crop := Sprite2D.new()
		crop.texture = load(root_path + "Elements/Crops/sunflower_05.png")
		crop.position = Vector2(x,566)
		crop.scale = Vector2(2,2)
		crop.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		crop.z_index = 58
		add_child(crop)
	for p in [Vector2(1220,172),Vector2(1360,173),Vector2(1340,758)]:
		var tree := Sprite2D.new()
		tree.texture = load(root_path + "Elements/Plants/spr_deco_tree_01_strip4.png")
		tree.hframes = 4
		tree.scale = Vector2(3,3)
		tree.position = p
		tree.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		tree.z_index = int(p.y/10)
		add_child(tree)


func _add_wall_collision(rect: Rect2) -> void:
	var body := StaticBody2D.new()
	var collision := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = rect.size
	collision.shape = shape
	body.position = rect.position + rect.size / 2.0
	body.add_child(collision)
	add_child(body)


func _add_room_label(text: String, pos: Vector2) -> void:
	var label := Label.new()
	label.text = text
	label.position = pos
	label.add_theme_font_size_override("font_size", 18)
	label.add_theme_color_override("font_color", Color("76535a"))
	add_child(label)


func _add_furniture(file_name: String, pos: Vector2, scale_value: float, flip_h := false) -> void:
	if file_name=="Chair.png":
		var chair=preload("res://scripts/pixel_furniture_2d.gd").new()
		chair.kind="chair"
		chair.width=30
		chair.height=45
		chair.position=(pos+Vector2(-15,-27)).snapped(Vector2.ONE*3)
		chair.z_index=int((pos.y+18)/10)
		add_child(chair)
		return
	scale_value=3.0
	var sprite := Sprite2D.new()
	sprite.texture = load(FURNITURE_ROOT + file_name)
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.position = pos
	sprite.scale = Vector2(scale_value, scale_value)
	sprite.flip_h = flip_h
	sprite.z_index = int(pos.y / 10.0)
	if file_name=="Television.png": sprite.z_index=31
	add_child(sprite)


func _build_players() -> void:
	var p1 = PLAYER_SCRIPT.new()
	p1.setup("你", Color("ffe09a"), [KEY_W, KEY_S, KEY_A, KEY_D], KEY_E, "longhair")
	p1.position = Vector2(420, 420)
	add_child(p1)
	players.append(p1)

	var p2 = PLAYER_SCRIPT.new()
	p2.setup("男朋友", Color("9ee3d6"), [KEY_UP, KEY_DOWN, KEY_LEFT, KEY_RIGHT], KEY_ENTER, "shorthair")
	p2.position = Vector2(500, 420)
	add_child(p2)
	players.append(p2)


func _build_ui() -> void:
	var layer := CanvasLayer.new()
	layer.name = "HomeHUD"
	layer.layer = 50
	add_child(layer)

	var top := ColorRect.new()
	top.color = Color("302f3f")
	top.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	top.custom_minimum_size.y = 92
	layer.add_child(top)

	var title := Label.new()
	title.text = "兩個人的座標"
	title.position = Vector2(34, 18)
	title.add_theme_font_size_override("font_size", 27)
	title.add_theme_color_override("font_color", CREAM)
	top.add_child(title)

	var subtitle := Label.new()
	subtitle.text = "我們的家  ·  今天不用趕路"
	subtitle.position = Vector2(36, 54)
	subtitle.add_theme_font_size_override("font_size", 16)
	subtitle.add_theme_color_override("font_color", Color("b9d9cf"))
	top.add_child(subtitle)

	coin_label = Label.new()
	coin_label.position = Vector2(1190, 26)
	coin_label.size = Vector2(210, 40)
	coin_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	coin_label.add_theme_font_size_override("font_size", 22)
	coin_label.add_theme_color_override("font_color", Color("f4cb68"))
	top.add_child(coin_label)
	_update_coin_label()

	var note_card := PanelContainer.new()
	note_card.position = Vector2(1185, 690)
	note_card.size = Vector2(210, 105)
	note_card.add_theme_stylebox_override("panel", _panel_style(PAPER, Color("76535a"), 3, 6))
	layer.add_child(note_card)
	note_preview = Label.new()
	note_preview.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	note_preview.add_theme_font_size_override("font_size", 15)
	note_preview.add_theme_color_override("font_color", Color("60464b"))
	note_card.add_child(note_preview)

	var help := Label.new()
	help.text = "共同之家"
	help.position = Vector2(32, 852)
	help.add_theme_font_size_override("font_size", 16)
	help.add_theme_color_override("font_color", INK)
	layer.add_child(help)

	prompt_label = Label.new()
	prompt_label.position = Vector2(410, 805)
	prompt_label.size = Vector2(620, 46)
	prompt_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	prompt_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	prompt_label.add_theme_font_size_override("font_size", 19)
	prompt_label.add_theme_color_override("font_color", CREAM)
	prompt_label.add_theme_stylebox_override("normal", _panel_style(Color("302f3fdd"), TEAL, 2, 8))
	layer.add_child(prompt_label)

	toast_label = Label.new()
	toast_label.position = Vector2(420, 110)
	toast_label.size = Vector2(600, 52)
	toast_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	toast_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	toast_label.add_theme_font_size_override("font_size", 18)
	toast_label.add_theme_color_override("font_color", INK)
	toast_label.add_theme_stylebox_override("normal", _panel_style(CREAM, GOLD, 3, 8))
	toast_label.hide()
	layer.add_child(toast_label)
	var zoom_bar := HBoxContainer.new()
	zoom_bar.position = Vector2(1110,818)
	zoom_bar.add_theme_constant_override("separation",6)
	layer.add_child(zoom_bar)
	for spec in [["−","縮小",-1.0],["+","放大",1.0],["全景","顯示整區",0.0],["跟隨","自動跟隨角色",0.0]]:
		var button := _make_button(spec[0],TEAL)
		button.custom_minimum_size=Vector2(52,40)
		button.tooltip_text=spec[1]
		button.focus_mode=Control.FOCUS_NONE
		var value: float=spec[2]
		var mode: String=spec[0]
		button.pressed.connect(func(): _set_view_zoom(1.0 if mode=="全景" else (0.0 if mode=="跟隨" else area_camera.zoom.x+value)))
		zoom_bar.add_child(button)
	action_button=_make_button("",TEAL)
	action_button.custom_minimum_size=Vector2(180,42)
	action_button.focus_mode=Control.FOCUS_NONE
	action_button.pressed.connect(func():
		if is_instance_valid(action_player): _try_interact(action_player))
	layer.add_child(action_button)
	action_button.hide()

	_build_note_dialog(layer)


func _build_note_dialog(layer: CanvasLayer) -> void:
	note_panel = PanelContainer.new()
	note_panel.position = Vector2(420, 205)
	note_panel.size = Vector2(600, 450)
	note_panel.add_theme_stylebox_override("panel", _panel_style(CREAM, Color("76535a"), 5, 10))
	layer.add_child(note_panel)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 16)
	note_panel.add_child(box)

	note_title = Label.new()
	note_title.text = "冰箱上的便條"
	note_title.add_theme_font_size_override("font_size", 25)
	note_title.add_theme_color_override("font_color", INK)
	box.add_child(note_title)

	var description := Label.new()
	description.text = "留一句對方下次回家時會看到的話。"
	description.add_theme_font_size_override("font_size", 16)
	description.add_theme_color_override("font_color", Color("76535a"))
	box.add_child(description)

	note_text = TextEdit.new()
	note_text.custom_minimum_size = Vector2(540, 245)
	note_text.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
	note_text.add_theme_font_size_override("font_size", 19)
	note_text.add_theme_color_override("font_color", INK)
	note_text.add_theme_stylebox_override("normal", _panel_style(Color("fffaf0"), Color("d8a84e"), 2, 5))
	box.add_child(note_text)

	var buttons := HBoxContainer.new()
	buttons.alignment = BoxContainer.ALIGNMENT_END
	buttons.add_theme_constant_override("separation", 12)
	box.add_child(buttons)
	var cancel := _make_button("稍後再寫", Color("846b70"))
	cancel.pressed.connect(_close_note)
	buttons.add_child(cancel)
	var save := _make_button("貼上便條", TEAL)
	save.pressed.connect(_save_note)
	buttons.add_child(save)
	note_panel.hide()


func _make_button(text: String, color: Color) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(140, 48)
	button.add_theme_font_size_override("font_size", 17)
	button.add_theme_color_override("font_color", CREAM)
	button.add_theme_stylebox_override("normal", _panel_style(color, color.darkened(0.25), 2, 6))
	button.add_theme_stylebox_override("hover", _panel_style(color.lightened(0.12), CREAM, 2, 6))
	button.add_theme_stylebox_override("pressed", _panel_style(color.darkened(0.12), CREAM, 2, 6))
	return button


func _panel_style(fill: Color, border: Color, width: int, radius: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(width)
	style.set_corner_radius_all(radius)
	style.content_margin_left = 16
	style.content_margin_right = 16
	style.content_margin_top = 12
	style.content_margin_bottom = 12
	return style


func _process(_delta: float) -> void:
	var local=players[0 if social.connection.identity=="a" else 1] if social.connection.connected else players[0]
	current_area=clampi(int(local.position.x/1440),0,2)
	_update_camera(local,_delta)
	note_preview.get_parent().visible = current_area == 0
	action_button.hide()
	if note_panel.visible:
		prompt_label.text = "正在寫便條"
		return
	var nearest_player: Node
	var nearest_interaction: Dictionary = {}
	var nearest_distance := 80.0
	for player in players:
		if int(player.position.x/1440) != current_area: continue
		if social.connection.connected and player != local: continue
		for interaction in interactions:
			var distance: float = player.position.distance_to(interaction.position)
			if distance < nearest_distance:
				nearest_distance = distance
				nearest_player = player
				nearest_interaction = interaction
	if nearest_interaction.is_empty():
		prompt_label.text = ["我們的家","花園與回家的路","兩個人的海邊"][current_area]
	else:
		var key_name := "E" if nearest_player == players[0] else "Enter"
		prompt_label.text = "%s：按 %s  ·  %s" % [nearest_player.player_name, key_name, nearest_interaction.title]
		if not social.panel.visible:
			action_player=nearest_player
			action_button.text=str(nearest_interaction.title)
			action_button.reset_size()
			var point: Vector2=get_global_transform_with_canvas()*nearest_interaction.position
			action_button.position=Vector2(clampf(point.x-action_button.size.x/2,16,1424-action_button.size.x),clampf(point.y-90,170,750))
			action_button.show()


func _unhandled_key_input(event: InputEvent) -> void:
	if not event.pressed or event.echo or note_panel.visible:
		return
	for player in players:
		if event.keycode == player.interact_key:
			if social.connection.connected and player!=players[0 if social.connection.identity=="a" else 1]: continue
			_try_interact(player)
			get_viewport().set_input_as_handled()
			return


func _try_interact(player: Node) -> void:
	if social.panel.visible: return
	if not social.connection.cookie.is_empty() and player!=players[0 if social.connection.identity=="a" else 1]: return
	var closest: Dictionary = {}
	var closest_distance := 80.0
	for interaction in interactions:
		var distance: float = player.position.distance_to(interaction.position)
		if distance < closest_distance:
			closest_distance = distance
			closest = interaction
	if closest.is_empty():
		_show_toast("再靠近一點，就能和家裡的東西互動。")
		return
	var id: String = closest.id
	if id in ["town_shop","town_cafe","town_post"]:
		social.open({"town_shop":"shop","town_cafe":"cards","town_post":"diary"}[id])
		return
	if id=="town_station":
		_show_toast("海風車站正在整備，旅行路線尚未開放。")
		return
	if id in ["sink","stove"]:
		get_node("HomeFurnishings").play_activity(id)
		_show_toast(str(closest.hint))
		return
	if id=="entry":
		player.position=Vector2(1100,448)
		return
	if id=="pier":
		social.open("photo")
		return
	if id in ["picnic","coast"]:
		_show_toast(str(closest.hint))
		return
	if id in ["fridge", "desk"]:
		_open_note(player.player_name, str(closest.title))
		return
	var reward := 10 if id == "garden" else 5
	if not social.connection.cookie.is_empty():
		if await social.connection.command({"action":"activity","id":id}): _show_toast(str(closest.hint))
		return
	if not _session_rewards.has(id):
		_session_rewards[id] = true
		shared_coins += reward
		_update_coin_label()
		_save_state()
		_show_toast("%s  +%d 共同金幣" % [closest.hint, reward])
	else:
		_show_toast(str(closest.hint))


func _open_note(author: String, source_title: String) -> void:
	if social.connection.connected: editing_revision=int(social.connection.last_state.revision)
	_note_author = author
	note_title.text = source_title
	note_text.text = saved_note
	note_panel.show()
	for player in players:
		player.can_move = false
	note_text.grab_focus()


func _close_note() -> void:
	note_panel.hide()
	social._set_input()


func _save_note() -> void:
	var clean_text := note_text.text.strip_edges()
	if clean_text.is_empty():
		_show_toast("便條還是空白的。")
		return
	if not social.connection.cookie.is_empty():
		if await social.connection.command({"action":"note","text":clean_text,"revision":editing_revision}):
			_close_note()
			_show_toast("便條已同步到共同之家")
		return
	saved_note = clean_text.left(180)
	_update_note_preview()
	_save_state()
	_close_note()
	_show_toast("%s 把便條貼好了。" % _note_author)


func _update_note_preview() -> void:
	if not is_instance_valid(note_preview):
		return
	var preview := saved_note.replace("\n", " ")
	if preview.length() > 54:
		preview = preview.left(54) + "…"
	note_preview.text = "冰箱便條\n“%s”" % preview


func _show_toast(message: String) -> void:
	toast_label.text = message
	toast_label.show()
	var tween := create_tween()
	tween.tween_interval(3.0)
	tween.tween_callback(toast_label.hide)


func _update_coin_label() -> void:
	coin_label.text = "共同錢包  %d" % shared_coins


func _load_state() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	var parsed = JSON.parse_string(file.get_as_text())
	if parsed is Dictionary:
		shared_coins = int(parsed.get("shared_coins", shared_coins))
		saved_note = str(parsed.get("note", saved_note))


func _save_state() -> void:
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	file.store_string(JSON.stringify({"shared_coins": shared_coins, "note": saved_note}, "\t"))
