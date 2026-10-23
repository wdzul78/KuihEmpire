extends Node

func _ready() -> void:
	run.call_deferred()

func run() -> void:
	SaveManager.save_path = "user://selorot_test.json"
	SaveManager.reset()
	assert(BoardArt.special_texture(BoardCell.Special.TAPAU_VERTICAL) == BoardArt.TAPAU_VERTICAL_ART)
	assert(BoardArt.TAPAU_VERTICAL_ART.resource_path.contains("selorot_v3_pale"))
	assert(BoardArt.special_texture(PowerupRecipes.PISANG_COMBO) == BoardArt.PISANG_ART)
	assert(PowerupRecipes.ENTRIES.size() == 6)
	PowerupRecipes.introduce(BoardCell.Special.TAPAU_VERTICAL)
	PowerupRecipes.sync_seen_kuih()
	assert(ProgressionManager.is_recipe_unlocked(PowerupRecipes.key(PowerupRecipes.PISANG_COMBO)))
	for x in [0,3,6]:
		for reverse in [false,true]:
			var board := BoardState.new()
			board.setup(7,7,KuihLibrary.starter_set(),83)
			var a := Vector2i(x,3)
			var b := a+Vector2i.RIGHT if x < 6 else a+Vector2i.LEFT
			board.get_cell(a).special = BoardCell.Special.TAPAU_VERTICAL
			board.get_cell(b).special = BoardCell.Special.DULANG
			var result := board.activate_specials([b,a] if reverse else [a,b])
			assert(result.combo == &"badak_vertical")
			var columns := {}
			for pos in result.combo_cells:
				columns[pos.x] = true
				assert(absi(pos.x-result.combo_origin.x) <= 1)
			assert(columns.size() == (2 if result.combo_origin.x in [0,6] else 3))
			assert(result.combo_cells.size() == columns.size()*7)
	var text := SpecialExecutionText.new()
	add_child(text)
	text.show_wave([BoardCell.Special.TAPAU_VERTICAL],Vector2(700,700),100)
	assert(text.has_node("SelorotGraphic") and not text.has_node("TapauGraphic"))
	text.show_pisang(Vector2(700,700),100)
	assert(text.has_node("PisangCrispyGraphic"))
	text.reset()
	text.queue_free()
	var view := MatchBoard.new()
	view.size = Vector2(560,560)
	add_child(view)
	var level := LevelDefinition.new()
	level.width = 7
	level.height = 7
	level.kuih = KuihLibrary.starter_set()
	view.build(level)
	var origin := Vector2i(3,3)
	view.logic.get_cell(origin).special = BoardCell.Special.TAPAU_VERTICAL
	view._refresh_tiles()
	var result := view.logic.activate_specials([origin])
	var context := {"pending":1}
	view._play_activation_wave(result,result.activated,0,{},context)
	await view._wait(.05)
	assert(not view._tiles[origin].visible)
	assert(view._tiles[Vector2i(3,0)].visible,"Far item remains until leaf arrives")
	assert(view._vfx.effects.any(func(e): return e.kind == "selorot_unwrap"))
	await view._wait(.4)
	assert(not view._tiles[Vector2i(3,0)].visible,"Far item disappears with leaf sweep")
	while context.pending > 0:
		await get_tree().process_frame
	view.free()
	AudioManager.stop_music()
	print("Selorot: PASS (stable art ID, Pisang book retention, triple-column clipping both directions, title routing, progressive clearing)")
	get_tree().quit()
