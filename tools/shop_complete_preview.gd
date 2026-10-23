extends Node

func _ready() -> void:
	SaveManager.save_path = "user://shop_complete_test.json"
	SaveManager.load_game()
	var screen := GeraiScreen.new()
	add_child(screen)
	await get_tree().create_timer(.6).timeout
	assert(screen._hotspots.get_child_count() == 0,"Completed tasks leave the shop view unobstructed")
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://.analysis/shop-complete-full-stall.png")
	screen._show_design()
	await get_tree().create_timer(.4).timeout
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://.analysis/shop-complete-owned-designs.png")
	screen.free()
	print("Complete shop preview: PASS (completed shop unobstructed, owned designs available)")
	get_tree().quit()
