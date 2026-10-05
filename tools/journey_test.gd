extends Node

func _ready() -> void:
	run.call_deferred()

func run() -> void:
	SaveManager.save_path = "user://kuih_journey_test.json"
	SaveManager.reset()
	ProgressionManager.complete_tutorial()
	assert(LevelLibrary.count() == 30 and not LevelLibrary.has_level(31))
	assert(not ProgressionManager.is_level_unlocked(2))
	for stage in range(1, 31):
		assert(ProgressionManager.is_level_unlocked(stage))
		assert(LevelLibrary.get_level(stage).chapter_id == JourneyLibrary.STORY)
		ProgressionManager.record_win(stage, 1, 0)
	assert(ProgressionManager.total_stars() == 30)
	assert(ProgressionManager.world_state() == 0 and LocationManager.available_level(&"family_stall") == 3)
	EconomyManager.add_coins(3000)
	for i in 3:
		assert(LocationManager.upgrade(&"family_stall"))
	assert(ProgressionManager.world_state() == 3)
	assert(not ProgressionManager.is_level_unlocked(31))
	assert(ProgressionManager.gerai_level() >= 2)
	assert(SaveManager.data["chapters"].has("school_canteen"))
	var cosmetics: Array = SaveManager.data["gerai"]["cosmetics"].duplicate()
	ProgressionManager.record_win(30, 3, 20)
	ProgressionManager.claim_journey_milestones()
	assert(SaveManager.data["gerai"]["cosmetics"] == cosmetics and cosmetics.size() == 3)
	assert(SaveManager.save_game())
	SaveManager.load_game()
	assert(ProgressionManager.world_state() == 3)
	assert(ProgressionManager.story_seen(&"milestone_claim_30"))
	var map := JourneyMap.new()
	add_child(map)
	await get_tree().process_frame
	await get_tree().process_frame
	assert(map._nodes.size() == 31)
	assert(map._point(29).y < map._point(0).y)
	map._start.pressed.emit()
	assert(map.has_node("StagePreview"))
	var before := EconomyManager.booster_count(EconomyManager.Booster.TRAY)
	map.get_node("StagePreview").free()
	assert(EconomyManager.booster_count(EconomyManager.Booster.TRAY) == before)
	var preview := StagePreview.new()
	map.add_child(preview)
	preview.show_stage(30)
	await get_tree().process_frame
	if not DisplayServer.get_name() == "headless":
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("res://.shots/journey_preview_30.png")
	preview.free()
	var popup := JourneyMilestonePopup.new()
	map.add_child(popup)
	popup.show_milestone(30)
	await get_tree().process_frame
	if not DisplayServer.get_name() == "headless":
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("res://.shots/journey_complete_30.png")
	popup.free()
	if not DisplayServer.get_name() == "headless":
		await get_tree().process_frame
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("res://.shots/journey_mvp_30.png")
	map.free()
	var board := MatchBoard.new()
	board.size = Vector2(900, 900)
	add_child(board)
	board.build(LevelLibrary.get_level(1))
	var picks: Array[int] = [EconomyManager.Booster.TRAY, EconomyManager.Booster.GIFT]
	board.apply_start_specials(picks)
	assert(EconomyManager.booster_count(EconomyManager.Booster.TRAY) == before - 1)
	var found := 0
	for y in board.logic.height:
		for x in board.logic.width:
			if board.logic.get_cell(Vector2i(x, y)).special != BoardCell.Special.NONE:
				found += 1
	assert(found == 2)
	board.free()
	# Winning a milestone must show its story after the result is dismissed.
	GameManager.pending_tutorial_index = 0
	var screen := LevelController.new()
	screen.level_id = 10
	add_child(screen)
	await get_tree().process_frame
	screen.story.close()
	for order in screen.orders:
		order.collect(order.target.duplicate())
	for row in screen.board.logic.grid:
		for cell in row:
			cell.blocker_kind = BoardCell.NO_BLOCKER
	screen.score.add_points(screen.level.score_three_star)
	screen._win()
	await get_tree().create_timer(.6).timeout
	assert(not ProgressionManager.story_seen(&"milestone_scene_10"))
	screen._on_result_continue()
	var completion: JourneyMilestonePopup
	for child in screen.get_children():
		if child is JourneyMilestonePopup:
			completion = child
	assert(completion != null)
	completion.dismissed.disconnect(screen._advance_campaign)
	for button in completion.find_children("*", "Button", true, false):
		button.pressed.emit()
	assert(ProgressionManager.story_seen(&"milestone_scene_10"))
	await get_tree().process_frame
	screen.free()
	SaveManager.reset()
	SaveManager.data["levels"] = {"10": {"stars": 1}, "20": {"stars": 1}}
	ProgressionManager.claim_journey_milestones()
	assert(ProgressionManager.world_state() == 0 and LocationManager.available_level(&"family_stall") == 2)
	EconomyManager.add_coins(2000)
	assert(LocationManager.upgrade(&"family_stall") and LocationManager.upgrade(&"family_stall"))
	assert(ProgressionManager.world_state() == 2)
	assert(SaveManager.data["gerai"]["cosmetics"].size() == 2)
	await get_tree().create_timer(.6).timeout
	print("PASS Journey MVP: 30 stages, milestones, replay, persistence, preview and starting specials")
	get_tree().quit()
