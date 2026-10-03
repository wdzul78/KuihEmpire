class_name TutorialLibrary
extends RefCounted

## The eight tutorial stages.
##
## These sit **outside** the 30-stage campaign: the plan's campaign numbering and
## its measured balance stay untouched, and the tutorial is its own short flow
## with its own progress flag.
##
## Design follows what the genre actually does for onboarding - one idea per
## beat, a scripted board so the lesson is deterministic, no fail state early on
## - while honouring the request to start on a 3x3 board and grow.
##
##   T1  3x3  swipe vertically
##   T2  3x3  swipe horizontally
##   T3  3x3  a real customer order, then SERVE
##   T4  4x4  match four makes a Tapau Pack
##   T5  5x5  an L or T makes a Dulang
##   T6  6x6  daun pisang covers some kuih
##   T7  7x7  steamer plus a second customer in the queue
##   T8  8x8  the full board, the real thing
##
## T1, T2, T4 and T5 use hand-authored layouts whose solution is verified by the
## test harness. A 3x3 random fill is often unsolvable, so this is required, not
## a nicety.

const TUTORIAL_COUNT := 8

const A := &"onde_onde"
const B := &"kuih_lapis"
const C := &"seri_muka"
const D := &"kuih_ketayap"

static var _cache: Dictionary = {}


static func count() -> int:
	return TUTORIAL_COUNT


static func has(index: int) -> bool:
	return index >= 1 and index <= TUTORIAL_COUNT


static func get_stage(index: int) -> LevelDefinition:
	if _cache.has(index):
		return _cache[index]
	var stage := _build(index)
	_cache[index] = stage
	return stage


static func all() -> Array[LevelDefinition]:
	var out: Array[LevelDefinition] = []
	for i in range(1, TUTORIAL_COUNT + 1):
		out.append(get_stage(i))
	return out


# --- helpers ---------------------------------------------------------------

static func _make(
	index: int,
	title: String,
	size: int,
	kuih_ids: Array,
	layout: Array,
	moves: int,
	orders: Array,
	blockers: Array,
	steps: Array[TutorialStepData]
) -> LevelDefinition:
	var level := LevelDefinition.new()
	level.tutorial_index = index
	level.id = -index
	level.title = title
	level.width = size
	level.height = size
	level.moves = moves
	level.background_id = &"stall_dawn"
	level.tag = "Tutorial"
	level.difficulty = 1
	# Nothing in the tutorial can be lost.
	level.allow_fail = false
	level.always_three_stars = true
	level.fixed_layout = layout
	for id in kuih_ids:
		var kuih := KuihLibrary.get_kuih(id)
		if kuih != null:
			level.kuih.append(kuih)
	for entry in orders:
		var customer_id: StringName = entry[0]
		var items: Array = entry[1]
		var order_items: Array[OrderItem] = []
		for item in items:
			var kuih := KuihLibrary.get_kuih(item[0])
			if kuih == null:
				continue
			order_items.append(OrderItem.make(kuih, int(item[1])))
		var customer := CustomerLibrary.get_customer(customer_id)
		if customer != null and not order_items.is_empty():
			level.customer_orders.append(CustomerOrderSpec.make(customer, order_items))
	for spec in blockers:
		level.blockers.append(spec)
	for step in steps:
		level.tutorial_steps.append(step)
	return level


static func _step(
	title: String,
	body: String,
	gate: TutorialStepData.Gate,
	gate_value: int = 0,
	nudge: String = ""
) -> TutorialStepData:
	return TutorialStepData.make(title, body, gate, gate_value, nudge)


static func _step_here(
	title: String,
	body: String,
	gate: TutorialStepData.Gate,
	cells: Array,
	nudge: String = ""
) -> TutorialStepData:
	var step := TutorialStepData.make(title, body, gate, 0, nudge)
	for cell in cells:
		step.highlight.append(cell)
	return step


# --- the eight stages ------------------------------------------------------

