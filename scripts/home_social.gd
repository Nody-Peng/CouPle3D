extends CanvasLayer

var home: Node
var connection: Node
var panel: PanelContainer
var body: VBoxContainer
var status: Label
var reader: TextEdit
var page := ""
var elapsed := 0.0
var poll_elapsed := 0.0
var added_furniture: Dictionary = {}
var last_invitation := ""
var remote_target := Vector2.ZERO

func _ready() -> void:
	home=get_parent()
	layer=60
	connection=preload("res://scripts/home_connection.gd").new()
	add_child(connection)
	connection.updated.connect(_state)
	connection.problem.connect(func(message): home._show_toast(message))
	status=Label.new()
	status.position=Vector2(800,857)
	status.add_theme_color_override("font_color",home.INK)
	status.text="本機試玩 · 尚未連線"
	add_child(status)
	connection.connection_changed.connect(func(ok):
		if not ok: status.text="連線中斷 · 等待恢復" )
	var nav:=HBoxContainer.new()
	nav.position=Vector2(400,23)
	nav.add_theme_constant_override("separation",8)
	add_child(nav)
	for item in [["連線","connect"],["聊天","chat"],["日記","diary"],["家具","shop"],["約會","date"],["抱抱","hug"],["默契","cards"],["合照","photo"]]:
		var key: String=item[1]
		var button: Button=home._make_button(item[0],home.TEAL)
		button.custom_minimum_size=Vector2(78,42)
		button.pressed.connect(func(): open(key))
		nav.add_child(button)
	panel=PanelContainer.new()
	panel.position=Vector2(300,185)
	panel.size=Vector2(840,530)
	panel.add_theme_stylebox_override("panel",home._panel_style(home.CREAM,home.TEAL,3,6))
	add_child(panel)
	body=VBoxContainer.new()
	var theme:=Theme.new()
	theme.default_font_size=18
	for type_name in ["LineEdit","TextEdit","OptionButton"]:
		for style_name in ["normal","read_only"]:
			theme.set_stylebox(style_name,type_name,home._panel_style(Color("fffaf0"),home.TEAL,1,4))
		theme.set_color("font_color",type_name,home.INK)
		theme.set_color("font_readonly_color",type_name,home.INK)
		theme.set_color("caret_color",type_name,home.INK)
		theme.set_color("font_placeholder_color",type_name,Color("777c79"))
	body.theme=theme
	body.add_theme_constant_override("separation",12)
	panel.add_child(body)
	panel.hide()

func _process(delta: float) -> void:
	elapsed+=delta
	poll_elapsed+=delta
	if connection.connected:
		var remote=home.players[1 if connection.identity=="a" else 0]
		var offset: Vector2=remote_target-remote.position
		remote.position=remote.position.lerp(remote_target,minf(delta*12,1))
		var moving: bool=offset.length()>1
		if remote._moving!=moving:
			remote._moving=moving
			remote._set_animation(moving)
		remote._base.frame=int(elapsed*(10 if moving else 4))%(8 if moving else 9)
		remote._hair.frame=remote._base.frame
		if absf(offset.x)>1:
			remote._base.flip_h=offset.x<0
			remote._hair.flip_h=offset.x<0
	if connection.cookie.is_empty() or connection.busy or poll_elapsed<0.4: return
	poll_elapsed=0
	var local=home.players[0 if connection.identity=="a" else 1]
	connection.send("/api/home2d",{"action":"position","x":local.position.x,"y":local.position.y})

func close() -> void:
	panel.hide()
	page=""
	_set_input()

func _set_input() -> void:
	for i in range(2):
		var remote: bool=not connection.cookie.is_empty() and i!=(0 if connection.identity=="a" else 1)
		home.players[i].can_move=not remote and not panel.visible and not home.note_panel.visible
		if connection.connected and not remote:
			home.players[i].movement_keys.assign([KEY_W,KEY_S,KEY_A,KEY_D])
			home.players[i].interact_key=KEY_E

func label(text: String) -> Label:
	var node:=Label.new()
	node.text=text
	node.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	node.add_theme_font_size_override("font_size",18)
	node.add_theme_color_override("font_color",home.INK)
	body.add_child(node)
	return node

