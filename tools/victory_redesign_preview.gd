extends Node

func _ready() -> void:
	run.call_deferred()

func run() -> void:
	var overlay := ResultOverlay.new()
	add_child(overlay)
	var details := StageResult.new()
	details.final_score = 4991
	overlay.stage_number = 13
	overlay.show_win("Crisp Corner",3,169,[],false,details)
	await get_tree().create_timer(.6).timeout
	assert(overlay._primary.visible and overlay._coins_label.text == "+169")
	assert(overlay.score_target == 4991)
	if DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("res://.analysis/victory-redesign.png")
	overlay.show_fail("Missing kuih",false,details)
	assert(not overlay._coin_caption.visible and overlay._primary.visible)
	overlay.free()
	AudioManager.stop_music()
	print("Victory redesign: PASS (reward values, primary action, win/fail layout switching)")
	get_tree().quit()
