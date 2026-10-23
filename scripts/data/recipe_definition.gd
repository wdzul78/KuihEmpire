class_name RecipeDefinition
extends Resource

enum Rarity { COMMON, REGIONAL, RARE, LEGENDARY }

@export var id: StringName
@export var collection_number: int
@export var discovery_stage: int
@export var image_path: String
@export var gameplay_reference_id: StringName
@export var gameplay_candidate := false
@export var collection_tags: PackedStringArray
@export var rarity: Rarity = Rarity.COMMON
@export var reward_id := "discovery"
@export var research_status := "RESEARCH_REQUIRED"
## Stable localization keys: recipe.<id>.<field>; values are locale -> text.
@export var localized_fields: Dictionary = {}

func text(field: String, locale: String = "") -> String:
	if locale.is_empty():
		locale = str(SaveManager.get_setting("language", "en"))
	var translations: Dictionary = localized_fields.get(field, {})
	return str(translations.get(locale, translations.get("en", "RESEARCH_REQUIRED")))

func artwork() -> Texture2D:
	if not image_path.is_empty() and ResourceLoader.exists(image_path):
		return load(image_path) as Texture2D
	return null
