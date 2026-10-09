extends Node

func _ready() -> void:
	run.call_deferred()

func run() -> void:
	SaveManager.save_path = "user://score_meter_visual_test.json"
	var screen := LevelController.new()
	screen.level_id = 20
	add_child(screen)
	await get_tree().create_timer(.4).timeout
	screen.story.hide()
	var meter := screen.hud.score_progress
	assert(not screen.hud.has_node("HintButton"))
	var settings := screen.hud.get_node("PauseButton") as Control
	var tray := screen.hud.get_node("SpecialItemsTray") as Control
	assert(absf(settings.get_global_rect().get_center().y-tray.get_global_rect().get_center().y) < 20)
	assert(settings.get_global_rect().end.x <= tray.get_global_rect().position.x)
	meter.set_score(0)
	assert(meter.lit_stars() == 0)
	meter.set_score(ceili(meter.two_star*.26/.54))
	assert(meter.lit_stars() == 1)
	meter.set_score(meter.two_star)
	assert(meter.lit_stars() == 2)
	meter.set_score(meter.three_star)
	assert(meter.lit_stars() == 3)
	assert(is_zero_approx(meter.progress_for_score(0)))
	assert(is_equal_approx(meter.progress_for_score(meter.two_star),.54))
	assert(is_equal_approx(meter.progress_for_score(meter.three_star),1))
	for value in [1,meter.two_star,meter.three_star,1000000,0]:
		meter.set_score(value)
		await get_tree().create_timer(.45).timeout
		assert(is_equal_approx(meter.fill_ratio,meter.progress_for_score(value)))
		assert(meter._number.text == str(value))
		assert(meter.illustration_rect().encloses(meter._number.get_rect()))
		if value == meter.two_star and DisplayServer.get_name() != "headless":
			await RenderingServer.frame_post_draw
			get_viewport().get_texture().get_image().save_png("res://.shots/score_meter_half.png")
	meter.set_completed(true)
	assert(meter.completed)
	meter.configure(screen.level)
	assert(not meter.completed and is_zero_approx(meter.fill_ratio))
	screen.free()
	AudioManager.stop_music()
	print("Score meter: PASS (empty, tiny, middle, full, overflow score and replay reset)")
	get_tree().quit()
