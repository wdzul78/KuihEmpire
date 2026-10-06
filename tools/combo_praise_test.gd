extends Node

var problems := 0

func check(ok: bool, message: String) -> void:
	if not ok:
		problems += 1
		push_error(message)

func _ready() -> void:
	run.call_deferred()

func run() -> void:
	var board := MatchBoard.new()
	board.size = Vector2(400,400)
	add_child(board)
	board.build(TutorialLibrary.get_stage(8))
	board.show_score_feedback(30,0)
	check(not board._combo_praise.visible,"first match does not trigger praise")
	board.show_score_feedback(30,1)
	check(not board._combo_praise.visible,"second match does not trigger praise")
	for count in [3,4,5]:
		board.show_score_feedback(50,count-1)
		var praise := board._combo_praise
		check(praise.visible and praise._graphic.accessibility_name == ComboPraise.WORDS[count],"correct cascade milestone graphic")
		check(praise.mouse_filter == Control.MOUSE_FILTER_IGNORE,"praise cannot block board input")
		check(praise._graphic.texture is AtlasTexture and praise._graphic.texture.atlas == ComboPraise.ART[count],"each milestone uses its generated PNG")
		check(praise._graphic.stretch_mode == TextureRect.STRETCH_KEEP_ASPECT_CENTERED and praise.size.x <= board.size.x,"graphic fits board without distortion")
		check(praise._graphic.texture.atlas.get_image().get_pixel(0,0).a == 0,"asset preserves transparent background")
		var audio := SfxSynth.combo(count)
		check(audio.data.size() > 20000 and audio.format == AudioStreamWAV.FORMAT_16_BITS,"each milestone has original PCM audio")
	board._combo_praise.reset()
	board.show_score_feedback(50,5)
	check(not board._combo_praise.visible,"sixth combo does not repeat fifth milestone")
	board.show_score_feedback(50,4)
	await get_tree().create_timer(1.2).timeout
	check(not board._combo_praise.visible,"praise cleans up after animation")
	for voice in AudioManager._voices:
		voice.stop()
	AudioManager.sfx_enabled = false
	AudioManager.play_combo(5)
	check(not AudioManager._voices.any(func(voice): return voice.playing),"praise sound respects mute")
	AudioManager.sfx_enabled = true
	board.free()
	AudioManager.stop_music()
	print("Combo praise tests: %s (%d problems)" % ["PASS" if problems == 0 else "FAIL",problems])
	get_tree().quit(0 if problems == 0 else 1)
