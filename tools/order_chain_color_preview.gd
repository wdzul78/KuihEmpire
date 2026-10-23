extends LevelController
func _notification(what: int) -> void:
	if what in [NOTIFICATION_APPLICATION_PAUSED,NOTIFICATION_APPLICATION_FOCUS_OUT]:
		return
	super._notification(what)
func _ready() -> void:
	SaveManager.save_path = "user://order_chain_colors_preview.json"
	SaveManager.reset()
	SaveManager.data["tutorial_done"] = true
	GameManager.pending_tutorial_index = 0
	endless_mode = true
	super._ready()
	_demo.call_deferred()
func _demo() -> void:
	await get_tree().create_timer(.5).timeout
	for row in board.logic.grid:
		for cell in row:
			cell.special = BoardCell.Special.NONE
	board.logic.get_cell(Vector2i(1,3)).special = BoardCell.Special.TAPAU
	for i in 3:
		var pos := Vector2i(3+i,3)
		board.logic.get_cell(pos).special = BoardCell.Special.ORDER
		board.logic.get_cell(pos).order_kuish = board.logic.pool[i].id
	board._refresh_tiles()
	await get_tree().create_timer(1.1).timeout
	await board.attempt_activate(Vector2i(1,3))
	await get_tree().create_timer(1.5).timeout
	get_tree().quit()
