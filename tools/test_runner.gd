extends Node

## Headless smoke test + balance harness (Master Plan sections 61 and 76).
##
## Run with:
##   godot --headless res://tools/balance_scene.tscn
##
## It drives [BoardState] directly - no view, no tweens - so it can play all 30
## MVP stages thousands of times and report win rates. Any stage that a greedy
## player cannot clear is a balance bug, not a player bug.

const TRIALS := 8

var failures: Array[String] = []
var _last_score := 0


func _ready() -> void:
	run.call_deferred()

func run() -> void:
	var start := Time.get_ticks_msec()
	_test_board_invariants()
	_test_specials()
	_test_blockers()
	_test_tutorial_layouts()
	_print_tutorial_report()
	var report: Array = []
	if not "--rules-only" in OS.get_cmdline_user_args():
		report = _simulate_all()
	print("")
	print("Balance report")
	print("-------------")
	for entry in report:
		print(entry)
	print("")
	print("invariants + specials + blockers + tutorial layouts: %s" % (
		"PASS" if failures.is_empty() else "FAIL"
	))
	for failure in failures:
		print("  ! " + failure)
	print("")
	print("Elapsed: %d ms" % (Time.get_ticks_msec() - start))
	get_tree().quit(0 if failures.is_empty() else 1)


# --- unit style checks -----------------------------------------------------

func _make_board(level: LevelDefinition, seed_value: int) -> BoardState:
	var board := BoardState.new()
	board.delivery_enabled = level.tutorial_index in [9, 5, 7, 8]
	board.setup(level.width, level.height, level.kuih, seed_value)
	if not level.fixed_layout.is_empty():
		if not board.apply_layout(level.fixed_layout):
			_check(false, "stage %d: fixed_layout could not be applied" % level.id)
	else:
		# Mirror MatchBoard.build(): a generated board that happens to be dead is
		# reshuffled rather than left unplayable.
		if not board.has_possible_move():
			board.shuffle_board()
	board.apply_blockers(level.blockers)
	if level.tutorial_index == 11:
		board.get_cell(Vector2i(1,1)).special = BoardCell.Special.TAPAU
		board.get_cell(Vector2i(2,1)).special = BoardCell.Special.TAPAU_VERTICAL
	return board


func _test_board_invariants() -> void:
	var level := LevelLibrary.get_level(18)
	var board := _make_board(level, 12345)

	for attempt in 40:
		# MatchBoard reshuffles when a cascade settles without a legal move.
		if not board.has_possible_move():
			board.shuffle_board()
		var moves := board.find_possible_moves(6)
		if moves.is_empty():
			_check(false, "seed %d: no legal move found on a fresh board" % attempt)
			return
		var pair: Dictionary = moves[randi() % moves.size()]
		var a: Vector2i = pair["a"]
		var b: Vector2i = pair["b"]
		var outcome := board.try_swap(a, b)
		_check(outcome != BoardState.SwapOutcome.INVALID, "seed %d: suggested move was rejected" % attempt)

		var guard := 0
		while guard < 60:
			guard += 1
			var result := board.resolve([a, b])
			if result.is_empty():
				break
			board.apply_gravity()
			board.refill()
		_check(_board_consistent(board), "seed %d: board inconsistent after cascade" % attempt)
		if board.has_any_match():
			_check(false, "seed %d: board settled with a live match" % attempt)
			return
	print("board invariants ......... ok")


func _board_consistent(board: BoardState) -> bool:
	for y in board.height:
		for x in board.width:
			var cell := board.get_cell(Vector2i(x, y))
			if cell == null:
				return false
			if cell.is_hole():
				return false
			if cell.has_overlay() and not cell.has_kuish() and not cell.is_target():
				return false
	return true


