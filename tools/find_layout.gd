extends SceneTree

## Layout finder for the tutorial stages.
##
## Hand-designing a 3x3 board is a trap: a swap changes two cells, so it can only
## complete a line it actually touches, and easy to get wrong. This brute-forces
## candidate layouts and prints the ones that provably have the property a lesson
## needs, so the shipped layouts are machine-verified rather than guessed.
##
##   godot --headless --script res://tools/find_layout.gd

const IDS := [
	&"onde_onde", &"kuih_lapis", &"seri_muka", &"kuih_ketayap",
	&"ang_ku_kueh", &"vadai",
]

var pool: Array[KuihData] = []
var pool_size: int = 3


func _initialize() -> void:
	for id in IDS:
		var kuih := KuihLibrary.get_kuih(id)
		if kuih != null:
			pool.append(kuih)

	print("== gesture boards: one legal move, in one direction ==")
	_find_gesture(3, 3, true, 3)
	_find_gesture(3, 3, false, 3)

	print("")
	print("== special boards: a reachable move creates the tile ==")
	_find_special(4, 4, BoardCell.Special.TAPAU, 8, 4)
	_find_special(5, 5, BoardCell.Special.DULANG, 8, 4)
	quit(0)


## Snapshot of the grid as text, so a layout can be printed before the board is
## mutated by the reachability probing.
func _layout_text(board: BoardState) -> String:
	var rows: Array = []
	for y in board.height:
		var row: Array = []
		for x in board.width:
			var cell := board.get_cell(Vector2i(x, y))
			var kuih: KuihData = cell.kuih
			row.append(kuih.id if kuih != null else &"?")
		rows.append(row)
	return str(rows)


func _build(size: int, cells: Array, rng: RandomNumberGenerator) -> BoardState:
	var board := BoardState.new()
	board.setup(size, size, cells.duplicate() as Array[KuihData], rng.randi())
	return board


func _moves(board: BoardState) -> Array[Dictionary]:
	return board.find_possible_moves(4096)


func _print_layout(board: BoardState, moves: Array[Dictionary]) -> void:
	var rows: Array = []
	for y in board.height:
		var row: Array = []
		for x in board.width:
			var cell := board.get_cell(Vector2i(x, y))
			row.append(cell.kuish_id())
		rows.append(row)
	print("  layout: ", rows)
	for pair in moves:
		print("    move: ", pair["a"], " <-> ", pair["b"])


## A 3x3 board with three kuih types is dense enough that "exactly one legal
## move" essentially never happens. What actually matters for the lesson is that
## EVERY move the player could find is in the direction being taught, so the
## search looks for the quietest board of the right kind.
func _find_gesture(width: int, height: int, want_vertical: bool, types: int) -> void:
	var label := "vertical" if want_vertical else "horizontal"
	print("-- %dx%d, %d kuih types, one move, %s --" % [width, height, types, label])
	var cells: Array[KuihData] = []
	for i in types:
		cells.append(pool[i])
	var shown := 0
	for attempt in 80000:
		if shown >= 2:
			break
		var board := BoardState.new()
		board.setup(width, height, cells.duplicate(), attempt + 1)
		if not board.is_clean():
			continue
		var moves := _moves(board)
		if moves.size() != 1:
			continue
		var pair: Dictionary = moves[0]
		var a: Vector2i = pair["a"]
		var b: Vector2i = pair["b"]
		if (a.x == b.x) != want_vertical:
			continue
		var text := _layout_text(board)
		board.try_swap(a, b)
		var result := board.resolve([a, b])
		if result.cleared.size() == 0:
			continue
		shown += 1
		print("   layout: ", text)
		print("   move:   ", a, " <-> ", b, "   clears ", result.cleared.size())


func _find_special(width: int, height: int, special: int, max_moves: int, types: int) -> void:
	var name := "TAPAU" if special == BoardCell.Special.TAPAU else "DULANG"
	print("-- %dx%d, %d kuih types, reachable %s --" % [width, height, types, name])
	var cells: Array[KuihData] = []
	for i in types:
		cells.append(pool[i])
	var shown := 0
	for attempt in 80000:
		if shown >= 2:
			break
		var board := BoardState.new()
		board.setup(width, height, cells.duplicate(), attempt + 1)
		if not board.is_clean():
			continue
		var moves := _moves(board)
		if moves.is_empty() or moves.size() > max_moves:
			continue
		var text := _layout_text(board)
		var hit: Dictionary = {}
		for pair in moves:
			var snapshot := board.snapshot()
			var a: Vector2i = pair["a"]
			var b: Vector2i = pair["b"]
			if board.try_swap(a, b) == BoardState.SwapOutcome.INVALID:
				_restore(board, snapshot)
				continue
			var result := board.resolve([a, b])
			for entry in result.created:
				if int(entry["special"]) == special:
					hit = {"pos": entry["pos"], "swap": pair}
			_restore(board, snapshot)
			if not hit.is_empty():
				break
		if hit.is_empty():
			continue
		shown += 1
		print("   layout: ", text)
		print("   creates ", name, " at ", hit["pos"], " via ", hit["swap"], "  (", moves.size(), " moves )")


func _restore(board: BoardState, snapshot: Array) -> void:
	for y in board.height:
		for x in board.width:
			var cell := board.get_cell(Vector2i(x, y))
			var data: Dictionary = snapshot[y][x]
			cell.kuih = KuihLibrary.get_kuih(data["kuish"])
			cell.special = data["special"]
			cell.order_kuish = data["order_kuish"]
			cell.blocker_kind = data["blocker"]
			cell.blocker_hp = data["hp"]
			cell.target_kuish = data["target"]
			cell.target_progress = data["target_progress"]
			cell.target_need = data["target_need"]