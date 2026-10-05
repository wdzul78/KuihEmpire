extends Node

func _ready() -> void:
	SaveManager.save_path = "user://kuih_achievement_ranking_test.json"
	SaveManager.reset()
	run.call_deferred()

func entry(id: String, stage: int, stars: int, score: int) -> PlayerRankingSnapshot:
	var result := PlayerRankingSnapshot.new()
	result.player_id = id
	result.highest_stage_completed = stage
	result.story_index = maxi(1, ceili(float(stage) / 30.0))
	result.total_stars = stars
	result.tie_break_score = score
	return result

func run() -> void:
	# A-E progression dominates stars, stars dominate score; coins and achievement count absent.
	assert(RankingComparator.before(entry("a", 50, 100, 0), entry("b", 49, 150, 90000)))
	assert(RankingComparator.before(entry("a", 50, 120, 0), entry("b", 50, 110, 90000)))
	assert(RankingComparator.before(entry("a", 50, 120, 8500), entry("b", 50, 120, 8200)))
	var a := entry("a", 50, 120, 8500)
	var b := entry("b", 50, 120, 8500)
	assert(a.get("coins") == null)
	b.achievement_count = 999
	assert(RankingComparator.tied(a, b))
	var ranked := RankingComparator.sort_entries([b, a])
	assert(ranked[0] == a and ranked[0].rank == 1 and ranked[1].rank == 1)
	b.journey_index = 2
	assert(RankingComparator.before(b, a))
	# Legacy records remain intact and can derive achievements, not historical event counts.
	var legacy := SaveManager._normalize({"version": 2, "profile": {"name": "Hana", "avatar": "aina"}, "coins": 999, "levels": {"1": {"stars": 3, "best_score": 4300}}, "stats": {"levels_won": 8}})
	assert(legacy.coins == 999 and legacy.profile.name == "Hana" and legacy.profile.player_id.length() == 32)
	assert(legacy.levels["1"].stars == 3 and legacy.levels["1"].best_score == 4300 and legacy.stats.orders_served == 0)
	SaveManager.data = legacy
	AchievementManager.refresh()
	assert(AchievementManager.state("first_steps").unlocked and AchievementManager.state("score_3000").unlocked)
	var paid := EconomyManager.coins()
	AchievementManager.refresh()
	assert(EconomyManager.coins() == paid)
	var id: String = SaveManager.data.profile.player_id
	assert(SaveManager.save_game())
	SaveManager.load_game()
	AchievementManager.refresh()
	assert(EconomyManager.coins() == paid and SaveManager.data.profile.player_id == id)
	var snapshot := PlayerRankingSnapshot.current()
	assert(snapshot.highest_stage_completed == 1 and snapshot.tie_break_score == 4300 and snapshot.total_stars == 3)
	SaveManager.data["coins"] = 999999
	SaveManager.data["achievements"]["serve_100"] = {"unlocked": true, "reward_claimed": true}
	var same_rank := PlayerRankingSnapshot.current()
	assert(RankingComparator.tied(snapshot, same_rank)) # D/E: wealth and achievement count do not affect ranking.
	SaveManager.reset()
	AchievementManager.refresh()
	assert(AchievementManager.completed_count() == 0)
	for i in 99:
		GameplayEvents.order_served.emit()
	assert(not AchievementManager.state("serve_100").get("unlocked", false))
	GameplayEvents.order_served.emit()
	assert(AchievementManager.state("serve_100").unlocked)
	GameplayEvents.specials_used.emit(1, false)
	assert(SaveManager.data.stats.special_combos == 0)
	for i in 25:
		GameplayEvents.specials_used.emit(2, true)
	assert(AchievementManager.state("combo_25").unlocked)
	for i in 4:
		GameplayEvents.stage_completed.emit(1, 3, 1000, true)
	assert(not AchievementManager.state("streak_5").get("unlocked", false))
	GameplayEvents.stage_failed.emit(1)
	GameplayEvents.stage_completed.emit(1, 3, 1000, false)
	assert(SaveManager.data.stats.achievement_win_streak == 1)
	assert(AchievementManager.state("no_help").unlocked)
	for i in 4:
		GameplayEvents.stage_completed.emit(1, 3, 1000, true)
	assert(AchievementManager.state("streak_5").unlocked)
	for stage in range(1, 31):
		ProgressionManager.record_win(stage, 3, 5, 3500)
	AchievementManager.refresh()
	assert(AchievementManager.state("perfect_server").unlocked and AchievementManager.state("stars_90").unlocked)
	assert(AchievementManager.state("story_1").unlocked and AchievementManager.state("next_story").unlocked)
	ProgressionManager.record_win(1, 1, 0, 10)
	assert(ProgressionManager.total_stars() == 90)
	var provider := LocalLeaderboardService.new()
	provider.submit_progress(PlayerRankingSnapshot.current())
	assert(provider.get_rankings().size() == 1)
	provider.set_samples(true)
	assert(provider.get_rankings("all").size() >= 25)
	var own := provider.get_player_rank("current_story")
	for competitor in provider.get_rankings("current_story"):
		assert(competitor.story_index == own.story_index)
	for competitor in provider.get_rankings("current_milestone"):
		assert(competitor.story_index == own.story_index and competitor.milestone_index == own.milestone_index)
	assert(own.rank > 1)
	# UI uses a manager signal, so replacing a provider does not leave stale subscriptions.
	RankingManager.set_provider(provider)
	var refreshed := [0]
	RankingManager.updated.connect(func() -> void: refreshed[0] += 1)
	RankingManager.set_provider(LocalLeaderboardService.new())
	assert(refreshed[0] == 1)
	provider.set_samples(false)
	assert(provider.get_rankings().size() == 1 and provider.get_player_rank().rank == 1)
	var screen := AchievementsScreen.new()
	add_child(screen)
	await get_tree().process_frame
	assert(screen._content.get_child_count() > 10)
	screen.get_node("RankingTab").pressed.emit()
	assert(screen._sticky.text.contains("YOUR RANK"))
	assert(screen._options.is_item_disabled(3))
	screen._options.item_selected.emit(2)
	assert(screen._filter == "current_milestone")
	screen.get_node("PersonalTab").pressed.emit()
	assert(not screen._ranking)
	screen._scroll.scroll_vertical = 500
	await get_tree().process_frame
	assert(screen._scroll.scroll_vertical > 0)
	screen.free()
	print("PASS achievements/ranking: A-E comparator, exact ties, events, streak reset, one-time rewards, migration, reload, milestones, profile, filters and local UI")
	get_tree().quit(0)
