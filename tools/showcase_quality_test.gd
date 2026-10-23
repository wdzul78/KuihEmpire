extends Node

func _ready() -> void:
	SaveManager.save_path = "user://showcase_quality_test.json"
	SaveManager.reset()
	run.call_deferred()

func shot(label: String) -> void:
	await get_tree().create_timer(.35).timeout
	if DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("res://.analysis/showcase-" + label + ".png")

func run() -> void:
	for kuih in KuihLibrary.all():
		assert(kuih.texture != null,"Missing artwork: " + str(kuih.id))
		assert(kuih.texture.get_width() > 0)
	for entry in PowerupRecipes.ENTRIES:
		assert(BoardArt.special_texture(int(entry[0])) != null,"Missing special artwork")
	var collection := RecipeBookScreen.new()
	add_child(collection)
	collection._page = 1
	collection.refresh()
	await shot("collection-page2")
	collection.free()
	for stage in range(1,31):
		SaveManager.data.levels[str(stage)] = {"stars":3,"completed":true}
	var screen := GeraiScreen.new()
	add_child(screen)
	await shot("fullscreen")
	assert(screen._panel == null and screen._panel_mode.is_empty(),"Start with the stall unobstructed")
	var scenery := screen._preview.get_rect()
	assert(scenery.position == Vector2.ZERO and scenery.size == screen.size,"Scenery fills screen")
	screen._tasks_button.pressed.emit()
	await shot("large-tasks")
	assert(screen._preview.get_rect() == scenery,"Opening tasks does not shrink scenery")
	screen._tasks_button.pressed.emit()
	assert(screen._panel == null,"Tasks toggles closed")
	screen._design_button.pressed.emit()
	assert(screen._panel_mode == "design","Design opens from navigation")
	screen._design_button.pressed.emit()
	assert(screen._panel == null,"Design toggles closed")
	screen._show_tasks()
	var escape := InputEventAction.new()
	escape.action = "ui_cancel"
	escape.pressed = true
	screen._unhandled_input(escape)
	assert(screen._panel == null,"Back/Escape closes the sheet before leaving")
	screen._tasks_button.pressed.emit()
	await get_tree().process_frame
	assert(screen._preview.showcase_active())
	assert(screen._preview._showcase_texture != null,"Backdrop texture remains alive after drawing")
	var scroll := screen._panel.find_child("TaskList",true,false) as ScrollContainer
	assert(scroll.get_v_scroll_bar().max_value > scroll.get_v_scroll_bar().page,"Task list can scroll")
	scroll.scroll_vertical = 500
	await get_tree().process_frame
	assert(scroll.scroll_vertical > 0,"Task scroll responds")
	screen._show_upgrade()
	screen._select_choice("pandan")
	await shot("canopy-preview")
	await screen._confirm_selection()
	assert(LocationManager.variant_for(&"family_stall",1) == "pandan")
	var second := RenovationTaskDefinition.for_location(&"family_stall")[1]
	assert(LocationManager.confirm_task(second,"batik").ok)
	var redesign := RenovationTaskDefinition.style_task(&"family_stall")
	redesign.state_index = 1
	redesign.title_key = "sign"
	screen._open_choices(redesign)
	var before := SaveManager.data.duplicate(true)
	screen._select_choice("classic")
	assert(SaveManager.data == before,"Component preview must not write saves")
	assert(screen._preview.structural_state == 2,"Previewing canopy retains newer rack")
	var stars := EconomyManager.stars()
	await screen._confirm_selection()
	assert(EconomyManager.stars() == stars,"Owned component redesign is free")
	assert(LocationManager.structural_level(&"family_stall") == 2,"Redesign cannot downgrade structure")
	assert(LocationManager.variant_for(&"family_stall",1) == "classic")
	assert(LocationManager.variant_for(&"family_stall",2) == "batik","Other components retain their saved styles")
	screen._show_tasks()
	await shot("new-stall")
	screen.free()
	print("Showcase quality: PASS (%d kuih textures, readable scrolling tasks, modular canopy/rack, free redesign without downgrade)" % KuihLibrary.count())
	get_tree().quit()
