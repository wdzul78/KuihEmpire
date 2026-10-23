class_name RecipeText
extends RefCounted

const WORDS := {
	"book": ["Buku Resipi", "Recipe Book"],
	"recipes": ["Resipi", "Recipes"], "collections": ["Koleksi", "Collections"],
	"guide": ["Panduan", "Gameplay Guide"], "locked": ["Belum ditemui", "Undiscovered"],
	"all": ["Semua resipi", "All recipes"], "card_stage": ["Stage %d", "Stage %d"],
	"awaiting_review": ["Dalam kajian", "Awaiting review"],
	"previous": ["Sebelum", "Previous"], "next": ["Seterusnya", "Next"],
	"progress": ["%d / %d ditemui · 200 dirancang", "%d / %d discovered · 200 planned"],
	"stage": ["Temui pada Stage %d", "Discover at Stage %d"],
	"future": ["Stage %d · Akan datang", "Stage %d · Coming later"],
	"art_pending": ["Ilustrasi akan datang", "Artwork coming later"],
	"new": ["KUIH BAHARU DITEMUI!", "NEW KUIH DISCOVERED!"],
	"view": ["Lihat resipi", "View Recipe"], "continue": ["Teruskan", "Continue"],
	"close": ["Tutup", "Close"], "claim": ["Tuntut ganjaran", "Claim Reward"],
	"claimed": ["Sudah dituntut", "Claimed"], "milestone": ["Koleksi %d resipi", "Collect %d recipes"],
	"research": ["Maklumat budaya sedang dikaji", "Cultural information awaiting review"],
	"alternative_names": ["Nama lain", "Alternative names"], "region": ["Wilayah", "Region"],
	"state": ["Negeri", "State"], "community": ["Komuniti", "Community"],
	"category": ["Kategori", "Category"], "short_description": ["Tentang kuih", "About this kuih"],
	"ingredients_summary": ["Bahan utama", "Key ingredients"], "interesting_fact": ["Fakta menarik", "Interesting fact"],
	"save_failed": ["Tidak dapat menyimpan. Sila cuba lagi.", "Could not save. Please try again."],
	"reward": ["Ganjaran: %s", "Reward: %s"],
	"coins": ["%d syiling", "%d coins"], "stars": ["%d bintang renovasi", "%d renovation stars"],
	"booster": ["%d booster (%s)", "%d booster (%s)"],
}

static func text(key: String) -> String:
	var pair: Array = WORDS.get(key, [key, key])
	return str(pair[0 if SaveManager.get_setting("language", "en") == "ms" else 1])

static func reward_summary(reward: Dictionary) -> String:
	var parts := PackedStringArray()
	if int(reward.get("coins", 0)) > 0:
		parts.append(text("coins") % int(reward.coins))
	if int(reward.get("renovation_stars", 0)) > 0:
		parts.append(text("stars") % int(reward.renovation_stars))
	for id in reward.get("boosters", {}):
		parts.append(text("booster") % [int(reward.boosters[id]), str(id)])
	return " + ".join(parts)
