class_name LevelLibrary
extends RefCounted

## The 30 curated MVP stages for the Kuching family stall.
##
## Follows the teach / practice / combine / challenge / relax cycle from
## Master Plan section 30 and the scripted first ten levels from section 31,
## then the chapter arc from sections 32-33. Everything is data, so rebalancing a
## stage is a one-line edit.
##
## Order of a level is `[[customer_id, [[kuih_id, count], ...]], ...]`.

const CHAPTER_PROLOGUE := &"prologue"
const CHAPTER_KUCHING := &"kuching"
const MORNING_RUSH := 10
const WEEKEND_CHALLENGE := 20
const CHAPTER_FINALE := 30

const SCORE_TARGETS := [
	[800, 1400], [1000, 1700], [1200, 2000], [1300, 2200], [1600, 2500],
	[1900, 3200], [1900, 2700], [1700, 2500], [2800, 4000], [3000, 4400],
	[1500, 2300], [2000, 3100], [2300, 3200], [2100, 3400], [2200, 3300],
	[1700, 3000], [1700, 3000], [1900, 3000], [2400, 3500], [2200, 2900],
	[1600, 2300], [2600, 3600], [2000, 3000], [2300, 3400], [2200, 3200],
	[1900, 3300], [2300, 3500], [3000, 4400], [2000, 3200], [3000, 4300],
]
static var _cache: Dictionary = {}


static func count() -> int:
	return 30


static func get_level(level_id: int) -> LevelDefinition:
	if _cache.has(level_id):
		return _cache[level_id]
	var level := _build(level_id)
	if level_id <= 10:
		_apply_starter_board(level)
	if level.base_coin_reward < 0:
		level.base_coin_reward = level.coins
	_cache[level_id] = level
	return level


static func has_level(level_id: int) -> bool:
	return level_id >= 1 and level_id <= count()


static func all() -> Array[LevelDefinition]:
	var out: Array[LevelDefinition] = []
	for id in range(1, count() + 1):
		out.append(get_level(id))
	return out


# --- authoring helpers -----------------------------------------------------

static func _make(
	level_id: int,
	title: String,
	tag: String,
	difficulty: int,
	kuih_ids: Array,
	orders: Array,
	moves: int = 22,
	blockers: Array = [],
	tutorial: Array = []
) -> LevelDefinition:
	var level := LevelDefinition.new()
	level.id = level_id
	level.chapter_id = JourneyLibrary.STORY
	level.title = title
	level.tag = tag
	level.difficulty = difficulty
	level.moves = moves
	var targets: Array = SCORE_TARGETS[clampi(level_id - 1, 0, 29)]
	level.score_two_star = targets[0]
	level.score_three_star = targets[1]
	level.background_id = &"stall_dawn" if level_id <= MORNING_RUSH else &"kuching_market"
	if level_id >= WEEKEND_CHALLENGE:
		level.background_id = &"weekend_market"
	if level_id == CHAPTER_FINALE:
		level.background_id = &"chapter_boss"

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

	level.tutorial = []
	for step in tutorial:
		var key: StringName = step
		level.tutorial.append(key)
	level.coins = 55 + level_id * 4
	return level


static func _leaf(cells: Array[Vector2i]) -> BlockerSpec:
	return BlockerSpec.make(BlockerSpec.Kind.BANANA_LEAF, cells, 1)


static func _cover(cells: Array[Vector2i], hp: int = 2) -> BlockerSpec:
	return BlockerSpec.make(BlockerSpec.Kind.FOOD_COVER, cells, hp)


static func _steamer(cells: Array[Vector2i], hp: int = 1) -> BlockerSpec:
	return BlockerSpec.make(BlockerSpec.Kind.STEAMER, cells, hp)


static func _box(cells: Array[Vector2i], kuih_id: StringName, need: int) -> BlockerSpec:
	return BlockerSpec.make_target(BlockerSpec.Kind.PACKAGING_BOX, cells, kuih_id, need)


