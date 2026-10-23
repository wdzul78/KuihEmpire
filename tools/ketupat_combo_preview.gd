extends "res://tools/ketupat_preview.gd"

func demo() -> void:
	await get_tree().create_timer(.5).timeout
	board.build(level)
	for row in board.logic.grid:
		for cell in row:
			cell.special = BoardCell.Special.NONE
	var a := Vector2i(3,4)
	var b := Vector2i(4,4)
	board.logic.get_cell(a).special = BoardCell.Special.TAPAU
	board.logic.get_cell(b).special = BoardCell.Special.TAPAU_VERTICAL
	board._refresh_tiles()
	await get_tree().create_timer(.5).timeout
	capture_after(.22,"ketupat-combo-appear")
	capture_after(.45,"ketupat-combo-readable-hold")
	capture_after(1.00,"ketupat-combo-cross")
	await board._play_step(board.logic.activate_specials([a,b]),0)
	await get_tree().create_timer(.8).timeout
	print("Ketupat combo rendered preview: PASS")
	get_tree().quit()
