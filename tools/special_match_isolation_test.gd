extends Node

var problems := 0
func check(ok: bool, message: String) -> void:
	if not ok:
		problems += 1
		push_error(message)

func board() -> BoardState:
	var state := BoardState.new()
	state.delivery_enabled = true
	state.setup(6,6,KuihLibrary.starter_set(),28)
	for y in state.height:
		for x in state.width:
			state.get_cell(Vector2i(x,y)).kuih = state.pool[(x+2*y)%state.pool.size()]
	return state

func _ready() -> void:
	for kind in [BoardCell.Special.HANTAR,BoardCell.Special.TAPAU,BoardCell.Special.TAPAU_VERTICAL,BoardCell.Special.DULANG,BoardCell.Special.ORDER]:
		for horizontal in [false,true]:
			var state := board()
			var start := Vector2i(0,2) if horizontal else Vector2i(2,0)
			var direction := Vector2i.RIGHT if horizontal else Vector2i.DOWN
			var special_pos := start+direction*3
			for i in 4:
				state.get_cell(start+direction*i).kuih = state.pool[0]
			state.get_cell(special_pos).special = kind
			var result := state.resolve([start])
			check(result.activated.is_empty(),"ordinary three-match must not activate neighbouring special")
			check(result.created.is_empty(),"hidden kuih inside special must not upgrade three-match to four")
			check(result.cleared.size() == 3,"only the three ordinary kuih clear")
			check(state.get_cell(special_pos).special == kind,"existing special survives ordinary match")
			var short := board()
			for i in 3:
				short.get_cell(start+direction*i).kuih = short.pool[0]
			short.get_cell(start+direction*2).special = kind
			check(short.resolve().is_empty(),"two ordinary kuih plus a special are not a match")
	var direct := board()
	var pos := Vector2i(2,2)
	direct.get_cell(pos).special = BoardCell.Special.HANTAR
	check(not direct.activate_specials([pos]).activated.is_empty(),"explicit activation still works")
	var chain := board()
	chain.get_cell(pos).special = BoardCell.Special.DULANG
	chain.get_cell(pos+Vector2i.RIGHT).special = BoardCell.Special.HANTAR
	check(chain.activate_specials([pos]).activated.any(func(activation): return activation.kind == BoardCell.Special.HANTAR),"special blast can still chain into Delivery")
	print("Special match isolation tests: %s (%d problems)" % ["PASS" if problems == 0 else "FAIL",problems])
	get_tree().quit(0 if problems == 0 else 1)
