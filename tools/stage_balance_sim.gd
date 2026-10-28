extends Node

## Headless difficulty probe for campaign stages 1-30.
##
## Plays every stage with two simple bots on the real BoardState rules and prints
## win rate and average moves left. "careful" ranks every legal swap by order
## value, blocker pressure and specials; "casual" takes a random legal swap 40%
## of the time, which is closer to a new player on a phone.
## Run: godot --headless --path . res://tools/stage_balance_sim_scene.tscn [-- --runs=40]

const CASUAL_RANDOM := .4

var runs := 40
var first := 1
var last := 30

func _ready() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--runs="):
			runs = int(arg.trim_prefix("--runs="))
		elif arg.begins_with("--stages="):
			var span := arg.trim_prefix("--stages=").split("-")
			first = int(span[0])
			last = int(span[-1])
	print("stage | moves | careful win% left | casual win% left")
	for id in range(first, last + 1):
		var level := LevelLibrary.get_level(id)
		var careful := _play_many(level, false)
		var casual := _play_many(level, true)
		print("%5d | %5d | %8.0f%% %5.1f | %7.0f%% %5.1f" % [id, level.move_budget(), careful.x * 100.0, careful.y, casual.x * 100.0, casual.y])
	get_tree().quit()

func _play_many(level: LevelDefinition, casual: bool) -> Vector2:
	var wins := 0
	var left_total := 0
	for i in runs:
		var left := _play(level, casual, 7919 * (i + 1) + level.id)
		if left >= 0:
			wins += 1
			left_total += left
	return Vector2(float(wins) / runs, float(left_total) / maxi(1, wins))

## Returns moves left on a win, -1 on a loss.
func _play(level: LevelDefinition, casual: bool, seed_value: int) -> int:
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
			var leftover := result.collected_totals()
			while active < orders.size() and not leftover.is_empty():
				leftover = orders[active].collect(leftover)
				if not orders[active].is_complete():
					break
				active += 1
			logic.apply_gravity()
			logic.refill()
		if active >= orders.size() and (not level.require_blockers_cleared or logic.remaining_blockers() == 0):
			return moves
	return -1

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
