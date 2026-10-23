extends Node

func _ready() -> void:
	AudioManager._suspended = false
	AudioManager._gameplay_track_index = 0
	AudioManager._gameplay_puzzle_started = false
	assert(AudioManager.GAMEPLAY_PLAYLIST.size() == 16)
	# Scene transitions may request gameplay music before the puzzle starts.
	AudioManager.play_music(AudioManager.GAMEPLAY_MUSIC)
	for index in 17:
		AudioManager.start_puzzle_music()
		var expected: String = AudioManager.GAMEPLAY_PLAYLIST[index % 16]
		assert(AudioManager._music_path == expected)
		assert(AudioManager._music_player.stream.get_length() > 0.0)
		assert(not AudioManager._music_player.stream.loop)
		var current: AudioStreamPlayer = AudioManager._music_player
		AudioManager.play_music(AudioManager.GAMEPLAY_MUSIC)
		assert(AudioManager._music_player == current)
	AudioManager._on_music_finished(AudioManager._music_player)
	assert(AudioManager._music_path == AudioManager.GAMEPLAY_PLAYLIST[1])
	AudioManager.play_music(AudioManager.MENU_MUSIC)
	AudioManager.play_music(AudioManager.GAMEPLAY_MUSIC)
	AudioManager.start_puzzle_music()
	assert(AudioManager._music_path == AudioManager.GAMEPLAY_PLAYLIST[2])
	AudioManager.stop_music()
	print("Gameplay playlist: PASS (eight priority tracks, eight old tracks, puzzle rotation, wrap, song end, menu return)")
	get_tree().quit()