func _test_specials() -> void:
	# A horizontal four creates Tapau Pack.
	var board := _force_board([
		[&"onde_onde", &"onde_onde", &"onde_onde", &"onde_onde", &"kuih_lapis"],
		[&"kuih_ketayap", &"ang_ku_kueh", &"keria", &"kuih_koci", &"ang_ku_kueh"],
		[&"ang_ku_kueh", &"kuih_lapis", &"kuih_ketayap", &"keria", &"kuih_koci"],
		[&"keria", &"kuih_koci", &"ang_ku_kueh", &"kuih_lapis", &"kuih_ketayap"],
	])
	var groups := board.find_matches()
	_check(groups.size() == 1, "expected exactly one match group, found %d" % groups.size())
	if not groups.is_empty():
		_check(
			groups[0].special == BoardCell.Special.TAPAU,
			"match-4 produced special %d instead of TAPAU" % groups[0].special
		)

	# A single horizontal special clears only its row.
	var firing := _force_board([
		[&"onde_onde", &"kuih_koci", &"ang_ku_kueh", &"keria", &"kuih_ketayap"],
		[&"keria", &"kuih_ketayap", &"onde_onde", &"kuih_koci", &"ang_ku_kueh"],
		[&"ang_ku_kueh", &"keria", &"kuih_ketayap", &"onde_onde", &"kuih_koci"],
		[&"kuih_koci", &"ang_ku_kueh", &"keria", &"kuih_ketayap", &"onde_onde"],
	])
	var trigger := Vector2i(2, 2)
	firing.get_cell(trigger).special = BoardCell.Special.TAPAU
	var fired := firing.activate_specials([trigger])
	var expected := firing.width
	_check(
		fired.cleared.size() == expected,
		"Tapau cleared %d tiles, expected %d" % [fired.cleared.size(), expected]
	)

	# Vertical four creates a column-only Tapau.
	var column_board := _force_board([
		[&"onde_onde", &"kuih_koci", &"ang_ku_kueh", &"keria", &"kuih_ketayap"],
		[&"onde_onde", &"kuih_ketayap", &"keria", &"kuih_koci", &"ang_ku_kueh"],
		[&"onde_onde", &"keria", &"kuih_ketayap", &"ang_ku_kueh", &"kuih_koci"],
		[&"onde_onde", &"ang_ku_kueh", &"keria", &"kuih_ketayap", &"kuih_koci"],
	])
	var column_groups := column_board.find_matches()
	_check(column_groups.size() == 1, "expected one vertical match")
	if not column_groups.is_empty():
		_check(column_groups[0].special == BoardCell.Special.TAPAU_VERTICAL, "vertical four must create vertical Tapau")
	column_board.get_cell(Vector2i(0, 2)).special = BoardCell.Special.TAPAU_VERTICAL
	var column_result := column_board.activate_specials([Vector2i(0, 2)])
	_check(column_result.cleared.size() == column_board.height, "vertical special must clear one column")
	for pos in column_result.cleared:
		_check(pos.x == 0, "vertical special cleared outside its column")
	for pos in fired.cleared:
		_check(pos.y == trigger.y, "horizontal special cleared outside its row")
	_check(BoardArt.special_texture(BoardCell.Special.TAPAU) != null, "row artwork missing")
	_check(BoardArt.special_texture(BoardCell.Special.TAPAU_VERTICAL) != null, "column artwork missing")

	# An L shape must become a Dulang that clears 3x3.
	var lshape := _force_board([
		[&"onde_onde", &"onde_onde", &"onde_onde", &"ang_ku_kueh", &"kuih_koci"],
		[&"kuih_koci", &"kuih_ketayap", &"onde_onde", &"keria", &"ang_ku_kueh"],
		[&"kuih_ketayap", &"keria", &"onde_onde", &"ang_ku_kueh", &"kuih_ketayap"],
		[&"keria", &"ang_ku_kueh", &"kuih_koci", &"kuih_ketayap", &"onde_onde"],
		[&"ang_ku_kueh", &"kuih_ketayap", &"keria", &"onde_onde", &"kuih_koci"],
	])
	var lgroups := lshape.find_matches()
	var dulang_ok := false
	for group in lgroups:
		if group.special == BoardCell.Special.DULANG:
			dulang_ok = true
	_check(dulang_ok, "L shape did not create a Dulang")
	var dulang_result := lshape.resolve([])
	_check(
		dulang_result.cleared.size() == 4,
		"L shape should clear the 4 non-origin tiles, cleared %d" % dulang_result.cleared.size()
	)
	_check(
		not dulang_result.created.is_empty()
			and dulang_result.created[0]["special"] == BoardCell.Special.DULANG,
		"L shape did not leave a Dulang behind"
	)

	# Five in a row must become a Special Order.
	var five := _force_board([
		[&"keria", &"keria", &"keria", &"keria", &"keria"],
		[&"kuih_koci", &"ang_ku_kueh", &"kuih_ketayap", &"kuih_lapis", &"onde_onde"],
		[&"ang_ku_kueh", &"kuih_ketayap", &"kuih_lapis", &"onde_onde", &"kuih_koci"],
		[&"kuih_ketayap", &"kuih_lapis", &"onde_onde", &"kuih_koci", &"ang_ku_kueh"],
	])
	var order_ok := false
	for group in five.find_matches():
		if group.special == BoardCell.Special.ORDER:
			order_ok = true
	_check(order_ok, "five in a row did not create a Special Order")
	# A package's hidden creation kuih must not make it a color-collection target.
	for kind in [BoardCell.Special.DULANG,BoardCell.Special.TAPAU,BoardCell.Special.TAPAU_VERTICAL,BoardCell.Special.HANTAR,BoardCell.Special.ORDER]:
		var independent := BoardState.new()
		independent.setup(5,5,KuihLibrary.starter_set(),89)
		var origin := Vector2i(2,2)
		var neighbour := Vector2i(3,2)
		var package_pos := Vector2i(0,0)
		var wanted := independent.pool[0]
		independent.get_cell(origin).special = BoardCell.Special.ORDER
		independent.get_cell(origin).order_kuish = independent.pool[1].id
		independent.get_cell(neighbour).kuih = wanted
		independent.get_cell(package_pos).kuih = wanted
		independent.get_cell(package_pos).special = kind
		independent.try_swap(origin,neighbour)
		var ordinary_collection := independent.activate_specials([origin,neighbour])
		_check(ordinary_collection.activated.size() == 1, "color collection must not trigger unrelated packages")
		_check(not ordinary_collection.cleared.has(package_pos) and independent.get_cell(package_pos).special == kind, "color collection preserves unrelated special")
	# Swapping Special Order must collect the partner's type, not its creation type.
	for partner in KuihLibrary.starter_set():
		for reverse in [false, true]:
			var color_board := BoardState.new()
			color_board.setup(5,5,KuihLibrary.starter_set(),424)
			var origin := Vector2i(2,2)
			var neighbour := Vector2i(3,2)
			color_board.get_cell(origin).kuih = KuihLibrary.get_kuih(&"kuih_lapis")
			color_board.get_cell(origin).special = BoardCell.Special.ORDER
			color_board.get_cell(origin).order_kuish = &"kuih_lapis"
			color_board.get_cell(neighbour).kuih = partner
			var pair := [neighbour,origin] if reverse else [origin,neighbour]
			_check(color_board.try_swap(pair[0],pair[1]) == BoardState.SwapOutcome.ACTIVATED_SPECIAL, "Special Order accepts either swipe order")
			_check(color_board.get_cell(neighbour).order_kuish == partner.id, "Special Order targets swapped partner")
			var expected_order_cells: Dictionary = {neighbour:true}
			for y in color_board.height:
				for x in color_board.width:
					var pos := Vector2i(x,y)
					if color_board.get_cell(pos).kuish_id() == partner.id:
						expected_order_cells[pos] = true
			var collected := color_board.activate_specials(pair)
			_check(collected.cleared.size() == expected_order_cells.size(), "Special Order clears exactly partner type plus package")
			for pos in collected.cleared:
				_check(expected_order_cells.has(pos), "Special Order must leave other kuih types intact")
	# A Dulang activates with every neighbouring kuih, without a match-three.
	for partner in KuihLibrary.starter_set():
		var dulang_board := BoardState.new()
		dulang_board.setup(5, 5, KuihLibrary.starter_set(), 321)
		dulang_board.get_cell(Vector2i(2, 2)).kuih = KuihLibrary.get_kuih(&"kuih_lapis")
		dulang_board.get_cell(Vector2i(2, 2)).special = BoardCell.Special.DULANG
		dulang_board.get_cell(Vector2i(3, 2)).kuih = partner
		_check(dulang_board.try_swap(Vector2i(2, 2), Vector2i(3, 2)) == BoardState.SwapOutcome.ACTIVATED_SPECIAL, "Dulang did not activate with %s" % partner.id)
		var blast := dulang_board.activate_specials([Vector2i(2, 2), Vector2i(3, 2)])
		_check(blast.cleared.size() == 9, "Dulang must clear a 3x3 area with %s" % partner.id)
	print("special tiles ............ ok")


