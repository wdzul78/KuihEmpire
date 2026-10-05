class_name LeaderboardService
extends RefCounted

## Future remote providers implement this contract and emit refreshed when ready.
signal refreshed()
func get_rankings(_filter: String = "current_story") -> Array[PlayerRankingSnapshot]:
	return []
func get_player_rank(_filter: String = "current_story") -> PlayerRankingSnapshot:
	return null
func submit_progress(_snapshot: PlayerRankingSnapshot) -> void:
	pass
func refresh_rankings() -> void:
	refreshed.emit()
