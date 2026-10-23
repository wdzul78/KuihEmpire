extends Node
func _ready() -> void:
	var supplies := EconomyManager.booster_count(EconomyManager.Booster.TRAY)
	var screen := load("res://scenes/game/endless_screen.tscn").instantiate() as LevelController
	add_child(screen)
	await get_tree().create_timer(.5).timeout
	assert(screen.board.logic.width == 8 and screen.board.logic.height == 8)
	assert(not screen.is_tutorial and screen.hud.booster_bar.practice_mode)
	assert(screen.hud._moves_label.text == "∞")
	var budget := screen.moves_left
	for i in 100:
		screen._on_move_committed()
	screen._on_settled()
	assert(screen.moves_left == budget and not screen.finished)
	assert(screen._consume_booster(EconomyManager.Booster.TRAY))
	assert(EconomyManager.booster_count(EconomyManager.Booster.TRAY) == supplies)
	var controls := screen.get_node("TestPowerControls")
	controls.get_child(1).pressed.emit()
	screen._on_restart()
	assert(screen.endless_mode and not screen.finished)
	assert(screen.board.logic.get_cell(Vector2i(2,3)).special == BoardCell.Special.ORDER)
	if DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("res://.shots/endless_test.png")
	screen.queue_free()
	await get_tree().process_frame
	var home := HomeScreen.new()
	add_child(home)
	assert(home.get_node("EndlessTestLink") is Button)
	if DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("res://.shots/endless_menu_link.png")
	home.queue_free()
	await get_tree().process_frame
	print("Endless: PASS (8x8, unlimited moves, free supplies, power button, restart)")
	get_tree().quit()
