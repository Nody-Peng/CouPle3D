extends "res://scripts/garden_cafe.gd"
## Three walk-in venues use a common accessible shell, with distinct architecture and working counters.
var venue := "bank"
func title_sign(text: String, p: Vector3, size := 42) -> void:
	host._label(self,text,p,size)
func obstacle(p: Vector3, size: Vector3) -> void:
	box(p,size,Color.TRANSPARENT,true).hide()
func point(id: String, name_text: String, p: Vector3) -> void:
	host._activity(id,name_text,"走到服務點按 E，開啟對應功能。",to_global(p))
func staff(p: Vector3, base: String, caption: String) -> void:
	var avatar := Node3D.new()
	avatar.set_script(load("res://scripts/couple_avatar.gd"))
	add_child(avatar)
	avatar.position = p
	avatar.rotation.y = PI
	avatar.apply_appearance({"base":base,"hat":"none","glasses":"glasses_round","bag":"none"})
	obstacle(p+Vector3(0,0.9,0),Vector3(1,1.8,1))
	title_sign(caption,p+Vector3(0,2.4,0),24)
func build(source: Node3D, p: Vector3, type: String = "bank") -> void:
	host = source
	venue = type
	position = p
	rotation.y = PI if p.z<0 else 0.0
	var accent: Color = {"bank":Color("476d69"),"shop":Color("b87782"),"home":Color("b88c61")}[venue]
	var name_text: String = {"bank":"一起銀行 · TOGETHER BANK","shop":"花漾百貨 · MAISON FLEUR","home":"生活選物 · OUR LIVING"}[venue]
	box(Vector3(0,0.025,0),Vector3(24,0.05,16),Color("dbd7c9") if venue=="bank" else Color("d4baa0"))
	for x in range(-11,12,2):
		box(Vector3(x,0.055,0),Vector3(0.025,0.01,16),Color("bcb6a5"))
	for z in range(-7,8,2):
		box(Vector3(0,0.057,z),Vector3(24,0.01,0.025),Color("bcb6a5"))
	box(Vector3(0,0.02,-10),Vector3(25,0.04,4),Color("ded4c2"))
	box(Vector3(0,0.027,-12.5),Vector3(4,0.055,2),Color("ded4c2"))
	# Solid rear wall, glazed sides and an unobstructed four-metre front entrance.
	box(Vector3(0,2.5,8),Vector3(24,5,0.25),PAPER,true)
	for x in [-12,12]:
		glass(Vector3(x,2.4,0),Vector3(0.08,4.8,16))
		obstacle(Vector3(x,2.4,0),Vector3(0.16,4.8,16))
		for z in [-8,-4,0,4,8]: box(Vector3(x,2.4,z),Vector3(0.22,4.8,0.22),accent)
	for side in [-1,1]:
		glass(Vector3(side*7,2.4,-8),Vector3(10,4.8,0.08))
		obstacle(Vector3(side*7,2.4,-8),Vector3(10,4.8,0.16))
		for x in [2,7,12]:
			box(Vector3(side*x,2.4,-8),Vector3(0.3,4.8,0.35),accent)
	box(Vector3(0,4.9,-8.4),Vector3(25,0.65,1.4),accent)
	title_sign(name_text,Vector3(0,5.3,-8.9),48)
	for x in [-11,11]: plant(Vector3(x,0,-10),true)
	roof = Node3D.new()
	add_child(roof)
	host._box(roof,Vector3(0,5.2,0),Vector3(24.8,0.4,17),PAPER)
	for z in [-7.8,7.8]: host._box(roof,Vector3(0,5.65,z),Vector3(24.8,0.5,0.25),accent)
	if venue=="bank":
		# Classical piers and a coin medallion distinguish the bank from the shops.
		for x in [-10,-6,6,10]:
			box(Vector3(x,2.4,-8.5),Vector3(0.65,4.8,0.65),PAPER,true)
			box(Vector3(x,0.18,-8.5),Vector3(0.95,0.36,0.95),PAPER)
			box(Vector3(x,4.6,-8.5),Vector3(0.95,0.3,0.95),PAPER)
		var seal: MeshInstance3D = host._cylinder(roof,Vector3(0,6.1,-8.3),0.85,0.2,Color("d5b96f"))
		seal.rotation.x = PI/2
		bank()
	elif venue=="shop":
		for x in range(-11,12): box(Vector3(x,4.5,-9.2),Vector3(0.8,0.13,2),PAPER if x%2==0 else accent)
		boutique()
	else:
		for x in range(-11,12,2): box(Vector3(x,4.5,-9.2),Vector3(0.13,0.22,2.2),WOOD)
		living()
	for x in [-9,9]: plant(Vector3(x,0,6.5),true)
