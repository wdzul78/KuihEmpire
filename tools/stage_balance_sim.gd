extends Node

## Headless difficulty probe for campaign stages. Split long runs with --stages=31-40.
##
## Plays every stage with two simple bots on the real BoardState rules and prints
## win rate and average moves left. "careful" ranks every legal swap by order
## value, blocker pressure and specials; "casual" takes a random legal swap 40%
## of the time, which is closer to a new player on a phone.
## Run: godot --headless --path . res://tools/stage_balance_sim_scene.tscn [-- --runs=40]

const CASUAL_RANDOM := .4

var runs := 40
var _scores: Array[int] = []
var first := 1
var last := LevelLibrary.count()
## Use a new offset to check tuning on boards it was not tuned against.
var seed_offset := 0
var _lost_on_orders := 0
var _lost_on_blockers := 0

func _ready() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--runs="):
			runs = int(arg.trim_prefix("--runs="))
		elif arg.begins_with("--stages="):
			var span := arg.trim_prefix("--stages=").split("-")
			first = int(span[0])
			last = int(span[-1])
		elif arg.begins_with("--seed-offset="):
			seed_offset = int(arg.trim_prefix("--seed-offset="))
	print("stage | moves | careful win% left 3star% | casual win% left 3star% | 2star/3star target | careful p40/p60 score | losses on orders/only blockers")
	for id in range(first, last + 1):
		var level := LevelLibrary.get_level(id)
		_scores.clear()
		_lost_on_orders = 0
		_lost_on_blockers = 0
		var careful := _play_many(level, false)
		var careful_scores := _scores.duplicate()
		var casual := _play_many(level, true)
		_scores = careful_scores
		print("%5d | %5d | %8.0f%% %5.1f %5.0f%% | %7.0f%% %5.1f %5.0f%% | %d/%d | %d/%d | %d/%d" % [id, level.move_budget(), careful.x * 100.0, careful.y, careful.z * 100.0, casual.x * 100.0, casual.y, casual.z * 100.0, level.score_two_star, level.score_three_star, _percentile(.4), _percentile(.6), _lost_on_orders, _lost_on_blockers])
	get_tree().quit()

## Win rate, average moves left on wins, and three-star rate over all runs.
func _play_many(level: LevelDefinition, casual: bool) -> Vector3:
	var wins := 0
	var left_total := 0
	var three := 0
	for i in runs:
		var outcome := _play(level, casual, 7919 * (i + 1) + level.id + seed_offset)
		if outcome.x >= 0:
			wins += 1
			left_total += outcome.x
			_scores.append(outcome.y)
			if level.stars_for_score(outcome.y) >= 3:
				three += 1
	return Vector3(float(wins) / runs, float(left_total) / maxi(1, wins), float(three) / runs)

## Returns (moves left, final score) on a win, (-1, 0) on a loss. The score is a
## lower bound: the end-of-stage special fireworks are not simulated.
func _play(level: LevelDefinition, casual: bool, seed_value: int) -> Vector2i:
	var score := StageScoreController.new()
	score.setup(level)
	var logic := BoardState.new()
	logic.delivery_enabled = true
	logic.setup(level.width, level.height, level.kuih, seed_value)
	logic.apply_blockers(level.blockers)
	if not logic.has_possible_move():
		logic.shuffle_board()
	var orders: Array[CustomerOrder] = []
	for spec in level.customer_orders:
		orders.append(CustomerOrder.from_spec(spec))
	var active := 0
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var moves := level.move_budget()
	while moves > 0:
		var needed: Dictionary = orders[active].remaining if active < orders.size() else {}
		logic.order_remaining = needed.duplicate()
		var options := logic.find_possible_moves(200)
		if options.is_empty():
			logic.shuffle_board()
			continue
		var pick: Dictionary = options[rng.randi_range(0, options.size() - 1)]
		if not (casual and rng.randf() < CASUAL_RANDOM):
			var best := -1.0
			for option in options:
				var value := _rate(logic, option.a, option.b, needed) + rng.randf() * .5
				if value > best:
					best = value
					pick = option
		var outcome := logic.try_swap(pick.a, pick.b)
		if outcome == BoardState.SwapOutcome.INVALID:
			continue
		moves -= 1
		var specials: Array = [] if outcome == BoardState.SwapOutcome.PLAYED else [pick.a, pick.b]
		var preferred: Array = [pick.a, pick.b]
		for step in 40:
			var result: BoardState.ClearResult = logic.resolve(preferred) if specials.is_empty() else logic.activate_specials(specials)
			specials = []
			preferred = []
			if result.is_empty():
				break
			score.add_clear(result, step)
			var leftover := result.collected_totals()
			var served_before := _served(orders)
			while active < orders.size() and not leftover.is_empty():
				leftover = orders[active].collect(leftover)
				if not orders[active].is_complete():
					break
				active += 1
			score.add_collection(_served(orders) - served_before)
			logic.apply_gravity()
			logic.refill()
		if active >= orders.size() and level.board_goals_met(logic):
			return Vector2i(moves, score.total + moves * level.scoring.remaining_move)
	if active < orders.size():
		_lost_on_orders += 1
	else:
		_lost_on_blockers += 1
	return Vector2i(-1, 0)

func _percentile(at: float) -> int:
	if _scores.is_empty():
		return 0
	var sorted := _scores.duplicate()
	sorted.sort()
	return sorted[clampi(int(at * sorted.size()), 0, sorted.size() - 1)]

func _served(orders: Array[CustomerOrder]) -> int:
	var total := 0
	for order in orders:
		total += order.total_collected
	return total

func _rate(logic: BoardState, a: Vector2i, b: Vector2i, needed: Dictionary) -> float:
	var ca := logic.get_cell(a)
	var cb := logic.get_cell(b)
	if ca.special != BoardCell.Special.NONE or cb.special != BoardCell.Special.NONE:
		return 12.0 + (8.0 if ca.special != BoardCell.Special.NONE and cb.special != BoardCell.Special.NONE else 0.0)
	logic.swap_cells(a, b)
	var value := 0.0
	var blockers: Dictionary = {}
	for group in logic.find_matches([a, b]):
		value += 6.0 if group.special != BoardCell.Special.NONE else 0.0
		for pos in group.cells:
			var id := logic.get_cell(pos).kuish_id()
			value += 3.0 if int(needed.get(id, 0)) > 0 else .5
			if logic.get_cell(pos).has_obstacle():
				blockers[pos] = true
			for dir in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
				var near := logic.get_cell(pos + dir)
				if near != null and (near.has_obstacle() or near.is_target()):
					blockers[pos + dir] = true
	logic.swap_cells(a, b)
	return value + blockers.size() * 2.0
