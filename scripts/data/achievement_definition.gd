class_name AchievementDefinition
extends RefCounted

var id: String
var title: String
var description: String
var category: String
var tier: String
var target: int
var reward_coins: int
var progress_type: String
var icon := "★"
var hidden := false

func _init(key: String, label: String, detail: String, group: String, metric: String, goal: int, coins: int = 25, rank_tier: String = "") -> void:
	id = key
	title = label
	description = detail
	category = group
	progress_type = metric
	target = goal
	reward_coins = coins
	tier = rank_tier

static func all() -> Array[AchievementDefinition]:
	return [
		AchievementDefinition.new("first_renovation", "First Renovation", "Buy your first structural stall upgrade.", "GERAI", "structural_upgrades", 1),
		AchievementDefinition.new("first_steps", "First Steps", "Complete your first stage.", "JOURNEY", "stages", 1),
		AchievementDefinition.new("stars_30", "Star Collector I", "Earn 30 permanent stars.", "STARS", "stars", 30, 50, "BRONZE"),
		AchievementDefinition.new("stars_60", "Star Collector II", "Earn 60 permanent stars.", "STARS", "stars", 60, 75, "SILVER"),
		AchievementDefinition.new("stars_90", "Star Collector III", "Earn 90 permanent stars.", "STARS", "stars", 90, 100, "GOLD"),
		AchievementDefinition.new("perfect_server", "Perfect Server", "Earn three stars on 10 different stages.", "PUZZLE", "perfect", 10, 75),
		AchievementDefinition.new("recipes_10", "Kuih Explorer", "Discover 10 recipes.", "RECIPES", "recipes", 10, 75, "BRONZE"),
		AchievementDefinition.new("recipe_master", "Kuih Master", "Discover the complete recipe book.", "RECIPES", "recipes", KuihLibrary.count(), 100, "MASTER"),
		AchievementDefinition.new("serve_100", "Busy Gerai", "Serve 100 customer orders.", "ORDERS", "orders_served", 100, 100),
		AchievementDefinition.new("combo_25", "Combo Cook", "Activate 25 special combinations.", "SPECIALS", "special_combos", 25, 75),
		AchievementDefinition.new("no_help", "No Help Needed", "Win a stage without using a booster.", "PUZZLE", "unassisted_wins", 1),
		AchievementDefinition.new("streak_5", "Sweet Streak", "Win five stages consecutively.", "STREAK", "best_win_streak", 5, 50),
		AchievementDefinition.new("story_1", "Gerai Keluarga Complete", "Complete all 30 stages of the family stall.", "JOURNEY", "stories", 1, 100),
		AchievementDefinition.new("next_story", "Journey Continues", "Unlock the school canteen story.", "JOURNEY", "next_story", 1, 50),
		AchievementDefinition.new("score_3000", "Sweet Score", "Reach a best stage score of 3,000.", "SCORE", "best_score", 3000, 50),
		AchievementDefinition.new("gerai_2", "Growing Gerai", "Upgrade your stall to level two.", "GERAI", "gerai", 2, 50),
	]
