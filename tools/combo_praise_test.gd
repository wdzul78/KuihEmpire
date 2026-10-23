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
	check(not board._combo_praise.visible,"first match does not trigger combo praise")
	for count in [7,13,19,25,31]:
		AudioManager.reset_combo_voice(true)
		board._combo_praise.show_combo(count,board.size)
		await get_tree().create_timer(.20).timeout
		var praise := board._combo_praise
		check(praise.visible and praise._graphic.accessibility_name == ComboPraise.WORDS[count],"correct cascade milestone graphic")
		check(praise.mouse_filter == Control.MOUSE_FILTER_IGNORE,"praise cannot block board input")
		check(praise._graphic.texture is AtlasTexture and praise._graphic.texture.atlas == ComboPraise.ART[count],"each threshold shows the original stylized artwork")
		check(praise._graphic.stretch_mode == TextureRect.STRETCH_KEEP_ASPECT_CENTERED,"artwork preserves aspect ratio")
		check(praise._graphic.texture.atlas.get_image().get_pixel(0,0).a == 0,"artwork preserves transparency")
		check(praise.size.x <= board.size.x,"caption fits board")
		var audio: AudioStream = load(AudioManager.COMBO_VOICES[ComboPraise.VOICE_TIERS[count]])
		check(AudioManager._combo_voice.playing and AudioManager._combo_voice.stream == audio,"each milestone plays its matching supplied voice")
	board._combo_praise.reset()
	for count in [0,1,2,3,4,5,6]:
		board._combo_praise.show_combo(count,board.size)
		check(not board._combo_praise.visible,"non-milestone does not trigger praise")
	board._combo_praise.show_combo(31,board.size)
	await get_tree().create_timer(AudioManager.combo_duration(5)+.5).timeout
	check(not board._combo_praise.visible,"praise cleans up after animation")
	board._combo_praise.show_combo(31,board.size)
	check(not board._combo_praise.visible,"top milestone cannot repeat within a move")
	board._combo_praise.reset()
	board._combo_praise.show_combo(7,board.size)
	check(board._combo_praise.accessibility_name == "Bagus!", "next move resets praise hierarchy")
	board._combo_praise.reset()
	board._combo_praise.show_combo(35,board.size)
	check(board._combo_praise._last_milestone == 31 and board._combo_praise.accessibility_name == "Steadey Bos!!!", "large burst skips directly to highest tier")
	board._combo_praise.reset()
	board._move_clear_count = 0
	board._record_praise_clear(clear_items(3))
	check(not board._combo_praise.visible, "three kuih do not trigger praise")
	board._record_praise_clear(clear_items(4))
	check(board._move_clear_count == 7 and board._combo_praise.accessibility_name == "Bagus!", "cascade accumulates newly refilled kuih at the same cells")
	board._record_praise_clear(clear_items(4))
	check(board._move_clear_count == 11 and board._combo_praise.accessibility_name == "Bagus!", "eleven kuih remain below second tier")
	board._record_praise_clear(clear_items(2))
	check(board._move_clear_count == 13 and board._combo_praise.accessibility_name == "Sedapnyaaa!", "cumulative item threshold")
	var empty_hit := BoardState.ClearResult.new()
	empty_hit.cleared[Vector2i.ZERO] = BoardState.ClearInfo.new()
	board._record_praise_clear(empty_hit)
	check(board._move_clear_count == 13, "blocker/empty hits do not count as kuih")
	for voice in AudioManager._voices:
		voice.stop()
	AudioManager.sfx_enabled = false
	AudioManager.reset_combo_voice(true)
	AudioManager.play_combo(5)
	check(not AudioManager._combo_voice.playing and AudioManager._combo_pending == 0,"praise sound respects mute")
	AudioManager.sfx_enabled = true
	AudioManager.reset_combo_voice(true)
	board._combo_praise.reset()
	board.free()
	AudioManager.stop_music()
	print("Combo praise tests: %s (%d problems)" % ["PASS" if problems == 0 else "FAIL",problems])
	get_tree().quit(0 if problems == 0 else 1)

func clear_items(count: int) -> BoardState.ClearResult:
	var cleared := BoardState.ClearResult.new()
	for index in count:
		var info := BoardState.ClearInfo.new()
		info.kuih = KuihLibrary.get_kuih(&"onde_onde")
		cleared.cleared[Vector2i(index,0)] = info
	return cleared
