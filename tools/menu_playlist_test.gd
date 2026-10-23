extends Node

func _ready() -> void:
	AudioManager._suspended = false
	AudioManager.music_enabled = true
	AudioManager._menu_track_index = 0
	AudioManager.play_music(AudioManager.MENU_MUSIC)
	assert(AudioManager.MENU_PLAYLIST.size() == 4)
	for index in 5:
		var expected: String = AudioManager.MENU_PLAYLIST[index % 4]
		assert(AudioManager._music_path == expected)
		assert(AudioManager._music_player.stream.get_length() > 0.0)
		assert(not AudioManager._music_player.stream.loop)
		var current: AudioStreamPlayer = AudioManager._music_player
		AudioManager.play_music(AudioManager.MENU_MUSIC)
		assert(AudioManager._music_player == current)
		AudioManager._on_music_finished(current)
	AudioManager.stop_music()
	print("Menu playlist: PASS (primary, second, two previous tracks, wrap, navigation continuity)")
	get_tree().quit()
