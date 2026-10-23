extends Node

func _ready() -> void:
	run.call_deferred()

func run() -> void:
	for reverse in [false,true]:
		var state := BoardState.new()
		state.setup(8,8,KuihLibrary.starter_set(),24)
		state.delivery_enabled = true
		for y in 8:
			for x in 8:
				var cell := state.get_cell(Vector2i(x,y))
				cell.special = BoardCell.Special.NONE
				cell.kuih = KuihLibrary.get_kuih(&"onde_onde") if x < 5 else KuihLibrary.starter_set()[1]
		var a := Vector2i(3,4)
		var b := Vector2i(4,4)
		state.get_cell(a).special = BoardCell.Special.HANTAR
		state.get_cell(b).special = BoardCell.Special.ORDER
		var pair := [b,a] if reverse else [a,b]
		assert(state.try_swap(pair[0],pair[1]) == BoardState.SwapOutcome.ACTIVATED_SPECIAL)
		var result := state.activate_specials(pair)
		assert(result.combo == &"order_conversion")
		assert(result.conversion_kind == BoardCell.Special.HANTAR)
		assert(result.conversion_kuih == &"onde_onde")
		assert(result.converted.size() == 38)
		for pos in result.converted:
			assert(result.activated.any(func(e): return e.pos == pos and e.kind == BoardCell.Special.HANTAR))
		assert(result.cleared.has(a) and result.cleared.has(b))
		assert(not result.activated.any(func(e): return e.pos == a or e.pos == b))
		var visual_board := MatchBoard.new()
		visual_board.size = Vector2(480,480)
		add_child(visual_board)
		var level := LevelDefinition.new()
		level.width = 8
		level.height = 8
		level.kuih = KuihLibrary.starter_set()
		visual_board.build(level)
		await visual_board._animate_order_conversion(result)
		assert(not visual_board._tiles[a].visible and not visual_board._tiles[b].visible)
		for pos in result.converted:
			assert(visual_board._tiles[pos].icon.special_kind == BoardCell.Special.HANTAR)
		visual_board.free()
	AudioManager.stop_music()
	print("Sepit + Lapis: PASS (majority type, 38 conversions and activations, both swap directions)")
	get_tree().quit()
