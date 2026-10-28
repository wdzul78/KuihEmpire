extends Node

func _ready() -> void:
	AudioManager._suspended = false
	AudioManager.sfx_enabled = true
	AudioManager.music_enabled = true
	AudioManager._victory_track_index = 0
	AudioManager.play_music(AudioManager.GAMEPLAY_MUSIC)
	await get_tree().create_timer(AudioManager.MUSIC_FADE + .1).timeout
	for index in [0, 1, 0]:
		AudioManager.play_result_jingle(true)
		var player: AudioStreamPlayer = AudioManager._jingle
		assert(player.stream == load(AudioManager.VICTORY_TRACKS[index]))
		assert(player.playing and player.pitch_scale == 1.0)
		assert(player.stream.get_length() > 0.0)
		player.stop()
	assert(AudioManager._victory_track_index == 1)
	# The jingle replaces the soundtrack: BGM fades out and pauses underneath.
	await get_tree().create_timer(AudioManager.RESULT_HOLD_FADE + .1).timeout
	assert(AudioManager._music_held and AudioManager._music_player.stream_paused)
	assert(AudioManager._music_player.volume_db <= -59.0)
	# Leaving the result resumes the same track at the gameplay level.
	AudioManager.set_music_ducked(false)
	assert(not AudioManager._music_held and not AudioManager._music_player.stream_paused)
	await get_tree().create_timer(AudioManager.RESULT_RESUME_FADE + .1).timeout
	assert(is_equal_approx(AudioManager._music_player.volume_db, AudioManager.GAMEPLAY_MUSIC_GAIN))
	# Starting a scene while held stops the jingle and resumes music.
	AudioManager.play_result_jingle(false)
	AudioManager.play_music(AudioManager.GAMEPLAY_MUSIC)
	assert(not AudioManager._music_held)
	await get_tree().create_timer(.4).timeout
	assert(not AudioManager._jingle.playing)
	AudioManager.sfx_enabled = false
	AudioManager.play_result_jingle(true)
	assert(AudioManager._victory_track_index == 1)
	AudioManager.sfx_enabled = true
	AudioManager.stop_music()
	print("Victory audio: PASS (win01/win02 alternation, BGM hold and resume, mute)")
	get_tree().quit()
