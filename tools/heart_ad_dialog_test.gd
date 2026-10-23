extends Node

signal ad_finished(completed: bool)
var requests := 0

func provider() -> bool:
	requests += 1
	return await ad_finished

func shot(filename: String) -> void:
	if DisplayServer.get_name() == "headless":
		return
	await get_tree().create_timer(.2).timeout
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://.analysis/"+filename+".png")

func _ready() -> void:
	SaveManager.save_path = "user://heart_ad_dialog_test.json"
	SaveManager.reset()
	HeartManager.test_now = 1000000
	HeartManager.state()["current_hearts"] = 0
	HeartManager.state()["last_heart_refill_timestamp"] = HeartManager.now()-1655
	SaveManager.data["coins"] = 5000
	HeartManager.rewarded_ad_provider = provider
	var background := GeraiBackdrop.new()
	background.background_context = "menu"
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(background)
	var dialog: HeartRefillDialog
	for language in ["en","ms"]:
		SaveManager.data.settings.language = language
		dialog = HeartRefillDialog.new()
		add_child(dialog)
		assert(dialog._ad.visible and not dialog._ad.disabled)
		assert(dialog._ad.anchor_top < dialog._one.anchor_top)
		await shot("heart-ad-dialog-"+language)
		if language == "en":
			dialog.free()
	dialog._ad.pressed.emit()
	assert(dialog._watching_ad and dialog._ad.disabled and requests == 1)
	assert(HeartManager.current() == 0)
	dialog._ad.pressed.emit()
	dialog._refresh()
	assert(requests == 1 and dialog._ad.disabled)
	ad_finished.emit(true)
	await get_tree().process_frame
	assert(HeartManager.current() == 1 and EconomyManager.coins() == 5000)
	assert(not dialog._watching_ad and not dialog._ad.disabled)
	assert(int(HeartManager.state()["rewarded_heart_ads_used_today"]) == 1)
	dialog._ad.pressed.emit()
	ad_finished.emit(false)
	await get_tree().process_frame
	assert(HeartManager.current() == 1 and requests == 2)
	HeartManager.state()["rewarded_heart_ads_used_today"] = HeartManager.AD_CAP
	dialog._refresh()
	assert(dialog._ad.disabled)
	HeartManager.rewarded_ad_provider = Callable()
	dialog._refresh()
	assert(dialog._ad.disabled and dialog._ad.visible)
	await shot("heart-ad-dialog-unavailable")
	dialog.free()
	HeartManager.rewarded_ad_provider = provider
	HeartManager.state()["rewarded_heart_ads_used_today"] = 0
	dialog = HeartRefillDialog.new()
	add_child(dialog)
	dialog._ad.pressed.emit()
	dialog.queue_free()
	await get_tree().process_frame
	ad_finished.emit(true)
	await get_tree().process_frame
	assert(HeartManager.current() == 2,"Verified reward still arrives after dialog closes")
	HeartManager.rewarded_ad_provider = Callable()
	HeartManager.test_now = -1
	print("Heart ad dialog: PASS (BM/EN layout, verified reward only, cancellation, duplicate taps, daily cap, unavailable provider and close during ad)")
	get_tree().quit()
