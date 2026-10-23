extends LevelController

func _notification(what: int) -> void:
	if what in [NOTIFICATION_APPLICATION_PAUSED,NOTIFICATION_APPLICATION_FOCUS_OUT]:
		return
	super._notification(what)

func _ready() -> void:
	SaveManager.save_path = "user://ketupat_preview.json"
	SaveManager.reset()
	SaveManager.data["tutorial_done"] = true
	GameManager.pending_tutorial_index = 0
	endless_mode = true
	super._ready()
	demo.call_deferred()

func capture_after(delay: float, filename: String) -> void:
	await board._wait(delay)
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://.analysis/"+filename+".png")

func demo() -> void:
	await get_tree().create_timer(.5).timeout
	board.build(level)
	for row in board.logic.grid:
		for cell in row:
			cell.special = BoardCell.Special.NONE
	board._refresh_tiles()
	await get_tree().create_timer(.5).timeout
	capture_after(.11,"ketupat-appearance")
	capture_after(.80,"ketupat-impact-shake")
	capture_after(1.80,"ketupat-readable-hold")
	capture_after(2.30,"ketupat-cross-sweep")
	capture_after(2.52,"ketupat-rice-reveal")
	await board.booster_clear(Vector2i(3,4),&"cross")
	await get_tree().create_timer(.8).timeout
	print("Ketupat rendered preview: PASS")
	get_tree().quit()