static func _build(index: int) -> LevelDefinition:
	match index:

		1:
			# Verified by tools/find_layout.gd: clean board, exactly one legal
			# move, and that move is vertical.
			return _make(1, "Swipe Up and Down", 3, [A, B, C], [
				[A, A, B],
				[C, B, B],
				[B, A, C],
			], 0, [], [],
			[
				_step_here(
					"Let's start small",
					"This is the whole tray today.\nSlide one kuih up or down until three of a kind line up.",
					TutorialStepData.Gate.SWAP_VERTICAL,
					[Vector2i(0, 1), Vector2i(0, 2)]
				),
			])

		2:
			# Verified: clean board, exactly one legal move, and it is horizontal.
			return _make(2, "Swipe Left and Right", 3, [A, B, C], [
				[A, A, C],
				[B, A, C],
				[B, C, B],
			], 0, [], [],
			[
				_step_here(
					"Now the other way",
					"Easy peasy - slide one kuih left or right this time.",
					TutorialStepData.Gate.SWAP_HORIZONTAL,
					[Vector2i(1, 2), Vector2i(2, 2)]
				),
			])

		3:
			# Fixed layout too, so the very first real order is deterministic as
			# well. Verified clean with a reachable onde-onde match.
			return _make(3, "Your First Customer", 3, [A, B, C], [
				[C, C, B],
				[C, C, A],
				[A, A, B],
			], 0,
				[[&"pakyai", [[A, 3]]]], [],
			[
				_step(
					"Someone is waiting",
					"Pakyai wants 3 Onde-onde.\nMatch any three Onde-onde and they go on his tray.",
					TutorialStepData.Gate.INTRO
				),
				_step_here(
					"Collect 3 Onde-onde",
					"Tap a kuih then tap its neighbour if you prefer - either way works.",
					TutorialStepData.Gate.COLLECTED,
					[Vector2i(2, 1), Vector2i(2, 2)]
				),
				_step(
					"Serve!",
					"The order is complete, so Pakyai gets his kuih.",
					TutorialStepData.Gate.INTRO
				),
			])

		4:
			# Verified: swapping (1,1)<->(1,2) drops the fourth onde-onde into
			# column 1, which builds a Tapau Pack.
			return _make(4, "Four In A Row", 4, [A, B, C, D], [
				[A, D, B, A],
				[B, C, B, C],
				[C, A, C, C],
				[B, C, A, A],
			], 0, [], [],
			[
				_step(
					"Four is special",
					"Line up FOUR of a kind and they wrap themselves in a tapau pack.",
					TutorialStepData.Gate.INTRO
				),
				_step_here(
					"Make a Tapau Pack",
					"A tapau pack clears a whole row and column when it fires.",
					TutorialStepData.Gate.CREATED_TAPAU,
					[Vector2i(1, 1), Vector2i(1, 2)]
				),
			])

		5:
			# Verified: swapping (3,0)<->(3,1) builds an L, which makes a Dulang.
			return _make(5, "L and T Shapes", 5, [A, B, C, D], [
				[A, C, A, B, C],
				[C, C, B, A, B],
				[D, D, C, B, D],
				[A, B, A, B, C],
				[B, B, A, D, A],
			], 0, [], [],
			[
				_step(
					"Bend the line",
					"Match an L or a T shape and you get a dulang instead.",
					TutorialStepData.Gate.INTRO
				),
				_step_here(
					"Make a Dulang",
					"A dulang scoops up a 3 x 3 patch of kuih.",
					TutorialStepData.Gate.CREATED_DULANG,
					[Vector2i(3, 0), Vector2i(3, 1)]
				),
			])

		6:
			return _make(6, "Under The Leaf", 6, [A, B, C, D], [], 0,
				[[&"abang", [[A, 6]]]],
				[
					BlockerSpec.make(BlockerSpec.Kind.BANANA_LEAF, [
						Vector2i(1, 1), Vector2i(4, 1),
						Vector2i(1, 4), Vector2i(4, 4),
					], 1)
				],
			[
				_step(
					"Covered in daun pisang",
					"Some kuih are under a banana leaf so they stay fresh.",
					TutorialStepData.Gate.INTRO
				),
				_step(
					"Lift the leaves",
					"Match right next to a leaf and the wind lifts it off.",
					TutorialStepData.Gate.BLOCKER_OPENED,
					4
				),
			])

		7:
			return _make(7, "The Steamer And The Queue", 7, [A, B, C, D], [], 0,
				[
					[&"pakyai", [[A, 8]]],
					[&"tourist", [[B, 8]]],
				],
				[BlockerSpec.make(BlockerSpec.Kind.STEAMER, [
					Vector2i(2, 2), Vector2i(4, 4), Vector2i(5, 1), Vector2i(1, 5),
				], 1)],
			[
				_step(
					"Steaming hot",
					"Kuih in a steamer opens the same way - match beside the basket.",
					TutorialStepData.Gate.INTRO
				),
				_step(
					"Open the steamers",
					"Four baskets to lift.",
					TutorialStepData.Gate.BLOCKER_OPENED,
					4
				),
				_step(
					"Two guests waiting",
					"Finish this order and the next guest steps up to the counter.",
					TutorialStepData.Gate.INTRO
				),
				_step(
					"Serve the queue",
					"Surplus kuih carries over, so a big match helps the next guest too.",
					TutorialStepData.Gate.SERVED
				),
			])

		8:
			return _make(8, "The Real Tray", 8, [A, B, C, D, &"ang_ku_kueh", &"vadai"], [], 20,
				[[&"makcik", [[A, 8], [C, 8]]]], [],
			[
				_step(
					"Here is the whole stall",
					"Eight by eight now, five kinds of kuih, and a proper order.",
					TutorialStepData.Gate.INTRO
				),
				_step(
					"Makcik's regular order",
					"8 Onde-onde and 8 Seri Muka. Take your time - nothing here can be lost.",
					TutorialStepData.Gate.INTRO
				),
				_step(
					"Serve and you are ready",
					"Fill the order and the tutorial is done. The real game starts next.",
					TutorialStepData.Gate.SERVED
				),
			])

	return _make(maxi(1, index), "Tutorial", 3, [A, B], [], 0, [], [], [])