func _force_board(rows: Array) -> BoardState:
	var pool: Array[KuihData] = [
		KuihLibrary.get_kuih(&"onde_onde"),
		KuihLibrary.get_kuih(&"kuih_koci"),
		KuihLibrary.get_kuih(&"ang_ku_kueh"),
		KuihLibrary.get_kuih(&"kuih_ketayap"),
		KuihLibrary.get_kuih(&"kuih_lapis"),
		KuihLibrary.get_kuih(&"keria"),
	]
	var board := BoardState.new()
	board.setup((rows[0] as Array).size(), rows.size(), pool, 999)
	for y in rows.size():
		var row: Array = rows[y]
		for x in row.size():
			var cell := board.get_cell(Vector2i(x, y))
			var replacement: KuihData = KuihLibrary.get_kuih(row[x])
			cell.kuih = replacement
	return board


func _test_blockers() -> void:
	var pool: Array[KuihData] = KuihLibrary.starter_set()
	var board := BoardState.new()
	board.setup(8, 8, pool, 4242)
	var spec := BlockerSpec.make(BlockerSpec.Kind.BANANA_LEAF, [Vector2i(3, 3)], 1)
	board.apply_blockers([spec])
	var cell := board.get_cell(Vector2i(3, 3))
	_check(cell.has_overlay(), "banana leaf was not placed")
	_check(not cell.is_playable(), "a covered cell must not be playable")

	var cleared := 0
	var hits := 0
	for _i in 40:
		var moves := board.find_possible_moves(1)
		if moves.is_empty():
			break
		var pair: Dictionary = moves[0]
		var a: Vector2i = pair["a"]
		var b: Vector2i = pair["b"]
		if board.try_swap(a, b) == BoardState.SwapOutcome.INVALID:
			continue
		var result := board.resolve([a, b])
		cleared += result.cleared.size()
		hits += result.blockers.size()
		var guard := 0
		while guard < 40:
			guard += 1
			var cascade := board.resolve([])
			if cascade.is_empty():
				break
			cleared += cascade.cleared.size()
			hits += cascade.blockers.size()
			board.apply_gravity()
			board.refill()
		if not board.get_cell(Vector2i(3, 3)).has_overlay():
			break
	_check(cleared > 0, "no tiles cleared while testing blockers")
	_check(hits > 0, "the banana leaf never took damage")
	_check(not board.get_cell(Vector2i(3, 3)).has_overlay(), "the banana leaf never opened")
	print("obstacles ................ ok")


