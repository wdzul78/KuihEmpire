extends SceneTree

## Headless smoke test + balance harness (Master Plan sections 61 and 76).
##
## Run with:
##   godot --headless --script res://tools/test_runner.gd
##
## It drives [BoardState] directly - no view, no tweens - so it can play all 30
## MVP stages thousands of times and report win rates. Any stage that a greedy
## player cannot clear is a balance bug, not a player bug.

const TRIALS := 8

var failures: Array[String] = []


func _initialize() -> void:
	var start := Time.get_ticks_msec()
	_test_board_invariants()
	_test_specials()
	_test_blockers()
	_test_tutorial_layouts()
	_print_tutorial_report()
	var report := _simulate_all()
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
	quit(0 if failures.is_empty() else 1)


# --- unit style checks -----------------------------------------------------

func _make_board(level: LevelDefinition, seed_value: int) -> BoardState:
	var board := BoardState.new()
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
	return board


func _test_board_invariants() -> void:
	var level := LevelLibrary.get_level(18)
	var board := _make_board(level, 12345)

	for attempt in 40:
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
	# A single horizontal run of four must become a Tapau Pack.
	var board := _force_board([
		[&"onde_onde", &"onde_onde", &"onde_onde", &"onde_onde", &"ang_ku_kueh"],
		[&"kuih_ketayap", &"seri_muka", &"vadai", &"kuih_lapis", &"seri_muka"],
		[&"seri_muka", &"ang_ku_kueh", &"kuih_ketayap", &"vadai", &"kuih_lapis"],
		[&"vadai", &"kuih_lapis", &"seri_muka", &"ang_ku_kueh", &"kuih_ketayap"],
	])
	var groups := board.find_matches()
	_check(groups.size() == 1, "expected exactly one match group, found %d" % groups.size())
	if not groups.is_empty():
		_check(
			groups[0].special == BoardCell.Special.TAPAU,
			"match-4 produced special %d instead of TAPAU" % groups[0].special
		)

	# Fire a Tapau on a pristine board: it must wipe its row and its column.
	var firing := _force_board([
		[&"onde_onde", &"kuih_lapis", &"seri_muka", &"vadai", &"kuih_ketayap"],
		[&"vadai", &"kuih_ketayap", &"onde_onde", &"kuih_lapis", &"seri_muka"],
		[&"seri_muka", &"vadai", &"kuih_ketayap", &"onde_onde", &"kuih_lapis"],
		[&"kuih_lapis", &"seri_muka", &"vadai", &"kuih_ketayap", &"onde_onde"],
	])
	var trigger := Vector2i(2, 2)
	firing.get_cell(trigger).special = BoardCell.Special.TAPAU
	var fired := firing.activate_specials([trigger])
	var expected := firing.width + firing.height - 1
	_check(
		fired.cleared.size() == expected,
		"Tapau cleared %d tiles, expected %d" % [fired.cleared.size(), expected]
	)

	# An L shape must become a Dulang that clears 3x3.
	var lshape := _force_board([
		[&"onde_onde", &"onde_onde", &"onde_onde", &"seri_muka", &"kuih_lapis"],
		[&"kuih_lapis", &"kuih_ketayap", &"onde_onde", &"vadai", &"seri_muka"],
		[&"kuih_ketayap", &"vadai", &"onde_onde", &"seri_muka", &"kuih_ketayap"],
		[&"vadai", &"seri_muka", &"kuih_lapis", &"kuih_ketayap", &"onde_onde"],
		[&"seri_muka", &"kuih_ketayap", &"vadai", &"onde_onde", &"kuih_lapis"],
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
		[&"vadai", &"vadai", &"vadai", &"vadai", &"vadai"],
		[&"kuih_lapis", &"seri_muka", &"kuih_ketayap", &"ang_ku_kueh", &"onde_onde"],
		[&"seri_muka", &"kuih_ketayap", &"ang_ku_kueh", &"onde_onde", &"kuih_lapis"],
		[&"kuih_ketayap", &"ang_ku_kueh", &"onde_onde", &"kuih_lapis", &"seri_muka"],
	])
	var order_ok := false
	for group in five.find_matches():
		if group.special == BoardCell.Special.ORDER:
			order_ok = true
	_check(order_ok, "five in a row did not create a Special Order")
	print("special tiles ............ ok")


