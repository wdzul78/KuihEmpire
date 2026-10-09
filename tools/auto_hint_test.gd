extends Node

func _ready() -> void:
	run.call_deferred()

func run() -> void:
	SaveManager.save_path = "user://auto_hint_test.json"
	var screen := LevelController.new()
	screen.level_id = 20
	add_child(screen)
	await get_tree().create_timer(.4).timeout
	screen.story.hide()
	screen.board.enabled = true
	var board := screen.board
	var before := []
	for row in board.logic.grid:
		for cell in row:
			before.append(cell)
	var rng_before := board.logic.rng.state
	board.clear_hints()
	board._idle_seconds = board.AUTO_HINT_DELAY-.05
	await get_tree().create_timer(.1).timeout
	assert(board._focus_cells.size() == 2 and board._hint_matches.size() >= 3)
	assert(board._hint_matches.has(board._focus_cells[0]))
	assert(board.logic.rng.state == rng_before)
	var after := []
	for row in board.logic.grid:
		for cell in row:
			after.append(cell)
	assert(before == after)
	if DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("res://.shots/auto_hint.png")
	# Keep the same hint alive across several motion cycles without new input.
	var hinted_pair := board._focus_cells.duplicate()
	var moving_tile: TileView = board._tiles[hinted_pair[0]]
	var origin := moving_tile._hint_origin
	for cycle in range(6):
		await get_tree().create_timer(1.7).timeout
		assert(board._idle_hint and board._focus_cells == hinted_pair)
		assert(moving_tile._hint_nudge and moving_tile._pulse_tween.is_valid() and moving_tile._pulse_tween.is_running())
		assert(moving_tile.position.distance_to(origin) <= moving_tile.size.x*.121)
		assert(board.logic.rng.state == rng_before)
	var touch := InputEventScreenTouch.new()
	touch.pressed = true
	touch.position = board._cell_center(Vector2i.ZERO)
	board._gui_input(touch)
	assert(board._hint_cells.is_empty() and board._hint_matches.is_empty())
	assert(moving_tile.position.is_equal_approx(origin) and not moving_tile._hint_nudge)
	board.cancel_interrupted_input()
	# Reproduce a real swipe; release occurs during its match animation.
	var move: Dictionary = board.logic.find_possible_moves(1)[0]
	touch.position = board._cell_center(move.a)
	board._gui_input(touch)
	var drag := InputEventScreenDrag.new()
	drag.position = board._cell_center(move.b)
	board._gui_input(drag)
	touch.pressed = false
	touch.position = drag.position
	board._gui_input(touch)
	assert(board._drag_from.x < 0)
	while board.busy:
		await get_tree().process_frame
	# After an action, the next idle period automatically starts another hint.
	await get_tree().create_timer(board.AUTO_HINT_DELAY+.1).timeout
	assert(board._idle_hint and board._focus_cells.size() == 2)
	board.busy = true
	board._idle_seconds = board.AUTO_HINT_DELAY
	await get_tree().process_frame
	await get_tree().process_frame
	assert(board._hint_cells.is_empty() and board._idle_seconds == 0)
	board.busy = false
	SaveManager.data.settings.show_hints = false
	board._idle_seconds = board.AUTO_HINT_DELAY
	await get_tree().process_frame
	await get_tree().process_frame
	assert(board._hint_cells.is_empty())
	screen.queue_free()
	await get_tree().process_frame
	AudioManager.stop_music()
	for voice in AudioManager._voices:
		voice.stop()
		voice.stream = null
	await get_tree().process_frame
	print("Auto hint: PASS (continuous idle loops, repeats after action, no model/RNG changes, touch reset, busy and settings guards)")
	get_tree().quit()
