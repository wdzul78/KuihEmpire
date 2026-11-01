class_name JourneyLibrary
extends RefCounted

## A milestone closes every ten stages. Recipes here are legacy unlocks; cultural
## recipes from the catalog are discovered by clearing the stage itself.
const STORY := &"family_stall"
const MILESTONES := {
	10: {"ms": "Mula Bangkit", "en": "A Fresh Start", "cosmetic": "family_signboard", "recipe": &"kuih_ketayap", "story_ms": "Pelanggan kembali ke gerai keluarga! Renovasi papan tanda kini dibuka dan resipi Ketayap dibuka.", "story_en": "Customers are returning to our family stall! A signboard upgrade is available in My Stalls, and the Ketayap recipe is unlocked."},
	20: {"ms": "Kemas & Cantikkan Gerai", "en": "Make the Stall Shine", "cosmetic": "family_awning_counter", "recipe": &"keria", "story_ms": "Gerai semakin meriah! Renovasi awning, kaunter dan rak kuih kini dibuka. Resipi Keria dibuka.", "story_en": "Our stall is thriving! The counter and display upgrade is now available in My Stalls. The Keria recipe is unlocked."},
	30: {"ms": "Kembangkan Bisnes", "en": "Grow the Business", "cosmetic": "family_stall_complete", "recipe": &"penyaram", "story_ms": "Tempahan komuniti berjaya disiapkan! Gerai Keluarga lengkap dan Gerai Lv 2 dibuka. Kantin Sekolah ialah destinasi seterusnya.", "story_en": "The community order is served! Our Family Stall story is complete and the final structural upgrade is available in My Stalls. School Canteen is our next destination."},
	40: {"ms": "Kantin Kembali Hidup", "en": "The Canteen Wakes Up", "cosmetic": "school_first_upgrade", "recipe": &"", "story_ms": "Hari jualan berjaya dan murid kembali ke kantin! Renovasi pertama Kantin Sekolah kini dibuka dan resipi Tebaloi ditemui.", "story_en": "Sale day was a success and the students are back! The first School Canteen upgrade is available in My Stalls, and the Tebaloi recipe is discovered."},
	50: {"ms": "Kantin Kegemaran Murid", "en": "The Students' Favourite", "cosmetic": "school_second_upgrade", "recipe": &"", "story_ms": "Hari Sukan selesai dan kantin semakin meriah! Renovasi kedua Kantin Sekolah kini dibuka dan resipi Putu Piring ditemui.", "story_en": "Sports Day is over and the canteen is thriving! The second School Canteen upgrade is available in My Stalls, and the Putu Piring recipe is discovered."},
	60: {"ms": "Kantin Lengkap", "en": "Canteen Complete", "cosmetic": "school_canteen_complete", "recipe": &"", "story_ms": "Hari Anugerah berakhir dengan gembira! Renovasi terakhir Kantin Sekolah kini dibuka dan resipi Ang Ku Kueh ditemui. Pasar Pagi ialah destinasi seterusnya.", "story_en": "Awards Day ended happily! The final School Canteen upgrade is available in My Stalls, and the Ang Ku Kueh recipe is discovered. The Morning Market is our next destination."},
}

## One map section per ten stages, bottom of the map first. `chapter` names the
## opening story group and `connector` the art frame on the seam below the section.
## The School Canteen sections borrow Family Stall worlds until their art arrives.
const SECTIONS := [
	{"id": 1, "last": 10, "location": &"family_stall", "world": "village", "connector": 0, "chapter": &"prologue", "place_ms": "Gerai Keluarga", "place_en": "Family Stall", "title_ms": "Gerai Keluarga · Mula Bangkit", "title_en": "Family Stall · A New Beginning"},
	{"id": 11, "last": 20, "location": &"family_stall", "world": "market", "connector": 1, "chapter": &"kuching", "place_ms": "Pasar Kampung", "place_en": "Village Market", "title_ms": "Gerai Keluarga · Kemas & Cantikkan", "title_en": "Family Stall · A Fresh Look"},
	{"id": 21, "last": 30, "location": &"family_stall", "world": "waterfront", "connector": 0, "chapter": &"sarawak", "place_ms": "Waterfront Kuching", "place_en": "Kuching Waterfront", "title_ms": "Gerai Keluarga · Kembangkan Bisnes", "title_en": "Family Stall · Growing Together"},
	{"id": 31, "last": 40, "location": &"school_canteen", "world": "village", "connector": 0, "chapter": &"school_canteen", "place_ms": "Pintu Sekolah", "place_en": "School Gate", "title_ms": "Kantin Sekolah · Hari Pertama", "title_en": "School Canteen · First Days"},
	{"id": 41, "last": 50, "location": &"school_canteen", "world": "market", "connector": 1, "chapter": &"school_canteen_2", "place_ms": "Kantin Sekolah", "place_en": "School Canteen", "title_ms": "Kantin Sekolah · Hari Sukan", "title_en": "School Canteen · Sports Day"},
	{"id": 51, "last": 60, "location": &"school_canteen", "world": "waterfront", "connector": 0, "chapter": &"school_canteen_3", "place_ms": "Padang Sekolah", "place_en": "School Field", "title_ms": "Kantin Sekolah · Hari Anugerah", "title_en": "School Canteen · Awards Day"},
]
const LOCATION_NAMES_MS := {
	&"family_stall": "Gerai Keluarga", &"school_canteen": "Kantin Sekolah", &"morning_market": "Pasar Pagi",
	&"town": "Pekan", &"city": "Bandar", &"festival": "Festival Kuih",
	&"bazaar_ramadan": "Bazar Ramadan", &"government_canteen": "Kantin Pejabat Kerajaan",
}

## Only sections that already have stages appear on the map.
static func released_sections() -> Array:
	return SECTIONS.filter(func(section: Dictionary) -> bool: return section["id"] <= LevelLibrary.count())

static func section_index(stage: int) -> int:
	for index in SECTIONS.size():
		if stage <= SECTIONS[index]["last"]:
			return index
	return SECTIONS.size() - 1

static func section_for(stage: int) -> Dictionary:
	return SECTIONS[section_index(stage)]

## Name of the place after the last released stage; empty when the route is complete.
static func next_destination() -> String:
	var next := LevelLibrary.count() + 1
	var location := LocationDefinition.for_stage(next)
	if next < location.stage_start or next > location.stage_end:
		return ""
	return JourneyArt.localized(LOCATION_NAMES_MS[location.id], location.display_name)

static func milestone(stage: int) -> Dictionary:
	return MILESTONES.get(stage, {})

static func name_for(stage: int) -> String:
	var last := mini(MILESTONES.keys().max(), (int((stage - 1) / 10) + 1) * 10)
	var info: Dictionary = MILESTONES[last]
	return JourneyArt.localized(info["ms"], info["en"])

static func completion_text(stage: int) -> String:
	var info := milestone(stage)
	return JourneyArt.localized(info["story_ms"], info["story_en"])
