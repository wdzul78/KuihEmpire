extends Node

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	run.call_deferred()

func run() -> void:
	var overlay := PauseOverlay.new()
	overlay.stage_title = "Crisp Corner · Halangan"
	overlay.extra_count = 2
	overlay.extra_available = true
	add_child(overlay)
	assert(not overlay._pause_panel.has_node("MusicSwitch"))
	assert(not overlay._pause_panel.has_node("SfxSwitch"))
	get_tree().paused = true
	await get_tree().create_timer(.3).timeout
	if DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("res://.analysis/clean-pause.png")
	var confirmed := [0]
	var original_language: String = str(SaveManager.get_setting("language","en"))
	for language in ["ms","en"]:
		SaveManager.data.settings.language = language
		overlay.confirm_leave(JourneyArt.localized("Keluar akan menolak 1 hati. Kembali ke gerai?","Leaving costs 1 heart. Return to the stall?"),func() -> void: confirmed[0] += 1)
		await get_tree().create_timer(.3).timeout
		if DisplayServer.get_name() != "headless":
			await RenderingServer.frame_post_draw
			get_viewport().get_texture().get_image().save_png("res://.analysis/leave-confirm-%s.png" % language)
		overlay._cancel_leave()
		await get_tree().process_frame
	SaveManager.data.settings.language = original_language
	overlay.confirm_leave(JourneyArt.localized("Keluar akan menolak 1 hati. Kembali ke gerai?","Leaving costs 1 heart. Return to the stall?"),func() -> void: confirmed[0] += 1)
	assert(overlay._heart.get_node("CurrentHeartCount").text == str(HeartManager.current()))
	assert(not overlay._pause_panel.visible)
	overlay.confirm_leave("duplicate",func() -> void: confirmed[0] += 1)
	assert(confirmed[0] == 0)
	await get_tree().create_timer(.3).timeout
	if DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("res://.analysis/clean-leave-confirm.png")
	await overlay.play_heart_loss(3,2)
	assert(overlay._heart.modulate.a == 0)
	overlay._cancel_leave()
	assert(overlay._pause_panel.visible)
	overlay.confirm_leave("Leaving costs 1 heart. Return to the stall?",func() -> void: confirmed[0] += 1)
	var leave_button: Button
	for child in overlay._leave_dialog.get_children():
		if child is Button and child.name == "LeaveButton":
			leave_button = child
	assert(leave_button != null and leave_button.anchor_right >= .70,"Leave icon shares the confirmation hit area")
	leave_button.pressed.emit()
	leave_button.pressed.emit()
	assert(confirmed[0] == 1,"Repeated leave presses confirm only once")
	get_tree().paused = false
	overlay.free()
	AudioManager.stop_music()
	print("Clean pause: PASS (single confirmation, cancel, paused heart animation, no premature confirmation)")
	get_tree().quit()
