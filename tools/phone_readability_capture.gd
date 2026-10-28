extends Node

## Captures real gameplay HUD states past the one-time kuih introductions so text
## size and dialogue can be reviewed at phone resolution. Writes .shots/phone_*.png.
## Optional user arg: --ms for Malay copy.

func _ready() -> void:
	SaveManager.save_path = "user://phone_readability_capture.json"
	SaveManager.reset()
	SaveManager.data.settings.language = "ms" if "--ms" in OS.get_cmdline_user_args() else "en"
	run.call_deferred()

func _mark_seen(level: LevelDefinition) -> void:
	for item in KuihIntroduction.for_level(level, true, []):
		if not String(item.id) in SaveManager.data.kuih_seen:
			SaveManager.data.kuih_seen.append(String(item.id))

func _settle(frames: int) -> void:
	for _i in frames:
		await get_tree().process_frame

func _save(name: String) -> void:
	await RenderingServer.frame_post_draw
	var suffix := "_ms" if "--ms" in OS.get_cmdline_user_args() else ""
	get_viewport().get_texture().get_image().save_png("res://.shots/phone_%s%s.png" % [name, suffix])

func _tutorial(index: int, step: int, name: String) -> void:
	var stage := TutorialLibrary.get_stage(index)
	_mark_seen(stage)
	var screen := LevelController.new()
	screen.tutorial_index = index
	add_child(screen)
	await get_tree().create_timer(1.2).timeout
	while screen.coach != null and screen.coach.index < step and not screen.coach.is_done():
		screen.coach._advance()
	await get_tree().create_timer(.5).timeout
	if "--debug" in OS.get_cmdline_user_args():
		var panel := screen.hud.order_panel
		print(name, " customer visible=", panel._portrait.is_visible_in_tree(), " customer=", panel._portrait.customer, " cast=", panel._portrait.cast, " rect=", panel._portrait.get_global_rect(), " mod=", panel._portrait.modulate, " self_mod=", panel._portrait.self_modulate)
		print(name, " name='", panel._name_label.text, "' vis=", panel._name_label.is_visible_in_tree(), " rect=", panel._name_label.get_global_rect(), " fs=", panel._name_label.get_theme_font_size("font_size"))
		var n := panel._name_label
		print(name, " namedbg mod=", n.modulate, " smod=", n.self_modulate, " vr=", n.visible_ratio, " vc=", n.visible_characters, " col=", n.get_theme_color("font_color"), " parent_mod=", n.get_parent().modulate, " lines=", n.get_line_count(), " vis_lines=", n.get_visible_line_count(), " clip=", n.clip_text, " canvas=", n.get_global_transform_with_canvas().origin)
		var l := panel._line_label
		print(name, " linedbg lines=", l.get_line_count(), " vis_lines=", l.get_visible_line_count(), " max_lines=", l.max_lines_visible, " lines_skipped=", l.lines_skipped)
		print(name, " line='", panel._line_label.text.c_escape(), "' rect=", panel._line_label.get_global_rect(), " fs=", panel._line_label.get_theme_font_size("font_size"), " bubble=", panel._bubble.get_global_rect())
	await _save(name)
	screen.free()
	await _settle(2)

func _stage(id: int, name: String, finish: String = "") -> void:
	_mark_seen(LevelLibrary.get_level(id))
	var screen := LevelController.new()
	screen.level_id = id
	add_child(screen)
	await get_tree().create_timer(1.2).timeout
	await _save(name)
	if finish == "win":
		screen.result.show_win("", 3, 120, [], false, StageResultCalculator.calculate(true, 900, 4, screen.level))
		await get_tree().create_timer(.8).timeout
		await _save(name + "_win")
	elif finish == "fail":
		screen.result.show_fail("", true, StageResultCalculator.calculate(false, 300, 0, screen.level))
		await get_tree().create_timer(.8).timeout
		await _save(name + "_fail")
	screen.free()
	await _settle(2)

func run() -> void:
	await _tutorial(1, 0, "t1")
	await _tutorial(3, 0, "t3_customer")
	await _tutorial(3, 1, "t3_aina")
	await _tutorial(7, 0, "t7_queue")
	await _tutorial(8, 1, "t8_makcik")
	await _stage(1, "stage01", "win")
	await _stage(10, "stage10")
	await _stage(20, "stage20", "fail")
	AudioManager.stop_music()
	print("Phone readability capture: done")
	get_tree().quit()
