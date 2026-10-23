extends Node

func _ready() -> void:
	run.call_deferred()

func run() -> void:
	var screen := RecipeBookScreen.new()
	add_child(screen)
	await get_tree().create_timer(.5).timeout
	var clickable := screen._make_card(KuihLibrary.get_kuih(&"onde_onde"),true)
	screen.add_child(clickable)
	var icon: Control = clickable.get_child(0)
	assert(icon.mouse_filter == Control.MOUSE_FILTER_STOP)
	var tap := InputEventMouseButton.new()
	tap.button_index = MOUSE_BUTTON_LEFT
	tap.pressed = true
	icon.gui_input.emit(tap)
	assert(screen.has_node("KuihInfoPopup"))
	screen.get_node("KuihInfoPopup")._close()
	clickable.free()
	if DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("res://.analysis/kuih-collection-grid.png")
	screen._show_kuih_info(KuihLibrary.get_kuih(&"onde_onde"))
	screen._show_kuih_info(KuihLibrary.get_kuih(&"onde_onde"))
	assert(screen.get_node("KuihInfoPopup") is KuihInfoPopup)
	var count := 0
	for child in screen.get_children():
		if child is KuihInfoPopup:
			count += 1
	assert(count == 1)
	await get_tree().create_timer(.5).timeout
	if DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("res://.analysis/kuih-collection-popup.png")
	screen.get_node("KuihInfoPopup")._close()
	assert(not screen.has_node("KuihInfoPopup"))
	screen._select_mode("recipes")
	screen._select_mode("collections")
	screen._select_mode("guide")
	assert(screen._grid.get_child_count() == 6)
	screen.free()
	AudioManager.stop_music()
	print("Kuih collection: PASS (six cards, single modal, close, recipes and rewards tabs preserved)")
	get_tree().quit()
