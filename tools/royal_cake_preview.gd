extends LevelController
func _notification(what: int) -> void:
	if what in [NOTIFICATION_APPLICATION_PAUSED,NOTIFICATION_APPLICATION_FOCUS_OUT]:
		return
	super._notification(what)
func _ready() -> void:
	SaveManager.save_path = "user://royal_cake_preview.json"
	SaveManager.reset()
	SaveManager.data["tutorial_done"] = true
	GameManager.pending_tutorial_index = 0
	endless_mode = true
	super._ready()
	_demo.call_deferred()
func _demo() -> void:
	await get_tree().create_timer(.5).timeout
	for direction in [Vector2i.RIGHT,Vector2i.DOWN,Vector2i.LEFT,Vector2i.UP]:
		board.build(level)
		for row in board.logic.grid:
			for cell in row:
				cell.special = BoardCell.Special.NONE
		var a := Vector2i(3,3)
		var b: Vector2i = a+direction
		board.logic.get_cell(a).special = BoardCell.Special.ORDER
		board.logic.get_cell(b).special = BoardCell.Special.ORDER
		board._refresh_tiles()
		await get_tree().create_timer(.85).timeout
		await board.attempt_swap(a,b)
		await get_tree().create_timer(.5).timeout
	get_tree().quit()
