extends Control

func _ready() -> void:
	var backdrop := GeraiBackdrop.new()
	JourneyArt.place(self,backdrop,Rect2(0,0,1,1))
	var hud := HUD.new()
	JourneyArt.place(self,hud,Rect2(0,0,1,1))
	hud.set_stage(18,"Long Order")
	hud.set_moves(28,28)
	hud.configure_score(LevelLibrary.get_level(18))
	hud.set_score(12345)
	hud.set_queue([CustomerLibrary.get_customer(&"kakak"),CustomerLibrary.get_customer(&"abang")])
	await get_tree().create_timer(.6).timeout
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://.analysis/hud-header-fit.png")
	print("HUD header preview: PASS")
	get_tree().quit()
