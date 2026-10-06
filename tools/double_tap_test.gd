extends Node

var problems := 0
var moves := 0
var first_clear: BoardState.ClearResult

func check(ok: bool, message: String) -> void:
	if not ok:
		problems += 1
		push_error(message)

func _ready() -> void:
	run.call_deferred()

func run() -> void:
	for kind in [BoardCell.Special.TAPAU, BoardCell.Special.TAPAU_VERTICAL, BoardCell.Special.DULANG, BoardCell.Special.HANTAR, BoardCell.Special.ORDER]:
		var view := MatchBoard.new()
		view.size = Vector2(400,400)
		add_child(view)
		view.build(TutorialLibrary.get_stage(9))
		view.enabled = true
		var origin := Vector2i(1,1)
		view.logic.get_cell(origin).special = kind
		view.logic.get_cell(origin).order_kuish = &"onde_onde"
		view.logic.order_remaining = {&"kuih_ketayap": 5}
		view.logic.get_cell(Vector2i(1,2)).kuih = KuihLibrary.get_kuih(&"kuih_ketayap")
		view.logic.get_cell(Vector2i(3,3)).kuih = KuihLibrary.get_kuih(&"kuih_ketayap")
		view._refresh_tiles()
		moves = 0
		first_clear = null
		view.move_committed.connect(func(): moves += 1)
		view.clear_resolved.connect(func(result, _cascade):
			if first_clear == null:
				first_clear = result)
		var at := view.cell_to_pos(origin) + Vector2.ONE * view.cell_size * .5
		view.activation_filter = func(_pos): return false
		view._finish_drag(at)
		view._finish_drag(at)
		check(moves == 0 and not view.busy, "tutorial filter blocks double tap without a move")
		view.activation_filter = Callable()
		view._finish_drag(at)
		view._last_tap_ms -= MatchBoard.DOUBLE_TAP_MS + 1
		view._finish_drag(at)
		check(moves == 0, "slow second tap does not activate")
		view._finish_drag(at)
		check(moves == 1 and view.busy, "double tap commits exactly one move")
		view.attempt_activate(origin)
		check(moves == 1, "busy board prevents duplicate activation")
		while view.busy:
			await get_tree().process_frame
		check(first_clear != null and not first_clear.activated.is_empty(), "every special resolves through double tap")
		if kind == BoardCell.Special.HANTAR:
			var activation: Dictionary = first_clear.activated[0]
			check(activation.cells.size() == 6, "double tap delivery clears local cross and remote tile")
			check(first_clear.cleared[activation.cells.back()].kuih.id == &"kuih_ketayap", "automatic delivery picks local unmet order type")
		view.free()
	var coach := TutorialCoach.new()
	coach.steps = TutorialLibrary.get_stage(9).tutorial_steps
	check(not coach.allows_activation(Vector2i.ZERO, BoardState.new()), "intro cannot be bypassed by double tap")
	coach.free()
	AudioManager.stop_music()
	print("Double tap tests: %s (%d problems)" % ["PASS" if problems == 0 else "FAIL", problems])
	get_tree().quit(0 if problems == 0 else 1)
