extends Node
var screen: GeraiScreen
var problems: Array[String] = []

func check(ok: bool, message: String) -> void:
	if not ok:
		problems.append(message)

func _ready() -> void:
	SaveManager.save_path = "user://renovation_interactive_test.json"
	SaveManager.reset()
	run.call_deferred()

func shot(label: String) -> void:
	if DisplayServer.get_name() == "headless":
		return
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://.analysis/stall-v2-" + label + ".png")

func finish_animation() -> void:
	var deadline := Time.get_ticks_msec() + 5000
	while screen._busy and Time.get_ticks_msec() < deadline:
		await get_tree().process_frame
	check(not screen._busy, "animation completed within five seconds")
	check(screen._panel_mode == "complete", "completion follows animation")

func run() -> void:
	for stage in range(1,31):
		SaveManager.data.levels[str(stage)] = {"stars":3,"completed":true}
	for achievement in AchievementManager.definitions:
		SaveManager.data.achievements[achievement.id] = {"unlocked":true,"reward_claimed":true}
	screen = GeraiScreen.new()
	add_child(screen)
	for item in DecorDefinition.all():
		for style in DecorDefinition.STYLES:
			check(RenovationArt.design_texture(item.id,style) != null, "accessory artwork exists: " + item.id + ":" + style)
	await get_tree().create_timer(.4).timeout
	await shot("tasks")
	var before := SaveManager.data.duplicate(true)
	screen._show_upgrade()
	screen._select_choice("pandan")
	check(SaveManager.data == before, "preview does not change save or charge stars")
	screen._show_tasks()
	check(SaveManager.data == before, "cancel leaves save unchanged")
	screen._show_upgrade()
	screen._select_choice("pandan")
	var stars := EconomyManager.stars()
	screen._confirm_selection()
	check(screen._busy, "confirmation blocks repeated input during animation")
	screen._confirm_selection()
	check(EconomyManager.stars() == stars - 5, "double confirmation charged exactly once")
	await finish_animation()
	check(LocationManager.structural_level(&"family_stall") == 1, "structure persisted")
	screen._show_decor(DecorDefinition.find("hibiscus"))
	screen._select_choice("fresh")
	await get_tree().create_timer(.35).timeout
	await shot("choices")
	check(screen._choice_buttons[0].find_child("AccessoryPreview",true,false).texture != screen._choice_buttons[1].find_child("DesignPreview",true,false).texture, "choices have distinct artwork")
	screen._confirm_selection()
	check(screen._preview.hidden_decor_slot == "PLANT_1", "new accessory hidden until landing")
	await get_tree().create_timer(.7).timeout
	await shot("installing")
	await finish_animation()
	check(screen._preview.hidden_decor_slot.is_empty(), "accessory restored after landing")
	check(LocationManager.decor_styles(&"family_stall").PLANT_1 == "fresh", "selected style saved")
	check(EconomyManager.stars() == stars - 7, "accessory charged exactly once")
	screen._show_decor(DecorDefinition.find("hibiscus"))
	screen._select_choice("warm")
	await screen._confirm_selection()
	check(EconomyManager.stars() == stars - 7, "owned redesign remains free")
	screen._show_decor(DecorDefinition.find("hibiscus"))
	screen._select_choice("none")
	await screen._confirm_selection()
	check(not LocationManager.equipped(&"family_stall").has("PLANT_1") and LocationManager.owned("hibiscus"), "removal retains ownership")
	SaveManager.load_game()
	check(LocationManager.structural_level(&"family_stall") == 1 and LocationManager.owned("hibiscus"), "reload retains renovation progress")
	screen._show_decor(DecorDefinition.find("rattan_lamp"))
	var good_path := SaveManager.save_path
	before = SaveManager.data.duplicate(true)
	SaveManager.save_path = "user://missing-folder/sub/failed.json"
	await screen._confirm_selection()
	check(not screen._busy and screen._panel_mode == "choices" and SaveManager.data == before, "save failure keeps choices open and restores inventory and stars")
	SaveManager.save_path = good_path
	screen._show_tasks()
	await shot("finished")
	SaveManager.set_setting("language","ms")
	screen._show_decor(DecorDefinition.find("rattan_lamp"))
	await get_tree().create_timer(.3).timeout
	await shot("malay")
	screen.free()
	for problem in problems:
		push_error(problem)
	print("Interactive renovation: %s (%d problems)" % ["PASS" if problems.is_empty() else "FAIL",problems.size()])
	get_tree().quit(0 if problems.is_empty() else 1)
