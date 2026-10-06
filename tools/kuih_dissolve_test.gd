extends Node

var done := false

func _ready() -> void:
	run.call_deferred()

func play(board: MatchBoard, result: BoardState.ClearResult) -> void:
	done = false
	await board._play_step(result, 0)
	done = true

func run() -> void:
	var vfx := GameVfx.new()
	add_child(vfx)
	var items: Array[Dictionary] = []
	for index in 100:
		items.append({"at": Vector2(index % 10, index / 10) * 40, "color": Color.GREEN})
	vfx.burst(Vector2.ZERO, Color.WHITE, 9999)
	vfx.kuih_dissolve(items, 40)
	assert(vfx.effects.back().items.size() == 100)
	assert(vfx.particles.size() == GameVfx.MAX_PARTICLES)
	await get_tree().create_timer(1).timeout
	assert(vfx.effects.is_empty() and vfx.particles.is_empty())
	vfx.free()
	var board := MatchBoard.new()
	board.size = Vector2(400, 400)
	add_child(board)
	for hidden in [false, true]:
		board.build(TutorialLibrary.get_stage(8))
		var result := BoardState.ClearResult.new()
		for x in 3:
			var pos := Vector2i(x, 0)
			var info := BoardState.ClearInfo.new()
			info.kuih = board.logic.get_cell(pos).kuih
			result.cleared[pos] = info
		var run := BoardState.MatchRun.new()
		run.cells = [Vector2i(0,0),Vector2i(1,0),Vector2i(2,0)]
		result.match_runs.append(run)
		if hidden:
			board._tiles[Vector2i(1,0)].visible = false
		play(board, result)
		assert(not board._vfx.effects.any(func(e): return e.kind == "beam"))
		var batches := board._vfx.effects.filter(func(e): return e.kind == "kuih_dissolve")
		assert(batches.size() == 1)
		assert(batches[0].items.size() == (2 if hidden else 3))
		while not done:
			await get_tree().process_frame
	board.build(TutorialLibrary.get_stage(8))
	var origin := Vector2i(3,4)
	board.logic.get_cell(origin).special = BoardCell.Special.HANTAR
	board._refresh_tiles()
	play(board, board.logic.activate_specials([origin]))
	while not done:
		assert(not board._vfx.effects.any(func(e): return e.kind == "kuih_dissolve"))
		await get_tree().process_frame
	board.free()
	AudioManager.stop_music()
	print("PASS kuih dissolve: every visible item, hidden pickup exclusion, actual drone cross/flight exclusion, 100-item batch, cleanup")
	get_tree().quit()
