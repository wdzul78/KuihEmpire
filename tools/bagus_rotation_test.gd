extends Node

func _ready() -> void:
	AudioManager._suspended = false
	AudioManager.sfx_enabled = true
	AudioManager._bagus_voice_index = 0
	for index in [0,1,0]:
		AudioManager.reset_combo_voice(true)
		AudioManager.play_combo(1,7)
		AudioManager._combo_timer.stop()
		AudioManager._play_pending_combo()
		assert(AudioManager._combo_voice.stream == load(AudioManager.BAGUS_VOICES[index]))
		assert(AudioManager._combo_voice.playing)
		assert(AudioManager.combo_duration(1) >= AudioManager._combo_voice.stream.get_length())
	AudioManager.reset_combo_voice(true)
	# A superseded Bagus milestone must not consume a rotation slot.
	AudioManager.play_combo(1,7)
	AudioManager.play_combo(3,13)
	AudioManager._combo_timer.stop()
	AudioManager._play_pending_combo()
	assert(AudioManager._bagus_voice_index == 1)
	assert(AudioManager._combo_voice.stream == load(AudioManager.COMBO_VOICES[3]))
	AudioManager.reset_combo_voice(true)
	AudioManager.sfx_enabled = false
	AudioManager.play_combo(1,7)
	assert(AudioManager._bagus_voice_index == 1 and AudioManager._combo_pending == 0)
	AudioManager.sfx_enabled = true
	AudioManager.stop_music()
	print("Bagus rotation: PASS (alternation, caption duration, superseded praise, mute)")
	get_tree().quit()