func _force_board(rows: Array) -> BoardState:
	var pool: Array[KuihData] = [
		KuihLibrary.get_kuih(&"onde_onde"),
		KuihLibrary.get_kuih(&"kuih_lapis"),
		KuihLibrary.get_kuih(&"seri_muka"),
		KuihLibrary.get_kuih(&"kuih_ketayap"),
		KuihLibrary.get_kuih(&"ang_ku_kueh"),
		KuihLibrary.get_kuih(&"vadai"),
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
	}

	for index in range(1, TutorialLibrary.count() + 1):
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
		_check(stage.always_three_stars, "tutorial %d: must always award three stars" % index)
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
	for index in range(1, TutorialLibrary.count() + 1):
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
		TutorialStepData.Gate.BLOCKER_OPENED: "open covers",
		TutorialStepData.Gate.COLLECTED: "collect",
		TutorialStepData.Gate.SERVED: "serve",
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
		return _play_lesson_board(board, gate, 12)

	while guard < budget:
		guard += 1
		var best: Dictionary = _choose_move(board, orders, index)

		if best.is_empty():
			break
		var a: Vector2i = best["a"]
		var b: Vector2i = best["b"]
		if board.try_swap(a, b) == BoardState.SwapOutcome.INVALID:
			continue

		# Gesture lessons are taught by the swap itself.
		if gate == TutorialStepData.Gate.SWAP_ANY:
			return true
		if gate == TutorialStepData.Gate.SWAP_VERTICAL and a.x == b.x:
			return true
		if gate == TutorialStepData.Gate.SWAP_HORIZONTAL and a.y == b.y:
			return true

		var result := board.resolve([a, b])
		var steps := 0
		while not result.is_empty() and steps < 40:
			steps += 1
			if gate == TutorialStepData.Gate.CREATED_TAPAU:
				if _has_special(result, BoardCell.Special.TAPAU):
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
		if board.try_swap(a, b) == BoardState.SwapOutcome.INVALID:
			continue
		if gate == TutorialStepData.Gate.SWAP_ANY:
			return true
		if gate == TutorialStepData.Gate.SWAP_VERTICAL and a.x == b.x:
			return true
		if gate == TutorialStepData.Gate.SWAP_HORIZONTAL and a.y == b.y:
			return true
		var result := board.resolve([a, b])
		if gate == TutorialStepData.Gate.CREATED_TAPAU and _has_special(result, BoardCell.Special.TAPAU):
			return true
		if gate == TutorialStepData.Gate.CREATED_DULANG and _has_special(result, BoardCell.Special.DULANG):
			return true
		board.apply_gravity()
		board.refill()
		var cascade := board.resolve([])
		var steps := 0
		while not cascade.is_empty() and steps < 40:
			steps += 1
			if gate == TutorialStepData.Gate.CREATED_TAPAU and _has_special(cascade, BoardCell.Special.TAPAU):
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
	for id in range(1, LevelLibrary.count() + 1):
		var level := LevelLibrary.get_level(id)
		var wins := 0
		var star_sum := 0
		for trial in TRIALS:
			var stars := _play(level, 1000 + trial * 7919)
			if stars > 0:
				wins += 1
				star_sum += stars
		total_wins += wins
		total_runs += TRIALS
		var rate := 100.0 * float(wins) / float(TRIALS)
		var effective := _effective_items(level)
		var per_move := float(effective) / float(maxi(1, level.move_budget()))
		var flag := "ok " if rate >= 70.0 else "!! "
		lines.append(
			"%sstage %2d  win %3d%%  ★%.1f  moves %2d  items %3d (%.2f/move)  blockers %d  %s" % [
				flag, id, int(rate),
				float(star_sum) / float(maxi(1, TRIALS)),
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
	var board := _make_board(level, seed_value)
	var orders: Array[CustomerOrder] = []
	for spec in level.customer_orders:
		orders.append(CustomerOrder.from_spec(spec))
	var index := 0
	var moves_left := level.move_budget()
	var guard := 0

	while moves_left > 0 and guard < 400:
		guard += 1
		var best: Dictionary = _choose_move(board, orders, index)
		if best.is_empty():
			break
		var a: Vector2i = best["a"]
		var b: Vector2i = best["b"]
		if board.try_swap(a, b) == BoardState.SwapOutcome.INVALID:
			continue
		moves_left -= 1
		_apply(board, [a, b], orders, index)
		index = _first_unfinished(orders)

		if _cleared(orders) and (not level.require_blockers_cleared or board.remaining_blockers() == 0):
			return level.stars_for_moves_left(moves_left)
	return 0


func _apply(board: BoardState, preferred: Array, orders: Array[CustomerOrder], index: int) -> void:
	var result := board.resolve(preferred)
	var guard := 0
	while not result.is_empty() and guard < 40:
		guard += 1
		var totals := result.collected_totals()
		var i := index
		var leftover: Dictionary = totals
		while i < orders.size() and not leftover.is_empty():
			leftover = orders[i].collect(leftover)
			if not orders[i].is_complete():
				break
			i += 1
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
