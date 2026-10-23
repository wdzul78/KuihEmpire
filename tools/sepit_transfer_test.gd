extends Node
func _ready() -> void:
	for kind in [BoardCell.Special.TAPAU,BoardCell.Special.TAPAU_VERTICAL,BoardCell.Special.DULANG,BoardCell.Special.HANTAR]:
		for reverse in [false,true]:
			var state := BoardState.new()
			state.setup(8,8,KuihLibrary.starter_set(),24)
			state.delivery_enabled = true
			for row in state.grid:
				for cell in row:
					cell.special = BoardCell.Special.NONE
			var a := Vector2i(3,4)
			var b := Vector2i(4,4)
			state.get_cell(a).special = BoardCell.Special.HANTAR
			state.get_cell(b).special = kind
			var pair: Array[Vector2i] = []
			pair.assign([b,a] if reverse else [a,b])
			assert(state.try_swap(pair[0],pair[1]) == BoardState.SwapOutcome.ACTIVATED_SPECIAL)
			var result := state.activate_specials(pair)
			assert(result.combo == &"delivery_transfer" and result.conversion_kind == kind)
			assert(result.converted.size() == 1)
			var target: Vector2i = result.converted[0]
			assert(not result.combo_members.has(target))
			assert(not result.activated.any(func(e): return e.pos == result.delivery_partner))
			assert(result.activated.any(func(e): return e.pos == target and e.kind == kind and e.chain_depth == 1))
			assert(result.cleared.has(result.delivery_partner))
			for pos in state.delivery_cross(result.combo_origin):
				assert(result.cleared.has(pos))
	print("Sepit transfer: PASS (four partner kinds, both swap directions, consumed partner, remote conversion/activation)")
	get_tree().quit()
