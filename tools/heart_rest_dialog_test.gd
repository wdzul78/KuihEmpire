extends Node

func shot(filename: String) -> void:
	if DisplayServer.get_name() == "headless":
		return
	await get_tree().create_timer(.2).timeout
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://.analysis/"+filename+".png")

func _ready() -> void:
	SaveManager.save_path = "user://rest_dialog_test.json"
	SaveManager.reset()
	HeartManager.test_now = 1000000
	HeartManager.state()["current_hearts"] = 0
	HeartManager.state()["last_heart_refill_timestamp"] = HeartManager.now()-1655
	SaveManager.data["coins"] = 5000
	var background := GeraiBackdrop.new()
	background.background_context = "menu"
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(background)
	var dialog: HeartRefillDialog
	for language in ["en","ms"]:
		SaveManager.data.settings.language = language
		dialog = HeartRefillDialog.new()
		add_child(dialog)
		assert(dialog._status.text == "0 / 5")
		assert(dialog._timer.text == "02:25")
		assert(dialog._ad.visible and dialog._ad.disabled)
		assert(not dialog._one.disabled and not dialog._full.disabled)
		assert(dialog.get_node("CartoonAinaRest").texture.resource_path.contains("aina_rest"))
		HeartRefillDialog.open(self)
		assert(get_children().filter(func(node): return node is HeartRefillDialog).size() == 1)
		await shot("heart-rest-"+language)
		if language == "en":
			dialog.free()
	dialog._one.pressed.emit()
	assert(HeartManager.current() == 1 and EconomyManager.coins() == 4500)
	dialog._full.pressed.emit()
	assert(HeartManager.current() == 5 and EconomyManager.coins() == 2700)
	assert(dialog._one.disabled and dialog._full.disabled)
	assert(dialog._timer.text == "5 / 5")
	HeartManager.state()["current_hearts"] = 0
	HeartManager.state()["last_heart_refill_timestamp"] = HeartManager.now()
	SaveManager.data["coins"] = 499
	dialog._refresh()
	assert(dialog._one.disabled and dialog._full.disabled and not dialog._message.text.is_empty())
	await shot("heart-rest-insufficient")
	HeartManager.state()["free_play_end_timestamp"] = HeartManager.now()+180
	dialog._refresh()
	assert(dialog._timer.text == "03:00")
	HeartManager.state()["free_play_end_timestamp"] = 0
	HeartManager.test_now += 1
	dialog._refresh()
	assert(dialog._timer.text == "29:59")
	dialog.get_node("CloseRestDialog").pressed.emit()
	await get_tree().process_frame
	assert(not has_node("HeartRefillDialog"))
	HeartManager.test_now = -1
	print("Heart rest dialog: PASS (cartoon asset, BM/EN, countdown, duplicate guard, both purchase costs, full/low balance/free-play states and close)")
	get_tree().quit()
