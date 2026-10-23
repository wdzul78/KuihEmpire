extends Node
var done := false
func play(board: MatchBoard, result: BoardState.ClearResult) -> void:
	await board._play_step(result,0)
	done = true
func _ready() -> void:
	var screen := LevelController.new()
	screen.level_id = 20
	add_child(screen)
	await get_tree().create_timer(.4).timeout
	screen.story.hide()
	var board := screen.board
	board.auto_hints = false
	for pos in [Vector2i(3,3),Vector2i(4,3)]:
		board.logic.get_cell(pos).special = BoardCell.Special.ORDER
	board._refresh_tiles()
	var result := board.logic.activate_specials([Vector2i(3,3),Vector2i(4,3)])
	assert(result.combo == &"order_wipe" and result.combo_cells.size() == 64)
	play(board,result)
	await get_tree().create_timer(.65).timeout
	assert(board._vfx.effects.any(func(e): return e.kind == "royal_cake_bomb"))
	assert(board._special_text.visible)
	var solar = board._vfx.effects.filter(func(e): return e.kind == "royal_cake_bomb")[0]
	assert(solar.a.is_equal_approx(board._double_dulang_center(result)))
	assert(solar.orbit_direction == Vector2.RIGHT)
	assert(board._special_text.get_child(0).text == "Kek Lapis Diraja!")
	if DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("res://.shots/royal_cake_charge.png")
	await get_tree().create_timer(.5).timeout
	if DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("res://.shots/royal_cake_flare.png")
	while not done:
		await get_tree().process_frame
	await get_tree().create_timer(1.8).timeout
	assert(board._vfx.effects.is_empty())
	print("Royal cake: PASS (ORDER pair, whole board coverage, directional orbit, title and cleanup)")
	get_tree().quit()