static func _tray(cells: Array[Vector2i], kuih_id: StringName, need: int) -> BlockerSpec:
	return BlockerSpec.make_target(BlockerSpec.Kind.EMPTY_TRAY, cells, kuih_id, need)


static func _tut(ids: Array) -> Array:
	var out: Array = []
	for id in ids:
		out.append(id)
	return out


# --- the 30 stages ---------------------------------------------------------

static func _build(level_id: int) -> LevelDefinition:
	match level_id:

		1:
			var l := _make(1, "First Order", "Teach swap", 1,
				[&"onde_onde", &"kuih_koci", &"ang_ku_kueh", &"kuih_ketayap"],
				[[&"pakyai", [[&"onde_onde", 6]]]], 24,
				[], _tut([&"swap"]))
			l.story_before = &"beat_01_open"
			return l

		2:
			return _make(2, "Sweet Start", "Practice collect", 1,
				[&"onde_onde", &"kuih_koci", &"ang_ku_kueh", &"kuih_ketayap"],
				[[&"pakyai", [[&"onde_onde", 10], [&"kuih_koci", 6]]]], 22)

		3:
			return _make(3, "Two at Once", "Teach queue", 2,
				[&"onde_onde", &"kuih_koci", &"ang_ku_kueh", &"kuih_ketayap"],
				[
					[&"abang", [[&"onde_onde", 8]]],
					[&"tourist", [[&"kuih_koci", 8]]],
				], 24)

		4:
			var l := _make(4, "Four in a Row", "Teach Tapau", 2,
				[&"onde_onde", &"kuih_koci", &"ang_ku_kueh", &"kuih_ketayap"],
				[[&"abang", [[&"kuih_koci", 12], [&"ang_ku_kueh", 8]]]], 22,
				[], _tut([&"match4"]))
			l.story_before = &"beat_04_tapau"
			return l

		5:
			var l := _make(5, "Full Order", "Practice", 2,
				[&"onde_onde", &"kuih_koci", &"ang_ku_kueh", &"kuih_ketayap"],
				[[&"kakak", [[&"onde_onde", 10], [&"kuih_koci", 8], [&"ang_ku_kueh", 8]]]], 24,
				[], _tut([&"serve"]))
			l.kuih_unlock = &"kuih_lapis"
			return l

		6:
			var l := _make(6, "New Flavour", "Combine", 3,
				[&"onde_onde", &"kuih_koci", &"ang_ku_kueh", &"kuih_ketayap", &"kuih_lapis"],
				[[&"makcik", [[&"kuih_lapis", 10], [&"onde_onde", 8]]]], 22)
			l.recipe_unlock = &"kuih_lapis"
			return l

		7:
			var l := _make(7, "Under the Leaf", "Teach banana leaf", 3,
				[&"onde_onde", &"kuih_koci", &"ang_ku_kueh", &"kuih_ketayap", &"kuih_lapis"],
				[[&"runner", [[&"onde_onde", 12], [&"kuih_ketayap", 10]]]], 24,
				[_leaf([Vector2i(2, 2), Vector2i(5, 2), Vector2i(2, 5), Vector2i(5, 5)])],
				_tut([&"blocker_leaf"]))
			l.story_before = &"beat_07_leaf"
			return l

		8:
			return _make(8, "Round Dulang", "Teach Dulang", 3,
				[&"onde_onde", &"kuih_koci", &"ang_ku_kueh", &"kuih_ketayap", &"kuih_lapis"],
				[[&"abang", [[&"ang_ku_kueh", 12], [&"kuih_koci", 12]]]], 22,
				[_leaf([Vector2i(3, 3), Vector2i(4, 4)])],
				_tut([&"special_dulang"]))

		9:
			var l := _make(9, "Morning Prep", "Multi objective", 3,
				[&"onde_onde", &"kuih_koci", &"ang_ku_kueh", &"kuih_ketayap", &"kuih_lapis"],
				[
					[&"nenek", [[&"onde_onde", 10]]],
					[&"kakak", [[&"ang_ku_kueh", 10], [&"kuih_ketayap", 8]]],
				], 26)
			l.require_blockers_cleared = true
			return l

		10:
			var l := _make(10, "Morning Rush", "Chapter mini boss", 4,
				[&"onde_onde", &"kuih_koci", &"ang_ku_kueh", &"kuih_ketayap", &"kuih_lapis"],
				[
					[&"makcik", [[&"onde_onde", 12]]],
					[&"runner", [[&"kuih_koci", 12]]],
					[&"tourist", [[&"ang_ku_kueh", 10]]],
				], 28,
				[_leaf([Vector2i(1, 3), Vector2i(6, 3), Vector2i(3, 6)])])
			l.story_after = &"beat_10_rush"
			l.recipe_unlock = &"kuih_ketayap"
			return l

		11:
			return _make(11, "New Regular", "More variety", 2,
				[&"onde_onde", &"kuih_koci", &"ang_ku_kueh", &"kuih_ketayap", &"kuih_lapis", &"keria"],
				[[&"makcik", [[&"keria", 12], [&"onde_onde", 8]]]], 22,
				[_leaf([Vector2i(2, 4), Vector2i(5, 4)])])

		12:
			var l := _make(12, "Two Regulars", "Two customers", 3,
				[&"onde_onde", &"kuih_koci", &"ang_ku_kueh", &"kuih_ketayap", &"kuih_lapis", &"keria"],
				[
					[&"makcik", [[&"keria", 12]]],
					[&"nenek", [[&"kuih_koci", 10], [&"ang_ku_kueh", 8]]],
				], 26)
			l.story_before = &"beat_12_special_order"
			return l

		13:
			return _make(13, "Crisp Corner", "Blockers", 3,
				[&"onde_onde", &"kuih_koci", &"ang_ku_kueh", &"kuih_ketayap", &"kuih_lapis", &"keria"],
				[[&"abang", [[&"kuih_ketayap", 14], [&"kuih_lapis", 10]]]], 22,
				[_cover([Vector2i(1, 1), Vector2i(6, 1), Vector2i(1, 6), Vector2i(6, 6)], 2)])

		14:
			return _make(14, "Kitchen Rhythm", "Flow", 3,
				[&"onde_onde", &"kuih_koci", &"ang_ku_kueh", &"kuih_ketayap", &"kuih_lapis", &"keria"],
				[[&"kakak", [[&"keria", 14], [&"kuih_koci", 12], [&"onde_onde", 10]]]], 26)

		15:
			var l := _make(15, "Recipe Book", "Relax + reward", 2,
				[&"onde_onde", &"kuih_koci", &"ang_ku_kueh", &"kuih_ketayap", &"kuih_lapis", &"keria"],
				[[&"makcik", [[&"onde_onde", 14], [&"ang_ku_kueh", 12]]]], 28)
			l.story_before = &"beat_15_book"
			return l

		16:
			return _make(16, "Sticky Situation", "Teach syrup", 3,
				[&"onde_onde", &"kuih_koci", &"ang_ku_kueh", &"kuih_ketayap", &"kuih_lapis", &"keria"],
				[[&"runner", [[&"kuih_koci", 14], [&"keria", 12]]]], 22,
				[BlockerSpec.make(BlockerSpec.Kind.STICKY_SYRUP, [Vector2i(3, 3), Vector2i(4, 4), Vector2i(3, 4)], 1)])

		17:
			return _make(17, "Combo Night", "Combos", 4,
				[&"onde_onde", &"kuih_koci", &"ang_ku_kueh", &"kuih_ketayap", &"kuih_lapis", &"keria"],
				[[&"encik", [[&"onde_onde", 12], [&"kuih_koci", 12]]]], 24,
				[_leaf([Vector2i(0, 4), Vector2i(7, 4)])])

		18:
			var l := _make(18, "Long Order", "Denser board", 3,
				[&"onde_onde", &"kuih_koci", &"ang_ku_kueh", &"kuih_ketayap", &"kuih_lapis", &"keria"],
				[
					[&"encik", [[&"kuih_lapis", 10]]],
					[&"meiling", [[&"onde_onde", 10], [&"ang_ku_kueh", 10]]],
					[&"meena", [[&"kuih_ketayap", 10]]],
				], 28)
			l.require_blockers_cleared = true
			return l

		19:
			return _make(19, "Sweet Corner", "Relax", 2,
				[&"onde_onde", &"kuih_koci", &"ang_ku_kueh", &"kuih_ketayap", &"kuih_lapis", &"keria"],
				[[&"nenek", [[&"ang_ku_kueh", 12], [&"kuih_koci", 12]]]], 30)

		20:
			var l := _make(20, "Weekend Market", "Chapter challenge", 4,
				[&"onde_onde", &"kuih_koci", &"ang_ku_kueh", &"kuih_ketayap", &"kuih_lapis", &"keria"],
				[
					[&"kakak", [[&"onde_onde", 12]]],
					[&"encik", [[&"keria", 12], [&"kuih_lapis", 10]]],
				], 28,
				[_cover([Vector2i(2, 2), Vector2i(5, 5)], 2)])
			l.story_before = &"beat_20_weekend"
			l.story_after = &"beat_20_done"
			return l

		21:
			var l := _make(21, "Steamed Fresh", "Teach steamer", 3,
				[&"onde_onde", &"kuih_koci", &"ang_ku_kueh", &"kuih_ketayap", &"kuih_lapis", &"keria"],
				[[&"pakyai", [[&"onde_onde", 16], [&"ang_ku_kueh", 12]]]], 22,
				[_steamer([Vector2i(1, 5), Vector2i(3, 6), Vector2i(5, 5), Vector2i(6, 2)])],
				_tut([&"blocker_steamer"]))
			l.story_before = &"beat_21_steamer"
			return l

		22:
			return _make(22, "Order Sequence", "Queue", 3,
				[&"onde_onde", &"kuih_koci", &"ang_ku_kueh", &"kuih_ketayap", &"kuih_lapis", &"keria"],
				[
					[&"tourist", [[&"kuih_koci", 12]]],
					[&"abang", [[&"ang_ku_kueh", 12]]],
					[&"nenek", [[&"keria", 12]]],
				], 28)

		23:
			var l := _make(23, "Office Order", "Packaging", 4,
				[&"onde_onde", &"kuih_koci", &"ang_ku_kueh", &"kuih_ketayap", &"kuih_lapis", &"keria"],
				[[&"encik", [[&"kuih_koci", 14], [&"onde_onde", 14]]]], 24,
				[_box([Vector2i(3, 7)], &"kuih_koci", 8)])
			l.require_blockers_cleared = true
			return l

		24:
			return _make(24, "Big Basket", "Bigger orders", 4,
				[&"onde_onde", &"kuih_koci", &"ang_ku_kueh", &"kuih_ketayap", &"kuih_lapis", &"keria"],
				[[&"kakak", [[&"kuih_lapis", 12], [&"keria", 12], [&"ang_ku_kueh", 10]]]], 28)

		25:
			return _make(25, "Calm Corner", "Relax", 2,
				[&"onde_onde", &"kuih_koci", &"ang_ku_kueh", &"kuih_ketayap", &"kuih_lapis", &"keria"],
				[[&"nenek", [[&"kuih_ketayap", 14], [&"onde_onde", 12]]]], 30)

		26:
			var l := _make(26, "Tray Packing", "Packaging + queue", 4,
				[&"onde_onde", &"kuih_koci", &"ang_ku_kueh", &"kuih_ketayap", &"kuih_lapis", &"keria"],
				[
					[&"encik", [[&"keria", 12]]],
					[&"pakyai", [[&"kuih_koci", 12]]],
				], 26,
				[_tray([Vector2i(2, 7), Vector2i(5, 7)], &"keria", 6),
				 _box([Vector2i(4, 0)], &"kuih_koci", 8)])
			l.require_blockers_cleared = true
			return l

		27:
			return _make(27, "Market Crush", "Challenge", 5,
				[&"onde_onde", &"kuih_koci", &"ang_ku_kueh", &"kuih_ketayap", &"kuih_lapis", &"keria"],
				[
					[&"runner", [[&"onde_onde", 10], [&"kuih_koci", 9]]],
					[&"kakak", [[&"kuih_lapis", 9], [&"ang_ku_kueh", 8]]],
					[&"encik", [[&"keria", 10]]],
				], 28,
				[_cover([Vector2i(1, 2), Vector2i(6, 2), Vector2i(3, 4)], 2)])

		28:
			var l := _make(28, "Old Friends", "Warm finale build", 3,
				[&"onde_onde", &"kuih_koci", &"ang_ku_kueh", &"kuih_ketayap", &"kuih_lapis", &"keria"],
				[
					[&"makcik", [[&"onde_onde", 12], [&"kuih_koci", 12], [&"ang_ku_kueh", 10]]],
					[&"nenek", [[&"kuih_lapis", 12]]],
				], 28)
			l.story_before = &"beat_28_rival"
			return l

		29:
			return _make(29, "Last Prep", "Challenge", 4,
				[&"onde_onde", &"kuih_koci", &"ang_ku_kueh", &"kuih_ketayap", &"kuih_lapis", &"keria"],
				[[&"encik", [[&"keria", 14], [&"kuih_koci", 12], [&"onde_onde", 10]]]], 26,
				[_steamer([Vector2i(0, 0), Vector2i(7, 0), Vector2i(0, 7), Vector2i(7, 7)], 2),
				 _leaf([Vector2i(3, 1), Vector2i(4, 6)])])

		30:
			var l := _make(30, "Big Community Order", "Family Stall finale", 5,
				[&"onde_onde", &"kuih_koci", &"ang_ku_kueh", &"kuih_ketayap", &"kuih_lapis", &"keria"],
				[
					[&"kakak", [[&"onde_onde", 10], [&"ang_ku_kueh", 9]]],
					[&"encik", [[&"kuih_lapis", 10], [&"keria", 12]]],
					[&"runner", [[&"kuih_koci", 11], [&"kuih_ketayap", 9]]],
				], 32,
				[_cover([Vector2i(1, 1), Vector2i(6, 1), Vector2i(1, 6), Vector2i(6, 6)], 2),
				 _leaf([Vector2i(3, 3), Vector2i(4, 4)]),
				 _box([Vector2i(2, 7)], &"kuih_koci", 10)])
			l.require_blockers_cleared = true
			l.story_before = &"beat_30_finale"
			l.story_after = &"beat_30_done"
			l.coins = 300
			return l

	return _make(maxi(1, level_id), "Stage %d" % level_id, "", 1,
		[&"onde_onde", &"kuih_koci", &"ang_ku_kueh", &"kuih_ketayap"],
		[[&"pakyai", [[&"onde_onde", 8]]]], 24)


# --- editor support --------------------------------------------------------

## Writes every level to `res://resources/levels/level_XXX.tres` so designers can
## hand-tune them in the editor (Master Plan sections 57 and 58).
static func export_all() -> int:
	var written := 0
	for level in all():
		var path := "res://resources/levels/level_%03d.tres" % level.id
		var err := ResourceSaver.save(level, path)
		if err == OK:
			written += 1
		else:
			push_error("LevelLibrary: could not save %s (%d)" % [path, err])
	return written


static func _apply_starter_board(level: LevelDefinition) -> void:
	var side: int = [3,3,4,4,5,5,6,6,7,7][level.id-1]
	level.width = side
	level.height = side
	if level.id <= 2:
		level.kuih.assign([KuihLibrary.get_kuih(&"onde_onde"),KuihLibrary.get_kuih(&"kuih_koci"),KuihLibrary.get_kuih(&"ang_ku_kueh")])
	for order in level.customer_orders:
		for item in order.items:
			item.count = mini(item.count, 3 if level.id == 1 else 5 if level.id <= 4 else 8)
	level.score_two_star = 100 if side == 3 else 300 if side == 4 else 600 if side == 5 else 1000
	level.score_three_star = level.score_two_star * 2
