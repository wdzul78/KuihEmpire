extends Node

func _ready() -> void:
	for vertical in [false,true]:
		for reverse in [false,true]:
			for origin in [Vector2i(3,3),Vector2i(0,0),Vector2i(7,7)]:
				var board := BoardState.new()
				board.setup(8,8,KuihLibrary.starter_set(),73)
				var partner: Vector2i = origin + Vector2i(1 if origin.x < 7 else -1,0)
				var kind := BoardCell.Special.TAPAU_VERTICAL if vertical else BoardCell.Special.TAPAU
				board.get_cell(partner).special = kind if reverse else BoardCell.Special.DULANG
				board.get_cell(origin).special = BoardCell.Special.DULANG if reverse else kind
				var result := board.activate_specials([partner,origin])
				assert(result.combo == (&"badak_vertical" if vertical else &"badak_horizontal"))
				assert(result.combo_cells.size() == (24 if origin == Vector2i(3,3) else 16))
				assert(result.cleared.size() == result.combo_cells.size())
				for pos in result.combo_cells:
					assert(absi(pos.x-origin.x) <= 1 if vertical else absi(pos.y-origin.y) <= 1)
	var vfx := GameVfx.new()
	add_child(vfx)
	for x in range(2,5):
		var points := PackedVector2Array()
		for y in 8:
			points.append(Vector2(x,y)*80+Vector2(40,40))
		vfx.special(Vector2(x,3)*80+Vector2(40,40),BoardCell.Special.TAPAU_VERTICAL,points,80)
	var lane_count := 0
	for effect in vfx.effects:
		if effect.get("tapau",false):
			lane_count += 1
	assert(lane_count == 6) # Two directions along each of three columns.
	vfx.free()
	var screen := LevelController.new()
	screen.endless_mode = true
	add_child(screen)
	await get_tree().create_timer(.3).timeout
	screen.story.hide()
	var game_board := screen.board
	game_board.auto_hints = false
	for y in 8:
		for x in 8:
			game_board.logic.get_cell(Vector2i(x,y)).special = BoardCell.Special.NONE
	game_board.logic.get_cell(Vector2i(3,3)).special = BoardCell.Special.DULANG
	game_board.logic.get_cell(Vector2i(4,3)).special = BoardCell.Special.TAPAU
	game_board._refresh_tiles()
	var clear := game_board.logic.activate_specials([Vector2i(3,3),Vector2i(4,3)])
	await game_board._play_step(clear,0)
	await get_tree().create_timer(1.8).timeout
	assert(game_board._vfx.effects.is_empty())
	print("Badak directional: PASS (3 rows/columns, both member orders, edge clipping, 3 lane VFX)")
	get_tree().quit()
