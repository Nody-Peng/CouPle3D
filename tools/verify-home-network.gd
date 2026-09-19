extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var home=load("res://scenes/CoupleHome2D.tscn").instantiate()
	root.add_child(home)
	home.social.set_process(false)
	var a=home.social.connection
	var b=load("res://scripts/home_connection.gd").new()
	root.add_child(b)
	await a.login(OS.get_environment("HOME_TEST_URL"),"private-test","a")
	await b.login(OS.get_environment("HOME_TEST_URL"),"private-test","b")
	if not a.connected or not b.connected:
		push_error("Login failed")
		quit(1)
		return
	await a.command({"action":"note","revision":a.last_state.revision,"text":"Godot network verified"})
	await b.send("/api/home2d")
	if b.last_state.note!="Godot network verified":
		quit(1)
		return
	await b.command({"action":"chat","text":"Hello from second client"})
	await a.send("/api/home2d")
	home.social.open("chat")
	if not home.social.reader.text.contains("Hello from second client"):
		quit(1)
		return
	for page in ["shop","date","hug","cards","diary"]:
		home.social.open(page)
		await process_frame
		if OS.get_environment("HOME_CAPTURE")=="1":
			await create_timer(0.5).timeout
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png("res://screenshots/home-"+page+".png")
	print("PASS: two Godot HTTP clients, cookies, note/chat sync and social panels")
	quit()
