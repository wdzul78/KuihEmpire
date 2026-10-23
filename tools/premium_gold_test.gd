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
	for pos in [Vector2i(3,3)]:
		board.logic.get_cell(pos).special = BoardCell.Special.ORDER
	board.logic.get_cell(Vector2i(3,3)).order_kuish = &"onde_onde"
	for y in 8:
		for x in 8:
			if (x+y)%3 == 0 and Vector2i(x,y) != Vector2i(3,3):
				board.logic.get_cell(Vector2i(x,y)).kuih = KuihLibrary.get_kuih(&"onde_onde")
	board.logic.get_cell(Vector2i.ZERO).special = BoardCell.Special.TAPAU
	board._refresh_tiles()
	var result := board.logic.activate_specials([Vector2i(3,3)])
	assert(result.combo != &"order_wipe" and result.activated[0].cells.size() > 10)
	assert(not result.activated[0].cells.has(Vector2i.ZERO)) # Existing ORDER targeting excludes packaged specials.
	var seen := {}
	for activation in result.activated:
		assert(not seen.has(activation.pos))
		seen[activation.pos] = true
	play(board,result)
	await get_tree().create_timer(.20).timeout
	assert(board._vfx.effects.any(func(e): return e.kind == "order_electric"))
	assert(board._special_text.visible)
	if DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("res://.shots/premium_gold_charge.png")
	await get_tree().create_timer(.5).timeout
	if DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("res://.shots/premium_gold_blast.png")
	while not done:
		await get_tree().process_frame
	await get_tree().create_timer(1.8).timeout
	assert(board._vfx.effects.is_empty())
	print("Premium gold: PASS (charge, title, unique chain activations and cleanup)")
	get_tree().quit()


