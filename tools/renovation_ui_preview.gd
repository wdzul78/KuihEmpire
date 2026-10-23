extends Node

var screen: GeraiScreen

func _ready() -> void:
	SaveManager.save_path = "user://renovation_preview_test.json"
	SaveManager.reset()
	run.call_deferred()

func shot(name: String) -> void:
	for frame in 6:
		await get_tree().process_frame
	await get_tree().create_timer(.35).timeout
	await RenderingServer.frame_post_draw
	var suffix := "_tall" if "--tall" in OS.get_cmdline_user_args() else ""
	get_viewport().get_texture().get_image().save_png("res://.shots/renovation_" + name + suffix + ".png")
	if is_instance_valid(screen._panel):
		var panel_rect := screen._panel.get_global_rect()
		assert(panel_rect.end.y <= screen.size.y + 2, "panel must fit in phone viewport")

func run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://.shots"))
	for stage in range(1,31):
		SaveManager.data.levels[str(stage)] = {"stars":3,"completed":true}
	for achievement in AchievementManager.definitions:
		SaveManager.data.achievements[achievement.id] = {"unlocked":true,"reward_claimed":true}
	screen = GeraiScreen.new()
	add_child(screen)
	screen._show_tasks()
	await shot("tasks")
	screen._show_upgrade()
	await shot("structure_choices")
	screen._choice_buttons[1].pressed.emit()
	await shot("batik_preview")
	await screen._confirm_selection()
	await shot("task_complete")
	screen._show_tasks()
	await shot("next_task")
	screen._show_decor(DecorDefinition.find("hibiscus"))
	screen._choice_buttons[2].pressed.emit()
	await shot("decor_choices")
	await screen._confirm_selection()
	screen._show_design()
	await shot("design_mode")
	screen._show_decor(DecorDefinition.find("hibiscus"))
	await shot("owned_redesign")
	screen._show_tasks()
	SaveManager.set_setting("language","ms")
	screen.free()
	screen = GeraiScreen.new()
	add_child(screen)
	screen._show_tasks()
	await shot("malay_tasks")
	screen._show_decor(DecorDefinition.find("rattan_lamp"))
	SaveManager.data.stars_spent = ProgressionManager.total_stars()
	screen._refresh()
	await shot("no_stars")
	screen._show_tasks()
	screen._location = &"school_canteen"
	screen._refresh()
	screen._show_decor(DecorDefinition.find("office_plant"))
	await shot("school_choices")
	screen.free()
	print("Renovation preview: PASS (tasks, choice previews, confirmation, completion, redesign, Malay and phone bounds)")
	get_tree().quit()
