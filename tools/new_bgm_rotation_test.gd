extends Node

func _ready() -> void:
	AudioManager.apply_settings({"music":true,"sfx":false})
	assert(AudioManager.GAMEPLAY_PLAYLIST.size() == 20)
	for index in 5:
		AudioManager.start_puzzle_music()
		var expected := "res://audio/music/gameplay_v3/gameplay_%02d.ogg" % (index+1) if index < 4 else "res://audio/music/gameplay_v2/gameplay_01.ogg"
		assert(AudioManager._music_player.stream.resource_path == expected)
		assert(AudioManager._music_player.stream.get_length() > 1)
	AudioManager.stop_music()
	print("New BGM rotation: PASS (001-004 first, then previous playlist; 20 tracks)")
	get_tree().quit()
