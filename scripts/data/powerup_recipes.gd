class_name PowerupRecipes
extends RefCounted

## Recipe-only ID. Existing board/save enum values remain unchanged.
const PISANG_COMBO := 100
const ENTRIES := [
	[BoardCell.Special.TAPAU, "Pulut Panggang", "Clears one full row."],
	[BoardCell.Special.TAPAU_VERTICAL, "Kuih Selorot", "Unwraps its leaf to clear one full column."],
	[BoardCell.Special.DULANG, "Badak Berendam", "Clears a 3 × 3 area. Combine with a directional special to clear three rows or columns."],
	[BoardCell.Special.ORDER, "Kek Lapis Sarawak Premium", "Zaps the most numerous kuih on the board. Combine two to blast the whole board."],
	[BoardCell.Special.HANTAR, "Kuih Sepit", "Created by a square match; flies towards an order target."],
	[PISANG_COMBO, "Pisang Goreng", "Combine Badak Berendam + Kuih Selorot. Crispy banana fritters clear three neighbouring columns."],
]

static func key(kind: int) -> StringName:
	return StringName("powerup_%d" % kind)

static func introduce(kind: int) -> void:
	for entry in ENTRIES:
		if int(entry[0]) == kind:
			ProgressionManager.unlock_recipe(key(kind))
			return

static func sync_seen_kuih() -> void:
	# Preserve access to Pisang Goreng for players who already discovered it.
	if ProgressionManager.is_recipe_unlocked(key(BoardCell.Special.TAPAU_VERTICAL)):
		ProgressionManager.unlock_recipe(key(PISANG_COMBO))
	for kuih in KuihLibrary.all():
		if String(kuih.id) in SaveManager.data.get("kuih_seen", []):
			ProgressionManager.unlock_recipe(kuih.recipe_id)
