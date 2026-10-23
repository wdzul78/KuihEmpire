extends Node

func _ready() -> void:
	var original := SaveManager.data.duplicate(true)
	var original_path := SaveManager.save_path
	SaveManager.save_path = "user://stall_regression_test.json"
	SaveManager.data = SaveManager._normalize({})
	assert(LocationManager.active_stall_id() == &"family_stall")
	assert(LocationManager.stall_snapshot().visual_state == "old")
	assert(not LocationManager.set_active_stall(&"school_canteen"))
	assert(not LocationManager.set_active_stall(&"invalid"))
	assert(not LocationManager.set_active_stall(&"government_canteen"))
	assert(LocationDefinition.find(&"government_canteen").stage_start == 211)
	assert(LocationDefinition.find(&"city").stage_start == 121)
	var backgrounds: Array[GeraiBackdrop] = []
	for context in ["menu","gameplay","renovation","journey"]:
		var bg := GeraiBackdrop.new()
		bg.follow_active_stall = true
		bg.background_context = context
		bg.gameplay_mode = context == "gameplay"
		bg.size = Vector2(1080,2400)
		add_child(bg)
		backgrounds.append(bg)
		assert(bg.location_id == &"family_stall" and bg.structural_state == 0)
		assert(bg._background != null)
	assert(not LocationManager.upgrade(&"family_stall"))
	for stage in range(1,31):
		SaveManager.data.levels[str(stage)] = {"stars":3,"completed":true}
	for achievement in AchievementManager.definitions:
		SaveManager.data.achievements[achievement.id] = {"unlocked":true,"reward_claimed":true}
	SaveManager.data.coins = 1234
	SaveManager.data.stars_spent = 90
	assert(not LocationManager.upgrade(&"family_stall"))
	SaveManager.data.stars_spent = 0
	for index in range(1,4):
		var before := EconomyManager.stars()
		var cost := StallDefinition.find(&"family_stall").state(index).star_cost
		assert(LocationManager.upgrade(&"family_stall", "batik"))
		assert(EconomyManager.stars() == before - cost)
		assert(ProgressionManager.total_stars() == 90)
		assert(EconomyManager.coins() == 1234)
		assert(LocationManager.variant_for(&"family_stall") == "batik")
		for bg in backgrounds:
			assert(bg.structural_state == index)
	assert(not LocationManager.upgrade(&"family_stall"))
	var school := StallDefinition.find(&"school_canteen").state(0)
	var school_paths := {}
	for context in ["menu","gameplay","renovation","journey"]:
		school_paths[context] = school.get(context + "_background")
		school.set(context + "_background", "res://assets/stalls/__missing__/" + context + ".png")
	assert(LocationManager.set_active_stall(&"school_canteen"))
	for bg in backgrounds:
		assert(bg.location_id == &"school_canteen" and bg.structural_state == 0)
		assert(bg._background == null) # No authored image: procedural fallback.
	for context in school_paths:
		school.set(context + "_background", school_paths[context])
	LocationManager.location_state_changed.emit(&"school_canteen")
	for bg in backgrounds:
		assert(bg._authored_background and bg._background != null)
	assert(SaveManager.save_game())
	SaveManager.load_game()
	assert(LocationManager.active_stall_id() == &"school_canteen")
	assert(LocationManager.variant_for(&"family_stall") == "batik")
	assert(LocationManager.set_active_stall(&"family_stall"))
	assert(LocationManager.select_variant(&"family_stall", "pandan"))
	assert(not LocationManager.select_variant(&"family_stall", "invalid"))
	var normalized := SaveManager._normalize(SaveManager.data)
	assert(normalized.active_stall_id == "family_stall")
	assert(normalized.stall_variants.family_stall["3"] == "pandan")
	var legacy := SaveManager._normalize({"version":5,"levels":SaveManager.data.levels,"structural_upgrades":{"family_stall":2},"stars_spent":7,"coins":42,"owned_decor":["hibiscus"]})
	assert(legacy.structural_upgrades.family_stall == 2 and legacy.stars_spent == 7)
	assert(legacy.coins == 42 and legacy.owned_decor.has("hibiscus"))
	assert(legacy.active_stall_id == "family_stall")
	assert(legacy.structural_upgrades.government_canteen == 0)
	SaveManager.data.levels["210"] = {"stars":3,"completed":true}
	assert(LocationManager.set_active_stall(&"government_canteen"))
	assert(not LocationManager.accessible(&"government_canteen"))
	for bg in backgrounds:
		assert(bg.location_id == &"government_canteen" and bg._authored_background)
	# Unpublished campaign records intentionally do not survive save normalization.
	assert(SaveManager._normalize(SaveManager.data).active_stall_id == "family_stall")
	SaveManager.data.levels.erase("210")
	assert(LocationManager.set_active_stall(&"family_stall"))
	var visual := StallDefinition.find(&"family_stall").state(3)
	var original_image := visual.menu_background
	visual.menu_background = "res://tools/stall_test_background.tres"
	LocationManager.location_state_changed.emit(&"family_stall")
	assert(backgrounds[0]._authored_background)
	assert(backgrounds[0].texture_path == visual.menu_background)
	assert(backgrounds[0]._previous_background != null)
	await get_tree().create_timer(.35).timeout
	assert(backgrounds[0]._previous_background == null and is_equal_approx(backgrounds[0]._blend, 1.0))
	visual.menu_background = original_image
	LocationManager.location_state_changed.emit(&"family_stall")
	for bg in backgrounds:
		bg.free()
	var gameplay := LevelController.new()
	gameplay.level_id = 1
	GameManager.pending_tutorial_index = 0
	add_child(gameplay)
	assert(gameplay.backdrop.follow_active_stall and gameplay.backdrop.structural_state == 3)
	assert(gameplay.backdrop.gameplay_mode)
	await get_tree().process_frame
	gameplay.free()
	# The gameplay fixture can pause on focus loss; later UI tweens need a live tree.
	get_tree().paused = false
	var home := HomeScreen.new()
	add_child(home)
	var menu_bg := home.get_node("BackgroundLayer") as GeraiBackdrop
	assert(menu_bg.follow_active_stall and menu_bg.structural_state == 3)
	await get_tree().process_frame
	home.free()
	var stall := GeraiScreen.new()
	add_child(stall)
	assert(stall._location == &"family_stall")
	stall._show_style()
	assert(is_instance_valid(stall._panel))
	stall._close_panel()
	stall._location = &"school_canteen"
	stall._refresh()
	stall._show_tasks()
	assert(not stall._active.disabled)
	stall._show_supplies()
	assert(is_instance_valid(stall._panel))
	stall._close_panel()
	SaveManager.data.structural_upgrades.family_stall = 2
	stall._location = &"family_stall"
	stall._refresh()
	stall._show_upgrade()
	var before_animation := EconomyManager.stars()
	await stall._renovate()
	assert(not stall._busy and stall._panel_mode == "complete")
	assert(EconomyManager.stars() == before_animation - 12)
	await get_tree().create_timer(.8).timeout
	assert(not stall._busy and stall._preview.structural_state == 3)
	stall.free()
	var journey := JourneyMap.new()
	add_child(journey)
	await get_tree().process_frame
	journey.free()
	SaveManager.data = original
	SaveManager.save_path = original_path
	LocationManager.reconcile()
	print("Stall progression: PASS (defaults, gates, 3 upgrades, star costs, variants, active selection, reload, migration, missing assets, menu/stall/journey integration)")
	get_tree().quit()
