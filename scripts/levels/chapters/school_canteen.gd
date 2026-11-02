class_name SchoolCanteenChapter
extends StageChapter

## Stages 31-60 at the School Canteen. Tiles rotate so every board keeps six kuih,
## and the same six blockers from the Family Stall come back in new combinations.
## See section 5 of `design/Stage_Expansion_Plan_2026-11-01.md`.

const FIRST_STAGE := 31
const LAST_STAGE := 60

const TILES_FIRST_DAYS := [&"onde_onde", &"kuih_koci", &"ang_ku_kueh", &"kuih_ketayap", &"kuih_lapis", &"karipap"]
const TILES_TEACHERS := [&"onde_onde", &"kuih_koci", &"ang_ku_kueh", &"kuih_lapis", &"karipap", &"tart"]
const TILES_SPORTS := [&"kuih_koci", &"ang_ku_kueh", &"kuih_lapis", &"karipap", &"tart", &"kuih_bom"]
const TILES_AWARDS := [&"ang_ku_kueh", &"kuih_lapis", &"karipap", &"tart", &"kuih_bom", &"agar_agar_ros"]

const TITLES_MS := {
	"First Day": "Hari Pertama", "Recess Bell": "Loceng Rehat",
	"Line Up!": "Beratur Ya!", "Teacher's Tray": "Bekal Cikgu",
	"Quiet Break": "Rehat Tenang", "Canteen Steam": "Stim Kantin",
	"Double Covers": "Tudung Berlapis", "Teacher's Tart": "Tart Cikgu",
	"Lunch Boxes": "Kotak Bekal", "Sale Day": "Hari Jualan",
	"After the Sale": "Selepas Jualan", "Syrup Spill": "Sirap Tumpah",
	"Two Shifts": "Dua Giliran", "Classmates": "Kawan Sekelas",
	"Easy Hour": "Waktu Senang", "Sweet Bom": "Bom Manis",
	"Morning Steam": "Stim Pagi", "Club Order": "Tempahan Kelab",
	"Syrup and Leaves": "Sirap & Daun", "Sports Day": "Hari Sukan",
	"Field Break": "Rehat Padang", "Packed Canteen": "Kantin Sesak",
	"Rose Jelly": "Agar-agar Ros", "Stacked Trays": "Dulang Bersusun",
	"PTA Meeting": "Mesyuarat PIBG", "Rainy Afternoon": "Hujan Petang",
	"Everything at Once": "Semua Sekali", "Final Rehearsal": "Latihan Akhir",
	"Prep Night": "Malam Persediaan", "Awards Day": "Hari Anugerah",
}


