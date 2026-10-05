extends Node

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	SaveManager.save_path = "user://kuih_score_test.json"
	SaveManager.reset()
	run.call_deferred()

func run() -> void:
	var level := LevelDefinition.new()
	level.score_two_star = 4000
	level.score_three_star = 6000
	level.base_coin_reward = 40
	level.first_clear_bonus = 20
	level.score_per_coin = 200
	for sample in [[false, 10000, 0], [true, 3500, 1], [true, 4800, 2], [true, 6200, 3]]:
		var outcome := StageResultCalculator.calculate(sample[0], sample[1], 0, level)
		assert(outcome.earned_stars == sample[2])
		assert(outcome.success == sample[0])
		if not sample[0]:
			assert(outcome.total_coins == 0)
	var first := StageResultCalculator.calculate(true, 6200, 0, level, true)
	assert(first.base_coins == 40 and first.score_bonus == 31 and first.star_bonus == 18 and first.first_clear_bonus == 20 and first.total_coins == 109)
	var bonus := StageResultCalculator.calculate(true, 3500, 5, level)
	assert(bonus.final_score == 4000 and bonus.move_bonus == 500 and bonus.earned_stars == 2)
	ProgressionManager.record_win(1, 3, 5, 6200)
	assert(not ProgressionManager.first_clear_available(1))
	ProgressionManager.record_win(1, 1, 0, 3500)
	assert(ProgressionManager.stars_for(1) == 3 and ProgressionManager.best_score(1) == 6200)
	ProgressionManager.record_win(1, 2, 0, 6500)
	assert(ProgressionManager.best_score(1) == 6500)
	assert(StageResultCalculator.calculate(true, 6500, 0, level, ProgressionManager.first_clear_available(1)).first_clear_bonus == 0)
	assert(SaveManager.save_game())
	SaveManager.load_game()
	assert(ProgressionManager.best_score(1) == 6500 and ProgressionManager.stars_for(1) == 3)
	var migrated := SaveManager._normalize({"version": 1, "coins": 777, "levels": {"2": {"stars": 2, "best_moves_left": 8}}})
	assert(migrated.levels["2"].stars == 2 and migrated.levels["2"].best_score == 0 and migrated.levels["2"].first_clear_claimed and migrated.coins == 777)
	var scoring := StageScoreController.new()
	scoring.setup(level)
	for length in [3, 4, 5]:
		var state := BoardState.new()
		state.setup(length, 3, KuihLibrary.starter_set(), 18)
		for y in 3:
			for x in length:
				state.get_cell(Vector2i(x, y)).kuih = state.pool[(x+y) % 3]
		for x in length:
			state.get_cell(Vector2i(x, 1)).kuih = state.pool[0]
		var cleared := state.resolve()
		var gained := scoring.add_clear(cleared, 0)
		assert(gained == (30 if length == 3 else 80 if length == 4 else 150))
	var simple := BoardState.ClearResult.new()
	for x in 3:
		simple.cleared[Vector2i(x, 0)] = BoardState.ClearInfo.new()
	assert(scoring.add_clear(simple, 1) == 38 and scoring.add_clear(simple, 2) == 45)
	var activation := BoardState.ClearResult.new()
	activation.cleared[Vector2i.ZERO] = BoardState.ClearInfo.new()
	activation.activated.append({"kind": BoardCell.Special.TAPAU})
	assert(scoring.add_clear(activation, 0) == 110)
	activation.activated.append({"kind": BoardCell.Special.DULANG})
	assert(scoring.add_clear(activation, 0) == 460)
	var unchanged := scoring.total
	assert(scoring.add_clear(BoardState.ClearResult.new(), 0) == 0 and scoring.total == unchanged)
	for stage in LevelLibrary.all():
		assert(stage.score_two_star > 0 and stage.score_three_star > stage.score_two_star)
	# Representative late-stage scores now give attainable performance ratings.
	assert(LevelLibrary.get_level(11).stars_for_score(1869) == 2)
	assert(LevelLibrary.get_level(11).stars_for_score(2404) == 3)
	assert(LevelLibrary.get_level(30).stars_for_score(3869) == 2)
	assert(LevelLibrary.get_level(30).stars_for_score(4341) == 3)
	SaveManager.reset()
	ProgressionManager.complete_tutorial()
	GameManager.pending_tutorial_index = 0
	var live := LevelController.new()
	live.level_id = 1
	add_child(live)
	await get_tree().process_frame
	live.story.close()
	live.score.add_points(10000)
	live.moves_left = 0
	var hearts := HeartManager.current()
	var coins := EconomyManager.coins()
	live._on_settled()
	live._on_settled()
	assert(live.finished and not live.stage_result.success and live.stage_result.earned_stars == 0)
	assert(HeartManager.current() == hearts - 1 and EconomyManager.coins() == coins)
	assert(ProgressionManager.stars_for(1) == 0)
	live._start_level()
	live.story.close()
	live.score.add_points(500)
	live.moves_left = 5
	for order in live.orders:
		order.collect(order.target.duplicate())
	live._on_settled()
	assert(live.finished and live.stage_result.success and live.stage_result.final_score == 1000)
	assert(not live.hud._coin_pill.visible and live.hud.score_progress.anchor_right - live.hud.score_progress.anchor_left > .4)
	assert(live.hud.score_progress.score == 1000 and live.result._score_value.text == "1000")
	assert(HeartManager.current() == hearts - 1)
	assert(live.stage_result.first_clear_bonus == live.level.first_clear_bonus)
	assert(EconomyManager.coins() == coins + live.stage_result.total_coins + 50) # First Steps + No Help Needed, each once.
	var previous := ProgressionManager.best_score(1)
	live._start_level()
	live.story.close()
	live.score.add_points(100)
	live.moves_left = 0
	for order in live.orders:
		order.collect(order.target.duplicate())
	live._on_settled()
	assert(live.stage_result.success and live.stage_result.earned_stars == 1 and live.stage_result.first_clear_bonus == 0)
	assert(ProgressionManager.best_score(1) == previous and not live.stage_result.is_new_best)
	live.free()
	print("PASS score A-J: order gate, ratings, replay, first clear, move bonus, migration, formulas, cascades, HUD, rewards and hearts")
	get_tree().quit(0)
