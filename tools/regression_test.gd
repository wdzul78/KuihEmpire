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


func _check_character_layout() -> void:
	for id in CustomerLibrary.all_ids():
		check(CustomerLibrary.get_customer(id).texture != null, "customer art missing: %s" % id)
	for blocker in TutorialLibrary.get_stage(7).blockers:
		check(blocker.kind != BlockerSpec.Kind.STEAMER, "steamer reintroduced in queue tutorial")
	GameManager.pending_tutorial_index = 0
	var screen := LevelController.new()
	screen.level_id = 21
	add_child(screen)
	await get_tree().create_timer(0.4).timeout
	check(screen.story.visible, "stage 21 steamer introduction missing")
	check(screen.story._tap_indicator.is_visible_in_tree(), "story dialogue lacks tap hand")
	var spotlight := screen.story.get_node("DialogueSpotlight") as DialogueSpotlight
	check(spotlight.visible and screen.story._card.z_index > spotlight.z_index, "story bubble not highlighted above dim layer")
	check(screen.hud.order_panel._aina.z_index > spotlight.z_index and screen.hud.order_panel._aina.modulate == Color.WHITE, "Aina dimmed during dialogue")
	screen.story._tap_indicator._clock = 0
	screen.story._tap_indicator._process(.20)
	check(screen.story._tap_indicator.frame_index == 1, "supplied finger sprite does not animate")
	check(screen.hud.size.x <= screen.get_viewport_rect().size.x, "long title expanded HUD outside screen")
	check(screen.story._card.get_global_rect().end.y <= screen.hud.order_panel._card.get_global_rect().position.y, "dialogue covers order panel")
	check(screen.hud.booster_bar._buttons.size() == 4, "main booster tray must contain four buttons")
	for entry in screen.hud.order_panel._chips.values():
		check(screen.hud.order_panel._card.get_global_rect().encloses(entry["root"].get_global_rect()), "order item exceeds wooden board")
		check(entry["root"].get_global_rect().encloses(entry["label"].get_global_rect()), "order counter exceeds item area")
	check(screen.hud.board_holder.get_global_rect().end.y < screen.hud._booster_row.get_global_rect().position.y, "board overlaps booster tray")
	for pos in screen.board._overlays:
		check(screen.board._overlays[pos].z_index > screen.board._tiles[pos].z_index, "cover hidden below food sprite")
	screen.story.close()
	check(screen.story._card.z_index == 0, "story bubble z order not restored")
	check(screen.hud.order_panel._aina.z_index == 0, "Aina z order not restored")
	check(screen.hud.order_panel._portrait.modulate == Color.WHITE, "dialogue left customer dimmed")
	screen.queue_free()
	await get_tree().process_frame
	screen = LevelController.new()
	screen.tutorial_index = 1
	add_child(screen)
	await get_tree().process_frame
	check(screen.hud._booster_row.visible, "early tutorial hides booster tray")
	check(not screen.coach._tap_indicator.visible, "gesture lesson incorrectly asks for dialogue tap")
	check(screen.hud.booster_bar._buttons[EconomyManager.Booster.SPATULA].disabled, "early tutorial booster is unlocked")
	var heart := screen.hud.find_child("HeartMeter", true, false) as HeartDisplay
	heart.pressed.emit()
	check(not get_tree().current_scene.has_node("HeartRefillDialog"), "gameplay heart opened refill dialog")
	check(not screen.hud._coin_pill.show_plus, "gameplay coin shows refill plus")
	for button in screen.hud.booster_bar._buttons.values():
		check(button.get_node("LockIcon").visible and not button.get_node("BoosterArt").visible, "locked booster did not replace art with lock")
		check(not button.get_parent().get_node("Badge").visible, "locked booster shows inventory badge")
	var inventory := EconomyManager.booster_count(EconomyManager.Booster.SHUFFLE)
	screen._on_booster_requested(EconomyManager.Booster.SHUFFLE)
	check(EconomyManager.booster_count(EconomyManager.Booster.SHUFFLE) == inventory, "early tutorial consumed locked booster")
	screen.queue_free()
	await get_tree().process_frame
	screen = LevelController.new()
	screen.level_id = 1
	add_child(screen)
	await get_tree().process_frame
	check(screen.story._name_label.text == "Pakyai", "customer dialogue name missing")
	check((screen.story._card as SpeechBubble).speaker_on_left, "customer bubble tail points away from speaker")
	screen.story.advance()
	check(screen.story._name_label.text == "Aina", "dialogue did not switch speaker")
	check(not (screen.story._card as SpeechBubble).speaker_on_left, "Aina bubble tail points away from speaker")
	screen.story.close()
	screen._on_kuih_collected({&"onde_onde": 1})
	check(screen.hud.score_progress.score == screen.level.scoring.order_item, "score header did not update from order collection")
	EconomyManager.grant_booster(EconomyManager.Booster.EXTRA_MOVES, 1)
	var previous_moves := screen.moves_left
	screen._open_pause_menu()
	var extra_button: Button = null
	for button in screen._pause_overlay.find_children("*", "Button", true, false):
		if (button as Button).text.begins_with("+5 "):
			extra_button = button
	check(extra_button != null, "extra moves unavailable from pause menu")
	if extra_button != null:
		extra_button.pressed.emit()
		check(screen.moves_left == previous_moves + 5 and not get_tree().paused, "pause extra moves did not grant/resume")
	screen.queue_free()
	await get_tree().process_frame


