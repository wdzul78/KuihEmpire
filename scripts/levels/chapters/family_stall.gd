class_name FamilyStallChapter
extends StageChapter

## The 30 curated MVP stages for the Kuching family stall.
##
## Follows the teach / practice / combine / challenge / relax cycle from
## Master Plan section 30 and the scripted first ten levels from section 31,
## then the chapter arc from sections 32-33. Everything is data, so rebalancing a
## stage is a one-line edit.

const FIRST_STAGE := 1
const LAST_STAGE := 30
const MORNING_RUSH := 10
const WEEKEND_CHALLENGE := 20

const TITLES_MS := {
	"First Order": "Pesanan Pertama", "Sweet Start": "Permulaan Manis",
	"Two at Once": "Dua Sekali Gus", "Four in a Row": "Empat Sebaris",
	"Full Order": "Pesanan Penuh", "New Flavour": "Perisa Baharu",
	"Under the Leaf": "Di Bawah Daun", "Round Dulang": "Dulang Bulat",
	"Morning Prep": "Persiapan Pagi", "Morning Rush": "Kesibukan Pagi",
	"New Regular": "Pelanggan Baharu", "Two Regulars": "Dua Pelanggan Tetap",
	"Crisp Corner": "Sudut Rangup", "Kitchen Rhythm": "Rentak Dapur",
	"Recipe Book": "Buku Resipi", "Sticky Situation": "Situasi Melekit",
	"Combo Night": "Malam Kombo", "Long Order": "Pesanan Panjang",
	"Sweet Corner": "Sudut Manis", "Weekend Market": "Pasar Hujung Minggu",
	"Steamed Fresh": "Segar Dikukus", "Order Sequence": "Giliran Pesanan",
	"Office Order": "Pesanan Pejabat", "Big Basket": "Bakul Besar",
	"Calm Corner": "Sudut Tenang", "Tray Packing": "Isi Dulang",
	"Market Crush": "Pasar Sesak", "Old Friends": "Kawan Lama",
	"Last Prep": "Persiapan Akhir", "Big Community Order": "Pesanan Besar Komuniti",
}


static func build(level_id: int) -> LevelDefinition:
	var level := _build(level_id)
	level.background_id = &"stall_dawn" if level_id <= MORNING_RUSH else &"kuching_market"
	if level_id >= WEEKEND_CHALLENGE:
		level.background_id = &"weekend_market"
	if level_id == LAST_STAGE:
		level.background_id = &"chapter_boss"
	if level_id <= MORNING_RUSH:
		_apply_starter_board(level)
	return level


