extends Node

func _ready() -> void:
	SaveManager.save_path = "user://audio_volume_test.json"
	var screen := SettingsScreen.new()
	add_child(screen)
	var bgm := screen.find_child("Volume_music_volume", true, false) as HSlider
	var sfx := screen.find_child("Volume_sfx_volume", true, false) as HSlider
	assert(bgm != null and sfx != null)
	bgm.value = 35
	sfx.value = 70
	var music_bus := AudioServer.get_bus_index(&"BGM")
	var sfx_bus := AudioServer.get_bus_index(&"SFX")
	assert(is_equal_approx(db_to_linear(AudioServer.get_bus_volume_db(music_bus)), 0.35))
	assert(is_equal_approx(db_to_linear(AudioServer.get_bus_volume_db(sfx_bus)), 0.70))
	AudioManager.play_music(AudioManager.MENU_MUSIC)
	assert(AudioManager._music_player.bus == &"BGM" and AudioManager._music_other.bus == &"BGM")
	for voice in AudioManager._voices:
		assert(voice.bus == &"SFX")
	bgm.value = 0
	assert(AudioServer.is_bus_mute(music_bus))
	assert(not AudioServer.is_bus_mute(sfx_bus))
	bgm.value = 35
	GameManager.set_setting("music", false)
	assert(AudioServer.is_bus_mute(music_bus))
	GameManager.set_setting("music", true)
	assert(not AudioServer.is_bus_mute(music_bus))
	assert(is_equal_approx(db_to_linear(AudioServer.get_bus_volume_db(music_bus)), 0.35))
	SaveManager.save_game()
	SaveManager.load_game()
	assert(is_equal_approx(float(SaveManager.get_setting("music_volume")), 0.35))
	assert(is_equal_approx(float(SaveManager.get_setting("sfx_volume")), 0.70))
	screen.free()
	print("Audio volume: PASS (independent sliders, buses, zero/mute, saved values)")
	get_tree().quit()