func field(value: String, placeholder: String, secret:=false) -> LineEdit:
	var node:=LineEdit.new()
	node.text=value
	node.placeholder_text=placeholder
	node.secret=secret
	node.custom_minimum_size.y=40
	node.add_theme_font_size_override("font_size",18)
	body.add_child(node)
	return node

func button(title: String, action: Callable) -> Button:
	var node: Button=home._make_button(title,home.TEAL)
	node.pressed.connect(action)
	body.add_child(node)
	return node

func open(key: String) -> void:
	if home.note_panel.visible: return
	if key=="photo":
		close()
		visible=false
		home.get_node("HomeHUD").visible=false
		await RenderingServer.frame_post_draw
		if OS.has_feature("web"):
			var bytes: PackedByteArray=home.get_viewport().get_texture().get_image().save_png_to_buffer()
			JavaScriptBridge.download_buffer(bytes,"together-home.png","image/png")
			visible=true
			home.get_node("HomeHUD").visible=true
			home._show_toast("合照已交給瀏覽器下載")
			return
		var folder:=OS.get_system_dir(OS.SYSTEM_DIR_PICTURES).path_join("TogetherHome")
		var error:=DirAccess.make_dir_recursive_absolute(folder)
		if error==OK:
			var path:=folder.path_join("together-"+str(Time.get_unix_time_from_system()).replace(".","-")+".png")
			error=home.get_viewport().get_texture().get_image().save_png(path)
		visible=true
		home.get_node("HomeHUD").visible=true
		home._show_toast("合照已存到圖片資料夾 TogetherHome" if error==OK else "無法儲存合照")
		return
	for child in body.get_children():
		body.remove_child(child)
		child.queue_free()
	reader=null
	page=key
	panel.show()
	var row:=HBoxContainer.new()
	body.add_child(row)
	var title:=Label.new()
	title.text={"connect":"回到我們的家","chat":"兩個人的聊天","diary":"共同日記","shop":"生活選物","date":"下一次約會","hug":"想抱抱你","cards":"兩個人的默契卡"}.get(key,key)
	title.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	title.add_theme_color_override("font_color",home.INK)
	title.add_theme_font_size_override("font_size",24)
	row.add_child(title)
	var exit_button: Button=home._make_button("關閉",home.CORAL)
	exit_button.pressed.connect(close)
	row.add_child(exit_button)
	_set_input()
	if key=="connect":
		label("私人家園伺服器")
		var address:=field(connection.base_url,"https://你的伺服器網址")
		address.editable=not OS.has_feature("web")
		var code:=field("","私人通行碼",true)
		var nickname:=field("","你的暱稱")
		nickname.max_length=12
		var identity:=OptionButton.new()
		identity.add_item("我是第一位玩家")
		identity.add_item("我是第二位玩家")
		identity.custom_minimum_size.y=40
		body.add_child(identity)
		button("進入共同之家",func():
			await connection.login(address.text,code.text,"a" if identity.selected==0 else "b")
			if connection.connected and not nickname.text.strip_edges().is_empty():
				await connection.command({"action":"profile","name":nickname.text,"status":"在家"})
			if connection.connected: close())
		label("連線後，便條、日記與共同錢包使用伺服器的存檔。")
		return
	if not connection.connected:
		label("先連上共同之家，就能和另一台電腦共享這些內容。")
		button("連線",func(): open("connect"))
		return
	match key:
		"cards":
			var question=connection.last_state.get("question")
			if not question is Dictionary:
				label("輪流認識彼此，兩人都交卷後一起揭曉。")
				button("抽一張卡",func():
					if await connection.command({"action":"question"}): open("cards"))
			else:
				label(question.prompt)
				for id in question.answers:
					label(connection.last_state.profiles[id].name+"："+question.answers[id])
				if not question.answers.has(connection.identity):
					var answer:=field("","你的答案")
					answer.max_length=180
					button("交出答案",func():
						if await connection.command({"action":"answer","id":question.id,"text":answer.text}): open("cards"))
				elif question.answers.size()<2: label("已交卷，等伴侶的答案。")
				button("查看最新答案",func(): open("cards"))
				if question.answers.size()==2:
					button("下一張",func():
						if await connection.command({"action":"question"}): open("cards"))
		"chat", "diary":
			reader=TextEdit.new()
			reader.editable=false
			reader.custom_minimum_size=Vector2(760,235)
			reader.wrap_mode=TextEdit.LINE_WRAPPING_BOUNDARY
			body.add_child(reader)
			var entry:=field("","寫給彼此的話")
			entry.max_length=300 if key=="chat" else 800
			button("送出" if key=="chat" else "記下今天",func():
				if await connection.command({"action":key,"text":entry.text}): entry.clear())
			_state(connection.last_state)
		"shop":
			label("共同錢包購買，每件家具會擺在預留的位置。")
			for item in connection.last_state.catalog:
				var owned: bool=item.id in connection.last_state.owned
				var node:=button("%s · %s" % [item.name,"已擺好" if owned else str(int(item.price))+" 金幣"],func():
					if await connection.command({"action":"purchase","id":item.id}): open("shop"))
				node.icon=load(home.FURNITURE_ROOT+item.file)
				node.expand_icon=true
				node.add_theme_constant_override("icon_max_width",32)
				node.disabled=owned or connection.last_state.coins<int(item.price)
		"date":
			var saved=connection.last_state.get("date")
			var title_entry:=field(str(saved.title) if saved is Dictionary else "","約會名稱，例如週五一起看電影")
			var link:=field(str(saved.link) if saved is Dictionary else "","活動網址（可留空）")
			button("保存約會",func():
				if await connection.command({"action":"date","title":title_entry.text,"link":link.text}): home._show_toast("約會已保存"))
			button("開啟活動網址",func():
				if link.text.begins_with("https://") or link.text.begins_with("http://"): OS.shell_open(link.text))
		"hug":
			var invitation=connection.last_state.get("invitation")
			if invitation is Dictionary and invitation.status=="pending" and invitation.author!=connection.identity:
				label("伴侶想抱抱你。")
				for answer in [["好呀","accepted"],["今天先不要","declined"]]:
					var response: String=answer[1]
					button(answer[0],func():
						if await connection.command({"action":"respond","id":invitation.id,"answer":response}): close())
			else:
				label("送一張抱抱邀請，等對方願意時回應。")
				button("送出邀請",func():
					if await connection.command({"action":"invite"}): close())

