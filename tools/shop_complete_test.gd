extends Node
var screen: GeraiScreen

func _ready() -> void:
	SaveManager.save_path = "user://shop_complete_test.json"
	SaveManager.reset()
	run.call_deferred()

func shot(label: String) -> void:
	await get_tree().create_timer(.4).timeout
	if DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("res://.analysis/shop-complete-" + label + ".png")

func row_count() -> int:
	var list: Control = screen._panel.find_child("TaskList",true,false).get_child(0)
	var count := 0
	for child in list.get_children():
		if str(child.name).begins_with("Task_"):
			count += 1
	return count

func run() -> void:
	for stage in range(1,31):
		SaveManager.data.levels[str(stage)] = {"stars":3,"completed":true}
	SaveManager.set_setting("language","ms")
	screen = GeraiScreen.new()
	add_child(screen)
	await shot("empty-with-markers")
	assert(screen._hotspots.get_child_count() == 9,"One marker per component or accessory slot")
	screen._task_filter = "remaining"
	screen._show_tasks()
	await shot("tasks")
	assert(row_count() == 10)
	screen._show_design()
	assert(row_count() == 0,"Unpurchased designs are kept in the task list")
	var tasks := screen._tasks()
	var premium: RenovationTaskDefinition = tasks[7]
	screen._inspect_task(premium)
	assert(screen._panel_mode == "locked","Locked tasks explain their prerequisite")
	var initial_stars := EconomyManager.stars()
	var spent := 0
	for index in tasks.size():
		var task: RenovationTaskDefinition = tasks[index]
		assert(task.available(),"Task must unlock in the full progression: " + task.id)
		screen._inspect_task(task)
		var snapshot := SaveManager.data.duplicate(true)
		var choice: String = task.choices()[index % 3]
		screen._select_choice(choice)
		assert(SaveManager.data == snapshot,"Preview does not alter state")
		if task.decor_id == "shop_sign":
			await shot("sign-preview")
		if task.decor_id == "counter_finish":
			await shot("counter-preview")
		spent += task.cost()
		await screen._confirm_selection()
		assert(task.complete() and EconomyManager.stars() == initial_stars-spent)
		assert(screen._panel.find_child("CompletionProgress",true,false) != null)
	await shot("completion")
	screen._show_tasks()
	assert(row_count() == 0,"Completed tasks leave the to-do list")
	screen._task_filter = "done"
	screen._show_tasks()
	assert(row_count() == 10,"Completed filter records every upgrade")
	screen._show_design()
	assert(row_count() == 10,"Every owned component can be redesigned")
	await shot("owned-designs")
	var stars := EconomyManager.stars()
	screen._inspect_task(tasks[0])
	screen._select_choice("pandan")
	await screen._confirm_selection()
	assert(EconomyManager.stars() == stars and LocationManager.structural_level(&"family_stall") == 3,"Owned canopy redesign is free and preserves the highest structural level")
	SaveManager.save_game()
	SaveManager.load_game()
	assert(LocationManager.equipped(&"family_stall").has("SIGN_BOARD") and LocationManager.equipped(&"family_stall").has("COUNTER_FRONT"),"New finishes survive reload")
	screen._close_panel()
	await shot("full-stall")
	screen.free()
	print("Complete shop: PASS (10 upgrades, graphics, markers, filters, locking, free previews, exact star costs, owned redesign and reload)")
	get_tree().quit()
