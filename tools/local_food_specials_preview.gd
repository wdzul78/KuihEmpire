extends LevelController
func _notification(what: int) -> void:
	# Offline capture must keep rendering if the user focuses another app.
	# Production gameplay retains its normal pause-on-interruption behaviour.
	if what in [NOTIFICATION_APPLICATION_PAUSED,NOTIFICATION_APPLICATION_FOCUS_OUT]:
		return
	super._notification(what)
func _ready() -> void:
	SaveManager.save_path = "user://local_food_specials_preview.json"
	SaveManager.reset()
	SaveManager.data["tutorial_done"] = true
	GameManager.pending_tutorial_index = 0
	endless_mode = true
	super._ready()
	_demo.call_deferred()
func prepare() -> void:
	board.build(level)
	board.logic.delivery_enabled = true
	for row in board.logic.grid:
		for cell in row:
			cell.special = BoardCell.Special.NONE
func _demo() -> void:
	await get_tree().create_timer(.5).timeout
	prepare()
	board.logic.get_cell(Vector2i(1,3)).special = BoardCell.Special.TAPAU
	board.logic.get_cell(Vector2i(6,3)).special = BoardCell.Special.TAPAU_VERTICAL
	board.logic.get_cell(Vector2i(3,5)).special = BoardCell.Special.HANTAR
	board._refresh_tiles()
	await get_tree().create_timer(2.5).timeout
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://.shots/local_food_specials_final.png")
	await board.attempt_activate(Vector2i(3,5))
	await get_tree().create_timer(.6).timeout
	prepare()
	board.logic.get_cell(Vector2i(3,4)).special = BoardCell.Special.TAPAU
	board._refresh_tiles()
	await get_tree().create_timer(.8).timeout
	await board.attempt_activate(Vector2i(3,4))
	await get_tree().create_timer(.6).timeout
	prepare()
	board.logic.get_cell(Vector2i(4,4)).special = BoardCell.Special.TAPAU_VERTICAL
	board._refresh_tiles()
	await get_tree().create_timer(.8).timeout
	await board.attempt_activate(Vector2i(4,4))
	await get_tree().create_timer(.6).timeout
	get_tree().quit()
