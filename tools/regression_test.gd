extends Node

var problems: Array[String] = []


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	SaveManager.save_path = "user://kuih_regression_save.json"
	SaveManager.reset()
	run.call_deferred()


func check(condition: bool, message: String) -> void:
	if not condition:
		problems.append(message)


func wait_idle(screen: LevelController) -> void:
	var deadline := Time.get_ticks_msec() + 20000
	while screen.board.busy or screen._serving:
		if Time.get_ticks_msec() > deadline:
			check(false, "board/serving did not settle")
			return
		await get_tree().process_frame
	await get_tree().create_timer(0.25).timeout


func run() -> void:
	var rules := BoardState.new()
	var stage := TutorialLibrary.get_stage(8)
	rules.setup(stage.width, stage.height, stage.kuih, 12345)
	rules.get_cell(Vector2i.ZERO).clear_kuish()
	rules.apply_blockers([BlockerSpec.make(BlockerSpec.Kind.BANANA_LEAF, [Vector2i.ZERO])])
	check(rules.get_cell(Vector2i.ZERO).has_kuish(), "blocker on empty cell did not restore kuih")
	var screen := LevelController.new()
	screen.tutorial_index = 8
	add_child(screen)
	await get_tree().process_frame
	var board := screen.board
	# Keep objectives open so boosters can be tested independently of rewards.
	for order in screen.orders:
		for id in order.remaining:
			order.remaining[id] = 10000
	var captured: Array[Dictionary] = []
	board.kuih_collected.connect(func(totals: Dictionary) -> void: captured.append(totals))
	var totals := board.collect_all()
	var count := 0
	for id in totals:
		count += int(totals[id])
	check(count == 64, "collect_all must count all occupied cells")
	# Pause during a live tween; no animation or restart may advance the board.
	var moves := board.logic.find_possible_moves(1)
	board.attempt_swap(moves[0]["a"], moves[0]["b"])
	await get_tree().process_frame
	screen._open_pause_menu()
	var paused_overlay := screen._pause_overlay
	var paused_logic := board.logic
	var positions: Dictionary = {}
	for tile in board._tiles.values():
		positions[tile] = tile.position
	screen._open_pause_menu()
	check(screen._pause_overlay == paused_overlay, "duplicate pause menu was created")
	screen._on_restart()
	await get_tree().create_timer(0.4).timeout
	check(get_tree().paused and board.logic == paused_logic and board.busy, "paused move advanced or restarted")
	for tile in positions:
		check(tile.position == positions[tile], "board tween moved while paused")
	screen._resume_level()
	await wait_idle(screen)
	captured.clear()
	# Invalid swaps must return both views to their original positions.
	var a := Vector2i(0, 0)
	var b := Vector2i(7, 7)
	board.attempt_swap(a, b)
	await wait_idle(screen)
	check(board._tiles[a].position == board.cell_to_pos(a), "invalid swap displaced first tile")
	check(board._tiles[b].position == board.cell_to_pos(b), "invalid swap displaced second tile")
	board.show_hint()
	await get_tree().create_timer(0.23).timeout
	for pos in board._hint_cells:
		check(board._tiles[pos].scale == Vector2.ONE, "hint enlarged a tile")
	board.clear_hints()
	EconomyManager.grant_booster(EconomyManager.Booster.TRAY, 2)
	EconomyManager.grant_booster(EconomyManager.Booster.SHUFFLE, 2)
	EconomyManager.grant_booster(EconomyManager.Booster.SPATULA, 2)
	var inventory := EconomyManager.booster_count(EconomyManager.Booster.SPATULA)
	screen._on_booster_targeted(EconomyManager.Booster.SPATULA, Vector2i(-1, -1))
	check(EconomyManager.booster_count(EconomyManager.Booster.SPATULA) == inventory, "invalid target consumed booster")
	screen._on_booster_targeted(EconomyManager.Booster.TRAY, Vector2i(3, 3))
	check(board.busy, "tray did not lock board during animation")
	var shuffle_count := EconomyManager.booster_count(EconomyManager.Booster.SHUFFLE)
	screen._on_booster_requested(EconomyManager.Booster.SHUFFLE)
	screen._on_restart()
	check(EconomyManager.booster_count(EconomyManager.Booster.SHUFFLE) == shuffle_count, "busy board consumed second booster")
	await wait_idle(screen)
	count = 0
	if not captured.is_empty():
		for id in captured[0]:
			count += int(captured[0][id])
	check(count == 9, "tray must collect exactly nine initial tiles, got %d" % count)
	check(board.logic.is_clean() and board.logic.has_possible_move(), "booster left matches or dead board")
	for tile in board._tiles.values():
		check(tile.scale == Vector2.ONE, "refilled tile remained undersized")
	# Two collection batches during the serve animation must advance once each.
	screen.orders.clear()
	screen.active_index = 0
	screen._served_index = 0
	for i in 3:
		var order := CustomerOrder.new()
		order.remaining = {&"onde_onde": 1}
		order.target = order.remaining.duplicate()
		screen.orders.append(order)
	screen._on_kuih_collected({&"onde_onde": 1})
	screen._on_kuih_collected({&"onde_onde": 1})
	check(screen.active_index == 2, "overlapping collections lost queue progress")
	check(not board.enabled, "serving allowed another move before result evaluation")
	screen._open_pause_menu()
	await get_tree().create_timer(1.0).timeout
	check(screen._served_index == 0 and screen._serving, "serve timer advanced while paused")
	screen._resume_level()
	await wait_idle(screen)
	check(screen._served_index == 2 and screen.orders[0].served and screen.orders[1].served, "guests not served once each")
	screen.result.show_win("Test", 3, 10, [], false)
	check(screen.result.visible and screen.result.is_win, "win overlay stayed hidden")
	screen.result.visible = false
	screen.result.show_fail("Test", true)
	check(screen.result.visible and not screen.result.is_win, "failure overlay stayed hidden")
	for button in screen.result._buttons.get_children():
		if button is Button and not button.is_queued_for_deletion():
			check(not button.text.begins_with("Watch Ad"), "MVP offered an unconfigured ad")
	screen.queue_free()
	await get_tree().process_frame
	SaveManager.data["levels"] = {"30": {"stars": 3}}
	check(ProgressionManager.current_level() == 30, "campaign completion offered nonexistent stage 31")
	SaveManager.reset()
	# Keep this runner alive while real screen navigation frees Home / Journey.
	get_tree().current_scene = null
	await SceneManager.goto(SceneManager.HOME, true)
	get_tree().current_scene._on_story()
	await wait_navigation()
	check(get_tree().current_scene is StoryScreen, "Home story did not open")
	get_tree().current_scene.finish()
	await wait_navigation()
	check(ProgressionManager.story_read(StoryLibrary.PROLOGUE), "finished prologue was not recorded after caller freed")
	check(get_tree().current_scene.scene_file_path == SceneManager.HOME, "Home story did not return after caller freed")
	await SceneManager.goto(SceneManager.JOURNEY, true)
	get_tree().current_scene._on_story()
	await wait_navigation()
	get_tree().current_scene.finish()
	await wait_navigation()
	check(get_tree().current_scene.scene_file_path == SceneManager.JOURNEY, "Journey story did not return after caller freed")
	await SceneManager.goto_tutorial(1)
	var current: LevelController = get_tree().current_scene
	current._notification(NOTIFICATION_APPLICATION_PAUSED)
	check(get_tree().paused and current._pause_overlay != null, "application background did not pause current level")
	await SceneManager.goto(SceneManager.HOME, true)
	check(not get_tree().paused, "leaving a paused level left Home paused")
	print("Regression tests: %s (%d problems)" % ["PASS" if problems.is_empty() else "FAIL", problems.size()])
	for problem in problems:
		print("  ! " + problem)
	get_tree().quit(0 if problems.is_empty() else 1)


func wait_navigation() -> void:
	var deadline := Time.get_ticks_msec() + 5000
	while SceneManager._busy:
		if Time.get_ticks_msec() > deadline:
			check(false, "navigation timed out")
			return
		await get_tree().process_frame
