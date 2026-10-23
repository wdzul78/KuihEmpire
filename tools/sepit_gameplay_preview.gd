extends LevelController

func _ready() -> void:
	SaveManager.save_path = "user://sepit_gameplay_preview.json"
	SaveManager.reset()
	SaveManager.data["tutorial_done"] = true
	SaveManager.data["delivery_unlocked"] = true
	GameManager.pending_tutorial_index = 0
	endless_mode = true
	super._ready()
	_demo.call_deferred()

func _prepare(origin: Vector2i) -> void:
	board.build(level)
	board.logic.delivery_enabled = true
	for row in board.logic.grid:
		for cell in row:
			cell.special = BoardCell.Special.NONE
	board.logic.get_cell(origin).special = BoardCell.Special.HANTAR
	board.logic.get_cell(origin).order_kuish = &""
	board._refresh_tiles()

func _demo() -> void:
	await get_tree().create_timer(.8).timeout
	var origin := Vector2i(2,5)
	_prepare(origin)
	await get_tree().create_timer(1.0).timeout
	await board.attempt_swap(origin,origin+Vector2i.RIGHT)
	await get_tree().create_timer(.7).timeout
	origin = Vector2i(5,4)
	_prepare(origin)
	await get_tree().create_timer(1.0).timeout
	await board.attempt_activate(origin)
	await get_tree().create_timer(.8).timeout
	if OS.get_environment("KUIH_DELIVERY_CAPTURE") == "1":
		get_tree().quit()