# --- tutorial guarantees ---------------------------------------------------

## A tutorial stage must be provably safe.
##
##   * any hand-authored layout must have NO pre-existing match, so the player
##     has to work for every clear
##   * the two gesture lessons must have at least one legal move, and EVERY
##     legal move must be in the direction the coach asks for - a sideways
##     solution on the "swipe up and down" board would teach the wrong thing
##   * the two special lessons must have a reachable move that creates the
##     special tile
##   * every stage must have at least one legal move, or the coach can never be
##     satisfied and the stage soft-locks
func _test_tutorial_layouts() -> void:
	var gesture_gate := {
		1: TutorialStepData.Gate.SWAP_VERTICAL,
		2: TutorialStepData.Gate.SWAP_HORIZONTAL,
	}
	var special_gate := {
		4: BoardCell.Special.TAPAU,
		5: BoardCell.Special.DULANG,
		9: BoardCell.Special.HANTAR,
		10: BoardCell.Special.TAPAU_VERTICAL,
	}

	for index in TutorialLibrary.ACTIVE_LESSONS:
		var stage := TutorialLibrary.get_stage(index)
		var board := _make_board(stage, 1000 + index * 31)

		_check(
			board.width == stage.width and board.height == stage.height,
			"tutorial %d: board is %dx%d, expected %dx%d" % [
				index, board.width, board.height, stage.width, stage.height
			]
		)
		_check(
			board.is_clean(),
			"tutorial %d: layout starts with a free match" % index
		)
		_check(
			board.has_possible_move(),
			"tutorial %d: board has no legal move, the coach can never pass" % index
		)
		_check(not stage.allow_fail, "tutorial %d: must not be losable" % index)
		_check(stage.score_three_star >= stage.score_two_star and stage.score_two_star > 0, "tutorial %d: score thresholds invalid" % index)
		_check(not stage.tutorial_steps.is_empty(), "tutorial %d: has no coaching steps" % index)

		var moves := board.find_possible_moves(128)
		_check(
			not moves.is_empty(),
			"tutorial %d: no legal move found" % index
		)

		if gesture_gate.has(index):
			var wanted: int = gesture_gate[index]
			var label := "vertical" if wanted == TutorialStepData.Gate.SWAP_VERTICAL else "horizontal"
			for pair in moves:
				var a: Vector2i = pair["a"]
				var b: Vector2i = pair["b"]
				var is_vertical := a.x == b.x
				if (wanted == TutorialStepData.Gate.SWAP_VERTICAL) == is_vertical:
					continue
				_check(
					false,
					"tutorial %d: move %s-%s is %s, but the lesson teaches %s only (%d legal moves)" % [
						index, a, b,
						"vertical" if is_vertical else "horizontal",
						label,
						moves.size()
					]
				)

		if special_gate.has(index):
			var required: int = special_gate[index]
			var reached := false
			for pair in moves:
				var a: Vector2i = pair["a"]
				var b: Vector2i = pair["b"]
				var snapshot := board.snapshot()
				if board.try_swap(a, b) == BoardState.SwapOutcome.INVALID:
					_restore(board, snapshot)
					continue
				var result := board.resolve([a, b])
				for entry in result.created:
					if int(entry["special"]) == required:
						reached = true
				_restore(board, snapshot)
				if reached:
					break
			_check(
				reached,
				"tutorial %d: no reachable move creates special %d" % [index, required]
			)

		# Authored highlights must point at real cells.
		for step in stage.tutorial_steps:
			for cell in step.highlight:
				_check(
					cell.x >= 0 and cell.y >= 0 and cell.x < stage.width and cell.y < stage.height,
					"tutorial %d: highlight %s is outside the board" % [index, cell]
				)

	print("tutorial layouts ..... ok")


