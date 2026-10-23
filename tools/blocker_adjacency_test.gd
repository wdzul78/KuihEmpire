extends Node
func _ready() -> void:
	for kind in [BlockerSpec.Kind.BANANA_LEAF,BlockerSpec.Kind.FOOD_COVER,BlockerSpec.Kind.STEAMER,BlockerSpec.Kind.STICKY_SYRUP]:
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
	print("Blocker adjacency: PASS (four sides, no diagonals, final hit removal)")
	get_tree().quit()