func _check_special_lesson() -> void:
	for lesson in [4, 5]:
		var screen := LevelController.new()
		screen.tutorial_index = lesson
		add_child(screen)
		await get_tree().process_frame
		var pair := screen.coach.guided_cells()
		check(pair.size() == 2, "special tutorial has no guided swap")
		screen._on_hint()
		check(screen.board._hint_cells == pair, "tutorial hint chose a generic match instead of lesson swap")
		var before := screen.board.logic.get_cell(pair[0]).kuish_id()
		if screen.coach.can_tap_through():
			check(screen.coach._tap_indicator.visible, "intro dialogue lacks tap hand")
			check(screen.coach._spotlight.visible and screen.coach._card.z_index == 81, "tutorial intro not highlighted")
			check(screen.hud.order_panel._aina.z_index == 81, "tutorial Aina not highlighted")
			check(not screen.coach._body.text.contains("Tap here"), "intro still contains tap-to-continue text")
			screen.board.attempt_swap(pair[0], pair[1])
			await wait_idle(screen)
			check(screen.board.logic.get_cell(pair[0]).kuish_id() == before, "intro allowed board changes")
			screen.coach.tap_through()
		check(not screen.coach._tap_indicator.visible, "special action step shows dialogue tap hand")
		check(not screen.coach._spotlight.visible and screen.coach._card.z_index == 0, "tutorial action still dimmed by dialogue overlay")
		check(screen.hud.order_panel._aina.z_index == 0, "Aina remained above the board after dialogue")
		screen._process(0)
		check(screen.board._swipe_indicator.visible, "guided special lesson lacks swipe hand")
		check(screen.board._swipe_indicator.mouse_filter == Control.MOUSE_FILTER_IGNORE, "swipe hand blocks player input")
		for test_pair in [[Vector2i(1, 1), Vector2i(0, 1), "left"], [Vector2i(0, 1), Vector2i(1, 1), "right"], [Vector2i(1, 1), Vector2i(1, 0), "up"], [Vector2i(1, 0), Vector2i(1, 1), "down"]]:
			screen.board._swipe_indicator.show_swipe(test_pair[0], test_pair[1])
			check(screen.board._swipe_indicator.direction == test_pair[2], "wrong swipe sprite direction")
			screen.board._swipe_indicator._process(.5)
			check(screen.board._swipe_indicator.frame_index != (3 if test_pair[2] == "left" else 0), "swipe sprite does not animate")
		screen.board._swipe_indicator.show_swipe(pair[0], pair[1])
		if lesson == 4:
			check(not screen.coach.can_tap_through(), "match-4 lesson still waits for intro tap")
			check(screen.coach.allows_swap(pair[0], pair[1]), "highlighted match-4 swap is locked")
			screen._process(0)
			check(screen.board._focus_cells == pair, "special lesson lacks immediate focus")
			check(screen.board._tiles[Vector2i.ZERO].modulate.r < .5, "unrelated tutorial tiles are not dimmed")
			var wrong := Vector2i(0, 2)
			before = screen.board.logic.get_cell(wrong).kuish_id()
			screen.board.attempt_swap(wrong, Vector2i(1, 2))
			await wait_idle(screen)
			check(screen.board.logic.get_cell(wrong).kuish_id() == before, "match-3 consumed the scripted match-4 layout")
		var created: Array[int] = []
		screen.board.special_created.connect(func(kind: int) -> void: created.append(kind))
		screen.board.attempt_swap(pair[0], pair[1])
		await wait_idle(screen)
		var expected := BoardCell.Special.TAPAU if lesson == 4 else BoardCell.Special.DULANG
		check(expected in created, "guided tutorial swap did not create expected special")
		check(not screen.coach._finished and not screen.finished, "special tutorial ended at creation before activation")
		check(screen.coach.can_tap_through(), "Aina did not explain the newly created special")
		var visible_specials := 0
		for pos in screen.board._tiles:
			var tile: TileView = screen.board._tiles[pos]
			if screen.board.logic.get_cell(pos).special == expected:
				visible_specials += 1
				check(tile.icon.special_kind == expected, "created special is hidden behind its old kuih icon")
		check(visible_specials > 0, "created special disappeared before activation")
		if lesson == 4 and "--capture-special" in OS.get_cmdline_user_args():
			await RenderingServer.frame_post_draw
			get_viewport().get_texture().get_image().save_png("res://.shots/tapau_ready.png")
		check(screen.board._focus_cells.is_empty(), "focus remained after special creation")
		check(not screen.board._swipe_indicator.visible, "swipe hand remained after successful move")
		screen.coach.tap_through()
		screen._process(0)
		var activation := screen.coach.hint_cells()
		check(activation.size() == 2 and screen.board._swipe_indicator.visible, "special activation has no guided gesture")
		if activation.size() == 2:
			check(screen.board._tiles[activation[0]].icon.special_kind == expected, "activation hand points at an ordinary kuih")
		if lesson == 4 and "--capture-special" in OS.get_cmdline_user_args():
			await RenderingServer.frame_post_draw
			get_viewport().get_texture().get_image().save_png("res://.shots/tapau_activation.png")
		var effects: Array[int] = []
		screen.board.special_activated.connect(func(kind: int) -> void: effects.append(kind))
		var previews: Array = []
		var batches: Array = []
		screen.board.special_effect_preview.connect(func(kind: int, cells: Array[Vector2i]):
			previews.append(cells.duplicate())
			if "--capture-special" in OS.get_cmdline_user_args():
				await RenderingServer.frame_post_draw
				get_viewport().get_texture().get_image().save_png("res://.shots/dulang_preview.png")
				await get_tree().create_timer(.95).timeout
				await RenderingServer.frame_post_draw
				get_viewport().get_texture().get_image().save_png("res://.shots/dulang_cleared.png"))
		screen.board.kuih_collected.connect(func(totals: Dictionary): batches.append(totals.duplicate()))
		if activation.size() == 2:
			if lesson == 5:
				check(TutorialCoach._edge_distance(activation[1], screen.board.logic) >= 1, "Dulang guide sends blast to an edge")
			screen.board.attempt_swap(activation[0], activation[1])
			await wait_idle(screen)
		if lesson == 5:
			check(previews.size() == 1 and previews[0].size() == 9, "Dulang preview does not cover nine tiles")
			var collected := 0
			if not batches.is_empty():
				for amount in batches[0].values():
					collected += int(amount)
			check(collected == 9, "Dulang actual first clear is not nine tiles: %d" % collected)
		check(expected in effects, "special effect was not activated")
		check(not screen.finished and screen.coach.can_tap_through(), "effect recap disappeared before Aina could explain")
		screen.coach.tap_through()
		await get_tree().process_frame
		check(screen.coach._finished and screen.finished, "special tutorial did not finish after effect and recap")
		await get_tree().create_timer(.5).timeout
		screen.queue_free()
		await get_tree().process_frame


