extends Node

var finished := false

func _ready() -> void:
	run.call_deferred()

func play(view: MatchBoard, result: BoardState.ClearResult) -> void:
	await view._play_step(result,0)
	finished = true

func run() -> void:
	SaveManager.save_path = "user://ketupat_test.json"
	SaveManager.reset()
	for origin in [Vector2i(3,3),Vector2i.ZERO,Vector2i(6,6),Vector2i(0,3)]:
		var state := BoardState.new()
		state.setup(7,7,KuihLibrary.starter_set(),83)
		var result := state.clear_booster(origin,&"cross")
		assert(result.combo == &"booster_cross")
		for y in 7:
			for x in 7:
				var pos := Vector2i(x,y)
				assert(result.combo_cells.has(pos) == (absi(x-origin.x) <= 1 or absi(y-origin.y) <= 1))
		assert(result.cleared.size() == result.combo_cells.size())
	var view := MatchBoard.new()
	view.size = Vector2(560,560)
	add_child(view)
	var level := LevelDefinition.new()
	level.width = 7
	level.height = 7
	level.kuih = KuihLibrary.starter_set()
	view.build(level)
	var origin := Vector2i(3,3)
	var result := view.logic.clear_booster(origin,&"cross")
	play(view,result)
	assert(view._special_text.has_node("KetupatRayaGraphic"))
	assert(view._vfx.effects.any(func(e): return e.kind == "ketupat_appear"))
	var foreground: TextureRect = view._vfx.get_node("KetupatForeground")
	assert(foreground.z_index+view._vfx.z_index > view._special_text.z_index)
	assert(foreground.size.x >= view.cell_size*4.0,"Ketupat drops in larger than its final 3x3 size")
	await view._wait(.40)
	assert(is_instance_valid(foreground) and foreground.visible)
	assert(foreground.texture == GameVfx.KETUPAT_ART,"Full Ketupat including upper leaf stems stays visible during extended shake")
	assert(not view._vfx.effects.any(func(e): return e.kind == "ketupat_lane"))
	assert(not view._tiles[origin].visible)
	assert(view._tiles[Vector2i(3,0)].visible)
	while not view._vfx.effects.any(func(e): return e.kind == "ketupat_lane"):
		await get_tree().process_frame
	assert(view._vfx.effects.filter(func(e): return e.kind == "ketupat_lane").size() == 6)
	assert(view._tiles[Vector2i(3,0)].visible,"Far item waits for leaf arrival")
	await view._wait(GameVfx.KETUPAT_TRAVEL+.025)
	for pos in result.combo_cells:
		assert(not view._tiles[pos].visible,"Every cross item clears with the leaf sweep")
	assert(view._tiles[Vector2i.ZERO].visible,"Outside cross stays intact")
	while not finished:
		await get_tree().process_frame
	view.queue_free()
	await get_tree().process_frame
	AudioManager.stop_music()
	print("Ketupat Raya: PASS (3 rows + 3 columns, edge clipping, appearance, title, six leaf lanes, progressive clearing, outside cells retained)")
	get_tree().quit()
