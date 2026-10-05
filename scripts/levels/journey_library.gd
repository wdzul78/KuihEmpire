class_name JourneyLibrary
extends RefCounted

## MVP: one story, three milestones, thirty playable stages.
const STORY := &"family_stall"
const MILESTONES := {
	10: {"ms": "Mula Bangkit", "en": "A Fresh Start", "cosmetic": "family_signboard", "recipe": &"kuih_ketayap", "story_ms": "Pelanggan kembali ke gerai keluarga! Papan tanda baharu kini siap dan resipi Ketayap dibuka.", "story_en": "Customers are returning to our family stall! A signboard upgrade is available in My Stalls, and the Ketayap recipe is unlocked."},
	20: {"ms": "Kemas & Cantikkan Gerai", "en": "Make the Stall Shine", "cosmetic": "family_awning_counter", "recipe": &"keria", "story_ms": "Gerai semakin meriah! Awning, kaunter dan rak kuih dinaik taraf. Resipi Keria dibuka.", "story_en": "Our stall is thriving! The counter and display upgrade is now available in My Stalls. The Keria recipe is unlocked."},
	30: {"ms": "Kembangkan Bisnes", "en": "Grow the Business", "cosmetic": "family_stall_complete", "recipe": &"penyaram", "story_ms": "Tempahan komuniti berjaya disiapkan! Gerai Keluarga lengkap dan Gerai Lv 2 dibuka. Kantin Sekolah ialah destinasi seterusnya — akan datang selepas MVP.", "story_en": "The community order is served! Our Family Stall story is complete and the final structural upgrade is available in My Stalls. School Canteen is our next destination — coming after the MVP."},
}

static func milestone(stage: int) -> Dictionary:
	return MILESTONES.get(stage, {})

static func name_for(stage: int) -> String:
	var last := mini(30, (int((stage - 1) / 10) + 1) * 10)
	var info: Dictionary = MILESTONES[last]
	return JourneyArt.localized(info["ms"], info["en"])

static func completion_text(stage: int) -> String:
	var info := milestone(stage)
	return JourneyArt.localized(info["story_ms"], info["story_en"])