## Plays every tutorial stage the way a player would and checks the stage's
## coaching gate can actually be satisfied. Tutorial stages never fail, so the
## bot is allowed to keep going past the move budget.
func _print_tutorial_report() -> void:
	var lines: Array[String] = []
	lines.append("")
	lines.append("Tutorial report")
	lines.append("----------------")
	for index in TutorialLibrary.ACTIVE_LESSONS:
		var stage := TutorialLibrary.get_stage(index)
		var wins := 0
		var seeds := 4
		for trial in seeds:
			if _play_tutorial(stage, 2000 + trial * 613):
				wins += 1
		var gate := _gate_of(stage)
		var flag := "ok " if wins == seeds else "!! "
		lines.append(
			"%sT%d  %dx%d  gate %-16s  achievable %d/%d  %s" % [
				flag, index, stage.width, stage.height,
				_gate_name(gate), wins, seeds, stage.title
			]
		)
	print("\n".join(lines))


## The gate the coach actually waits on - the last step that is not an intro line.
static func _gate_of(stage: LevelDefinition) -> int:
	var gate := TutorialStepData.Gate.INTRO
	for step in stage.tutorial_steps:
		if step.gate != TutorialStepData.Gate.INTRO:
			gate = step.gate
	return gate


static func _gate_name(gate: int) -> String:
	var names := {
		TutorialStepData.Gate.INTRO: "intro only",
		TutorialStepData.Gate.SWAP_ANY: "any swap",
		TutorialStepData.Gate.SWAP_VERTICAL: "swipe vertical",
		TutorialStepData.Gate.SWAP_HORIZONTAL: "swipe horizontal",
		TutorialStepData.Gate.CREATED_TAPAU: "make tapau",
		TutorialStepData.Gate.CREATED_DULANG: "make dulang",
		TutorialStepData.Gate.CREATED_HANTAR: "make delivery",
		TutorialStepData.Gate.BLOCKER_OPENED: "open covers",
		TutorialStepData.Gate.COLLECTED: "collect",
		TutorialStepData.Gate.SERVED: "serve",
		TutorialStepData.Gate.ACTIVATED_SPECIAL: "activate special",
		TutorialStepData.Gate.ACTIVATED_CROSS: "combine cross",
	}
	return String(names.get(gate, "?"))


