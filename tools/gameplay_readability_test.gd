extends Node

var problems := 0
func check(ok: bool, message: String) -> void:
	if not ok:
		problems += 1
		push_error(message)
func _ready() -> void:
	run.call_deferred()
func run() -> void:
	SaveManager.save_path = "user://gameplay_readability_test.json"
	for tutorial in [0,8]:
		var screen := LevelController.new()
		screen.level_id = 20
		screen.tutorial_index = tutorial
		add_child(screen)
		await get_tree().create_timer(.4).timeout
		# Inspect puzzle presentation after the introductory story gate.
		screen.story.hide()
		if screen.coach != null:
			screen.coach._spotlight.hide()
			screen.coach._tap_indicator.hide()
		var hud := screen.hud
		check(not hud.get_node("Logo").visible and not hud.get_node("HeartMeter").visible,"no logo or hearts during puzzles")
		check(screen.backdrop.gameplay_mode,"gameplay background mode enabled")
		if screen.backdrop.location_id == &"family_stall":
			check(screen.backdrop.texture_path == GeraiBackdrop.SOFT_GAMEPLAY_PATH,"new soft stall background")
		check(hud.order_panel.compact_mode == (tutorial == 0),"campaign portraits compact; tutorial coaching retained")
		check(hud.board_holder.get_global_rect().position.y >= hud.order_panel.get_global_rect().end.y,"board clears order area")
		var board := screen.board
		var board_rect := Rect2(board.get_global_rect().position+board.board_origin,Vector2.ONE*board.cell_size*board.logic.width)
		check(get_viewport().get_visible_rect().encloses(board_rect),"board fits viewport")
		if board.logic.width == 8 and get_viewport().get_visible_rect().size.aspect() < .6:
			check(board_rect.size.x/hud.size.x >= .85,"eight-column board uses at least 85 percent width")
		for tile in board._tiles.values():
			check(is_equal_approx(tile.icon.cell_ratio,.92),"larger food within cell")
		for button in hud.booster_bar._buttons.values():
			check(button.size.x <= 137 and absf(button.size.x-button.size.y)<1,"compact square booster buttons")
		check(hud.booster_bar._available == (tutorial == 0),"tutorial boosters stay locked")
		if DisplayServer.get_name() != "headless":
			await RenderingServer.frame_post_draw
			var pixels := get_window().size
			get_viewport().get_texture().get_image().save_png("res://.shots/readability_%dx%d_%s.png" % [pixels.x,pixels.y,"tutorial" if tutorial > 0 else "campaign"])
		screen.free()
	AudioManager.stop_music()
	print("Gameplay readability: %s (%d problems)" % ["PASS" if problems == 0 else "FAIL",problems])
	get_tree().quit(0 if problems == 0 else 1)
