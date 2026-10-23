extends Node

func _ready() -> void:
	run.call_deferred()

func run() -> void:
	for kind in [BoardCell.Special.TAPAU,BoardCell.Special.TAPAU_VERTICAL,BoardCell.Special.DULANG,BoardCell.Special.HANTAR]:
		for reverse in [false,true]:
			var board := MatchBoard.new()
			board.size = Vector2(480,480)
			add_child(board)
			var level := LevelDefinition.new()
			level.width = 8
			level.height = 8
			level.kuih = KuihLibrary.starter_set()
			board.build(level)
			var a := Vector2i(3,3)
			var b := Vector2i(4,3)
			board.logic.get_cell(a).special = BoardCell.Special.ORDER
			board.logic.get_cell(b).special = kind
			var pair := [b,a] if reverse else [a,b]
			assert(board.logic.try_swap(pair[0],pair[1]) == BoardState.SwapOutcome.ACTIVATED_SPECIAL)
			board._refresh_tiles()
			var result := board.logic.activate_specials(pair)
			assert(result.combo == &"order_conversion" and not result.converted.is_empty())
			assert(not result.activated.any(func(e): return e.pos == a or e.pos == b))
			await board._animate_order_conversion(result)
			assert(not board._tiles[a].visible and not board._tiles[b].visible)
			for pos in result.converted:
				assert(board._tiles[pos].icon.special_kind == result.conversion_kinds[pos])
			board.free()
	AudioManager.stop_music()
	print("Lapis partner sequence: PASS (four special kinds, both swap directions, originals consumed, converted graphics)")
	get_tree().quit()
