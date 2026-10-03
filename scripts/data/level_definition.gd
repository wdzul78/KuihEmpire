class_name LevelDefinition
extends Resource

## Data-driven description of one puzzle stage.
##
## Levels are authored in `scripts/levels/level_library.gd` and can be exported
## to `resources/levels/level_XXX.tres` via [method export_all] for the level
## editor / hand tuning (Master Plan sections 57 and 58).

@export var id: int = 1
@export var chapter_id: StringName = &"prologue"
@export var title: String = ""
@export_multiline var subtitle: String = ""

@export_group("Board")
@export var width: int = 8
@export var height: int = 8
@export var moves: int = 20
## Tile types that can appear on this board.
@export var kuih: Array[KuihData] = []
## Authored board, row-major Array[Array] of kuih ids. Empty means "generate one".
## Tutorial stages use this so each lesson has exactly one intended answer.
@export var fixed_layout: Array = []

@export_group("Objective")
@export var customer_orders: Array[CustomerOrderSpec] = []
@export var blockers: Array[BlockerSpec] = []
## When true the level is not won by finishing orders alone - every blocker
## must be cleaned too.
@export var require_blockers_cleared: bool = false

@export_group("Reward")
@export var coins: int = 60
## Fraction of moves that must remain for 2 and 3 stars. Generous on purpose -
## the plan asks for a cozy game, not a punishing one.
@export_range(0.0, 0.95, 0.01) var star2_moves: float = 0.25
@export_range(0.0, 0.95, 0.01) var star3_moves: float = 0.5

@export_group("Presentation")
@export var background_id: StringName = &"stall_dawn"
## Tutorial beats shown one after another before the first move.
@export var tutorial: Array[StringName] = []
## Story beats played before / after the puzzle.
@export var story_before: StringName = &""
@export var story_after: StringName = &""
## Kuih unlocked once this level is cleared.
@export var kuih_unlock: StringName = &""
@export var recipe_unlock: StringName = &""

@export_group("Difficulty")
@export_range(1, 5, 1) var difficulty: int = 1
@export var tag: String = ""

@export_group("Tutorial")
## 0 for campaign stages, 1-based for tutorial stages.
@export var tutorial_index: int = 0
## Tutorial stages cannot be failed - the plan wants onboarding to be cozy.
@export var allow_fail: bool = true
## Tutorial stages always award three stars because there is no move pressure.
@export var always_three_stars: bool = false
## Coaching steps, one idea each.
@export var tutorial_steps: Array[TutorialStepData] = []


func is_tutorial() -> bool:
	return tutorial_index > 0


func total_order_items() -> int:
	var total := 0
	for order in customer_orders:
		total += order.total_items()
	return total


func move_budget() -> int:
	var budget := moves
	for order in customer_orders:
		if order.customer != null:
			budget += order.customer.move_bonus
	return budget


func stars_for_moves_left(left: int) -> int:
	var budget := move_budget()
	if budget <= 0:
		return 1
	var ratio := float(left) / float(budget)
	if ratio >= star3_moves:
		return 3
	if ratio >= star2_moves:
		return 2
	return 1


func coin_reward() -> int:
	var total := coins
	for order in customer_orders:
		if order.customer != null:
			total = int(round(total * order.customer.reward_scale))
	return total


func uses_kuih(kuih_id: StringName) -> bool:
	for k in kuih:
		if k.id == kuih_id:
			return true
	return false
