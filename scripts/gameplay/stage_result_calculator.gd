class_name StageResultCalculator
extends RefCounted

static func calculate(order_complete: bool, score: int, moves: int, level: LevelDefinition, first_clear: bool = false, previous_best: int = 0) -> StageResult:
	var result := StageResult.new()
	result.success = order_complete
	result.final_score = maxi(0, score)
	result.previous_best = maxi(0, previous_best)
	if not order_complete:
		return result
	result.move_bonus = maxi(0, moves) * maxi(0, level.scoring.remaining_move)
	result.final_score += result.move_bonus
	result.earned_stars = level.stars_for_score(result.final_score)
	result.base_coins = maxi(0, level.coin_reward())
	result.score_bonus = int(result.final_score / maxi(1, level.score_per_coin))
	result.star_bonus = maxi(0, level.star_coin_bonus[result.earned_stars]) if level.star_coin_bonus.size() > result.earned_stars else 0
	result.first_clear_bonus = maxi(0, level.first_clear_bonus) if first_clear else 0
	result.total_coins = result.base_coins + result.score_bonus + result.star_bonus + result.first_clear_bonus
	result.is_new_best = result.final_score > result.previous_best
	return result
