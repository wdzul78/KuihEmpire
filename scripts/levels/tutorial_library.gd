class_name TutorialLibrary
extends RefCounted

## Ten active lessons, with stable historical IDs for saved progress.
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
##   T4  4x4  match four makes Tapau
##   T5  5x5  an L or T makes a Dulang
##   T6  deferred: banana leaf is introduced in campaign Stage 7 instead
##   T7  7x7  a second customer in the queue
##   T8  8x8  the full board, the real thing
##   T9  4x4  create and activate a 2x2 Pesanan Hantar; unlock for campaign
##   T10 4x4  create and activate a vertical Tapau
##   T11 4x4  combine two directionals for a cross
## Display order: T1, T2, T3, T4, T10, T11, T9, T5, T7, T8.
##
## T1, T2, T4 and T5 use hand-authored layouts whose solution is verified by the
## test harness. A 3x3 random fill is often unsolvable, so this is required, not
## a nicety.

const TUTORIAL_COUNT := 11 # Highest stable save ID, not the displayed lesson count.
const ACTIVE_LESSONS := [1, 2, 3, 4, 10, 11, 9, 5, 7, 8]

static func resume_index(index: int) -> int:
	return 7 if index == 6 else index

static func next_index(index: int) -> int:
	var position := ACTIVE_LESSONS.find(resume_index(index))
	return ACTIVE_LESSONS[position + 1] if position >= 0 and position + 1 < ACTIVE_LESSONS.size() else 0

static func lesson_number(index: int) -> int:
	return ACTIVE_LESSONS.find(resume_index(index)) + 1

static func is_last(index: int) -> bool:
	# Older players who finished onboarding need only the missing delivery lesson.
	return index == ACTIVE_LESSONS.back() or (index == 9 and ProgressionManager.tutorial_done())

const A := &"onde_onde"
const B := &"kuih_koci"
const C := &"ang_ku_kueh"
const D := &"kuih_ketayap"

static var _cache: Dictionary = {}


static func count() -> int:
	return TUTORIAL_COUNT


static func has(index: int) -> bool:
	return index in ACTIVE_LESSONS


static func get_stage(index: int) -> LevelDefinition:
	index = resume_index(index)
	if _cache.has(index):
		return _cache[index]
	var stage := _build(index)
	_cache[index] = stage
	return stage


static func all() -> Array[LevelDefinition]:
	var out: Array[LevelDefinition] = []
	for i in ACTIVE_LESSONS:
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
	level.always_three_stars = false
	var targets: Dictionary = {1: [20, 30], 2: [20, 30], 3: [45, 75], 4: [140, 220], 5: [180, 300], 6: [100, 180], 7: [450, 850], 8: [700, 1200], 9: [40, 80], 10: [140, 220], 11: [140, 220]}
	level.score_two_star = targets[index][0]
	level.score_three_star = targets[index][1]
	level.scoring.remaining_move = 0
	level.first_clear_bonus = 0
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
	nudge: String = "",
	gate_value: int = 0
) -> TutorialStepData:
	var step := TutorialStepData.make(title, body, gate, gate_value, nudge)
	for cell in cells:
		step.highlight.append(cell)
	return step


