extends Node
func _ready() -> void:
	var screen := LevelController.new()
	screen.level_id = 20
	add_child(screen)
	await get_tree().create_timer(.4).timeout
	screen.story.hide()
	var board := screen.board
	for pos in [Vector2i(2,2),Vector2i(4,4),Vector2i(6,6)]:
		board.logic.get_cell(pos).special = BoardCell.Special.DULANG
	board._refresh_tiles()
	board.auto_hints = false
	await get_tree().create_timer(.5).timeout
	if DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("res://.shots/badak_idle_orbit.png")
	await get_tree().create_timer(1).timeout
	print("Badak idle layered preview: PASS")
	get_tree().quit()
