class_name PlayGamesIds
extends RefCounted

## IDs that Google Play Console gives for Kuih Empire's Play Games project.
## An empty ID switches that one feature off; the game keeps working without it.
## The Game ID itself goes in the Android export preset
## (godot_play_game_services/game_id), not here.

## Local achievement id (AchievementDefinition) -> Play Games achievement ID.
const ACHIEVEMENTS := {
	"first_renovation": "CgkI0fz9ztYLEAIQBA",
	"first_steps": "CgkI0fz9ztYLEAIQAw",
	"stars_30": "CgkI0fz9ztYLEAIQBQ",
	"stars_60": "CgkI0fz9ztYLEAIQBg",
	"stars_90": "CgkI0fz9ztYLEAIQBw",
	"stars_120": "CgkI0fz9ztYLEAIQCA",
	"stars_180": "CgkI0fz9ztYLEAIQCQ",
	"perfect_server": "CgkI0fz9ztYLEAIQCg",
	"recipes_10": "CgkI0fz9ztYLEAIQCw",
	"malaysian_kuih_master": "CgkI0fz9ztYLEAIQDA",
	"recipe_master": "CgkI0fz9ztYLEAIQDQ",
	"serve_100": "CgkI0fz9ztYLEAIQDg",
	"combo_25": "CgkI0fz9ztYLEAIQDw",
	"no_help": "CgkI0fz9ztYLEAIQEA",
	"streak_5": "CgkI0fz9ztYLEAIQEQ",
	"story_1": "CgkI0fz9ztYLEAIQEg",
	"next_story": "CgkI0fz9ztYLEAIQEw",
	"story_2": "CgkI0fz9ztYLEAIQFA",
	"score_3000": "CgkI0fz9ztYLEAIQFQ",
	"gerai_2": "CgkI0fz9ztYLEAIQFg",
}

## Leaderboard of total stars earned.
const LEADERBOARD_STARS := "CgkI0fz9ztYLEAIQGA"
## Leaderboard of the furthest stage completed.
const LEADERBOARD_STAGE := "CgkI0fz9ztYLEAIQFw"

static func achievement(local_id: String) -> String:
	return str(ACHIEVEMENTS.get(local_id, ""))

static func has_leaderboards() -> bool:
	return not LEADERBOARD_STARS.is_empty() or not LEADERBOARD_STAGE.is_empty()