# --- the lessons ------------------------------------------------------

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
					"Slide one kuih up or down until three of a kind line up.",
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
					[Vector2i(2, 1), Vector2i(2, 2)], "", 3
				),
				_step(
					"Serve!",
					"The order is complete, so Pakyai gets his kuih.",
					TutorialStepData.Gate.INTRO
				),
			])

		4:
			# A horizontal swipe makes a horizontal package, even for a column match.
			return _make(4, "Horizontal Tapau", 4, [A, B, C, D], [
				[A, B, C, A], [B, A, C, B], [C, C, B, A], [A, B, C, B],
			], 0, [], [],
			[
				_step_here(
					"Make a Tapau Pack",
					"Slide the Ang Ku right to match FOUR. A sideways swipe makes a horizontal Tapau.",
					TutorialStepData.Gate.CREATED_TAPAU,
					[Vector2i(1, 2), Vector2i(2, 2)]
				),
				_step("Your Tapau is ready!", "Swap the Tapau Pack with any neighbouring kuih to activate it.", TutorialStepData.Gate.INTRO),
				_step("Use your Tapau", "Slide the horizontal special to clear one full row.", TutorialStepData.Gate.ACTIVATED_SPECIAL, BoardCell.Special.TAPAU),
				_step("One whole row!", "Next, make a directional special that clears a column.", TutorialStepData.Gate.INTRO),
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
					"Match an L or a T shape and you get a Dulang instead.",
					TutorialStepData.Gate.INTRO
				),
				_step_here(
					"Make a Dulang",
					"A Dulang clears up a 3 x 3 patch of kuih.",
					TutorialStepData.Gate.CREATED_DULANG,
					[Vector2i(3, 0), Vector2i(3, 1)]
				),
				_step("Your Dulang is ready!", "Swap the Dulang with any neighbouring kuih to activate it.", TutorialStepData.Gate.INTRO),
				_step("Use your Dulang", "Slide the highlighted Dulang onto its neighbour. Watch the 3 × 3 area clear!", TutorialStepData.Gate.ACTIVATED_SPECIAL, BoardCell.Special.DULANG),
				_step("Nine tiles at once!", "That was the Dulang effect! Combine it with any kuih to clear a 3 × 3 area.", TutorialStepData.Gate.INTRO),
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
			return _make(7, "Two Guests And The Queue", 7, [A, B, C, D], [], 0,
				[
					[&"pakyai", [[A, 8]]],
					[&"tourist", [[B, 8]]],
				],
				[],
			[
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
			return _make(8, "The Real Tray", 8, [A, B, C, D, &"kuih_lapis", &"keria"], [], 20,
				[[&"makcik", [[A, 8], [C, 8]]]], [],
			[
				_step(
					"Here is the whole stall",
					"Eight by eight now, six kinds of kuih, and a proper order.",
					TutorialStepData.Gate.INTRO
				),
				_step(
					"Makcik's regular order",
					"8 Onde-onde and 8 Ang Ku. Match kuih to complete Makcik's order.",
					TutorialStepData.Gate.INTRO
				),
				_step("Power-ups unlock after training", "These four tools stay locked during tutorials. You can use them in regular stages after training.", TutorialStepData.Gate.INTRO),
				_step(
					"Serve and you are ready",
					"Fill the order. You are ready to start your journey!",
					TutorialStepData.Gate.SERVED
				),
			])

		9:
			return _make(9, "Square Delivery", 4, [A, B, C, D], [
				[A, A, B, C],
				[A, B, A, D],
				[C, D, A, C],
				[D, C, D, B],
			], 0, [], [], [
				_step("A little delivery", "A 2 by 2 square makes a Pesanan Hantar package.", TutorialStepData.Gate.INTRO),
				_step_here("Make a square", "Slide the Onde-onde left to complete the square.", TutorialStepData.Gate.CREATED_HANTAR, [Vector2i(2,1), Vector2i(1,1)]),
				_step("Send the package", "Swap the package to deliver a useful kuih.", TutorialStepData.Gate.ACTIVATED_SPECIAL, BoardCell.Special.HANTAR),
				_step("Delivery unlocked!", "Make 2 by 2 squares for deliveries in the main game.", TutorialStepData.Gate.INTRO),
			])

		10:
			return _make(10, "Vertical Tapau", 4, [A, B, C, D], [
				[A, B, C, A], [B, A, C, B], [C, C, B, C], [A, B, A, B],
			], 0, [], [], [
				_step_here("Make a vertical Tapau", "Slide the Ang Ku down to match FOUR. An up or down swipe makes a vertical Tapau that clears a column.", TutorialStepData.Gate.CREATED_VERTICAL, [Vector2i(2,1), Vector2i(2,2)]),
				_step("Use the vertical Tapau", "Swap the highlighted package with its neighbour. Its arrow clears one full column.", TutorialStepData.Gate.ACTIVATED_SPECIAL, BoardCell.Special.TAPAU_VERTICAL),
				_step("One whole column!", "The arrow shows which direction your special clears.", TutorialStepData.Gate.INTRO),
			])

		11:
			return _make(11, "Combine Two Directionals", 4, [A, B, C, D], [
				[A,B,C,D], [B,C,D,A], [C,D,A,B], [D,A,B,C],
			], 0, [], [], [
				_step("Two packages, one cross", "These two directional specials are ready. Swap them together for a cross clear.", TutorialStepData.Gate.INTRO),
				_step_here("Combine the packages", "Slide one highlighted package onto the other. Watch the row and column clear together!", TutorialStepData.Gate.ACTIVATED_CROSS, [Vector2i(1,1), Vector2i(2,1)]),
				_step("A sweet cross!", "Two directional specials combine into one row-and-column blast.", TutorialStepData.Gate.INTRO),
			])

	return _make(maxi(1, index), "Tutorial", 3, [A, B], [], 0, [], [], [])
