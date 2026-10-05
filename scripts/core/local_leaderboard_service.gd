class_name LocalLeaderboardService
extends LeaderboardService

var _player: PlayerRankingSnapshot
var _samples: Array[PlayerRankingSnapshot] = []
var samples_enabled := false

func submit_progress(snapshot: PlayerRankingSnapshot) -> void:
	_player = snapshot

func set_samples(enabled: bool) -> void:
	# Never present fictional competitors in a production export.
	samples_enabled = enabled and OS.has_feature("debug")
	_samples.clear()
	if samples_enabled:
		var names := ["Hana", "Amir", "Mei", "Zara", "Sara", "Adam", "Lina", "Nur", "Kai", "Rina", "Dan", "Lily"]
		for i in 24:
			var entry := PlayerRankingSnapshot.new()
			entry.player_id = "sample_%02d" % i
			entry.nickname = names[i % names.size()] + " (sample)"
			entry.is_sample = true
			entry.highest_stage_completed = clampi(_player.highest_stage_completed + 12 - i, 0, 60)
			entry.story_index = maxi(1, ceili(float(entry.highest_stage_completed) / 30.0))
			entry.milestone_index = maxi(1, ceili(float(maxi(1, entry.highest_stage_completed) - (entry.story_index - 1) * 30) / 10.0))
			entry.total_stars = mini(entry.highest_stage_completed * 3, entry.highest_stage_completed * 2 + i % 3)
			entry.tie_break_score = 2000 + i * 100
			_samples.append(entry)
		# Explicit stage/star/score ties, including an exact tie with the player.
		for i in 3:
			var entry := PlayerRankingSnapshot.new()
			entry.player_id = "tie_sample_%d" % i
			entry.nickname = "Tie example %d (sample)" % (i + 1)
			entry.is_sample = true
			entry.story_index = _player.story_index
			entry.milestone_index = _player.milestone_index
			entry.highest_stage_completed = _player.highest_stage_completed
			entry.total_stars = mini(_player.highest_stage_completed * 3, _player.total_stars + (1 if i == 0 else 0))
			entry.tie_break_score = _player.tie_break_score + (100 if i == 1 else 0)
			_samples.append(entry)
	refresh_rankings()

func get_rankings(filter: String = "current_story") -> Array[PlayerRankingSnapshot]:
	var entries: Array[PlayerRankingSnapshot] = []
	if _player == null:
		return entries
	entries.append(_player)
	for entry in _samples:
		if filter == "current_story" and entry.story_index != _player.story_index:
			continue
		if filter == "current_milestone" and (entry.story_index != _player.story_index or entry.milestone_index != _player.milestone_index):
			continue
		entries.append(entry)
	return RankingComparator.sort_entries(entries)

func get_player_rank(filter: String = "current_story") -> PlayerRankingSnapshot:
	get_rankings(filter)
	return _player