func _play_tutorial(stage: LevelDefinition, seed_value: int) -> bool:
	var board := _make_board(stage, seed_value)
	var orders: Array[CustomerOrder] = []
	for spec in stage.customer_orders:
		orders.append(CustomerOrder.from_spec(spec))
	var index := 0
	var gate := _gate_of(stage)
	var gate_value := 1
	for step in stage.tutorial_steps:
		if step.gate == gate:
			gate_value = maxi(1, step.gate_value)
	# An intro-only stage is really "play the stage out".
	if gate == TutorialStepData.Gate.INTRO:
		gate = TutorialStepData.Gate.SERVED if not orders.is_empty() else TutorialStepData.Gate.SWAP_ANY

	var progress := 0
	var guard := 0
	var budget := maxi(24, stage.move_budget() * 3)

	if orders.is_empty():
		if gate == TutorialStepData.Gate.ACTIVATED_CROSS:
			var a := Vector2i(1,1)
			var b := Vector2i(2,1)
			return board.try_swap(a,b) == BoardState.SwapOutcome.ACTIVATED_SPECIAL and board.activate_specials([a,b]).combo == &"sweet_cross"
		if gate == TutorialStepData.Gate.ACTIVATED_SPECIAL:
			for step in stage.tutorial_steps:
				if step.gate in [TutorialStepData.Gate.CREATED_TAPAU, TutorialStepData.Gate.CREATED_DULANG, TutorialStepData.Gate.CREATED_HANTAR, TutorialStepData.Gate.CREATED_VERTICAL] and step.highlight.size() == 2:
					var a := step.highlight[0]
					var b := step.highlight[1]
					if board.try_swap(a, b) == BoardState.SwapOutcome.INVALID:
						return false
					var made := board.resolve([a, b])
					for entry in made.created:
						var pos: Vector2i = entry.pos
						for direction in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
							var neighbour: Vector2i = pos + direction
							if board.try_swap(pos, neighbour) == BoardState.SwapOutcome.ACTIVATED_SPECIAL:
								return not board.activate_specials([pos, neighbour]).activated.is_empty()
			return false
		return _play_lesson_board(board, gate, 12)

	while guard < budget:
		guard += 1
		var best: Dictionary = _choose_move(board, orders, index)

		if best.is_empty():
			break
		var a: Vector2i = best["a"]
		var b: Vector2i = best["b"]
		var outcome := board.try_swap(a, b)
		if outcome == BoardState.SwapOutcome.INVALID:
			continue

		# Gesture lessons are taught by the swap itself.
		if gate == TutorialStepData.Gate.SWAP_ANY:
			return true
		if gate == TutorialStepData.Gate.SWAP_VERTICAL and a.x == b.x:
			return true
		if gate == TutorialStepData.Gate.SWAP_HORIZONTAL and a.y == b.y:
			return true

		var result := board.activate_specials([a,b]) if outcome == BoardState.SwapOutcome.ACTIVATED_SPECIAL else board.resolve([a, b])
		var steps := 0
		while not result.is_empty() and steps < 40:
			steps += 1
			if gate == TutorialStepData.Gate.CREATED_TAPAU:
				if (_has_special(result, BoardCell.Special.TAPAU) or _has_special(result, BoardCell.Special.TAPAU_VERTICAL)):
					return true
			if gate == TutorialStepData.Gate.CREATED_DULANG:
				if _has_special(result, BoardCell.Special.DULANG):
					return true
			if gate == TutorialStepData.Gate.BLOCKER_OPENED:
				progress += _removed_count(result.blockers)
			var totals := result.collected_totals()
			# Collected kuih always feed the queue, whatever the gate is;
			# otherwise a SERVED stage could never complete.
			var filled := _fill_order(orders, index, totals)
			if gate == TutorialStepData.Gate.COLLECTED:
				progress += filled
			index = _first_unfinished(orders)
			board.apply_gravity()
			board.refill()
			result = board.resolve([])

		if gate == TutorialStepData.Gate.BLOCKER_OPENED and progress >= gate_value:
			return true
		if gate == TutorialStepData.Gate.COLLECTED and progress >= gate_value:
			return true
		if gate == TutorialStepData.Gate.SERVED and _cleared(orders):
			return true
		if not board.has_possible_move():
			board.shuffle_board()

	return false