func bank() -> void:
	# Two staffed teller desks, with screens and writing pads.
	for x in [-7,-3.5]:
		box(Vector3(x,0.55,2.8),Vector3(3,1.1,1.4),SAGE,true)
		box(Vector3(x,1.18,2.8),Vector3(3.2,0.16,1.6),PAPER)
		box(Vector3(x-0.5,1.52,3.0),Vector3(0.75,0.5,0.1),DARK)
		box(Vector3(x+0.55,1.3,2.4),Vector3(0.5,0.03,0.5),Color("e5d5ae"))
		staff(Vector3(x,0,4.2),"female-d" if x< -5 else "male-e","存款服務" if x< -5 else "共同帳戶")
	point("city_bank","一起銀行 · 共同存款",Vector3(-5,0,0.1))
	# ATM is a real account-history entry point, never a fake withdrawal control.
	box(Vector3(8,1.2,-5.4),Vector3(1.7,2.4,1),DARK,true)
	box(Vector3(8,1.85,-5.96),Vector3(1.2,0.65,0.07),Color("85b7b0"))
	box(Vector3(8,1.18,-5.98),Vector3(0.8,0.08,0.06),Color("cfb06b"))
	for x in [-0.22,0,0.22]:
		for y in [0.62,0.8,0.98]: box(Vector3(8+x,y,-5.98),Vector3(0.12,0.08,0.04),PAPER)
	title_sign("ATM · 帳戶查詢",Vector3(8,3,-5.4),24)
	point("bank_atm","ATM · 個人錢包明細",Vector3(8,0,-7.1))
	# Vault wall with a circular steel door, hinges, bolts and spoke wheel.
	box(Vector3(3,2.1,7.65),Vector3(4.8,4.2,0.35),Color("a2aaa4"))
	var door: MeshInstance3D = host._cylinder(self,Vector3(3,2.2,7.35),1.65,0.3,Color("657c7b"))
	door.rotation.x = PI/2
	for i in range(12):
		var a := TAU*i/12
		host._ball(self,Vector3(3+cos(a)*1.45,2.2+sin(a)*1.45,7.12),0.09,PAPER)
	for i in range(6):
		var a := TAU*i/6
		host._beam(self,Vector3(3,2.2,7.04),Vector3(3+cos(a)*0.65,2.2+sin(a)*0.65,7.04),0.09,Color("d4b774"))
	title_sign("共同金庫",Vector3(3,4.35,7.15),28)
	for z in [0,2.1,4.2]: chair(Vector3(8.5,0,z),PI/2)
	box(Vector3(6,0.7,1.5),Vector3(1.3,1.4,0.9),WOOD,true)
	box(Vector3(6,1.45,1.5),Vector3(1,0.06,0.6),PAPER)
	# Wall clock and restrained queue markers keep the central walking aisle clear.
	var clock_face: MeshInstance3D = host._cylinder(self,Vector3(-6,4.3,7.5),0.55,0.1,PAPER)
	clock_face.rotation.x = PI/2
	host._beam(self,Vector3(-6,4.3,7.4),Vector3(-6,4.67,7.4),0.04,DARK)
	host._beam(self,Vector3(-6,4.3,7.4),Vector3(-5.72,4.15,7.4),0.04,DARK)
	for x in [-8.8,-1.7]:
		host._cylinder(self,Vector3(x,0.55,0.5),0.07,1.1,Color("c6ad76"))
		host._cylinder(self,Vector3(x,0.05,0.5),0.25,0.1,DARK)
		obstacle(Vector3(x,0.6,0.5),Vector3(0.5,1.2,0.5))
	title_sign("一起存下日常的小夢想",Vector3(-5,3.15,7.5),28)
