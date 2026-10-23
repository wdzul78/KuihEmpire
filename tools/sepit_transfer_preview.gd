extends LevelController
func _pause_after_interruption() -> void:
	pass # Only this offline capture ignores focus changes.
func _notification(what: int) -> void:
	if what in [NOTIFICATION_APPLICATION_PAUSED,NOTIFICATION_APPLICATION_FOCUS_OUT]:
		return
	super._notification(what)
func _ready() -> void:
	SaveManager.save_path = "user://sepit_transfer_preview.json"
	SaveManager.reset()
	SaveManager.data["tutorial_done"] = true
	GameManager.pending_tutorial_index = 0
	endless_mode = true
	super._ready()
	_demo.call_deferred()
func _demo() -> void:
	await get_tree().create_timer(.4).timeout
	for kind in [BoardCell.Special.TAPAU,BoardCell.Special.TAPAU_VERTICAL,BoardCell.Special.DULANG,BoardCell.Special.ORDER,BoardCell.Special.HANTAR]:
		board.build(level)
		board.logic.delivery_enabled = true
		for row in board.logic.grid:
			for cell in row:
				cell.special = BoardCell.Special.NONE
		var a := Vector2i(2,5)
		var b := Vector2i(3,5)
		board.logic.get_cell(a).special = BoardCell.Special.HANTAR
		board.logic.get_cell(b).special = kind
		board._refresh_tiles()
		await get_tree().create_timer(.8).timeout
		await board.attempt_swap(a,b)
		await get_tree().create_timer(.5).timeout
	get_tree().quit()
