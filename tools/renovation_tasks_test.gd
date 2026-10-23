extends Node

var problems: Array[String] = []

func check(condition: bool, message: String) -> void:
	if not condition:
		problems.append(message)

func _ready() -> void:
	SaveManager.save_path = "user://renovation_tasks_test.json"
	SaveManager.reset()
	run.call_deferred()

func run() -> void:
	var tasks := RenovationTaskDefinition.for_location(&"family_stall")
	check(tasks.size() == 10, "three structural, five decor and two food-display tasks")
	check(not tasks[0].available(), "stage milestone gate")
	check(not tasks[1].available(), "sequential task gate")
	for stage in range(1,31):
		SaveManager.data.levels[str(stage)] = {"stars":3,"completed":true}
	for achievement in AchievementManager.definitions:
		SaveManager.data.achievements[achievement.id] = {"unlocked":true,"reward_claimed":true}
	var screen := GeraiScreen.new()
	add_child(screen)
	await get_tree().process_frame
	check(screen._panel_mode.is_empty(), "default unobstructed full-screen stall")
	screen._show_tasks()
	check(screen._panel_mode == "tasks" and screen._panel.find_child("TaskList",true,false) != null, "default to-do panel")
	var before := SaveManager.data.duplicate(true)
	screen._show_upgrade()
	check(screen._choice_buttons.size() == 3 and screen._preview.structural_state == 1, "three upgrade choices and uncommitted state preview")
	screen._choice_buttons[1].pressed.emit()
	check(screen._variant == "batik" and screen._preview._variant_override == "batik", "choice button previews on stall")
	check(SaveManager.data == before, "preview charged or persisted")
	screen._show_tasks()
	check(SaveManager.data == before and screen._preview.structural_state == 0, "cancel restored saved scene")
	screen._show_upgrade()
	screen._select_choice("pandan")
	var stars := EconomyManager.stars()
	await screen._confirm_selection()
	check(LocationManager.structural_level(&"family_stall") == 1 and EconomyManager.stars() == stars - 5, "upgrade confirmation charges once")
	check(screen._panel_mode == "complete" and screen._completion_count == 1, "task-complete panel")
	check(LocationManager.variant_for(&"family_stall") == "pandan", "upgrade style persisted")
	check(not LocationManager.confirm_task(tasks[0],"classic").ok and EconomyManager.stars() == stars - 5, "stale confirmation cannot pay twice")
	var style_task := RenovationTaskDefinition.style_task(&"family_stall")
	check(LocationManager.confirm_task(style_task,"batik").ok and EconomyManager.stars() == stars - 5, "free redesign")
	screen._show_decor(DecorDefinition.find("hibiscus"))
	before = SaveManager.data.duplicate(true)
	screen._select_choice("fresh")
	check(screen._preview._decor.get("PLANT_1","") == "hibiscus" and screen._preview._decor_styles_override.PLANT_1 == "fresh", "decor/color preview")
	check(SaveManager.data == before, "decor preview wrote inventory")
	await screen._confirm_selection()
	check(LocationManager.owned("hibiscus") and LocationManager.equipped(&"family_stall").PLANT_1 == "hibiscus", "buy and equip as one confirmation")
	check(LocationManager.decor_styles(&"family_stall").PLANT_1 == "fresh" and EconomyManager.stars() == stars - 7, "decor color and exact cost")
	screen._show_decor(DecorDefinition.find("hibiscus"))
	screen._select_choice("warm")
	await screen._confirm_selection()
	check(EconomyManager.stars() == stars - 7 and LocationManager.decor_styles(&"family_stall").PLANT_1 == "warm", "owned decor redesign is free")
	screen._show_decor(DecorDefinition.find("hibiscus"))
	screen._select_choice("none")
	check(LocationManager.equipped(&"family_stall").has("PLANT_1"), "remove preview not committed early")
	await screen._confirm_selection()
	check(not LocationManager.equipped(&"family_stall").has("PLANT_1") and LocationManager.owned("hibiscus"), "remove retains ownership")
	check(tasks[3].complete(), "redesign/removal cannot undo completed task history")
	check(LocationManager.confirm_task(tasks[3],"fresh").ok and EconomyManager.stars() == stars - 7, "re-equip does not charge twice")
	var good_path := SaveManager.save_path
	SaveManager.save_path = "user://missing_task_directory/sub/save.json"
	before = SaveManager.data.duplicate(true)
	check(not LocationManager.confirm_task(tasks[1],"classic").ok and SaveManager.data == before, "save failure rolled back inventory and debit")
	SaveManager.save_path = good_path
	SaveManager.save_game()
	SaveManager.load_game()
	check(LocationManager.structural_level(&"family_stall") == 1 and LocationManager.variant_for(&"family_stall") == "batik", "restart preserves upgrade/style")
	check(LocationManager.decor_styles(&"family_stall").PLANT_1 == "fresh" and LocationManager.owned("hibiscus"), "restart preserves accessory choice/ownership")
	var legacy := SaveManager._normalize({"version":6,"levels":SaveManager.data.levels,"structural_upgrades":{"family_stall":3},"stars_spent":25,"owned_decor":["hibiscus"],"location_decor":{"family_stall":{"PLANT_1":"hibiscus"}},"stall_variants":{"family_stall":{"3":"pandan"}}})
	check(legacy.structural_upgrades.family_stall == 3 and legacy.owned_decor.has("hibiscus") and legacy.location_decor.family_stall.PLANT_1 == "hibiscus", "legacy progress/equipped migration")
	check(legacy.stars_spent == 25 and legacy.stall_variants.family_stall["3"] == "pandan", "legacy costs/style retained")
	var malformed := SaveManager._normalize({"decor_styles":{"family_stall":{"PLANT_1":"invalid","WRONG_SLOT":"fresh"}}})
	check(not malformed.decor_styles.family_stall.has("WRONG_SLOT") and not malformed.decor_styles.family_stall.has("PLANT_1"), "invalid decor styles rejected")
	SaveManager.data.stars_spent = 90
	screen._show_decor(DecorDefinition.find("rattan_lamp"))
	check(screen._confirm_button.disabled, "insufficient stars disables confirm")
	before = SaveManager.data.duplicate(true)
	check(not LocationManager.confirm_task(tasks[4],"original").ok and SaveManager.data == before, "insufficient funds changes nothing")
	check(not LocationManager.confirm_task(RenovationTaskDefinition.for_location(&"school_canteen")[3],"invalid").ok, "invalid design rejected")
	screen._close_panel()
	screen._location = &"school_canteen"
	screen._refresh()
	screen._show_decor(DecorDefinition.find("office_plant"))
	check(screen._selected_task.decor_id == "office_plant", "institutional task catalog")
	screen.free()
	SaveManager.save_game()
	print("Renovation tasks: %s (%d problems)" % ["PASS" if problems.is_empty() else "FAIL",problems.size()])
	for problem in problems:
		print("FAIL: " + problem)
	get_tree().quit(0 if problems.is_empty() else 1)
