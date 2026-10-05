extends Node

var problems: Array[String] = []
func check(value: bool, message: String) -> void:
	if not value:
		problems.append(message)

func _ready() -> void:
	SaveManager.save_path = "user://kuih_heart_test.json"
	SaveManager.reset()
	run.call_deferred()

func run() -> void:
	HeartManager.test_now = 1000000
	HeartManager.refresh()
	check(HeartManager.current() == 5, "old/new saves start full")
	var display := FiveHeartDisplay.new()
	display.refill_enabled = false
	display.size = Vector2(300,60)
	add_child(display)
	check(display._hearts.size() == 5, "health display has five slots")
	for count in range(6):
		HeartManager.state()["current_hearts"] = count
		display._refresh()
		for index in 5:
			check(display._hearts[index].texture == FiveHeartDisplay._texture(index < count), "full/empty health slot mapping")
		check(not display._timer.visible, "gameplay has no refill button/countdown")
	HeartManager.state()["current_hearts"] = 5
	HeartManager.state()["last_heart_refill_timestamp"] = 0
	display._refresh()
	display.refill_enabled = true
	HeartManager.state()["current_hearts"] = 3
	display._refresh()
	check(display._timer.visible, "main-menu strip retains refill countdown")
	display.pressed.emit()
	check(has_node("HeartRefillDialog"), "main-menu strip opens refill dialog")
	get_node("HeartRefillDialog").free()
	HeartManager.state()["current_hearts"] = 5
	HeartManager.state()["last_heart_refill_timestamp"] = 0
	display.queue_free()
	check(HeartManager.can_start_stage() and HeartManager.current() == 5, "starting stage spent a heart")
	HeartManager.consume_on_failure(true)
	check(HeartManager.current() == 5, "tutorial spent heart")
	HeartManager.consume_on_failure()
	check(HeartManager.current() == 4 and HeartManager.get_next_refill_remaining() == 1800, "failure/refill start")
	HeartManager.test_now += 1799
	check(HeartManager.current() == 4 and HeartManager.get_next_refill_remaining() == 1, "early refill")
	HeartManager.test_now += 1
	check(HeartManager.current() == 5 and HeartManager.get_next_refill_remaining() == 0, "30-minute refill")
	HeartManager.test_now += 5000
	HeartManager.consume_on_failure()
	check(HeartManager.get_next_refill_remaining() == 1800, "full timer did not pause")
	for i in 3:
		HeartManager.consume_on_failure()
	HeartManager.test_now += 3600
	check(HeartManager.current() == 3, "offline multi-heart recovery")
	HeartManager.test_now += 200
	check(HeartManager.get_next_refill_remaining() == 1600, "partial refill lost")
	HeartManager.start_free_play(900)
	HeartManager.consume_on_failure()
	check(HeartManager.current() == 3, "Free Play spent heart")
	check(SaveManager.save_game(), "heart save failed")
	SaveManager.load_game()
	HeartManager.test_now += 300
	check(HeartManager.get_free_play_remaining() == 600, "Free Play save timestamp")
	HeartManager.test_now += 601
	check(not HeartManager.is_free_play_active(), "Free Play did not expire")
	HeartManager.consume_on_failure()
	check(HeartManager.current() == 2, "post-Free Play failure")
	check(HeartManager.reward_win(1) == 0 and HeartManager.reward_win(2) == 0 and HeartManager.reward_win(3) == 900, "3-win streak reward")
	check(HeartManager.reward_win(10) == 1800, "chapter reward")
	check(HeartManager.reward_win(10) == 0, "repeated chapter bonus")
	HeartManager.state()["free_play_end_timestamp"] = 0
	HeartManager.consume_on_failure()
	HeartManager.reward_win(1)
	check(HeartManager.state()["win_streak"] == 1, "failure did not reset streak")
	SaveManager.data["coins"] = 499
	check(not HeartManager.purchase_refill() and EconomyManager.coins() == 499, "insufficient coin charge")
	SaveManager.data["coins"] = 2300
	var before := HeartManager.current()
	check(HeartManager.purchase_refill() and HeartManager.current() == before + 1 and EconomyManager.coins() == 1800, "single-heart purchase")
	check(HeartManager.purchase_refill(true) and HeartManager.current() == 5 and EconomyManager.coins() == 0, "full refill purchase")
	check(not HeartManager.can_watch_ad(), "ad available without provider")
	HeartManager.consume_on_failure()
	HeartManager.rewarded_ad_provider = func() -> bool: return false
	check(not await HeartManager.watch_ad() and HeartManager.current() == 4, "cancelled ad granted reward")
	HeartManager.rewarded_ad_provider = func() -> bool: return true
	for i in 3:
		check(await HeartManager.watch_ad(), "verified ad reward missing")
		HeartManager.consume_on_failure()
	check(not HeartManager.can_watch_ad(), "daily ad cap missing")
	HeartManager.test_now += 86400
	HeartManager.refresh()
	HeartManager.consume_on_failure()
	check(HeartManager.can_watch_ad(), "daily cap did not reset")
	HeartManager.rewarded_ad_provider = Callable()
	check(SaveManager._normalize({"hearts": {"current_hearts": 99, "free_play_end_timestamp": "bad"}})["hearts"]["current_hearts"] == 5, "save clamp")
	HeartManager.full_refill()
	GameManager.pending_tutorial_index = 0
	var screen := LevelController.new()
	screen.level_id = 1
	add_child(screen)
	await get_tree().process_frame
	screen.story.close()
	screen.moves_left = 0
	screen._on_settled()
	check(HeartManager.current() == 4, "controller failure did not consume exactly one")
	screen._on_result_continue()
	screen.moves_left = 0
	screen._on_settled()
	check(HeartManager.current() == 4, "continuation charged same attempt twice")
	await get_tree().create_timer(.5).timeout
	screen.free()
	ProgressionManager.complete_tutorial()
	HeartManager.state()["current_hearts"] = 0
	HeartManager.state()["last_heart_refill_timestamp"] = HeartManager.now()
	var map := JourneyMap.new()
	add_child(map)
	await get_tree().process_frame
	map._select_stage(1)
	check(map._nodes.size() == 31 and map.selected_stage == 1 and not ProgressionManager.is_level_unlocked(31), "30 stage map with future destination teaser")
	GameManager.start_selected_stage()
	check(has_node("HeartRefillDialog") and not SceneManager._busy, "zero-heart admission did not open refill")
	check(not get_node("HeartRefillDialog")._ad.visible, "unconnected ad option displayed")
	get_node("HeartRefillDialog").free()
	map.free()
	HeartManager.full_refill()
	# Keep this test runner alive while real scene transitions replace their scene.
	get_tree().current_scene = null
	GameManager.play_level(1)
	await navigation()
	check(get_tree().current_scene is JourneyMap, "Play skipped journey")
	GameManager.start_selected_stage()
	await navigation()
	check(get_tree().current_scene is LevelController and HeartManager.current() == 5, "map Start failed or charged heart")
	var live := get_tree().current_scene as LevelController
	live.story.close()
	live._on_result_retry()
	await navigation()
	check(get_tree().current_scene is JourneyMap, "retry skipped journey")
	GameManager.start_selected_stage()
	await navigation()
	live = get_tree().current_scene as LevelController
	live.story.close()
	ProgressionManager.record_win(1, 3, 8)
	live.result.show_win("test", 3, 10, [], false)
	await get_tree().create_timer(.5).timeout
	live._on_result_continue()
	await navigation()
	check(get_tree().current_scene is JourneyMap and GameManager.pending_level_id == 2, "next stage skipped journey")
	get_tree().current_scene.queue_free()
	await get_tree().process_frame
	await get_tree().process_frame
	HeartManager.test_now = -1
	print("Heart tests: %s (%d problems)" % ["PASS" if problems.is_empty() else "FAIL", problems.size()])
	for message in problems:
		print("  ! " + message)
	get_tree().quit(0 if problems.is_empty() else 1)

func navigation() -> void:
	while SceneManager._busy:
		await get_tree().process_frame
	await get_tree().process_frame
