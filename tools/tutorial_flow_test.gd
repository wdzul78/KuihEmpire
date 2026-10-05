extends Node

var failures: Array[String] = []
func check(ok: bool, why: String) -> void:
	if not ok:
		failures.append(why)
		push_error(why)

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	SaveManager.save_path = "user://kuih_tutorial_flow_test.json"
	SaveManager.reset()
	run.call_deferred()

func settle(screen: LevelController) -> void:
	var deadline := Time.get_ticks_msec() + 12000
	while screen.board.busy or screen._serving:
		if Time.get_ticks_msec() > deadline:
			check(false, "tutorial animation did not settle")
			return
		await get_tree().process_frame
	await get_tree().create_timer(.12).timeout

func intros(screen: LevelController) -> void:
	while screen.coach.can_tap_through():
		screen.coach.tap_through()
	await get_tree().process_frame

func lesson(id: int) -> LevelController:
	GameManager.pending_tutorial_index = 0
	var screen := LevelController.new()
	screen.tutorial_index = id
	add_child(screen)
	return screen

func run() -> void:
	check(TutorialLibrary.ACTIVE_LESSONS == [1,2,3,4,10,11,9,5,7,8], "teaching order grows toward the full board")
	for i in TutorialLibrary.ACTIVE_LESSONS.size():
		var id: int = TutorialLibrary.ACTIVE_LESSONS[i]
		check(TutorialLibrary.lesson_number(id) == i+1, "contiguous display numbering")
		check(TutorialLibrary.next_index(id) == (TutorialLibrary.ACTIVE_LESSONS[i+1] if i<9 else 0), "next lesson follows authored order")
	check(ProgressionManager.tutorial_index() == 0, "new profile begins before lesson one")
	# Every active piece of authored copy must have a Malay translation.
	SaveManager.data.settings.language = "ms"
	for stage in TutorialLibrary.all():
		check(TutorialText.text(stage.title) != stage.title, "translated lesson title: "+stage.title)
		for step in stage.tutorial_steps:
			check(TutorialText.text(step.title) != step.title, "translated step title: "+step.title)
			check(TutorialText.text(step.body) != step.body, "translated dialogue: "+step.body)
	var vertical := lesson(10)
	await get_tree().process_frame
	check(vertical.coach._body.text.contains("lajur"), "coach renders Malay in UI")
	check(not vertical.coach.allows_swap(Vector2i(0,0),Vector2i(1,0)), "wrong vertical lesson move is gated")
	await vertical.board.attempt_swap(Vector2i(2,1),Vector2i(2,2))
	await settle(vertical)
	check(vertical.coach._current().gate == TutorialStepData.Gate.ACTIVATED_SPECIAL, "vertical creation must precede activation")
	vertical.coach.guide_special_activation(vertical.board.logic)
	var pair := vertical.coach.hint_cells()
	check(pair.size() == 2, "vertical special has an actionable hint")
	if pair.size() == 2:
		check(vertical.board.logic.get_cell(pair[0]).special == BoardCell.Special.TAPAU_VERTICAL, "created special is vertical")
		await vertical.board.attempt_swap(pair[0],pair[1])
	await settle(vertical)
	check(vertical.coach.can_tap_through(), "effect reaches recap")
	await intros(vertical)
	check(vertical.finished and vertical.result.stage_number == 5, "vertical lesson completes with display number five")
	var awarded := EconomyManager.coins()
	check(vertical.stage_result.total_coins > 0, "first completion pays reward")
	vertical._on_result_retry()
	await get_tree().process_frame
	check(vertical.coach.modulate.a == 1 and not vertical.coach.is_done(), "replay restores coaching opacity and gates")
	await vertical.board.attempt_swap(Vector2i(2,1),Vector2i(2,2))
	await settle(vertical)
	vertical.coach.guide_special_activation(vertical.board.logic)
	pair = vertical.coach.hint_cells()
	if pair.size() == 2:
		await vertical.board.attempt_swap(pair[0],pair[1])
	await settle(vertical)
	await intros(vertical)
	check(vertical.finished and vertical.stage_result.total_coins == 0 and EconomyManager.coins() == awarded, "replay cannot farm coins")
	vertical.queue_free()
	await get_tree().process_frame
	check(SaveManager.save_game(), "tutorial reward marker saves")
	SaveManager.load_game()
	check(not ProgressionManager.claim_tutorial_reward(10), "reward protection survives save reload")
	SaveManager.data.settings.language = "en"
	var cross := lesson(11)
	await get_tree().process_frame
	await intros(cross)
	check(cross.coach._current().gate == TutorialStepData.Gate.ACTIVATED_CROSS, "cross requires a real combination")
	await cross.board.attempt_swap(Vector2i(1,1),Vector2i(2,1))
	await settle(cross)
	check(cross.coach.can_tap_through() and not cross.finished, "cross effect completes before recap")
	await intros(cross)
	check(cross.finished and cross.result.stage_number == 6, "cross lesson finishes as lesson six")
	cross.queue_free()
	await get_tree().process_frame
	# Even the full-board lesson locks all inventory power-ups.
	for key in SaveManager.data.boosters:
		SaveManager.data.boosters[key] = 0
	var full := lesson(8)
	await get_tree().process_frame
	await intros(full)
	check(not full.hud.booster_bar.practice_mode, "full-board lesson has no free practice supplies")
	for entry in BoosterBar.BUTTONS:
		var button: Button = full.hud.booster_bar._buttons[entry.booster]
		check(button.disabled and button.get_node("LockIcon").visible, "tutorial button is locked")
		check(not button.get_node("BoosterArt").visible and not button.get_parent().get_node("Badge").visible, "tutorial hides item art and infinity badge")
	var inventory: Dictionary = SaveManager.data.boosters.duplicate(true)
	var coins_before := EconomyManager.coins()
	var grid_before := full.board.logic.snapshot()
	await full._on_booster_requested(EconomyManager.Booster.SHUFFLE)
	await full._on_booster_targeted(EconomyManager.Booster.SPATULA, Vector2i(0,0))
	await full._on_booster_targeted(EconomyManager.Booster.TRAY, Vector2i(3,3))
	await full._on_booster_requested(EconomyManager.Booster.GIFT)
	await settle(full)
	check(full.board.logic.snapshot() == grid_before, "tutorial blocks direct booster requests and targets")
	check(SaveManager.data.boosters == inventory and EconomyManager.coins() == coins_before, "locked tutorial never spends inventory or currency")
	full._on_kuih_collected({&"onde_onde":100,&"ang_ku_kueh":100})
	await settle(full)
	check(full.finished and full.result.tutorial_final, "full-board lesson is final")
	check(full.result._primary.text.contains("OPEN YOUR GIFT"), "last result uses journey action")
	# Keep this runner alive across actual scene replacement.
	get_tree().current_scene = null
	full._on_result_continue()
	while SceneManager._busy:
		await get_tree().process_frame
	check(get_tree().current_scene.scene_file_path == SceneManager.WELCOME, "completion opens gift before Journey")
	var welcome := get_tree().current_scene as OnboardingFinish
	var before_gift := EconomyManager.coins()
	welcome._open_gift()
	await get_tree().create_timer(.9).timeout
	check(EconomyManager.coins() == before_gift+500, "opening chest grants 500 coins")
	check(int(SaveManager.data.hearts.free_play_end_timestamp) >= int(Time.get_unix_time_from_system())+3590, "gift grants one hour free play")
	check(not OnboardingProgress.claim_gift(), "gift cannot be claimed twice")
	SaveManager.load_game()
	check(not OnboardingProgress.claim_gift(), "gift survives reload without duplication")
	welcome._next_page()
	var before_restore := EconomyManager.coins()
	check(OnboardingProgress.restore_stall(), "starter restoration can be bought")
	check(EconomyManager.coins() == before_restore-300 and OnboardingProgress.restored(), "restoration saves and spends 300")
	check(not OnboardingProgress.restore_stall(), "restoration cannot charge twice")
	check(LocationManager.structural_level(&"family_stall") == 0, "restoration preserves milestone upgrades")
	welcome._next_page()
	welcome._finish()
	while SceneManager._busy:
		await get_tree().process_frame
	check(get_tree().current_scene.scene_file_path == SceneManager.JOURNEY and not OnboardingProgress.pending(), "accessory introduction leads to Journey")
	var host := Control.new()
	add_child(host)
	var known: Array[KuihData] = [KuihLibrary.get_kuih(&"onde_onde"),KuihLibrary.get_kuih(&"keria")]
	var completed := [false]
	KuihIntroduction.present(host,known,func() -> void: completed[0] = true)
	var intro := host.get_child(0) as KuihIntroduction
	for i in 2:
		for child in intro.get_children():
			if child is Button:
				child.pressed.emit()
				break
	check(completed[0] and KuihIntroduction.unseen(known).is_empty(), "kuih cards acknowledge each type once")
	host.queue_free()
	for id in range(1,11):
		var campaign := LevelLibrary.get_level(id)
		check(campaign.width == 3+(id-1)/2 and campaign.width == campaign.height, "starter boards grow in pairs")
		for order in campaign.customer_orders:
			for item in order.items:
				check(item.kuih in campaign.kuih, "all starter order kuih are in pool")
	check(ProgressionManager.tutorial_done() and not ProgressionManager.needs_tutorial(), "onboarding done and Hantar unlocked")
	check(GameManager.pending_level_id == 1 and GameManager.pending_tutorial_index == 0, "new player selects campaign stage one")
	full.queue_free()
	await get_tree().process_frame
	# Historical completed saves learn only Hantar, with no onboarding replay.
	SaveManager.data.tutorial_done = true
	SaveManager.data.special_unlocks.hantar = false
	check(GameManager.next_play_target().get("tutorial") == 9 and TutorialLibrary.is_last(9), "legacy player needs only delivery lesson")
	var old_save := SaveManager.data.duplicate(true)
	old_save.erase("tutorial_rewarded")
	var clean: Dictionary = SaveManager._normalize(old_save)
	check("1" in clean.tutorial_rewarded and "9" in clean.tutorial_rewarded, "legacy claimed rewards migrate")
	AudioManager.stop_music()
	for voice in AudioManager._voices:
		voice.stop()
		voice.stream = null
	await get_tree().create_timer(.15).timeout
	print("Tutorial flow tests: %s (%d problems)" % ["PASS" if failures.is_empty() else "FAIL",failures.size()])
	get_tree().quit(0 if failures.is_empty() else 1)