## Stages that teach a gesture or a special have no customer order, so they are
## played purely for the lesson.
func _play_lesson_board(board: BoardState, gate: int, budget: int) -> bool:
	var empty_orders: Array[CustomerOrder] = []
	for guard in budget:
		var best: Dictionary = _choose_move(board, empty_orders, 0)
		if best.is_empty():
			break
		var a: Vector2i = best["a"]
		var b: Vector2i = best["b"]
		var outcome := board.try_swap(a, b)
		if outcome == BoardState.SwapOutcome.INVALID:
			continue
		if gate == TutorialStepData.Gate.SWAP_ANY:
			return true
		if gate == TutorialStepData.Gate.SWAP_VERTICAL and a.x == b.x:
			return true
		if gate == TutorialStepData.Gate.SWAP_HORIZONTAL and a.y == b.y:
			return true
		if outcome == BoardState.SwapOutcome.ACTIVATED_SPECIAL:
			var activation := board.activate_specials([a, b])
			if gate == TutorialStepData.Gate.ACTIVATED_SPECIAL and not activation.activated.is_empty():
				return true
		var result := board.resolve([a, b])
		if gate == TutorialStepData.Gate.ACTIVATED_SPECIAL and not result.created.is_empty():
			continue
		if gate == TutorialStepData.Gate.CREATED_TAPAU and (_has_special(result, BoardCell.Special.TAPAU) or _has_special(result, BoardCell.Special.TAPAU_VERTICAL)):
			return true
		if gate == TutorialStepData.Gate.CREATED_DULANG and _has_special(result, BoardCell.Special.DULANG):
			return true
		board.apply_gravity()
		board.refill()
		var cascade := board.resolve([])
		var steps := 0
		while not cascade.is_empty() and steps < 40:
			steps += 1
			if gate == TutorialStepData.Gate.CREATED_TAPAU and (_has_special(cascade, BoardCell.Special.TAPAU) or _has_special(cascade, BoardCell.Special.TAPAU_VERTICAL)):
				return true
			if gate == TutorialStepData.Gate.CREATED_DULANG and _has_special(cascade, BoardCell.Special.DULANG):
				return true
			board.apply_gravity()
			board.refill()
			cascade = board.resolve([])
		if not board.has_possible_move():
			board.shuffle_board()
	return false


func _has_special(result: BoardState.ClearResult, kind: int) -> bool:
	for entry in result.created:
		if int(entry["special"]) == kind:
			return true
	return false


func _removed_count(hits: Array) -> int:
	var removed := 0
	for hit in hits:
		if hit.removed:
			removed += 1
	return removed


## Applies collected kuih to the queue and reports how much of the *active*
## order it satisfied.
func _fill_order(orders: Array[CustomerOrder], index: int, totals: Dictionary) -> int:
	if orders.is_empty():
		return 0
	var order: CustomerOrder = orders[mini(index, orders.size() - 1)]
	var before := order.missing_total()
	var leftover := order.collect(totals)
	return maxi(0, before - order.missing_total()) + leftover.size() * 0


# --- balance harness -------------------------------------------------------

## Greedy player: always take the swap that collects the most kuih the current
## order still needs. Deliberately not a search - if a dumb strategy can win,
## a human definitely can.
func _simulate_all() -> Array[String]:
	var lines: Array[String] = []
	var total_wins := 0
	var total_runs := 0
	var trials := 16 if "--starter-only" in OS.get_cmdline_user_args() else 2 if "--quick-balance" in OS.get_cmdline_user_args() else TRIALS
	for id in range(1, 11 if "--starter-only" in OS.get_cmdline_user_args() else LevelLibrary.count() + 1):
		var level := LevelLibrary.get_level(id)
		var wins := 0
		var star_sum := 0
		var scores: Array[int] = []
		for trial in trials:
			var stars := _play(level, 1000 + trial * 7919)
			if stars > 0:
				scores.append(_last_score)
				wins += 1
				star_sum += stars
		total_wins += wins
		total_runs += trials
		var rate := 100.0 * float(wins) / float(trials)
		var effective := _effective_items(level)
		var per_move := float(effective) / float(maxi(1, level.move_budget()))
		var flag := "ok " if rate >= 70.0 else "!! "
		lines.append("stage %d final scores: %s" % [id, str(scores)])
		lines.append(
			"%sstage %2d  win %3d%%  Ã¢Ëœâ€¦%.1f  moves %2d  items %3d (%.2f/move)  blockers %d  %s" % [
				flag, id, int(rate),
				float(star_sum) / float(maxi(1, trials)),
				level.move_budget(),
				effective,
				per_move,
				_count_blockers(level),
				level.title,
			]
		)
	lines.append("")
	lines.append("overall greedy win rate: %d%%" % int(100.0 * float(total_wins) / float(total_runs)))
	return lines


func _count_blockers(level: LevelDefinition) -> int:
	var count := 0
	for spec in level.blockers:
		count += spec.cells.size()
	return count


## Order totals after the customer archetype's scale is applied.
func _effective_items(level: LevelDefinition) -> int:
	var total := 0
	for spec in level.customer_orders:
		total += CustomerOrder.from_spec(spec).required_total()
	return total


