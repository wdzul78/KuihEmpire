extends Node
var screen: GeraiScreen

func _ready() -> void:
	SaveManager.save_path = "user://kuching_food_upgrade_test.json"
	SaveManager.reset()
	run.call_deferred()

func shot(label: String) -> void:
	await get_tree().create_timer(.35).timeout
	if DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("res://.analysis/kuching-" + label + ".png")

func food_task(id: String) -> RenovationTaskDefinition:
	for task in RenovationTaskDefinition.for_location(&"family_stall"):
		if task.decor_id == id:
			return task
	return null

func run() -> void:
	for stage in range(1,31):
		SaveManager.data.levels[str(stage)] = {"stars":3,"completed":true}
	SaveManager.set_setting("language","ms")
	screen = GeraiScreen.new()
	add_child(screen)
	await shot("empty-stall")
	assert(not screen._preview._decor.has("COUNTER_FOOD"),"Stall starts without food")
	var starter := food_task("kuih_display")
	var premium := food_task("kuih_feast")
	var before := SaveManager.data.duplicate(true)
	assert(not premium.available())
	assert(not LocationManager.buy("kuih_feast") and SaveManager.data == before,"Legacy purchase entry cannot skip prerequisite")
	assert(not LocationManager.confirm_task(premium,"original").ok and SaveManager.data == before,"Cannot skip first food upgrade")
	screen._show_decor(DecorDefinition.find("kuih_display"))
	screen._select_choice("original")
	assert(SaveManager.data == before,"Preview cannot charge or persist")
	await shot("daily-preview")
	var stars := EconomyManager.stars()
	await screen._confirm_selection()
	assert(EconomyManager.stars() == stars-2 and starter.complete() and premium.available())
	assert(LocationManager.equipped(&"family_stall").COUNTER_FOOD == "kuih_display")
	var spent: int = SaveManager.data.stars_spent
	SaveManager.data.stars_spent = ProgressionManager.total_stars()
	before = SaveManager.data.duplicate(true)
	assert(not LocationManager.confirm_task(premium,"warm").ok and SaveManager.data == before,"Insufficient stars retain the existing food display and inventory")
	SaveManager.data.stars_spent = spent
	screen._close_panel()
	await shot("daily-equipped")
	screen._show_decor(DecorDefinition.find("kuih_feast"))
	screen._select_choice("warm")
	await shot("variety-preview")
	await screen._confirm_selection()
	assert(EconomyManager.stars() == stars-6 and LocationManager.equipped(&"family_stall").COUNTER_FOOD == "kuih_feast")
	assert(LocationManager.structural_level(&"family_stall") == 0,"Food upgrade does not alter structural progress")
	screen._show_decor(DecorDefinition.find("kuih_feast"))
	screen._select_choice("fresh")
	await screen._confirm_selection()
	assert(EconomyManager.stars() == stars-6,"Owned layout changes are free")
	SaveManager.load_game()
	assert(LocationManager.decor_styles(&"family_stall").COUNTER_FOOD == "fresh" and LocationManager.owned("kuih_display") and LocationManager.owned("kuih_feast"),"Save reload retains food layouts and both purchases")
	screen._close_panel()
	await shot("variety-equipped")
	screen._show_decor(DecorDefinition.find("kuih_feast"))
	screen._select_choice("none")
	await screen._confirm_selection()
	assert(not LocationManager.equipped(&"family_stall").has("COUNTER_FOOD") and LocationManager.owned("kuih_feast"),"Removing food restores an empty counter without removing ownership")
	assert(starter.complete() and premium.complete(),"Removing a display retains completed tasks")
	screen.free()
	print("Kuching food upgrade: PASS (empty start, sequential food purchases, preview, exact costs, free layouts, persistence and removal)")
	get_tree().quit()