static func build(level_id: int) -> LevelDefinition:
	match level_id:

		31:
			var l := _make(31, "First Day", "Teach karipap", 2, [2500, 2700], TILES_FIRST_DAYS,
				[[&"adik_danish", [[&"karipap", 10], [&"onde_onde", 8]]]], 22)
			l.story_before = &"beat_31_canteen"
			return l

		32:
			return _make(32, "Recess Bell", "Two customers", 3, [2600, 3100], TILES_FIRST_DAYS,
				[
					[&"adik_priya", [[&"karipap", 9]]],
					[&"adik_danish", [[&"kuih_koci", 10]]],
				], 21,
				[_leaf([Vector2i(2, 3), Vector2i(5, 4)])])

		33:
			return _make(33, "Line Up!", "Queue of three", 3, [2800, 3100], TILES_FIRST_DAYS,
				[
					[&"pak_mat", [[&"ang_ku_kueh", 8]]],
					[&"adik_priya", [[&"kuih_lapis", 8]]],
					[&"adik_danish", [[&"karipap", 8]]],
				], 22)

		34:
			return _make(34, "Teacher's Tray", "Covers", 3, [2500, 2700], TILES_FIRST_DAYS,
				[[&"cikgu_salmah", [[&"kuih_ketayap", 12], [&"karipap", 12]]]], 20,
				[_cover([Vector2i(2, 2), Vector2i(5, 5)], 2)])

		35:
			return _make(35, "Quiet Break", "Relax", 2, [2600, 2900], TILES_FIRST_DAYS,
				[[&"nenek", [[&"onde_onde", 10], [&"kuih_koci", 10]]]], 24)

		36:
			return _make(36, "Canteen Steam", "Steamer and leaf", 3, [2500, 2700], TILES_FIRST_DAYS,
				[[&"pak_mat", [[&"karipap", 14], [&"ang_ku_kueh", 14]]]], 22,
				[_steamer([Vector2i(1, 5), Vector2i(4, 6), Vector2i(6, 4)]),
				 _leaf([Vector2i(3, 2)])])

		37:
			var l := _make(37, "Double Covers", "Corner covers", 4, [3000, 3200], TILES_FIRST_DAYS,
				[[&"cikgu_salmah", [[&"kuih_lapis", 16], [&"karipap", 14]]]], 23,
				[_cover([Vector2i(0, 0), Vector2i(7, 0), Vector2i(0, 7), Vector2i(7, 7)], 2)])
			l.kuih_unlock = &"tart"
			return l

		38:
			var l := _make(38, "Teacher's Tart", "Teach tart", 2, [2600, 2900], TILES_TEACHERS,
				[[&"cikgu_salmah", [[&"tart", 12], [&"onde_onde", 10]]]], 22)
			l.story_before = &"beat_38_tart"
			return l

		39:
			var l := _make(39, "Lunch Boxes", "Boxes, clear them all", 3, [2900, 3100], TILES_TEACHERS,
				[[&"pak_mat", [[&"tart", 16], [&"karipap", 14]]]], 23,
				[_box([Vector2i(3, 7)], &"tart", 8)])
			l.require_blockers_cleared = true
			return l

		40:
			var l := _make(40, "Sale Day", "Milestone, three customers", 5, [3500, 3900], TILES_TEACHERS,
				[
					[&"adik_danish", [[&"karipap", 12]]],
					[&"adik_priya", [[&"tart", 11]]],
					[&"cikgu_salmah", [[&"onde_onde", 6], [&"ang_ku_kueh", 5]]],
				], 26,
				[_leaf([Vector2i(1, 3), Vector2i(6, 3)]),
				 _cover([Vector2i(3, 1), Vector2i(4, 6)], 2)])
			l.story_after = &"beat_40_done"
			return l

		41:
			return _make(41, "After the Sale", "Relax", 2, [3100, 3300], TILES_TEACHERS,
				[[&"makcik", [[&"onde_onde", 12], [&"kuih_koci", 10]]]], 26)

		42:
			return _make(42, "Syrup Spill", "Syrup", 3, [2800, 3000], TILES_TEACHERS,
				[[&"adik_danish", [[&"kuih_lapis", 14], [&"tart", 14]]]], 22,
				[BlockerSpec.make(BlockerSpec.Kind.STICKY_SYRUP, [Vector2i(2, 3), Vector2i(3, 3), Vector2i(4, 4), Vector2i(5, 4)], 1)])

		43:
			var l := _make(43, "Two Shifts", "Queue and trays", 3, [3400, 3700], TILES_TEACHERS,
				[
					[&"pak_mat", [[&"ang_ku_kueh", 10]]],
					[&"adik_priya", [[&"karipap", 9]]],
					[&"adik_danish", [[&"tart", 9]]],
				], 25,
				[_tray([Vector2i(2, 7), Vector2i(5, 7)], &"karipap", 6)])
			l.require_blockers_cleared = true
			return l

		44:
			return _make(44, "Classmates", "Three students", 3, [3200, 3400], TILES_TEACHERS,
				[
					[&"adik_danish", [[&"onde_onde", 10]]],
					[&"adik_priya", [[&"tart", 10]]],
					[&"adik_danish", [[&"kuih_koci", 8]]],
				], 26,
				[_leaf([Vector2i(2, 5), Vector2i(5, 2)])])

		45:
			var l := _make(45, "Easy Hour", "Relax", 2, [3000, 3300], TILES_TEACHERS,
				[[&"adik_priya", [[&"kuih_lapis", 12], [&"karipap", 12]]]], 27)
			l.kuih_unlock = &"kuih_bom"
			l.story_before = &"beat_45_recipe"
			return l

		46:
			return _make(46, "Sweet Bom", "Teach kuih bom", 2, [2800, 3000], TILES_SPORTS,
				[[&"adik_danish", [[&"kuih_bom", 14], [&"kuih_koci", 10]]]], 23)

		47:
			return _make(47, "Morning Steam", "Two-layer steamers", 4, [2700, 2900], TILES_SPORTS,
				[[&"pak_mat", [[&"tart", 16], [&"ang_ku_kueh", 16]]]], 20,
				[_steamer([Vector2i(1, 2), Vector2i(6, 2), Vector2i(1, 5), Vector2i(6, 5)], 2)])

		48:
			var l := _make(48, "Club Order", "Box and trays, clear them all", 4, [3500, 3700], TILES_SPORTS,
				[[&"cikgu_salmah", [[&"karipap", 18], [&"kuih_bom", 18]]]], 26,
				[_box([Vector2i(3, 0)], &"karipap", 8),
				 _tray([Vector2i(2, 7), Vector2i(5, 7)], &"kuih_bom", 6)])
			l.require_blockers_cleared = true
			return l

		49:
			return _make(49, "Syrup and Leaves", "Combination", 4, [3500, 4000], TILES_SPORTS,
				[[&"kakak", [[&"kuih_koci", 18], [&"tart", 18]]]], 25,
				[BlockerSpec.make(BlockerSpec.Kind.STICKY_SYRUP, [Vector2i(3, 3), Vector2i(4, 3), Vector2i(3, 4)], 1),
				 _leaf([Vector2i(1, 1), Vector2i(6, 1), Vector2i(4, 6)])])

		50:
			var l := _make(50, "Sports Day", "Milestone, a big order", 5, [3700, 4100], TILES_SPORTS,
				[
					[&"cikgu_salmah", [[&"kuih_bom", 10], [&"kuih_lapis", 10]]],
					[&"adik_danish", [[&"karipap", 10]]],
					[&"adik_priya", [[&"tart", 10]]],
				], 28,
				[_cover([Vector2i(1, 1), Vector2i(6, 1), Vector2i(3, 6)], 2),
				 _steamer([Vector2i(2, 4), Vector2i(5, 4)])])
			l.story_before = &"beat_50_sports"
			l.story_after = &"beat_50_done"
			return l

		51:
			return _make(51, "Field Break", "Relax", 2, [3100, 3400], TILES_SPORTS,
				[[&"nenek", [[&"ang_ku_kueh", 14], [&"kuih_koci", 12]]]], 28)

		52:
			var l := _make(52, "Packed Canteen", "Queue of three", 3, [3600, 3900], TILES_SPORTS,
				[
					[&"pak_mat", [[&"kuih_lapis", 11]]],
					[&"adik_priya", [[&"tart", 10]]],
					[&"adik_danish", [[&"kuih_bom", 10]]],
				], 27,
				[_leaf([Vector2i(2, 2), Vector2i(5, 5)])])
			l.kuih_unlock = &"agar_agar_ros"
			return l

		53:
			return _make(53, "Rose Jelly", "Teach agar-agar", 2, [3000, 3300], TILES_AWARDS,
				[[&"adik_priya", [[&"agar_agar_ros", 14], [&"ang_ku_kueh", 12]]]], 24)

		54:
			var l := _make(54, "Stacked Trays", "Trays, clear them all", 4, [3800, 4100], TILES_AWARDS,
				[[&"meiling", [[&"karipap", 20], [&"agar_agar_ros", 18]]]], 27,
				[_tray([Vector2i(1, 7), Vector2i(3, 7), Vector2i(6, 7)], &"agar_agar_ros", 5)])
			l.require_blockers_cleared = true
			return l

		55:
			var l := _make(55, "PTA Meeting", "Two guests and a box", 4, [4100, 4500], TILES_AWARDS,
				[
					[&"encik", [[&"tart", 14]]],
					[&"cikgu_salmah", [[&"kuih_lapis", 13]]],
				], 30,
				[_box([Vector2i(4, 0)], &"tart", 6),
				 _cover([Vector2i(2, 3), Vector2i(5, 3)], 2)])
			l.require_blockers_cleared = true
			l.story_before = &"beat_55_pibg"
			return l

		56:
			return _make(56, "Rainy Afternoon", "Relax", 2, [3600, 3900], TILES_AWARDS,
				[[&"meena", [[&"karipap", 14], [&"agar_agar_ros", 14]]]], 30)

		57:
			return _make(57, "Everything at Once", "Three blocker types", 4, [3900, 4300], TILES_AWARDS,
				[
					[&"runner", [[&"kuih_bom", 11]]],
					[&"kakak", [[&"agar_agar_ros", 11]]],
					[&"pak_mat", [[&"kuih_lapis", 11]]],
				], 28,
				[_leaf([Vector2i(1, 3), Vector2i(6, 4)]),
				 _cover([Vector2i(2, 1), Vector2i(5, 6)], 2),
				 _steamer([Vector2i(1, 6), Vector2i(6, 1)])])

		58:
			var l := _make(58, "Final Rehearsal", "Syrup and a box", 4, [4000, 4200], TILES_AWARDS,
				[
					[&"cikgu_salmah", [[&"tart", 16]]],
					[&"adik_priya", [[&"ang_ku_kueh", 15]]],
				], 30,
				[BlockerSpec.make(BlockerSpec.Kind.STICKY_SYRUP, [Vector2i(2, 4), Vector2i(3, 4), Vector2i(4, 3)], 1),
				 _box([Vector2i(3, 7)], &"karipap", 8)])
			l.require_blockers_cleared = true
			return l

		59:
			return _make(59, "Prep Night", "A long order", 4, [3800, 4100], TILES_AWARDS,
				[
					[&"makcik", [[&"karipap", 13], [&"tart", 12]]],
					[&"abang", [[&"kuih_bom", 12]]],
				], 28,
				[_cover([Vector2i(2, 2), Vector2i(5, 2)], 2),
				 _steamer([Vector2i(2, 6), Vector2i(5, 6)])])

		60:
			var l := _make(60, "Awards Day", "School Canteen finale", 5, [4600, 4900], TILES_AWARDS,
				[
					[&"kakak", [[&"ang_ku_kueh", 9], [&"kuih_lapis", 9]]],
					[&"encik", [[&"karipap", 9], [&"tart", 9]]],
					[&"cikgu_salmah", [[&"kuih_bom", 8]]],
					[&"adik_priya", [[&"agar_agar_ros", 8]]],
				], 33,
				[_cover([Vector2i(1, 1), Vector2i(6, 1), Vector2i(1, 5), Vector2i(6, 5)], 2),
				 _leaf([Vector2i(3, 2), Vector2i(4, 4)]),
				 _steamer([Vector2i(2, 3), Vector2i(5, 3)]),
				 _box([Vector2i(3, 7)], &"karipap", 8)])
			l.require_blockers_cleared = true
			l.story_before = &"beat_60_awards"
			l.story_after = &"beat_60_done"
			l.coins = 300
			return l

	return null
