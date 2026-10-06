extends Node

var problems := 0

func check(ok: bool, message: String) -> void:
	if not ok:
		problems += 1
		push_error(message)

func state(width: int = 7, height: int = 7) -> BoardState:
	var value := BoardState.new()
	value.setup(width, height, KuihLibrary.starter_set(), 83)
	return value

func _ready() -> void:
	run.call_deferred()

func run() -> void:
	for reverse in [false, true]:
		var board := state()
		var a := Vector2i(2,2)
		var b := Vector2i(3,2)
		for pos in [a,b]:
			board.get_cell(pos).special = BoardCell.Special.HANTAR
		board.order_remaining = {&"onde_onde": 99}
		var pair := [b,a] if reverse else [a,b]
		check(board.try_swap(pair[0],pair[1]) == BoardState.SwapOutcome.ACTIVATED_SPECIAL, "delivery combo swap accepted in either direction")
		var result := board.activate_specials(pair)
		check(result.combo == &"triple_delivery" and result.delivery_targets.size() == 3, "two deliveries select three targets")
		var unique: Dictionary = {}
		for target in result.delivery_targets:
			check(not unique.has(target), "each delivery has a distinct target")
			unique[target] = true
			check(target not in board.delivery_cross(a) and target not in board.delivery_cross(b), "remote target is outside local cross")
		check(result.cleared.size() == 11 and result.activated.size() == 2, "cross union and three deliveries clear once")
		var view := MatchBoard.new()
		view.size = Vector2(450,450)
		add_child(view)
		view.build(TutorialLibrary.get_stage(8))
		view.logic = board
		view._refresh_tiles()
		view._play_step(result,0)
		await get_tree().create_timer(.68).timeout
		var flights := view._vfx.effects.filter(func(effect): return effect.kind == "delivery")
		check(flights.size() == 3, "combo animates exactly three parcels")
		for flight in flights:
			check(flight.a == view._cell_center(result.combo_origin), "all three launch from combination origin")
		await get_tree().create_timer(3).timeout
		view.free()
	var tiny := state(2,2)
	for y in tiny.height:
		for x in tiny.width:
			if x >= 2 or y >= 2:
				tiny.get_cell(Vector2i(x,y)).clear_kuish()
	tiny.get_cell(Vector2i.ZERO).special = BoardCell.Special.HANTAR
	tiny.get_cell(Vector2i.RIGHT).special = BoardCell.Special.HANTAR
	var clipped := tiny.activate_specials([Vector2i.ZERO,Vector2i.RIGHT])
	check(clipped.delivery_targets.is_empty() and clipped.cleared.size() == 4, "small exhausted board safely clips targets")
	for reverse in [false,true]:
		var board := state()
		var a := Vector2i(2,2)
		var b := Vector2i(3,2)
		board.get_cell(a).special = BoardCell.Special.ORDER
		board.get_cell(b).special = BoardCell.Special.ORDER
		board.get_cell(Vector2i(6,6)).special = BoardCell.Special.TAPAU
		var pair := [b,a] if reverse else [a,b]
		board.try_swap(pair[0],pair[1])
		var wipe := board.activate_specials(pair)
		check(wipe.combo == &"order_wipe" and wipe.combo_cells.size() == 49 and wipe.cleared.size() == 49, "two orders wipe every tile of every type")
		check(wipe.activated.size() == 3, "wipe activates the other special exactly once")
		for row in board.grid:
			for cell in row:
				check(not cell.has_kuish(), "no board items remain before refill")
	AudioManager.stop_music()
	print("Special combo tests: %s (%d problems)" % ["PASS" if problems == 0 else "FAIL", problems])
	get_tree().quit(0 if problems == 0 else 1)
