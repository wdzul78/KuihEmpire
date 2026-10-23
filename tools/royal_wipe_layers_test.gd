extends Node
func _ready() -> void:
	var state := BoardState.new()
	state.setup(8,8,KuihLibrary.starter_set(),78)
	for row in state.grid:
		for cell in row:
			cell.special = BoardCell.Special.NONE
	for pos in [Vector2i(3,3),Vector2i(4,3)]:
		state.get_cell(pos).special = BoardCell.Special.ORDER
	for index in 5:
		state.get_cell(Vector2i(index,2)).special = [BoardCell.Special.HANTAR,BoardCell.Special.TAPAU,BoardCell.Special.TAPAU_VERTICAL,BoardCell.Special.DULANG,BoardCell.Special.ORDER][index]
	var covered := state.get_cell(Vector2i(0,0))
	covered.blocker_kind = BlockerSpec.Kind.STEAMER
	covered.blocker_hp = 3
	var target := state.get_cell(Vector2i(7,7))
	target.blocker_kind = BlockerSpec.Kind.PACKAGING_BOX
	target.target_kuish = &"onde_onde"
	target.target_need = 8
	var result := state.activate_specials([Vector2i(3,3),Vector2i(4,3)])
	assert(result.combo == &"order_wipe")
	assert(result.cleared.size() == 64)
	assert(result.activated.is_empty(), "Royal wipe consumes every special without secondary activation waves")
	assert(result.blockers.size() == 1 and result.blockers[0].removed and result.blockers[0].hp_left == 0)
	assert(result.targets.size() == 1 and result.targets[0].done)
	for row in state.grid:
		for cell in row:
			assert(not cell.has_kuish() and not cell.has_obstacle())
	print("Royal full wipe: PASS (all 64 food, covered tile, all blocker layers, packaging target)")
	get_tree().quit()
