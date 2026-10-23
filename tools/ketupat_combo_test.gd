extends Node

var done := false

func _ready() -> void:
	run.call_deferred()

func play(view: MatchBoard, result: BoardState.ClearResult) -> void:
	await view._play_step(result,0)
	done = true

func run() -> void:
	for reverse in [false,true]:
		for origin in [Vector2i.ZERO,Vector2i(3,3)]:
			var state := BoardState.new()
			state.setup(7,7,KuihLibrary.starter_set(),83)
			state.get_cell(origin).special = BoardCell.Special.TAPAU
			state.get_cell(origin+Vector2i.RIGHT).special = BoardCell.Special.TAPAU_VERTICAL
			var pair := [origin+Vector2i.RIGHT,origin] if reverse else [origin,origin+Vector2i.RIGHT]
			var result := state.activate_specials(pair)
			assert(result.combo == &"sweet_cross" and result.combo_cells.size() == 13)
			for pos in result.combo_cells:
				assert(pos.x == result.combo_origin.x or pos.y == result.combo_origin.y)
	var view := MatchBoard.new()
	view.size = Vector2(560,560)
	add_child(view)
	var level := LevelDefinition.new()
	level.width = 7
	level.height = 7
	level.kuih = KuihLibrary.starter_set()
	view.build(level)
	var a := Vector2i(3,3)
	var b := a+Vector2i.RIGHT
	view.logic.get_cell(a).special = BoardCell.Special.TAPAU
	view.logic.get_cell(b).special = BoardCell.Special.TAPAU_VERTICAL
	view._refresh_tiles()
	var result := view.logic.activate_specials([a,b])
	play(view,result)
	while not view._special_text.has_node("KetupatGraphic"):
		await get_tree().process_frame
	assert(not view._special_text.has_node("KetupatRayaGraphic"))
	assert(not view._special_text.has_node("TapauGraphic"))
	assert(view._vfx.effects.any(func(e): return e.kind == "ketupat_appear"))
	assert(view.get_node_or_null("CrossComboRoller") == null)
	await view._wait(.30)
	var foreground: TextureRect = view._vfx.get_node("KetupatForeground")
	assert(foreground.texture == GameVfx.KETUPAT_ART,"Full asset preserves the upper leaf stems")
	assert(is_equal_approx(foreground.size.x,view.cell_size*GameVfx.KETUPAT_COMBO_EDGE))
	assert(foreground.self_modulate.a == 1.0,"Ketupat stays fully opaque during readable hold")
	assert(view._special_text.has_node("KetupatGraphic") and view._special_text.visible)
	assert(not view._vfx.effects.any(func(e): return e.kind == "ketupat_lane"))
	while not view._vfx.effects.any(func(e): return e.kind == "ketupat_lane"):
		await get_tree().process_frame
	assert(view._vfx.effects.filter(func(e): return e.kind == "ketupat_lane").size() == 2)
	assert(not view._vfx.effects.any(func(e): return e.kind in ["roller_lane","tapau_slots","beam"]))
	await view._wait(GameVfx.KETUPAT_TRAVEL+.025)
	assert(foreground.texture == GameVfx.KETUPAT_ART,"The full texture is never abruptly replaced")
	assert(foreground.get_node("UnwrapSequence").texture is AtlasTexture)
	for pos in result.combo_cells:
		assert(not view._tiles[pos].visible)
	assert(view._tiles[Vector2i.ZERO].visible)
	while not done:
		await get_tree().process_frame
	view.queue_free()
	await get_tree().process_frame
	AudioManager.stop_music()
	print("Ketupat combo: PASS (both swap orders, edge/centre, one-row/one-column footprint, Ketupat title, reused rice/leaf sequence, no roller, progressive clear)")
	get_tree().quit()
