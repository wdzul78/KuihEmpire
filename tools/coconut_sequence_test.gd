extends Node

var done := false

func _ready() -> void:
	run.call_deferred()

func shot(label: String) -> void:
	if DisplayServer.get_name() == "headless":
		return
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://.shots/coconut_"+label+".png")

func play(board: MatchBoard, result: BoardState.ClearResult) -> void:
	done = false
	await board._play_step(result,0)
	done = true

func run() -> void:
	SaveManager.save_path = "user://coconut_sequence_test.json"
	for combo in [false,true]:
		var screen := LevelController.new()
		screen.level_id = 20
		add_child(screen)
		await get_tree().create_timer(.3).timeout
		screen.story.hide()
		var board := screen.board
		var origin := Vector2i(3,3)
		var other := Vector2i(4,3)
		board.logic.get_cell(origin).special = BoardCell.Special.DULANG
		if combo:
			board.logic.get_cell(other).special = BoardCell.Special.DULANG
		board._refresh_tiles()
		var result := board.logic.activate_specials([origin,other] if combo else [origin])
		assert((result.combo == &"rounded_dulang") == combo)
		play(board,result)
		await get_tree().create_timer(.33 if combo else .08).timeout
		var vocal: AudioStream = AudioManager._streams.get(AudioManager.Sfx.PUTERI_VOCAL)
		assert(vocal != null)
		var singing := AudioManager._voices.any(func(voice): return voice.playing and voice.stream == vocal)
		assert(singing == combo)
		await shot("puteri_charge" if combo else "badak_charge")
		var frames := 0
		while not board._vfx.effects.any(func(e): return e.kind == "coconut_burst") and frames < 120:
			await get_tree().process_frame
			frames += 1
		assert(frames < 120)
		var effect: Dictionary = board._vfx.effects.filter(func(e): return e.kind == "coconut_burst")[0]
		assert(effect.double_blast == combo)
		var expected := PackedVector2Array()
		for pos in (result.combo_cells if combo else result.activated[0].cells):
			expected.append(board._cell_center(pos))
		assert(effect.points == expected)
		await get_tree().create_timer(.18).timeout
		await shot("puteri_impact" if combo else "badak_impact")
		while not done:
			await get_tree().process_frame
		await get_tree().create_timer(1.0).timeout
		assert(board._vfx.effects.is_empty())
		screen.queue_free()
		await get_tree().process_frame
	AudioManager.stop_music()
	for voice in AudioManager._voices:
		voice.stop()
		voice.stream = null
	await get_tree().process_frame
	print("Coconut sequence: PASS (single, double combo, exact coverage and cleanup)")
	get_tree().quit()
