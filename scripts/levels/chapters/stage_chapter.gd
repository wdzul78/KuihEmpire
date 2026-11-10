class_name StageChapter
extends RefCounted

## Authoring helpers shared by every chapter of stages.
##
## A chapter extends this class and declares `FIRST_STAGE`, `LAST_STAGE`,
## `TITLES_MS` and `static func build(level_id)`, then registers itself in
## `LevelLibrary.chapters()`.
##
## Order of a level is `[[customer_id, [[kuih_id, count], ...]], ...]`.
## `score_targets` is `[two_star, three_star]`.

## Coin rewards stop growing here so later chapters do not inflate the economy.
const COIN_GROWTH_LAST_STAGE := 30


static func _make(
	level_id: int,
	title: String,
	tag: String,
	difficulty: int,
	score_targets: Array,
	kuih_ids: Array,
	orders: Array,
	moves: int = 22,
	blockers: Array = [],
	tutorial: Array = []
) -> LevelDefinition:
	var location := LocationDefinition.for_stage(level_id)
	var level := LevelDefinition.new()
	level.id = level_id
	level.chapter_id = location.id
	level.title = title
	level.tag = tag
	level.difficulty = difficulty
	level.moves = moves
	level.score_two_star = score_targets[0]
	level.score_three_star = score_targets[1]
	level.background_id = location.preset

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
	level.coins = 55 + mini(level_id, COIN_GROWTH_LAST_STAGE) * 4
	return level


## Stands in for a stage id that no chapter has authored.
static func placeholder(level_id: int) -> LevelDefinition:
	return _make(maxi(1, level_id), "Stage %d" % level_id, "", 1, [3000, 4300],
		[&"onde_onde", &"kuih_koci", &"ang_ku_kueh", &"kuih_ketayap"],
		[[&"pakyai", [[&"onde_onde", 8]]]], 24)


static func _leaf(cells: Array[Vector2i]) -> BlockerSpec:
	return BlockerSpec.make(BlockerSpec.Kind.BANANA_LEAF, cells, 1)


## Gula melaka syrup. Spills start small and grow: 3 cells at stage 16,
## then 5 at stage 42, 6 at stage 49 and 8 at stage 58.
static func _syrup(cells: Array[Vector2i]) -> BlockerSpec:
	return BlockerSpec.make(BlockerSpec.Kind.STICKY_SYRUP, cells, 1)


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
