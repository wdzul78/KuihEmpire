extends Node

func fresh() -> BoardState:
	var state := BoardState.new()
	state.setup(8,8,KuihLibrary.starter_set(),78)
	for row in state.grid:
		for cell in row:
			cell.special = BoardCell.Special.NONE
	return state

func _ready() -> void:
	run.call_deferred()

func run() -> void:
	var state := fresh()
	var cleared := state.clear_booster(Vector2i(3,3), &"cross")
	assert(cleared.cleared.size() == 39)
	for pos in cleared.cleared:
		assert(absi(pos.x-3) <= 1 or absi(pos.y-3) <= 1)
	state = fresh()
	assert(state.clear_booster(Vector2i.ZERO,&"cross").cleared.size() == 28)
	state = fresh()
	state.get_cell(Vector2i.ZERO).blocker_kind = BlockerSpec.Kind.STEAMER
	state.get_cell(Vector2i.ZERO).blocker_hp = 3
	cleared = state.clear_booster(Vector2i.ZERO,&"sudip")
	assert(state.get_cell(Vector2i.ZERO).blocker_hp == 2)
	assert(cleared.blockers.size() == 1)
	state = fresh()
	state.get_cell(Vector2i.ZERO).blocker_kind = BlockerSpec.Kind.STEAMER
	state.get_cell(Vector2i.ZERO).blocker_hp = 3
	cleared = state.clear_booster(Vector2i(3,3),&"royal")
	assert(cleared.cleared.size() == 64 and not state.get_cell(Vector2i.ZERO).has_obstacle())
	var board := MatchBoard.new()
	board.size = Vector2(480,480)
	add_child(board)
	board.build(TutorialLibrary.get_stage(8))
	var moves := [0]
	board.move_committed.connect(func() -> void: moves[0] += 1)
	var a := Vector2i(0,0)
	var b := Vector2i(1,0)
	await board.booster_hand(a,b)
	assert(moves[0] == 0 and not board.busy)
	await board.booster_clear(Vector2i(2,2),&"cross")
	assert(moves[0] == 0 and not board.busy)
	await board.booster_clear(Vector2i(2,2),&"royal")
	assert(moves[0] == 0 and not board.busy)
	var bar := BoosterBar.new()
	bar.size = Vector2(800,140)
	add_child(bar)
	bar._recenter()
	assert(bar._buttons.size() == 6)
	assert(EconomyManager.booster_id(EconomyManager.Booster.SPATULA) == "spatula")
	assert(EconomyManager.booster_id(EconomyManager.Booster.HAND) == "hand")
	bar.free()
	board.free()
	var controller := LevelController.new()
	controller.endless_mode = true
	add_child(controller)
	await get_tree().create_timer(.8).timeout
	controller.board.enabled = true
	controller._on_booster_requested(EconomyManager.Booster.HAND)
	controller._on_booster_targeted(EconomyManager.Booster.HAND,Vector2i(0,0))
	assert(controller._hand_origin == Vector2i(0,0))
	await controller._on_booster_targeted(EconomyManager.Booster.HAND,Vector2i(1,0))
	assert(controller._hand_origin == Vector2i(-1,-1) and not controller.board.busy)
	controller.free()
	AudioManager.reset_combo_voice(true)
	AudioManager.stop_music()
	print("Booster rework: PASS (cross 39 / edge 28, hammer blocker damage, royal 64, free swap, six slots, stable save IDs)")
	get_tree().quit()
