class_name RankingComparator
extends RefCounted

static func before(a: PlayerRankingSnapshot, b: PlayerRankingSnapshot) -> bool:
	for key in ["journey_index", "story_index", "highest_stage_completed", "total_stars", "tie_break_score"]:
		if a.get(key) != b.get(key):
			return a.get(key) > b.get(key)
	# Stable display order for equal metrics; identical positions receive the same rank.
	return a.player_id < b.player_id

static func tied(a: PlayerRankingSnapshot, b: PlayerRankingSnapshot) -> bool:
	for key in ["journey_index", "story_index", "highest_stage_completed", "total_stars", "tie_break_score"]:
		if a.get(key) != b.get(key):
			return false
	return true

static func sort_entries(entries: Array[PlayerRankingSnapshot]) -> Array[PlayerRankingSnapshot]:
	var sorted := entries.duplicate()
	sorted.sort_custom(before)
	for i in sorted.size():
		sorted[i].rank = sorted[i - 1].rank if i > 0 and tied(sorted[i], sorted[i - 1]) else i + 1
	return sorted
