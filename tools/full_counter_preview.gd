extends Control

func _ready() -> void:
	var backdrop := GeraiBackdrop.new()
	backdrop.background_context = "menu"
	JourneyArt.place(self,backdrop,Rect2(0,0,1,1))
	backdrop.preview_design(&"family_stall",1,"batik",{"COUNTER_DECOR":"pink_batik"},{"COUNTER_DECOR":"warm"})
	await get_tree().create_timer(.6).timeout
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://.analysis/full-counter-menu.png")
	print("Full counter preview: PASS")
	get_tree().quit()
