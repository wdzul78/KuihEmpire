extends Node

var problems := 0

func check(ok: bool, message: String) -> void:
	if not ok:
		problems += 1
		push_error(message)

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	run.call_deferred()

func run() -> void:
	AudioManager._notification(NOTIFICATION_APPLICATION_FOCUS_IN)
	AudioManager.apply_settings({"music": true, "sfx": true})
	for which in AudioManager.FILE_SFX:
		var stream := AudioManager._streams.get(which) as AudioStreamWAV
		check(stream != null and stream.resource_path.begins_with("res://audio/sfx/"), "file-backed SFX %s" % which)
		if stream == null:
			continue
		check(stream.format == AudioStreamWAV.FORMAT_16_BITS, "SFX uses PCM, not boot synthesis or compressed bytes")
		var peak := 0
		for i in range(0, stream.data.size(), 2):
			peak = maxi(peak, absi(stream.data.decode_s16(i)))
		check(peak > 100 and peak < 20000, "SFX has audible signal and mixing headroom")
		check(stream.get_length() > 0 and stream.get_length() < 2.2, "SFX bounded duration")
	check(AudioManager._match_variants.size() == 4, "four original soft pop variants loaded")
	var last_variant := -1
	for step in range(10):
		var next_voice := AudioManager._next_voice
		AudioManager.play_match(step)
		var played := AudioManager._voices[next_voice]
		check(played.stream is AudioStreamWAV and played.stream.resource_path.contains("/v2/match_"), "match uses cozy variants")
		check(last_variant != AudioManager._last_match_variant, "consecutive clears vary timbre")
		check(is_equal_approx(played.pitch_scale,pow(2.0,float(AudioManager.CASCADE_NOTES[mini(step,7)])/12.0)), "cascade uses ascending musical notes and caps at seven")
		last_variant = AudioManager._last_match_variant
		played.stop()
		played.stream = null
	AudioManager.apply_settings({"music": true, "sfx": false})
	var muted_voice := AudioManager._next_voice
	AudioManager.play_match(3)
	check(muted_voice == AudioManager._next_voice, "new match variants obey SFX mute")
	AudioManager.apply_settings({"music": true, "sfx": true})
	AudioManager.play_music(AudioManager.MENU_MUSIC)
	await get_tree().create_timer(.15).timeout
	var menu_voice := AudioManager._music_player
	var before := menu_voice.get_playback_position()
	AudioManager.play_music(AudioManager.MENU_MUSIC)
	check(AudioManager._music_player == menu_voice, "same theme does not restart or exchange voices")
	await get_tree().create_timer(.12).timeout
	check(menu_voice.get_playback_position() >= before, "same theme continues playing")
	check(menu_voice.stream is AudioStreamOggVorbis and menu_voice.stream.loop, "menu music loops")
	AudioManager.play_music(AudioManager.GAMEPLAY_MUSIC)
	check(AudioManager._music_other == menu_voice, "music transition preserves outgoing player")
	AudioManager.apply_settings({"music": false, "sfx": false})
	check(AudioManager._music_player.stream_paused and AudioManager._music_other.stream_paused, "mute covers both crossfade voices")
	var voice := AudioManager._next_voice
	AudioManager.play(AudioManager.Sfx.CROSS_BLAST)
	check(voice == AudioManager._next_voice, "SFX mute blocks playback")
	AudioManager.apply_settings({"music": true, "sfx": true})
	check(not AudioManager._music_player.stream_paused, "music toggle resumes selected track")
	# Interrupt a transition: its old callback must not stop the new incoming voice.
	AudioManager.play_music(AudioManager.MENU_MUSIC)
	AudioManager.play_music(AudioManager.GAMEPLAY_MUSIC)
	await get_tree().create_timer(AudioManager.MUSIC_FADE + .15).timeout
	check(AudioManager._music_player.playing and not AudioManager._music_other.playing, "rapid transitions settle with exactly one music voice")
	AudioManager.set_music_ducked(true)
	await get_tree().create_timer(.35).timeout
	check(is_equal_approx(AudioManager._music_player.volume_db, -28), "result reduces music beneath jingle")
	AudioManager.set_music_ducked(false)
	await get_tree().create_timer(.35).timeout
	check(is_equal_approx(AudioManager._music_player.volume_db, -20), "return to gameplay restores music level")
	AudioManager._notification(NOTIFICATION_APPLICATION_PAUSED)
	check(AudioManager._music_player.stream_paused, "phone background pauses music")
	voice = AudioManager._next_voice
	AudioManager.play(AudioManager.Sfx.SPATULA)
	check(voice == AudioManager._next_voice, "background blocks SFX")
	AudioManager._notification(NOTIFICATION_APPLICATION_RESUMED)
	check(not AudioManager._music_player.stream_paused, "phone resume restores music")
	var canvas := GameVfx.new()
	add_child(canvas)
	canvas.scoop(Vector2(100,100), 80)
	canvas.shuffle(Rect2(0,0,500,500), 80)
	canvas.delivery(Vector2(60,60),Vector2(400,400),80)
	check(canvas.effects.size() == 4, "scoop, shuffle and delivery have bounded effects")
	await get_tree().create_timer(2.1).timeout
	check(canvas.effects.is_empty() and canvas.particles.is_empty() and not canvas.is_processing(), "power-up effects release themselves")
	canvas.free()
	AudioManager.stop_music()
	for player in AudioManager._voices:
		player.stop()
		player.stream = null
	# Let the audio mixer release its outgoing playback references before exit.
	await get_tree().create_timer(.15).timeout
	print("Audio installation tests: %s (%d problems)" % ["PASS" if problems == 0 else "FAIL", problems])
	get_tree().quit(0 if problems == 0 else 1)
