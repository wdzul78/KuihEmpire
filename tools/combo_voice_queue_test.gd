extends Node

func _ready() -> void:
	AudioManager.sfx_enabled = true
	AudioManager.reset_combo_voice(true)
	AudioManager.play_combo(2)
	AudioManager.play_combo(3)
	AudioManager.play_combo(4)
	await get_tree().create_timer(.20).timeout
	assert(AudioManager._combo_voice.stream.resource_path == AudioManager.COMBO_VOICES[4])
	AudioManager.reset_combo_voice(true)
	AudioManager.play_combo(2)
	await get_tree().create_timer(.20).timeout
	var current := AudioManager._combo_voice.stream
	AudioManager.play_combo(3)
	AudioManager.play_combo(4)
	await get_tree().create_timer(.20).timeout
	assert(AudioManager._combo_voice.stream == current and AudioManager._combo_voice.playing)
	assert(AudioManager._combo_pending == 4)
	# Fixed-fps tests advance simulation faster than the audio device clock.
	AudioManager._combo_voice.stop()
	AudioManager._combo_voice.finished.emit()
	await get_tree().create_timer(.20).timeout
	assert(AudioManager._combo_voice.stream.resource_path == AudioManager.COMBO_VOICES[4])
	AudioManager.play_combo(5)
	AudioManager.reset_combo_voice()
	assert(AudioManager._combo_pending == 0)
	AudioManager.reset_combo_voice(true)
	AudioManager.play_combo(3, 12) # Sedapnya at twelve cleared kuih.
	AudioManager.play_combo(2, 18) # Terbaik at eighteen outranks voice ID 3.
	await get_tree().create_timer(.20).timeout
	assert(AudioManager._combo_voice.stream.resource_path == AudioManager.COMBO_VOICES[2])
	AudioManager.reset_combo_voice(true)
	AudioManager.apply_settings({"sfx":false})
	assert(not AudioManager._combo_voice.playing)
	assert(AudioManager._combo_pending == 0)
	print("Combo voice queue: PASS (latest milestone, no interruption, skip 3, new-move reset, mute)")
	get_tree().quit()