func _check_result_actions() -> void:
	var popup := ResultOverlay.new()
	add_child(popup)
	await get_tree().process_frame
	var actions := {"next": 0, "retry": 0, "home": 0}
	popup.continue_pressed.connect(func() -> void: actions["next"] += 1)
	popup.retry_pressed.connect(func() -> void: actions["retry"] += 1)
	popup.home_pressed.connect(func() -> void: actions["home"] += 1)
	SaveManager.set_setting("language", "en")
	popup.stage_number = 3
	popup.show_win("Stage 3", 2, 60, [], false)
	check(popup._stage_label.text == "STAGE 3 COMPLETE", "result stage header is incorrect")
	check(popup._coins_label.text == "+60" and popup._stars.filled == 2, "result does not show actual rewards")
	popup._primary.pressed.emit()
	popup._secondary.pressed.emit()
	popup._home.pressed.emit()
	check(actions == {"next": 1, "retry": 1, "home": 1}, "success result buttons emit wrong actions")
	popup.show_fail("Missing kuih", true)
	popup._primary.pressed.emit()
	check(actions["retry"] == 2, "failure primary button does not retry")
	check(popup._coins_label.text == "+0" and popup._stars.filled == 0, "failure result invents rewards")
	SaveManager.set_setting("language", "ms")
	popup.show_win("Stage 3", 3, 60, [], false)
	check(popup._title.text == "PESANAN SIAP!", "result Malay translation missing")
	popup.queue_free()
	await get_tree().process_frame


