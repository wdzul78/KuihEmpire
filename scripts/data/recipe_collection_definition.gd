class_name RecipeCollectionDefinition
extends Resource

@export var id: StringName
@export var display_names: Dictionary
@export var recipe_ids: PackedStringArray
@export var completion_reward_id: String
@export var artwork_path: String
@export var badge_id: StringName
@export var content_version := 1

func display_name() -> String:
	return str(display_names.get(str(SaveManager.get_setting("language", "en")), display_names.get("en", String(id))))
