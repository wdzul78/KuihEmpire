extends Node

var step_done := false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	SaveManager.save_path = "user://kuih_vfx_test.json"
	SaveManager.reset()
	run.call_deferred()

func run_step(board: MatchBoard, result: BoardState.ClearResult) -> void:
	step_done = false
	await board._play_step(result, 0)
	step_done = true

func shot(name_text: String) -> void:
	if DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://.shots"))
		get_viewport().get_texture().get_image().save_png("res://.shots/vfx_%s.png" % name_text)

func run() -> void:
	# Resolution metadata must describe real horizontal/vertical matches and chains.
	for horizontal in [true, false]:
		var state := BoardState.new()
		state.setup(3, 3, KuihLibrary.starter_set(), 15)
		for y in 3:
			for x in 3:
				state.get_cell(Vector2i(x, y)).kuih = state.pool[(x+y) % 3]
		for i in 3:
			state.get_cell(Vector2i(i, 1) if horizontal else Vector2i(1, i)).kuih = state.pool[0]
		var matched := state.resolve()
		assert(matched.match_runs.size() == 1)
		assert(matched.match_runs[0].horizontal == horizontal and matched.match_runs[0].cells.size() == 3)
	var chained := BoardState.new()
	chained.setup(5, 5, KuihLibrary.starter_set(), 18)
	chained.get_cell(Vector2i(1, 1)).special = BoardCell.Special.TAPAU
	chained.get_cell(Vector2i(3, 1)).special = BoardCell.Special.DULANG
	assert(chained.activate_specials([Vector2i(1, 1)]).activated.size() == 2)
	var board := MatchBoard.new()
	board.process_mode = Node.PROCESS_MODE_PAUSABLE
	board.position = Vector2(90, 470)
	board.size = Vector2(900, 900)
	add_child(board)
	var score := StageScoreController.new()
	board.clear_resolved.connect(func(cleared: BoardState.ClearResult, step: int) -> void: score.add_clear(cleared, step))
	score.feedback.connect(board.show_score_feedback)
	for kind in [BoardCell.Special.TAPAU, BoardCell.Special.DULANG, BoardCell.Special.ORDER]:
		score.setup(TutorialLibrary.get_stage(5))
		board.build(TutorialLibrary.get_stage(5))
		var pos := Vector2i(1, 1)
		var cell := board.logic.get_cell(pos)
		cell.special = kind
		cell.order_kuish = cell.kuish_id()
		board._refresh_tiles()
		var result := board.logic.activate_specials([pos])
		assert(result.activated.size() == 1)
		assert(result.activated[0].kind == kind and result.activated[0].pos == pos)
		if kind == BoardCell.Special.DULANG:
			assert(result.cleared.size() == 9)
		run_step(board, result)
		await get_tree().create_timer(.12).timeout
		assert(not board._vfx.effects.is_empty())
		assert(board._special_text.visible and board._special_text.get_child_count() == 1)
		if kind == BoardCell.Special.DULANG:
			assert(board._vfx.effects.any(func(e: Dictionary) -> bool: return e.kind == "charge"))
			assert(not board._vfx.effects.any(func(e: Dictionary) -> bool: return e.kind == "flower_wave"))
			await get_tree().create_timer(.14).timeout
			assert(board._vfx.effects.any(func(e: Dictionary) -> bool: return e.kind == "flower_wave"))
		assert(score.total >= result.cleared.size() * score.rules.points_per_kuih)
		assert(board._feedback.visible)
		await shot(str(kind))
		var before := board._vfx.clock
		get_tree().paused = true
		await get_tree().create_timer(.10).timeout
		assert(board._vfx.clock == before)
		get_tree().paused = false
		while not step_done:
			await get_tree().process_frame
		await get_tree().create_timer(.9).timeout
		assert(board._vfx.effects.is_empty() and board._vfx.particles.is_empty())
		assert(not board._special_text.visible)
	board._feedback.show_clear(120, 2, board.size, 1.5)
	await get_tree().create_timer(.22).timeout
	assert(board._feedback._multiplier.text == "x1.5")
	await shot("combo_score")
	board._vfx.burst(Vector2.ZERO, Color.WHITE, 9999)
	assert(board._vfx.particles.size() == GameVfx.MAX_PARTICLES)
	board._special_text.show_wave([BoardCell.Special.TAPAU,BoardCell.Special.TAPAU_VERTICAL],board.size,board.cell_size)
	assert(board._special_text.get_child_count() == 1)
	board._special_text.reset()
	board.free()
	for sound in [AudioManager.Sfx.LINE_CLEAR, AudioManager.Sfx.TAPAU_BLAST, AudioManager.Sfx.TRAY_BLAST, AudioManager.Sfx.ORDER_BURST, AudioManager.Sfx.SUCCESS]:
		var wav: AudioStreamWAV = AudioManager._streams[sound]
		assert(wav.data.size() > 2000)
		var peak := 0
		for i in range(0, wav.data.size(), 2):
			peak = maxi(peak, absi(wav.data.decode_s16(i)))
		assert(peak > 100 and peak < SfxSynth.PEAK)
	AudioManager.sfx_enabled = false
	var voice := AudioManager._next_voice
	AudioManager.play_special(BoardCell.Special.TAPAU)
	assert(AudioManager._next_voice == voice)
	AudioManager.sfx_enabled = true
	var overlay := ResultOverlay.new()
	add_child(overlay)
	overlay.show_win("Success", 3, 60, [], false)
	assert(overlay._celebration.mouse_filter == Control.MOUSE_FILTER_IGNORE)
	await get_tree().create_timer(.4).timeout
	await shot("success")
	overlay.show_fail("", false)
	assert(overlay._celebration.particles.is_empty())
	overlay.free()
	AudioManager.stop_music()
	for player in AudioManager._voices:
		player.stop()
		player.stream = null
	await get_tree().create_timer(.15).timeout
	print("PASS VFX: special footprints, pause, cleanup, particle cap, SFX PCM/mute, success/failure")
	get_tree().quit(0)
