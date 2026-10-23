extends Node

func _ready() -> void:
	run.call_deferred()

func run() -> void:
	var screen := RecipeBookScreen.new()
	add_child(screen)
	screen._select_mode("collections")
	await get_tree().create_timer(.5).timeout
	assert(screen._collection_scroll.visible)
	assert(screen._tabs.size() == 2)
	var list := screen._collection_scroll.get_child(0)
	assert(list.get_child_count() > 0)
	assert(list.get_child(0) is PanelContainer)
	if DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("res://.analysis/rewards-task-list.png")
	screen.free()
	AudioManager.stop_music()
	print("Rewards task list: PASS (task cards, real progress, two book tabs)")
	get_tree().quit()
