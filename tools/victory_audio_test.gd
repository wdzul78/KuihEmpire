extends Node

func _ready() -> void:
	AudioManager._suspended = false
	AudioManager.sfx_enabled = true
	AudioManager._victory_track_index = 0
	for index in [0, 1, 0]:
		var voice_index: int = AudioManager._next_voice
		AudioManager.play(AudioManager.Sfx.SUCCESS, 1.0, -3.0)
		var player: AudioStreamPlayer = AudioManager._voices[voice_index]
		assert(player.stream == load(AudioManager.VICTORY_TRACKS[index]))
		assert(player.playing and player.pitch_scale == 1.0)
		assert(player.stream.get_length() > 0.0)
		player.stop()
	assert(AudioManager._victory_track_index == 1)
	AudioManager.sfx_enabled = false
	AudioManager.play(AudioManager.Sfx.SUCCESS)
	assert(AudioManager._victory_track_index == 1)
	AudioManager.sfx_enabled = true
	AudioManager.stop_music()
	print("Victory audio: PASS (win01/win02 alternation, original pitch, mute)")
	get_tree().quit()
