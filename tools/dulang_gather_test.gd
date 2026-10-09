extends Node

var done := false
func _ready() -> void:
	run.call_deferred()

func play(board: MatchBoard, result: BoardState.ClearResult) -> void:
	done = false
	await board._play_step(result, 0)
	done = true

func run() -> void:
	var board := MatchBoard.new()
	board.size = Vector2(400,400)
	add_child(board)
	board.build(TutorialLibrary.get_stage(8))
	var origin := Vector2i(3,3)
	var guard := Vector2i(2,2)
	board.logic.apply_blockers([BlockerSpec.make(BlockerSpec.Kind.STEAMER,[guard],2)])
	board.logic.get_cell(origin).special = BoardCell.Special.DULANG
	board._refresh_tiles()
	board._sync_overlay(guard)
	var result := board.logic.activate_specials([origin])
	play(board,result)
	await get_tree().create_timer(.04).timeout
	var trays := board._vfx.effects.filter(func(e): return e.kind == "charge")
	assert(trays.size() == 1 and trays[0].foods.size() == 7)
	assert(not board._tiles[origin].visible)
	assert(board._overlays[guard].visible)
	for dy in range(-1,2):
		for dx in range(-1,2):
			var pos := origin + Vector2i(dx,dy)
			if pos != origin and pos != guard:
				assert(not board._tiles[pos].visible)
	assert(not board._vfx.effects.any(func(e): return e.kind in ["preview","gold_slot"]))
	await get_tree().create_timer(.07).timeout
	assert(board._vfx.effects.any(func(e): return e.kind == "charge"))
	await get_tree().create_timer(.10).timeout
	assert(not board._vfx.effects.any(func(e): return e.kind in ["charge","preview","gold_slot"]))
	assert(board._vfx.effects.any(func(e): return e.kind == "flower_wave"))
	assert(board._vfx.effects.any(func(e): return e.kind == "kuih_dissolve"))
	while not done:
		await get_tree().process_frame
	assert(board.logic.get_cell(guard).blocker_hp == 1)
	await get_tree().create_timer(1).timeout
	assert(board._vfx.effects.is_empty() and board._vfx.particles.is_empty())
	board.free()
	AudioManager.stop_music()
	print("PASS Dulang: 7 foods gathered, guard preserved, grow/load before blast, particle explosion, no slot highlights, cleanup")
	get_tree().quit()
