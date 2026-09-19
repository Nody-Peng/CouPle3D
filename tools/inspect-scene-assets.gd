extends SceneTree

func _initialize() -> void:
	var source := Image.load_from_file("res://assets/2d/packs/sunnyside_world_v2_1/Sunnyside_World_ASSET_PACK_V2.1/Sunnyside_World_Assets/Tileset/spr_tileset_sunnysideworld_16px.png")
	for region in [Rect2i(328,176,128,64),Rect2i(472,192,32,32),Rect2i(240,272,80,128),Rect2i(0,144,96,96)]:
		var detail := source.get_region(region)
		detail.resize(detail.get_width()*4,detail.get_height()*4,Image.INTERPOLATE_NEAREST)
		detail.save_png("res://screenshots/atlas-%d-%d.png"%[region.position.x,region.position.y])
	quit()
