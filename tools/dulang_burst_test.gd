extends Node

func _ready() -> void:
	SaveManager.save_path = "user://kuih_dulang_burst_test.json"
	SaveManager.reset()
	run.call_deferred()

func shot(name_text: String) -> void:
	if DisplayServer.get_name() == "headless":
		return
	await RenderingServer.frame_post_draw
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://.shots"))
	get_viewport().get_texture().get_image().save_png("res://.shots/dulang_"+name_text+".png")

func run() -> void:
	var screen := LevelController.new()
	screen.tutorial_index = 5
	add_child(screen)
	screen.coach.index = 3
	screen.coach._show_step()
	var board := screen.board
	board.clear_hints()
	var center := Vector2i(2,2)
	board.logic.get_cell(center).special = BoardCell.Special.DULANG
	board._refresh_tiles()
	await get_tree().process_frame
	await shot("idle")
	var tile: TileView = board._tiles[center]
	assert(tile._special_idle_tween.is_valid() and tile.icon.scale == Vector2.ONE)
	var before := board.position
	var result := board.logic.activate_specials([center])
	assert(result.cleared.size() == 9)
	board._play_step(result,0)
	await get_tree().create_timer(.09).timeout
	assert(board._vfx.effects.any(func(e: Dictionary) -> bool: return e.kind == "charge"))
	await shot("charge")
	# Follow animation frames: a GPU screenshot can take several frames.
	var deadline := Time.get_ticks_msec()+2000
	while not board._vfx.effects.any(func(e: Dictionary) -> bool: return e.kind == "flower_wave") and Time.get_ticks_msec()<deadline:
		await get_tree().process_frame
	assert(board._vfx.effects.any(func(e: Dictionary) -> bool: return e.kind == "flower_wave"))
	var gold_slots := board._vfx.effects.filter(func(e: Dictionary) -> bool: return e.kind == "gold_slot")
	assert(gold_slots.size() == 9)
	for y in range(1,4):
		for x in range(1,4):
			var target := board._cell_center(Vector2i(x,y))
			assert(gold_slots.any(func(e: Dictionary) -> bool: return e.b.is_equal_approx(target)))
	await get_tree().create_timer(.12).timeout
	await shot("sweet_burst")
	await get_tree().create_timer(.16).timeout
	await shot("gold_slots")
	await get_tree().create_timer(.8).timeout
	assert(board.position.is_equal_approx(before))
	assert(board._vfx.effects.is_empty())
	# A corner only lights the four in-bounds slots, never off-board cells.
	board._vfx.reset()
	var corner := Vector2i.ZERO
	var corner_points := PackedVector2Array()
	for y in 2:
		for x in 2:
			corner_points.append(board._cell_center(Vector2i(x,y)))
	board._vfx.dulang_burst(board._cell_center(corner), corner_points, board.cell_size)
	assert(board._vfx.effects.filter(func(e: Dictionary) -> bool: return e.kind == "gold_slot").size() == 4)
	board._vfx.reset()
	board.build(TutorialLibrary.get_stage(5))
	board._burst_shake()
	await get_tree().create_timer(.02).timeout
	board.build(TutorialLibrary.get_stage(5))
	assert(board.position.is_equal_approx(before))
	await board.booster_tray(center)
	await get_tree().create_timer(.8).timeout
	assert(board.position.is_equal_approx(before))
	screen.free()
	AudioManager.stop_music()
	for player in AudioManager._voices:
		player.stop()
		player.stream = null
	await get_tree().create_timer(.15).timeout
	print("Golden Dulang: PASS (charge before burst, nine gold slots, corner clipping, stable wiggle, booster, shake reset and cleanup)")
	get_tree().quit()
