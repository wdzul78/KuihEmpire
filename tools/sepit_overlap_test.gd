extends Node
var problems := 0
var finished := false
func check(ok: bool, message: String) -> void:
	if not ok:
		problems += 1
		push_error(message)
func _ready() -> void:
	run.call_deferred()
func play(board: MatchBoard, result: BoardState.ClearResult) -> void:
	await board._play_step(result,0)
	finished = true
func run() -> void:
	var board := MatchBoard.new()
	board.size = Vector2(480,480)
	add_child(board)
	board.build(LevelLibrary.get_level(18))
	board.logic.delivery_enabled = true
	for row in board.logic.grid:
		for cell in row:
			cell.special = BoardCell.Special.NONE
	var origin := Vector2i(3,5)
	board.logic.get_cell(origin).special = BoardCell.Special.HANTAR
	board.logic.get_cell(origin).order_kuish = &""
	board._refresh_tiles()
	var result := board.logic.activate_specials([origin])
	var target: Vector2i = result.activated[0].cells.back()
	var target_tile: TileView = board._tiles[target]
	var target_at := target_tile.position
	play(board,result)
	await get_tree().create_timer(.85).timeout
	check(board._vfx.effects.any(func(e): return e.kind == "delivery"),"sepit is still flying during early fall")
	check(target_tile.visible and target_tile.position.is_equal_approx(target_at),"remote target stays fixed until landing")
	var moved := false
	for pos in board._tiles:
		var tile: TileView = board._tiles[pos]
		if tile.has_meta("sepit_local_fall") and tile.position.distance_to(board.cell_to_pos(pos)) > 3:
			moved = true
	check(moved,"surviving tile moves into the launch holes before sepit lands")
	while not finished:
		await get_tree().process_frame
	for pos in board._tiles:
		check(board._tiles[pos].position.distance_to(board.cell_to_pos(pos)) < .1,"final refill settles every tile at its logical position")
	board.free()
	print("Sepit concurrent fall: %s (%d problems)" % ["PASS" if problems == 0 else "FAIL",problems])
	get_tree().quit(problems)
