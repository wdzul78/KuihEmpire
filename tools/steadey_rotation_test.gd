extends Node

func _ready() -> void:
	AudioManager._suspended = false
	AudioManager.sfx_enabled = true
	AudioManager._steadey_voice_index = 0
	for index in [0,1,0]:
		AudioManager.reset_combo_voice(true)
		AudioManager.play_combo(5,31)
		AudioManager._combo_timer.stop()
		AudioManager._play_pending_combo()
		assert(AudioManager._combo_voice.stream == load(AudioManager.STEADEY_VOICES[index]))
		assert(AudioManager._combo_voice.playing)
		assert(AudioManager.combo_duration(5) >= AudioManager._combo_voice.stream.get_length())
	AudioManager.reset_combo_voice(true)
	# Another praise tier must not consume a Steadey rotation slot.
	AudioManager.play_combo(1,7)
	AudioManager._combo_timer.stop()
	AudioManager._play_pending_combo()
	assert(AudioManager._steadey_voice_index == 1)
	assert(AudioManager._combo_voice.stream == load(AudioManager.BAGUS_VOICES[0]))
	AudioManager.reset_combo_voice(true)
	AudioManager.sfx_enabled = false
	AudioManager.play_combo(5,31)
	assert(AudioManager._steadey_voice_index == 1 and AudioManager._combo_pending == 0)
	AudioManager.sfx_enabled = true
	AudioManager.stop_music()
	print("Steadey rotation: PASS (alternation, caption duration, independent tiers, mute)")
	get_tree().quit()
