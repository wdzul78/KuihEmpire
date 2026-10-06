extends Node

var problems := 0
var playing := false

func check(ok: bool, message: String) -> void:
	if not ok:
		problems += 1
		push_error(message)

func state() -> BoardState:
	var board := BoardState.new()
	board.setup(10,10,KuihLibrary.starter_set(),83)
	return board

func _ready() -> void:
	run.call_deferred()

func animate(view: MatchBoard, result: BoardState.ClearResult) -> void:
	playing = true
	await view._play_step(result,0)
	playing = false

func run() -> void:
	for test in [[Vector2i(5,5),9,21],[Vector2i(0,5),6,13],[Vector2i(0,0),4,8]]:
		var origin: Vector2i = test[0]
		for double_blast in [false,true]:
			var board := state()
			board.get_cell(origin).special = BoardCell.Special.DULANG
			var pair := [origin]
			if double_blast:
				board.get_cell(origin+Vector2i.RIGHT).special = BoardCell.Special.DULANG
				pair = [origin+Vector2i.RIGHT,origin]
			var result := board.activate_specials(pair)
			check(result.cleared.size() == int(test[2] if double_blast else test[1]), "center/edge/corner mask count")
			check(result.activated.size() == (2 if double_blast else 1), "one activation per consumed special")
			for pos in result.cleared:
				check(board.is_inside(pos), "all resolved coordinates are in bounds")
			if double_blast:
				check(result.combo == &"rounded_dulang", "explicit adjacent Dulang combo")
				for offset in [Vector2i(-2,-2),Vector2i(2,-2),Vector2i(-2,2),Vector2i(2,2)]:
					check(not result.cleared.has(origin+offset), "rounded mask excludes distant corners")
	var guarded := state()
	var origin := Vector2i(5,5)
	var guard := origin+Vector2i(2,0)
	guarded.apply_blockers([BlockerSpec.make(BlockerSpec.Kind.STEAMER,[guard],2)])
	for pos in [origin,origin+Vector2i.LEFT]:
		guarded.get_cell(pos).special = BoardCell.Special.DULANG
	var hit := guarded.activate_specials([origin+Vector2i.LEFT,origin])
	check(guarded.get_cell(guard).blocker_hp == 1, "combo damages guard once despite two members")
	check(not hit.cleared.has(guard), "guard absorbs blast and preserves kuih")
	var chain := state()
	chain.get_cell(origin).special = BoardCell.Special.DULANG
	chain.get_cell(origin+Vector2i.RIGHT).special = BoardCell.Special.DULANG
	chain.get_cell(origin+Vector2i(2,0)).special = BoardCell.Special.TAPAU
	chain.get_cell(Vector2i(9,5)).special = BoardCell.Special.DULANG
	var chained := chain.activate_specials([origin+Vector2i.RIGHT,origin])
	var activated: Dictionary = {}
	for entry in chained.activated:
		check(not activated.has(entry.pos), "chain activates each special exactly once")
		activated[entry.pos] = true
	check(activated.size() == 4 and chained.cleared.has(Vector2i(9,4)), "combo triggers Tapau and downstream Dulang")
	var incidental := state()
	incidental.get_cell(origin).special = BoardCell.Special.DULANG
	incidental.get_cell(origin+Vector2i.RIGHT).special = BoardCell.Special.DULANG
	check(incidental.activate_specials([origin]).combo == &"", "chain hit does not create deliberate-swap combo")
	var score := StageScoreController.new()
	score.rules = ScoreRules.new()
	var single := state()
	single.get_cell(origin).special = BoardCell.Special.DULANG
	var single_score := score.add_clear(single.activate_specials([origin]),0)
	var double_board := state()
	for pos in [origin,origin+Vector2i.RIGHT]:
		double_board.get_cell(pos).special = BoardCell.Special.DULANG
	check(score.add_clear(double_board.activate_specials([origin+Vector2i.RIGHT,origin]),0) > single_score, "existing score system rewards combo more")
	var view := MatchBoard.new()
	view.size = Vector2(500,500)
	add_child(view)
	view.build(TutorialLibrary.get_stage(8))
	var center := Vector2i(3,3)
	for pos in [center,center+Vector2i.RIGHT]:
		view.logic.get_cell(pos).special = BoardCell.Special.DULANG
	view._refresh_tiles()
	var result := view.logic.activate_specials([center+Vector2i.RIGHT,center])
	animate(view,result)
	await get_tree().create_timer(.12).timeout
	var charges := view._vfx.effects.filter(func(e): return e.kind == "charge")
	check(charges.size() == 1 and charges[0].double_blast and charges[0].foods.size() == 19, "combo gathers 19 foods into one enlarged tray")
	await get_tree().create_timer(.58).timeout
	var rings := view._vfx.effects.filter(func(e): return e.kind == "flower_wave")
	check(rings.size() == 2, "combo emits inner and delayed outer radial pulses")
	check(view._vfx.effects.any(func(e): return e.kind == "dulang_radial"), "warm radial glow replaces square presentation")
	check(not view._vfx.effects.any(func(e): return e.kind in ["preview","gold_slot"]), "no slot highlight")
	while playing:
		await get_tree().process_frame
	await get_tree().create_timer(1).timeout
	check(view._vfx.effects.is_empty() and view._vfx.particles.is_empty(), "VFX cleanup")
	view.free()
	AudioManager.stop_music()
	for voice in AudioManager._voices:
		voice.stop()
		voice.stream = null
	await get_tree().create_timer(.15).timeout
	print("Rounded Dulang tests: %s (%d problems)" % ["PASS" if problems == 0 else "FAIL",problems])
	get_tree().quit(0 if problems == 0 else 1)
