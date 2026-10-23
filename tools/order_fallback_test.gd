extends Node
func _ready() -> void:
	for preferred in [&"missing_type", &"", &"onde_onde"]:
		var board := BoardState.new()
		board.setup(8,8,KuihLibrary.starter_set(),73)
		for y in 8:
			for x in 8:
				board.get_cell(Vector2i(x,y)).kuih = KuihLibrary.get_kuih(&"onde_onde")
		var origin := Vector2i(3,3)
		board.get_cell(origin).special = BoardCell.Special.ORDER
		board.get_cell(origin).order_kuish = preferred
		var rng_before := board.rng.state
		var result := board.activate_specials([origin])
		assert(result.activated.size() == 1)
		assert(result.activated[0].cells.size() >= 63)
		assert(result.cleared.size() == 64)
		assert(board.rng.state == rng_before)
	var mixed := BoardState.new()
	mixed.setup(8,8,KuihLibrary.starter_set(),73)
	for y in 8:
		for x in 8:
			mixed.get_cell(Vector2i(x,y)).kuih = KuihLibrary.get_kuih(&"onde_onde" if y < 6 else &"kuih_lapis")
	assert(mixed.available_order_kuih(&"") == &"onde_onde")
	print("Order fallback: PASS (missing, empty, valid target; no empty zap or RNG changes)")
	get_tree().quit()
