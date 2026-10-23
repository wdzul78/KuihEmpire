extends Node

func _ready() -> void:
	run.call_deferred()

func run() -> void:
	var holder := Control.new()
	add_child(holder)
	var board := MatchBoard.new()
	board.size = Vector2(500,500)
	holder.add_child(board)
	var level := LevelDefinition.new()
	level.width = 6
	level.height = 6
	level.kuih = KuihLibrary.starter_set()
	board.build(level)
	board.logic.get_cell(Vector2i(1,2)).special = BoardCell.Special.TAPAU
	board.logic.get_cell(Vector2i(3,2)).special = BoardCell.Special.TAPAU_VERTICAL
	board.logic.get_cell(Vector2i(3,4)).special = BoardCell.Special.DULANG
	board._refresh_tiles()
	var ranks: Array[int] = []
	var overlapping_hits: Array[bool] = []
	board.combo_wave_started.connect(func(rank: int) -> void: ranks.append(rank))
	board.combo_wave_started.connect(func(rank: int) -> void:
		if rank > 0:
			overlapping_hits.append(not board._vfx.effects.is_empty())
	)
	var clear := board.logic.activate_specials([Vector2i(1,2)])
	await board._play_step(clear,0)
	assert(ranks == [0,1,2])
	assert(overlapping_hits.size() == 2 and overlapping_hits.all(func(active): return active))
	assert(board._combo_wave_count == 3)
	assert(board._move_clear_count == clear.collected_count())
	assert(board._combo_praise._last_milestone > 0)
	var first_count := board._move_clear_count
	# A subsequent match in the same move continues the special-wave streak.
	var following := BoardState.ClearResult.new()
	following.match_runs.append(BoardState.MatchRun.new())
	await board._play_step(following,1)
	assert(ranks == [0,1,2,3])
	assert(board._move_clear_count == first_count)
	# Starting a new move resets reached praise tiers without rebuilding the board.
	await board._play_step(following,0)
	board._advance_combo_wave()
	board._advance_combo_wave()
	assert(board._move_clear_count == 0 and not board._combo_praise.visible)
	# Two deliberate simultaneous specials count as one initial trigger.
	board.build(level)
	board.logic.get_cell(Vector2i(1,2)).special = BoardCell.Special.TAPAU
	board.logic.get_cell(Vector2i(2,2)).special = BoardCell.Special.TAPAU_VERTICAL
	board._refresh_tiles()
	ranks.clear()
	clear = board.logic.activate_specials([Vector2i(1,2),Vector2i(2,2)])
	await board._play_step(clear,0)
	assert(ranks == [0])
	assert(board._move_clear_count == clear.collected_count())
	assert(board._combo_praise.accessibility_name == "Bagus!")
	# Normal match then its triggered special produces Combo 1.
	board.build(level)
	board.logic.get_cell(Vector2i(1,2)).special = BoardCell.Special.TAPAU
	board._refresh_tiles()
	clear = board.logic.activate_specials([Vector2i(1,2)])
	clear.match_runs.append(BoardState.MatchRun.new())
	ranks.clear()
	await board._play_step(clear,0)
	assert(ranks == [0,1])
	assert(board._move_clear_count == 6 and not board._combo_praise.visible)
	AudioManager.reset_combo_voice(true)
	board._combo_praise.reset()
	holder.free()
	print("Special wave praise: PASS (chains, same-depth grouping, cascade continuation, reset, match-to-special)")
	get_tree().quit()
