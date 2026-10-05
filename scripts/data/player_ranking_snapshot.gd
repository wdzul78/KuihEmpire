class_name PlayerRankingSnapshot
extends RefCounted

var player_id := ""
var nickname := "Player"
var avatar_id := "aina"
var title := "Kuih Maker"
var journey_index := 1
var story_index := 1
var milestone_index := 1
var highest_stage_completed := 0
var total_stars := 0
var tie_break_score := 0
var total_orders_served := 0
var recipes_unlocked := 0
var achievement_count := 0
var rank := 0
var is_sample := false
var timestamp := 0
var game_version := ""
var progression_version := 1

static func current() -> PlayerRankingSnapshot:
	var result := PlayerRankingSnapshot.new()
	var profile: Dictionary = SaveManager.data["profile"]
	result.player_id = profile["player_id"]
	result.nickname = profile["name"]
	result.avatar_id = profile["avatar"]
	result.title = str(profile.get("title_id", "Kuih Maker"))
	result.highest_stage_completed = ProgressionManager.highest_cleared()
	# Derive completed position, not the next unlocked story/stage.
	result.story_index = maxi(1, ceili(float(result.highest_stage_completed) / 30.0))
	result.milestone_index = maxi(1, ceili(float(maxi(1, result.highest_stage_completed) - (result.story_index - 1) * 30) / 10.0))
	for id in range(1, result.highest_stage_completed + 1):
		result.total_stars += ProgressionManager.stars_for(id)
	# Relevant score belongs to the furthest completed stage; lifetime grinding has no metric.
	result.tie_break_score = ProgressionManager.best_score(result.highest_stage_completed)
	result.total_orders_served = int(SaveManager.data["stats"].get("orders_served", 0))
	result.recipes_unlocked = int(AchievementManager.metrics().get("recipes", 0))
	result.achievement_count = AchievementManager.completed_count()
	result.timestamp = int(Time.get_unix_time_from_system())
	result.game_version = ProjectSettings.get_setting("application/config/version", "")
	return result
