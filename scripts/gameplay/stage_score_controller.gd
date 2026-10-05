class_name StageScoreController
extends RefCounted

signal score_changed(total: int)
signal feedback(points: int, cascade: int, multiplier: float)
var total := 0
var rules: ScoreRules

func setup(level: LevelDefinition) -> void:
	rules = level.scoring
	total = 0
	score_changed.emit(total)

func add_clear(result: BoardState.ClearResult, cascade: int) -> int:
	var counted: Dictionary = result.cleared.duplicate()
	var bonus := 0
	for run in result.match_runs:
		for pos in run.cells:
			counted[pos] = true
		var count := run.cells.size()
		var reward := rules.match_five if count >= 5 else rules.match_four if count == 4 else rules.match_three
		bonus += maxi(0, reward - count * rules.points_per_kuih)
	var base := counted.size() * rules.points_per_kuih + bonus
	base += result.activated.size() * rules.special_activation
	if result.activated.size() >= 2:
		base += rules.special_combo
	var multiplier := minf(maxf(1, rules.cascade_max), 1.0 + maxi(0, cascade) * maxf(0, rules.cascade_step))
	var gained := maxi(0, int(round(base * multiplier)))
	add_points(gained)
	if gained > 0:
		feedback.emit(gained, cascade, multiplier)
	return gained

func add_collection(count: int) -> void:
	add_points(maxi(0, count) * maxi(0, rules.order_item))

func add_points(points: int) -> void:
	if points <= 0:
		return
	total += points
	score_changed.emit(total)