func _state(state: Dictionary) -> void:
	home.saved_note=state.note
	home.shared_coins=int(state.coins)
	home._update_note_preview()
	home._update_coin_label()
	var other: String="b" if connection.identity=="a" else "a"
	status.text="已連線 · " + ("伴侶在家" if state.presence.has(other) else "伴侶尚未上線")
	var remote=home.players[1 if other=="b" else 0]
	for i in range(2):
		var profile: Dictionary=state.profiles["a" if i==0 else "b"]
		home.players[i].player_name=profile.name
		home.players[i]._name_label.text=profile.name
	remote.visible=state.presence.has(other)
	if remote.visible:
		remote_target=Vector2(state.presence[other].x,state.presence[other].y)
	if is_instance_valid(reader):
		var lines:=PackedStringArray()
		for entry in state.messages if page=="chat" else state.diary:
			lines.append("%s：%s" % [state.profiles[entry.author].name,entry.text])
		var content: String="\n\n".join(lines)
		if reader.text!=content: reader.text=content
	for item in state.catalog:
		if item.id in state.owned and not added_furniture.has(item.id):
			home._add_furniture(item.file,Vector2(item.x,item.y),4)
			added_furniture[item.id]=true
	var invitation=state.get("invitation")
	if invitation is Dictionary:
		var signature: String=invitation.id+invitation.status
		if signature!=last_invitation:
			last_invitation=signature
			if invitation.status=="accepted": home._show_toast("收到你的抱抱了。")
			elif invitation.status=="pending" and invitation.author!=connection.identity: home._show_toast("伴侶送來抱抱邀請，點「抱抱」回應")
	_set_input()
