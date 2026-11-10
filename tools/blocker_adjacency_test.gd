extends Node
func _ready() -> void:
	# Syrup is a puddle UNDER the kuih: neighbours never clean it, only clearing
	# the kuih that sits on it does. The kuih on it can still be swapped.
	var puddle := BoardState.new()
	puddle.setup(8,8,KuihLibrary.starter_set(),42)
	puddle.apply_blockers([BlockerSpec.make(BlockerSpec.Kind.STICKY_SYRUP,[Vector2i(4,3),Vector2i(3,3)],1)])
	assert(puddle.is_playable(Vector2i(4,3)) and puddle.get_cell(Vector2i(4,3)).is_puddle())
	assert(puddle.remaining_blockers_of_kind(BlockerSpec.Kind.STICKY_SYRUP) == 2)
	var beside := BoardState.ClearResult.new()
	beside.cleared[Vector2i(5,3)] = BoardState.ClearInfo.new()
	puddle._register_blocker_progress(beside)
	assert(beside.blockers.is_empty())
	var on_top := BoardState.ClearResult.new()
	on_top.cleared[Vector2i(3,3)] = BoardState.ClearInfo.new()
	puddle._register_blocker_progress(on_top)
	assert(on_top.blockers.size() == 1 and on_top.blockers[0].pos == Vector2i(3,3) and on_top.blockers[0].removed)
	assert(puddle.remaining_blockers_of_kind(BlockerSpec.Kind.STICKY_SYRUP) == 1)
	for kind in [BlockerSpec.Kind.BANANA_LEAF,BlockerSpec.Kind.FOOD_COVER,BlockerSpec.Kind.STEAMER]:
		var board := BoardState.new()
		board.setup(8,8,KuihLibrary.starter_set(),42)
		for offset in [Vector2i(1,0),Vector2i(-1,0),Vector2i(0,1),Vector2i(0,-1),Vector2i(1,1),Vector2i(-1,1),Vector2i(1,-1),Vector2i(-1,-1)]:
			var cell := board.get_cell(Vector2i(3,3)+offset)
			cell.blocker_kind = kind
			cell.blocker_hp = 2
		var result := BoardState.ClearResult.new()
		result.cleared[Vector2i(3,3)] = BoardState.ClearInfo.new()
		board._register_blocker_progress(result)
		assert(result.blockers.size() == 4)
		for offset in [Vector2i(1,1),Vector2i(-1,1),Vector2i(1,-1),Vector2i(-1,-1)]:
			assert(board.get_cell(Vector2i(3,3)+offset).blocker_hp == 2)
		for hit in result.blockers:
			assert(hit.hp_left == 1 and not hit.removed)
		var second := BoardState.ClearResult.new()
		second.cleared[Vector2i(3,3)] = BoardState.ClearInfo.new()
		board._register_blocker_progress(second)
		for hit in second.blockers:
			assert(hit.removed)
	print("Blocker adjacency: PASS (four sides, no diagonals, final hit removal, syrup cleaned from on top)")
	get_tree().quit()
