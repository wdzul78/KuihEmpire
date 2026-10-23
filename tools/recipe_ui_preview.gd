extends Node

func _ready() -> void:
	SaveManager.save_path = "user://recipe_preview_test.json"
	SaveManager.reset()
	run.call_deferred()

func shot(name: String) -> void:
	for frame in 6:
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var image := get_viewport().get_texture().get_image()
	var suffix := "_tall" if "--tall" in OS.get_cmdline_user_args() else ""
	image.save_png("res://.shots/recipe_" + name + suffix + ".png")

func run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://.shots"))
	var book := RecipeBookScreen.new()
	add_child(book)
	await shot("locked")
	for recipe in RecipeCatalog.all():
		RecipeBookManager.discover_recipe(recipe.id, "event")
	book.refresh()
	await shot("discovered")
	book._filter = &"sarawak_heritage"
	book._page = 0
	book.refresh()
	await shot("filter")
	book._select_mode("collections")
	await shot("collections")
	book._select_mode("guide")
	await shot("guide")
	RecipePresentation.show_detail(book, RecipeCatalog.find(&"onde_onde"))
	await shot("detail")
	book.free()
	book = RecipeBookScreen.new()
	add_child(book)
	RecipePresentation.present_pending(book)
	await shot("discovery")
	var popup := book.get_node("RecipeDiscoveryOverlay") as RecipePresentation
	for child in popup.find_children("*", "Button", true, false):
		if child is Button and child.text == RecipeText.text("view"):
			child.pressed.emit()
	await shot("discovery_detail")
	book.free()
	SaveManager.data.pending_recipe_presentations = []
	SaveManager.set_setting("language", "ms")
	book = RecipeBookScreen.new()
	add_child(book)
	await shot("malay")
	book.free()
	# Real stage-completion path; no victory moves so this stays deterministic.
	SaveManager.reset()
	GameManager.pending_tutorial_index = 0
	var controller := LevelController.new()
	controller.level_id = 10
	add_child(controller)
	controller.story.close()
	for order in controller.orders:
		for id in order.remaining:
			order.remaining[id] = 0
	controller.moves_left = 0
	controller._win()
	assert(RecipeBookManager.is_recipe_discovered(&"onde_onde"))
	assert(controller.has_node("RecipeDiscoveryOverlay"))
	await shot("stage10_win")
	controller.free()
	print("Recipe preview: PASS (book, collections, guide, detail, discovery, Malay and real stage-10 win)")
	get_tree().quit()
