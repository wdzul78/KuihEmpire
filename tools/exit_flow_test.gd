extends Node

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	run.call_deferred()

func run() -> void:
	SaveManager.save_path = "user://exit_flow_test.json"
	for during_move in [false, true]:
		var screen := LevelController.new()
		screen.level_id = 20
		get_tree().root.add_child(screen)
		get_tree().current_scene = screen
		await get_tree().create_timer(.5).timeout
		screen.story.hide()
		if during_move:
			screen.board.booster_tray(Vector2i(3, 3))
			await get_tree().create_timer(.1).timeout
		screen._open_pause_menu()
		assert(get_tree().paused)
		screen._pause_overlay.quit_pressed.emit()
		await get_tree().create_timer(2.0).timeout
		assert(not get_tree().paused and not SceneManager._busy)
		assert(get_tree().current_scene.scene_file_path == SceneManager.HOME)
		assert(is_zero_approx(SceneManager._veil.color.a))
		var home := get_tree().current_scene
		get_tree().current_scene = self
		home.queue_free()
		await get_tree().process_frame
	print("Exit flow: PASS (Back to Stall idle and during special animation)")
	# Exercise the real window-close signal with a paused scene and live audio.
	var final_screen := LevelController.new()
	final_screen.level_id = 20
	get_tree().root.add_child(final_screen)
	get_tree().current_scene = final_screen
	await get_tree().create_timer(.3).timeout
	final_screen.propagate_notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
	final_screen.notification(Node.NOTIFICATION_WM_CLOSE_REQUEST)
	await get_tree().process_frame
	await get_tree().process_frame
	assert(not get_tree().paused and final_screen._pause_overlay == null)
	final_screen._open_pause_menu()
	print("Window close requested while paused")
	get_tree().root.close_requested.emit()
