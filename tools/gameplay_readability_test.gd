extends Node

var problems := 0
func check(ok: bool, message: String) -> void:
	if not ok:
		problems += 1
		push_error(message)
func _ready() -> void:
	run.call_deferred()
func run() -> void:
	SaveManager.save_path = "user://gameplay_readability_test.json"
	for tutorial in [0,8]:
		var screen := LevelController.new()
		screen.level_id = 20
		screen.tutorial_index = tutorial
		add_child(screen)
		await get_tree().create_timer(.4).timeout
		# Inspect puzzle presentation after the introductory story gate.
		screen.story.hide()
		if screen.coach != null:
			screen.coach._spotlight.hide()
			screen.coach._tap_indicator.hide()
		var hud := screen.hud
		check(not hud.get_node("Logo").visible and not hud.get_node("HeartMeter").visible,"no logo or hearts during puzzles")
		check(screen.backdrop.gameplay_mode,"gameplay background mode enabled")
		check(screen.backdrop.texture_path == GeraiBackdrop.SOFT_GAMEPLAY_PATH,"new gameplay market background")
		check(screen.backdrop.material is ShaderMaterial,"background blur applied")
		check(screen.backdrop.texture_filter == CanvasItem.TEXTURE_FILTER_LINEAR,"smooth upscaling")
		check(hud.material == null and screen.board.material == null,"HUD and puzzle remain sharp")
		check(hud.order_panel.compact_mode,"campaign and tutorial share compact portraits")
		check(hud.order_panel._aina.compact_portrait and hud.order_panel._portrait.compact_portrait,"both characters use circular portraits")
		if tutorial > 0:
			check(hud.order_panel._bubble.visible,"tutorial instructions stay visible")
			check(hud.order_panel._bubble.get_global_rect().position.y >= hud.order_panel._card.get_global_rect().end.y,"instructions clear the order strip")
			check(hud.order_panel._bubble.get_global_rect().end.y <= hud.board_holder.get_global_rect().position.y,"instructions clear the puzzle")
			# Validate authored copy at the real HUD size, including long Malay text.
			var language_before: String = SaveManager.get_setting("language", "en")
			var title_before := hud.order_panel._name_label.text
			var body_before := hud.order_panel._line_label.text
			for language in ["en", "ms"]:
				SaveManager.data.settings.language = language
				for lesson in TutorialLibrary.all():
					for step in lesson.tutorial_steps:
						hud.order_panel._name_label.text = TutorialText.text(step.title)
						hud.order_panel._line_label.text = TutorialText.text(step.body)
						await get_tree().process_frame
						await get_tree().process_frame
						for label in [hud.order_panel._name_label, hud.order_panel._line_label]:
							var font_size: int = label.get_theme_font_size("font_size")
							var extent: Vector2 = label.get_theme_font("font").get_multiline_string_size(label.text,HORIZONTAL_ALIGNMENT_CENTER,label.size.x-4,font_size,-1,TextServer.BREAK_MANDATORY | TextServer.BREAK_WORD_BOUND | TextServer.BREAK_ADAPTIVE)
							check(extent.y <= label.size.y, "tutorial copy fits actual HUD: " + label.text)
			SaveManager.data.settings.language = language_before
			hud.order_panel._name_label.text = title_before
			hud.order_panel._line_label.text = body_before
			await get_tree().process_frame
			await get_tree().process_frame
		check(hud.board_holder.get_global_rect().position.y >= hud.order_panel.get_global_rect().end.y,"board clears order area")
		var board := screen.board
		var board_rect := Rect2(board.get_global_rect().position+board.board_origin,Vector2.ONE*board.cell_size*board.logic.width)
		check(get_viewport().get_visible_rect().encloses(board_rect),"board fits viewport")
		if tutorial == 0 and board.logic.width == 8 and get_viewport().get_visible_rect().size.aspect() < .6:
			check(board_rect.size.x/hud.size.x >= .85,"eight-column board uses at least 85 percent width")
		for tile in board._tiles.values():
			check(is_equal_approx(tile.icon.cell_ratio,.92),"larger food within cell")
		for button in hud.booster_bar._buttons.values():
			check(button.size.x <= 137 and absf(button.size.x-button.size.y)<1,"compact square booster buttons")
		check(hud.booster_bar._available == (tutorial == 0),"tutorial boosters stay locked")
		for booster in hud.booster_bar._buttons:
			var button: Button = hud.booster_bar._buttons[booster]
			var badge := button.get_parent().get_node("Badge") as PanelContainer
			check(button.get_theme_stylebox("normal") is StyleBoxTexture,"booster icons use restored colorful squares")
			check(badge.get_theme_stylebox("panel") is StyleBoxTexture,"count chip uses graphic")
			check(is_equal_approx(badge.size.x,badge.size.y),"red chip remains circular")
			check(badge.visible == (tutorial == 0),"locked tutorial hides stock chips")
			check(button.get_node("LockIcon").visible == (tutorial != 0),"tutorial lock icon retained")
			if tutorial == 0:
				check(badge.get_child(0).text == str(EconomyManager.booster_count(booster)),"count shows actual stock")
			else:
				check(button.disabled,"tutorial booster is disabled")
		var hand := hud.booster_bar._buttons[EconomyManager.Booster.SPATULA].get_node("BoosterArt") as TextureRect
		check(hand.texture == GameplaySkin.texture("booster_hand"),"hand replaces spatula")
		if DisplayServer.get_name() != "headless":
			await RenderingServer.frame_post_draw
			var pixels := get_window().size
			get_viewport().get_texture().get_image().save_png("res://.shots/readability_%dx%d_%s.png" % [pixels.x,pixels.y,"tutorial" if tutorial > 0 else "campaign"])
		var settings := hud.get_node("PauseButton") as Button
		check(settings.get_node("SettingsArtwork").stretch_mode == TextureRect.STRETCH_KEEP_ASPECT_CENTERED,"settings icon stays circular")
		settings.pressed.emit()
		check(screen._pause_overlay != null and get_tree().paused,"settings button opens pause menu")
		screen._pause_overlay.resume_pressed.emit()
		check(not get_tree().paused,"resume returns to game")
		screen.free()
	AudioManager.stop_music()
	print("Gameplay readability: %s (%d problems)" % ["PASS" if problems == 0 else "FAIL",problems])
	get_tree().quit(0 if problems == 0 else 1)
