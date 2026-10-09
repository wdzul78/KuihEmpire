extends Node

var problems := 0

func check(ok: bool, message: String) -> void:
	if not ok:
		problems += 1
		push_error(message)

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	run.call_deferred()

func run() -> void:
	SaveManager.save_path = "user://call_pause_test.json"
	SaveManager.reset()
	for tutorial in [0, 1]:
		var screen := LevelController.new()
		screen.level_id = 1
		screen.tutorial_index = tutorial
		add_child(screen)
		await get_tree().create_timer(.4).timeout
		var board := screen.board
		var moves := screen.moves_left
		var logic := board.logic
		board._drag_from = Vector2i(0, 0)
		board._drag_moved = true
		board._last_tap_ms = Time.get_ticks_msec()
		# A busy board must retain its resolution while its tween is suspended.
		board.busy = true
		var tween := board.create_tween()
		tween.tween_interval(.25)
		tween.tween_callback(func() -> void: board.busy = false)
		screen.propagate_notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
		await get_tree().process_frame
		await get_tree().process_frame
		check(get_tree().paused and screen._pause_overlay != null, "focus loss opens usable pause menu")
		var overlay := screen._pause_overlay
		check(overlay.can_process(), "Resume remains interactive while gameplay is paused")
		check(board._drag_from == Vector2i(-1, -1) and not board._drag_moved and board._last_tap_ms == -1, "interrupted gesture cleared")
		screen.notification(Node.NOTIFICATION_APPLICATION_PAUSED)
		await get_tree().process_frame
		await get_tree().process_frame
		check(screen._pause_overlay == overlay, "duplicate OS events reuse one overlay")
		screen.notification(Node.NOTIFICATION_APPLICATION_RESUMED)
		screen.notification(Node.NOTIFICATION_APPLICATION_FOCUS_IN)
		await get_tree().create_timer(.35).timeout
		check(get_tree().paused and board.busy, "return from call waits for Resume and holds tween")
		check(screen.moves_left == moves and board.logic == logic, "pause preserves moves and puzzle")
		overlay.resume_pressed.emit()
		check(not get_tree().paused and screen._pause_overlay == null, "Resume unpauses gameplay")
		await get_tree().create_timer(.35).timeout
		check(not board.busy, "in-flight tween completes after Resume")
		screen.notification(Node.NOTIFICATION_APPLICATION_PAUSED)
		await get_tree().process_frame
		await get_tree().process_frame
		check(get_tree().paused, "background-only interruption also pauses")
		screen.queue_free()
		await get_tree().process_frame
		check(not get_tree().paused, "leaving paused screen releases tree pause")
	print("Call pause tests: %d failures" % problems)
	get_tree().quit(0 if problems == 0 else 1)
