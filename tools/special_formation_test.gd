extends Node

var done := false
func _ready() -> void:
	run.call_deferred()

func play(board: MatchBoard, result: BoardState.ClearResult) -> void:
	done = false
	await board._play_step(result,0)
	done = true

func run() -> void:
	var board := MatchBoard.new()
	board.size = Vector2(400,400)
	add_child(board)
	for stage_index in [4,10]:
		var level := TutorialLibrary.get_stage(stage_index)
		board.build(level)
		var pair: Array = level.tutorial_steps[0].highlight.duplicate()
		assert(board.logic.try_swap(pair[0],pair[1]) == BoardState.SwapOutcome.PLAYED)
		board._refresh_tiles()
		var result := board.logic.resolve(pair)
		assert(result.created.size() == 1)
		var origin: Vector2i = result.created[0].pos
		assert(board._formation_cells(result,origin).size() == 4)
		var unrelated := BoardState.MatchRun.new()
		unrelated.cells = [Vector2i(0,0),Vector2i(1,0)]
		if not board._formation_cells(result,origin).has(Vector2i(0,0)) and not board._formation_cells(result,origin).has(Vector2i(1,0)):
			result.match_runs.append(unrelated)
			assert(board._formation_cells(result,origin).size() == 4)
		play(board,result)
		await get_tree().create_timer(.10).timeout
		assert(not board._vfx.effects.any(func(e): return e.kind == "beam"))
		assert(board._vfx.effects.any(func(e): return e.kind == "special_formation" and e.points.size() == 4))
		assert(board._tiles[origin].icon.special_kind == BoardCell.Special.NONE)
		await get_tree().create_timer(.34).timeout
		assert(board._tiles[origin].icon.special_kind == result.created[0].special)
		while not done:
			await get_tree().process_frame
		await get_tree().create_timer(.6).timeout
		assert(not board._vfx.effects.any(func(e): return e.kind == "special_formation"))
	board.free()
	AudioManager.stop_music()
	print("PASS special formation: horizontal/vertical glow before reveal, all matched items, unrelated match exclusion, cleanup")
	get_tree().quit()
