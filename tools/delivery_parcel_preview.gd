extends LevelController

## Disposable gameplay preview: no changes to the player's discoveries/save.
func _ready() -> void:
	SaveManager.save_path = "user://delivery_parcel_preview.json"
	SaveManager.reset()
	SaveManager.data["tutorial_done"] = true
	SaveManager.data["delivery_unlocked"] = true
	GameManager.pending_tutorial_index = 0
	endless_mode = true
	super._ready()
	board.logic.delivery_enabled = true
	_demo.call_deferred()

func _demo() -> void:
	await get_tree().create_timer(1.0).timeout
	for origin in [Vector2i(2,5),Vector2i(5,4)]:
		var cell := board.logic.get_cell(origin)
		cell.special = BoardCell.Special.HANTAR
		cell.order_kuish = &"onde_onde"
		board._refresh_tiles()
		await get_tree().create_timer(1.0).timeout
		if DisplayServer.get_name() != "headless":
			await RenderingServer.frame_post_draw
			get_viewport().get_texture().get_image().save_png("res://.shots/delivery_parcel_idle_%d.png" % origin.x)
		var cleared := board.logic.activate_specials([origin])
		await board._play_step(cleared,0)
		# Use the board's normal refill after the real activation, rather than
		# a stand-alone flight mockup.
		board.build(level)
		board.logic.delivery_enabled = true
		await get_tree().create_timer(1.0).timeout
	if OS.get_environment("KUIH_DELIVERY_CAPTURE") == "1":
		get_tree().quit()