static func _build(level_id: int) -> LevelDefinition:
	match level_id:

		1:
			var l := _make(1, "First Order", "Teach swap", 1, [800, 1400],
				[&"onde_onde", &"kuih_koci", &"ang_ku_kueh", &"kuih_ketayap"],
				[[&"pakyai", [[&"onde_onde", 6]]]], 24,
				[], _tut([&"swap"]))
			l.story_before = &"beat_01_open"
			return l

		2:
			return _make(2, "Sweet Start", "Practice collect", 1, [1000, 1700],
				[&"onde_onde", &"kuih_koci", &"ang_ku_kueh", &"kuih_ketayap"],
				[[&"pakyai", [[&"onde_onde", 10], [&"kuih_koci", 6]]]], 22)

		3:
			return _make(3, "Two at Once", "Teach queue", 2, [1200, 2000],
				[&"onde_onde", &"kuih_koci", &"ang_ku_kueh", &"kuih_ketayap"],
				[
					[&"abang", [[&"onde_onde", 8]]],
					[&"tourist", [[&"kuih_koci", 8]]],
				], 24)

		4:
			var l := _make(4, "Four in a Row", "Teach Tapau", 2, [1300, 2200],
				[&"onde_onde", &"kuih_koci", &"ang_ku_kueh", &"kuih_ketayap"],
				[[&"abang", [[&"kuih_koci", 12], [&"ang_ku_kueh", 8]]]], 22,
				[], _tut([&"match4"]))
			l.story_before = &"beat_04_tapau"
			return l

		5:
			var l := _make(5, "Full Order", "Practice", 2, [1600, 2500],
				[&"onde_onde", &"kuih_koci", &"ang_ku_kueh", &"kuih_ketayap"],
				[[&"kakak", [[&"onde_onde", 10], [&"kuih_koci", 8], [&"ang_ku_kueh", 8]]]], 24,
				[], _tut([&"serve"]))
			l.kuih_unlock = &"kuih_lapis"
			return l

		6:
			var l := _make(6, "New Flavour", "Combine", 3, [1900, 3200],
				[&"onde_onde", &"kuih_koci", &"ang_ku_kueh", &"kuih_ketayap", &"kuih_lapis"],
				[[&"makcik", [[&"kuih_lapis", 10], [&"onde_onde", 8]]]], 18)
			l.recipe_unlock = &"kuih_lapis"
			return l

		7:
			var l := _make(7, "Under the Leaf", "Teach banana leaf", 3, [1900, 2700],
				[&"onde_onde", &"kuih_koci", &"ang_ku_kueh", &"kuih_ketayap", &"kuih_lapis"],
				[[&"runner", [[&"onde_onde", 12], [&"kuih_ketayap", 10]]]], 20,
				[_leaf([Vector2i(2, 2), Vector2i(5, 2), Vector2i(2, 5), Vector2i(5, 5)])],
				_tut([&"blocker_leaf"]))
			l.story_before = &"beat_07_leaf"
			return l

		8:
			return _make(8, "Round Dulang", "Teach Dulang", 3, [1700, 2500],
				[&"onde_onde", &"kuih_koci", &"ang_ku_kueh", &"kuih_ketayap", &"kuih_lapis"],
				[[&"abang", [[&"ang_ku_kueh", 12], [&"kuih_koci", 12]]]], 18,
				[_leaf([Vector2i(3, 3), Vector2i(4, 4)])],
				_tut([&"special_dulang"]))

		9:
			var l := _make(9, "Morning Prep", "Multi objective", 3, [2800, 4000],
				[&"onde_onde", &"kuih_koci", &"ang_ku_kueh", &"kuih_ketayap", &"kuih_lapis"],
				[
					[&"nenek", [[&"onde_onde", 10]]],
					[&"kakak", [[&"ang_ku_kueh", 10], [&"kuih_ketayap", 8]]],
				], 22)
			l.require_blockers_cleared = true
			return l

		10:
			var l := _make(10, "Morning Rush", "Chapter mini boss", 4, [3000, 4400],
				[&"onde_onde", &"kuih_koci", &"ang_ku_kueh", &"kuih_ketayap", &"kuih_lapis"],
				[
					[&"makcik", [[&"onde_onde", 12]]],
					[&"runner", [[&"kuih_koci", 12]]],
					[&"tourist", [[&"ang_ku_kueh", 10]]],
				], 24,
				[_leaf([Vector2i(1, 3), Vector2i(6, 3), Vector2i(3, 6)])])
			l.story_after = &"beat_10_rush"
			l.recipe_unlock = &"kuih_ketayap"
			return l

		11:
			return _make(11, "New Regular", "More variety", 2, [1500, 2300],
				[&"onde_onde", &"kuih_koci", &"ang_ku_kueh", &"kuih_ketayap", &"kuih_lapis", &"keria"],
				[[&"makcik", [[&"keria", 12], [&"onde_onde", 8]]]], 20,
				[_leaf([Vector2i(2, 4), Vector2i(5, 4)])])

		12:
			var l := _make(12, "Two Regulars", "Two customers", 3, [2000, 3100],
				[&"onde_onde", &"kuih_koci", &"ang_ku_kueh", &"kuih_ketayap", &"kuih_lapis", &"keria"],
				[
					[&"makcik", [[&"keria", 12]]],
					[&"nenek", [[&"kuih_koci", 10], [&"ang_ku_kueh", 8]]],
				], 26)
			l.story_before = &"beat_12_special_order"
			return l

		13:
			return _make(13, "Crisp Corner", "Blockers", 3, [2000, 2800],
				[&"onde_onde", &"kuih_koci", &"ang_ku_kueh", &"kuih_ketayap", &"kuih_lapis", &"keria"],
				[[&"abang", [[&"kuih_ketayap", 14], [&"kuih_lapis", 10]]]], 22,
				[_cover([Vector2i(1, 1), Vector2i(6, 1), Vector2i(1, 6), Vector2i(6, 6)], 2)])

		14:
			return _make(14, "Kitchen Rhythm", "Flow", 3, [2100, 3200],
				[&"onde_onde", &"kuih_koci", &"ang_ku_kueh", &"kuih_ketayap", &"kuih_lapis", &"keria"],
				[[&"kakak", [[&"keria", 14], [&"kuih_koci", 12], [&"onde_onde", 10]]]], 23)

		15:
			var l := _make(15, "Recipe Book", "Relax + reward", 2, [2200, 3100],
				[&"onde_onde", &"kuih_koci", &"ang_ku_kueh", &"kuih_ketayap", &"kuih_lapis", &"keria"],
				[[&"makcik", [[&"onde_onde", 14], [&"ang_ku_kueh", 12]]]], 25)
			l.story_before = &"beat_15_book"
			return l

		16:
			return _make(16, "Sticky Situation", "Teach syrup", 3, [1700, 2550],
				[&"onde_onde", &"kuih_koci", &"ang_ku_kueh", &"kuih_ketayap", &"kuih_lapis", &"keria"],
				[[&"runner", [[&"kuih_koci", 14], [&"keria", 12]]]], 20,
				[_syrup([Vector2i(3, 3), Vector2i(4, 4), Vector2i(3, 4)])])

		17:
			return _make(17, "Combo Night", "Combos", 4, [1700, 3000],
				[&"onde_onde", &"kuih_koci", &"ang_ku_kueh", &"kuih_ketayap", &"kuih_lapis", &"keria"],
				[[&"encik", [[&"onde_onde", 12], [&"kuih_koci", 12]]]], 24,
				[_leaf([Vector2i(0, 4), Vector2i(7, 4)])])

		18:
			var l := _make(18, "Long Order", "Denser board", 3, [1900, 3000],
				[&"onde_onde", &"kuih_koci", &"ang_ku_kueh", &"kuih_ketayap", &"kuih_lapis", &"keria"],
				[
					[&"encik", [[&"kuih_lapis", 9]]],
					[&"meiling", [[&"onde_onde", 8], [&"ang_ku_kueh", 8]]],
					[&"meena", [[&"kuih_ketayap", 9]]],
				], 30)
			l.require_blockers_cleared = true
			return l

		19:
			return _make(19, "Sweet Corner", "Relax", 2, [2300, 3200],
				[&"onde_onde", &"kuih_koci", &"ang_ku_kueh", &"kuih_ketayap", &"kuih_lapis", &"keria"],
				[[&"nenek", [[&"ang_ku_kueh", 12], [&"kuih_koci", 12]]]], 26)

		20:
			var l := _make(20, "Weekend Market", "Chapter challenge", 4, [2200, 2900],
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
			var l := _make(21, "Steamed Fresh", "Teach steamer", 3, [1600, 2300],
				[&"onde_onde", &"kuih_koci", &"ang_ku_kueh", &"kuih_ketayap", &"kuih_lapis", &"keria"],
				[[&"pakyai", [[&"onde_onde", 16], [&"ang_ku_kueh", 12]]]], 22,
				[_steamer([Vector2i(1, 5), Vector2i(3, 6), Vector2i(5, 5), Vector2i(6, 2)])],
				_tut([&"blocker_steamer"]))
			l.story_before = &"beat_21_steamer"
			return l

		22:
			return _make(22, "Order Sequence", "Queue", 3, [2600, 3600],
				[&"onde_onde", &"kuih_koci", &"ang_ku_kueh", &"kuih_ketayap", &"kuih_lapis", &"keria"],
				[
					[&"tourist", [[&"kuih_koci", 11]]],
					[&"abang", [[&"ang_ku_kueh", 11]]],
					[&"nenek", [[&"keria", 11]]],
				], 30)

		23:
			var l := _make(23, "Office Order", "Packaging", 4, [2000, 3000],
				[&"onde_onde", &"kuih_koci", &"ang_ku_kueh", &"kuih_ketayap", &"kuih_lapis", &"keria"],
				[[&"encik", [[&"kuih_koci", 14], [&"onde_onde", 14]]]], 24,
				[_box([Vector2i(3, 7)], &"kuih_koci", 8)])
			l.require_blockers_cleared = true
			return l

		24:
			return _make(24, "Big Basket", "Bigger orders", 4, [2300, 3350],
				[&"onde_onde", &"kuih_koci", &"ang_ku_kueh", &"kuih_ketayap", &"kuih_lapis", &"keria"],
				[[&"kakak", [[&"kuih_lapis", 12], [&"keria", 12], [&"ang_ku_kueh", 10]]]], 25)

		25:
			return _make(25, "Calm Corner", "Relax", 2, [2200, 3200],
				[&"onde_onde", &"kuih_koci", &"ang_ku_kueh", &"kuih_ketayap", &"kuih_lapis", &"keria"],
				[[&"nenek", [[&"kuih_ketayap", 14], [&"onde_onde", 12]]]], 27)

		26:
			var l := _make(26, "Tray Packing", "Packaging + queue", 4, [1900, 3300],
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
			return _make(27, "Market Crush", "Challenge", 5, [2300, 3500],
				[&"onde_onde", &"kuih_koci", &"ang_ku_kueh", &"kuih_ketayap", &"kuih_lapis", &"keria"],
				[
					[&"runner", [[&"onde_onde", 10], [&"kuih_koci", 9]]],
					[&"kakak", [[&"kuih_lapis", 9], [&"ang_ku_kueh", 8]]],
					[&"encik", [[&"keria", 10]]],
				], 28,
				[_cover([Vector2i(1, 2), Vector2i(6, 2), Vector2i(3, 4)], 2)])

		28:
			var l := _make(28, "Old Friends", "Warm finale build", 3, [2600, 3550],
				[&"onde_onde", &"kuih_koci", &"ang_ku_kueh", &"kuih_ketayap", &"kuih_lapis", &"keria"],
				[
					[&"makcik", [[&"onde_onde", 12], [&"kuih_koci", 12], [&"ang_ku_kueh", 10]]],
					[&"nenek", [[&"kuih_lapis", 12]]],
				], 28)
			l.story_before = &"beat_28_rival"
			return l

		29:
			return _make(29, "Last Prep", "Challenge", 4, [2000, 3200],
				[&"onde_onde", &"kuih_koci", &"ang_ku_kueh", &"kuih_ketayap", &"kuih_lapis", &"keria"],
				[[&"encik", [[&"keria", 14], [&"kuih_koci", 12], [&"onde_onde", 10]]]], 26,
				[_steamer([Vector2i(0, 0), Vector2i(7, 0), Vector2i(0, 7), Vector2i(7, 7)], 2),
				 _leaf([Vector2i(3, 1), Vector2i(4, 6)])])

		30:
			var l := _make(30, "Big Community Order", "Family Stall finale", 5, [3000, 4300],
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

	return null


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
