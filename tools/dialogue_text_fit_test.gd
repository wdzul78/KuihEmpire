extends Node

func _ready() -> void:
	SaveManager.save_path = "user://kuih_dialogue_fit_test.json"
	SaveManager.reset()
	run.call_deferred()

func run() -> void:
	var panel := OrderPanel.new()
	panel.size = Vector2(980,432)
	add_child(panel)
	panel.set_coaching(true)
	var checked := 0
	var smallest := 99
	for language in ["en","ms"]:
		SaveManager.data.settings.language = language
		for lesson in TutorialLibrary.all():
			for step in lesson.tutorial_steps:
				panel._name_label.text = TutorialText.text(step.title)
				panel._line_label.text = TutorialText.text(step.body)
				await get_tree().process_frame
				await get_tree().process_frame
				for label in [panel._name_label,panel._line_label]:
					var font_size: int = label.get_theme_font_size("font_size")
					smallest = mini(smallest,font_size)
					var extent: Vector2 = label.get_theme_font("font").get_multiline_string_size(label.text,HORIZONTAL_ALIGNMENT_CENTER,label.size.x-4,font_size,-1,TextServer.BREAK_MANDATORY | TextServer.BREAK_WORD_BOUND | TextServer.BREAK_ADAPTIVE)
					assert(extent.y <= label.size.y, "Dialogue text does not fit: "+label.text)
					assert(label.get_global_rect().end.y <= panel._bubble.get_global_rect().position.y+panel._bubble.size.y*.72, "Text enters bubble tail")
					assert(not label.text.contains("Ã"), "Broken multiplication character")
				checked += 1
	panel.free()
	if "--capture" in OS.get_cmdline_user_args():
		SaveManager.data.settings.language = "en"
		var screen := LevelController.new()
		screen.tutorial_index = 5
		add_child(screen)
		screen.coach.index = 3
		screen.coach._show_step()
		await get_tree().process_frame
		await get_tree().process_frame
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("res://.shots/dialogue_dulang_fixed.png")
		screen.free()
	AudioManager.stop_music()
	print("Dialogue text fit: PASS (%d steps, both languages; smallest font %d)" % [checked,smallest])
	get_tree().quit()