## Returns 0 for a loss, otherwise the star count.
func _play(level: LevelDefinition, seed_value: int) -> int:
	_last_score = 0
	var board := _make_board(level, seed_value)
	var orders: Array[CustomerOrder] = []
	for spec in level.customer_orders:
		orders.append(CustomerOrder.from_spec(spec))
	var index := 0
	var moves_left := level.move_budget()
	var scoring := StageScoreController.new()
	scoring.setup(level)
	var guard := 0

	while moves_left > 0 and guard < 400:
		guard += 1
		var best: Dictionary = _choose_move(board, orders, index)
		if best.is_empty():
			break
		var a: Vector2i = best["a"]
		var b: Vector2i = best["b"]
		var outcome := board.try_swap(a, b)
		if outcome == BoardState.SwapOutcome.INVALID:
			continue
		moves_left -= 1
		_apply(board, [a, b], orders, index, scoring, outcome)
		index = _first_unfinished(orders)

		if _cleared(orders) and (not level.require_blockers_cleared or board.remaining_blockers() == 0):
			var result := StageResultCalculator.calculate(true, scoring.total, moves_left, level)
			_last_score = result.final_score
			return result.earned_stars
	return 0


func _apply(board: BoardState, preferred: Array, orders: Array[CustomerOrder], index: int, scoring: StageScoreController, outcome: int) -> void:
	var result := board.activate_specials(preferred) if outcome == BoardState.SwapOutcome.ACTIVATED_SPECIAL else board.resolve(preferred)
	var guard := 0
	while not result.is_empty() and guard < 40:
		scoring.add_clear(result, guard)
		guard += 1
		var before := 0
		for order in orders:
			before += order.total_collected
		var totals := result.collected_totals()
		var i := index
		var leftover: Dictionary = totals
		while i < orders.size() and not leftover.is_empty():
			leftover = orders[i].collect(leftover)
			if not orders[i].is_complete():
				break
			i += 1
		var after := 0
		for order in orders:
			after += order.total_collected
		scoring.add_collection(after - before)
		board.apply_gravity()
		board.refill()
		result = board.resolve([])
	if not board.has_possible_move():
		board.shuffle_board()


func _choose_move(board: BoardState, orders: Array[CustomerOrder], index: int) -> Dictionary:
	var wanted: Dictionary = {}
	if index < orders.size():
		for id in orders[index].item_ids():
			wanted[id] = int(orders[index].remaining.get(id, 0))
	var best: Dictionary = {}
	var best_score := -1.0
	for pair in board.find_possible_moves(4096):
		var a: Vector2i = pair["a"]
		var b: Vector2i = pair["b"]
		var ca := board.get_cell(a)
		var cb := board.get_cell(b)
		if ca == null or cb == null:
			continue
		# Skip pointless identical swaps early.
		if ca.kuish_id() == cb.kuish_id() and ca.special == BoardCell.Special.NONE and cb.special == BoardCell.Special.NONE:
			continue
		var before := board.snapshot()
		var outcome := board.try_swap(a, b)
		if outcome == BoardState.SwapOutcome.INVALID:
			continue
		var result: BoardState.ClearResult = board.resolve([a, b]) if outcome == BoardState.SwapOutcome.PLAYED else board.activate_specials([a, b])
		var score := 0.0
		var totals := result.collected_totals()
		for id in totals:
			score += float(totals[id]) * (4.0 if wanted.has(id) else 1.0)
		score += float(result.cleared.size()) * 0.5
		score += float(result.blockers.size()) * 2.0
		for entry in result.targets:
			score += 3.0
		if not result.created.is_empty():
			score += 4.0
		_restore(board, before)
		if score > best_score:
			best_score = score
			best = {"a": a, "b": b}
	if best.is_empty():
		var fallback := board.find_possible_moves(1)
		if not fallback.is_empty():
			return fallback[0]
	return best


func _restore(board: BoardState, snapshot: Array) -> void:
	for y in board.height:
		for x in board.width:
			var cell := board.get_cell(Vector2i(x, y))
			var data: Dictionary = snapshot[y][x]
			cell.kuih = KuihLibrary.get_kuih(data["kuih"])
			cell.special = data["special"]
			cell.order_kuish = data["order_kuish"]
			cell.blocker_kind = data["blocker"]
			cell.blocker_hp = data["hp"]
			cell.target_kuish = data["target"]
			cell.target_progress = data["target_progress"]
			cell.target_need = data["target_need"]


func _first_unfinished(orders: Array[CustomerOrder]) -> int:
	for i in orders.size():
		if not orders[i].is_complete():
			return i
	return orders.size()


func _cleared(orders: Array[CustomerOrder]) -> bool:
	return _first_unfinished(orders) >= orders.size()


func _check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