func boutique() -> void:
	for side in [-1,1]:
		for z in [-3,2]:
			var p := Vector3(side*7,0,z)
			host._cylinder(self,p+Vector3(0,0.14,0),1.45,0.28,PAPER)
			obstacle(p+Vector3(0,1,0),Vector3(2.4,2,2.4))
			var mannequin := Node3D.new()
			mannequin.set_script(load("res://scripts/couple_avatar.gd"))
			add_child(mannequin)
			mannequin.position = p+Vector3(0,0.3,0)
			mannequin.rotation.y = PI
			mannequin.apply_appearance({"base":"female-f" if side<0 else "male-d","hat":"hat_beret" if z<0 else "hat_bunny","glasses":"none","bag":"bag_daypack"})
	for y in [1,2,3]:
		box(Vector3(-7,y,7.3),Vector3(6,0.1,0.8),WOOD)
		for x in [-9,-7,-5]: host._ball(self,Vector3(x,y+0.16,7.3),0.32,Color("d398a4"))
	box(Vector3(5,0.55,5.8),Vector3(5,1.1,1.4),Color("b98089"),true)
	box(Vector3(5,1.18,5.8),Vector3(5.3,0.14,1.7),PAPER)
	staff(Vector3(5,0,7),"female-e","花漾造型師")
	for x in [-1.2,1.2]: box(Vector3(x,1.65,6.8),Vector3(0.12,3.3,0.2),WOOD)
	box(Vector3(0,1.65,6.85),Vector3(2.3,3.3,0.06),Color("bdd2cd"))
	point("city_shop","花漾百貨 · 配件選物",Vector3(0,0,-2.5))
	point("city_fitting","穿搭鏡 · 打開衣櫃",Vector3(0,0,4.5))
	title_sign("NEW SEASON · 每一天都有新樣子",Vector3(-6,4.2,7.2),26)
func living() -> void:
	# Living-room vignette: a sofa, rug, side tables, books and a reading lamp.
	box(Vector3(-6,0.065,0),Vector3(7,0.06,7),Color("c8b8a4"))
	box(Vector3(-6,0.6,2),Vector3(4.8,1.2,1.7),Color("c89397"),true)
	box(Vector3(-6,1.4,2.6),Vector3(4.8,1.2,0.35),Color("b47e85"))
	for x in [-8.1,-3.9]: box(Vector3(x,1.1,2),Vector3(0.5,1,1.8),Color("b47e85"))
	for x in [-7.1,-4.9]: box(Vector3(x,1.35,2.25),Vector3(1,0.65,0.23),PAPER)
	box(Vector3(-6,0.55,-0.5),Vector3(2.6,1.1,1.4),WOOD,true)
	for i in range(3): box(Vector3(-6,1.16+i*0.08,-0.5),Vector3(0.7,0.07,0.5),SAGE if i%2 else PAPER)
	for y in [0.5,1.5,2.5,3.5]:
		box(Vector3(7,y,6.8),Vector3(6,0.13,1),WOOD)
		for x in [5,6,7,8,9]: box(Vector3(x,y+0.38,6.8),Vector3(0.22,0.65,0.45),[PAPER,SAGE,Color("b9847c")][int(x)%3])
	table(Vector3(7,0,0))
	plant(Vector3(-9.5,0,5.8),true)
	point("city_home","生活選物 · 布置我們的家",Vector3(0,0,-2))
	point("city_furniture","家具目錄 · 挑選新家具",Vector3(5,0,3.8))
	title_sign("把喜歡的日常，帶回家",Vector3(0,3.8,7.4),32)