func run() -> void:
	check(TutorialLibrary.next_index(5) == 7, "opening tutorial still leads into leaf lesson")
	check(not TutorialLibrary.has(6), "leaf lesson remains active in opening tutorial")
	SaveManager.data["tutorial_index"] = 6
	check(ProgressionManager.tutorial_index() == 7, "saved leaf lesson does not resume at queue lesson")
	check(LevelLibrary.get_level(7).story_before == &"beat_07_leaf", "campaign stage 7 lost leaf introduction")
	var collection := LevelController.new()
	collection.tutorial_index = 3
	add_child(collection)
	await get_tree().process_frame
	while collection.coach.can_tap_through():
		collection.coach.tap_through()
	await get_tree().process_frame
	collection._process(0)
	check(collection.board._swipe_indicator.visible, "collection tutorial lacks immediate swipe gesture")
	check(collection.board._swipe_indicator.direction == "down", "collection gesture points away from Onde-onde match")
	collection.board._swipe_indicator.direction = "right"
	collection.board._swipe_indicator.frame_index = 3
	check(collection.board._swipe_indicator.frame_region().position.x == 1705, "last right-swipe frame includes neighbouring hand")
	check(collection.coach._current().gate_value == 3, "Pakyai lesson has no collection target")
	# Play the actual taught swap; a full order must lead to Aina's recap.
	collection.board.attempt_swap(Vector2i(2, 1), Vector2i(2, 2))
	await wait_idle(collection)
	check(collection.orders[0].is_complete(), "Pakyai guided swap did not fill the order")
	check(collection.coach.can_tap_through(), "Pakyai lesson stuck collecting after 3/3")
	check(not collection.finished, "Pakyai lesson skipped the serving explanation")
	collection.coach.tap_through()
	await get_tree().process_frame
	await get_tree().process_frame
	check(collection.finished and collection.result.is_win, "Pakyai lesson did not end after serving recap")
	collection.free()
	await _check_result_actions()
	await _check_character_layout()
	await _check_special_lesson()
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
	check(screen.hud._booster_row.visible, "tutorial booster tray is hidden")
	check(screen.coach._card == screen.hud.order_panel._bubble, "coach did not use the upper dialogue")
	check(screen.coach._card.get_global_rect().end.y <= screen.hud.order_panel._card.get_global_rect().position.y, "tutorial instructions cover order board")
	check(not screen.hud.booster_bar._buttons[EconomyManager.Booster.SPATULA].disabled, "full tutorial booster is locked")
	for button in screen.hud.booster_bar._buttons.values():
		check(not button.get_node("LockIcon").visible and button.get_node("BoosterArt").visible, "unlocked booster kept lock icon")
	if screen.coach.can_tap_through():
		var before_step := screen.coach.index
		var tap := InputEventMouseButton.new()
		tap.pressed = true
		tap.button_index = MOUSE_BUTTON_LEFT
		tap.position = Vector2(4, 4)
		screen.coach._input(tap)
		check(screen.coach.index == before_step + 1, "tutorial dialogue did not accept tap outside bubble")
		screen.coach.begin(stage.tutorial_steps)
		var touch := InputEventScreenTouch.new()
		touch.pressed = true
		touch.position = board.get_global_rect().get_center()
		screen.coach._input(touch)
		check(screen.coach.index == before_step + 1, "tutorial dialogue did not accept touch over board")
		while screen.coach.can_tap_through():
			screen.coach._input(touch)
		var action_step := screen.coach.index
		screen.coach._input(touch)
		check(screen.coach.index == action_step, "screen tap skipped tutorial action gate")
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
	check(screen.result._coins_label.text == "+0" and screen.result._stars.filled == 0, "failure displays unearned rewards")
	screen.result._secondary.pressed.emit()
	check(screen.result.has_node("RecoveryOptions"), "Use Booster does not open recovery choices")
	var extra := screen.result.find_child("InventoryMoves", true, false) as Button
	EconomyManager.grant_booster(EconomyManager.Booster.EXTRA_MOVES, 1)
	var stock := EconomyManager.booster_count(EconomyManager.Booster.EXTRA_MOVES)
	var prior := screen.moves_left
	screen.finished = true
	screen.board.enabled = false
	extra.pressed.emit()
	check(EconomyManager.booster_count(EconomyManager.Booster.EXTRA_MOVES) == stock - 1, "result booster did not consume exactly one item")
	check(screen.moves_left == prior + LevelController.EXTRA_MOVES and not screen.finished and screen.board.enabled and not screen.result.visible, "result booster did not resume play with five moves")
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
	check(get_tree().current_scene.scene_file_path == SceneManager.RECIPE_BOOK, "Home book did not open Recipes")
	ProgressionManager.mark_story_read(StoryLibrary.PROLOGUE)
	await SceneManager.goto(SceneManager.JOURNEY, true)
	var map: JourneyMap = get_tree().current_scene
	var memories := map.memories_for(JourneyMap.ROUTE[0])
	check(not memories.is_empty(), "map omitted the read prologue")
	map._replay_memory(memories[0])
	await wait_navigation()
	check(get_tree().current_scene is StoryScreen, "map memory did not open story deck")
	get_tree().current_scene.finish()
	await wait_navigation()
	check(get_tree().current_scene.scene_file_path == SceneManager.JOURNEY, "map story did not return after caller freed")
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
