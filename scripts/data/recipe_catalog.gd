class_name RecipeCatalog
extends RefCounted

const MANIFEST := "res://data/recipes/catalog.json"
const TARGET_COUNT := 200
static var _loaded := false
static var _recipes: Array[RecipeDefinition] = []
static var _collections: Array[RecipeCollectionDefinition] = []
static var rewards: Dictionary = {}
static var milestones: Array = []
static var load_errors: Array[String] = []

static func _build() -> void:
	if _loaded:
		return
	_loaded = true
	var file := FileAccess.open(MANIFEST, FileAccess.READ)
	if file == null:
		load_errors.append("Cannot read recipe manifest")
		return
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if not parsed is Dictionary:
		load_errors.append("Invalid recipe manifest")
		return
	rewards = parsed.get("rewards", {})
	milestones = parsed.get("milestones", [])
	for row in parsed.get("recipes", []):
		var recipe := RecipeDefinition.new()
		recipe.id = StringName(row.get("id", ""))
		recipe.collection_number = int(row.get("collection_number", 0))
		recipe.discovery_stage = int(row.get("discovery_stage", 0))
		recipe.image_path = row.get("image", "")
		recipe.gameplay_reference_id = StringName(row.get("gameplay_reference_id", ""))
		recipe.gameplay_candidate = row.get("gameplay_candidate", false)
		recipe.collection_tags = PackedStringArray(row.get("collection_tags", []))
		recipe.rarity = int(row.get("rarity", 0)) as RecipeDefinition.Rarity
		recipe.reward_id = row.get("reward_id", "discovery")
		recipe.research_status = row.get("research_status", "RESEARCH_REQUIRED")
		recipe.localized_fields = row.get("localized_fields", {})
		_recipes.append(recipe)
	for row in parsed.get("collections", []):
		var collection := RecipeCollectionDefinition.new()
		collection.id = StringName(row.get("id", ""))
		collection.display_names = row.get("display_names", {})
		collection.recipe_ids = PackedStringArray(row.get("recipe_ids", []))
		collection.completion_reward_id = row.get("completion_reward_id", "")
		_collections.append(collection)

static func all() -> Array[RecipeDefinition]:
	_build()
	return _recipes.duplicate()

static func find(id: StringName) -> RecipeDefinition:
	for recipe in all():
		if recipe.id == id:
			return recipe
	return null

static func for_stage(stage: int) -> StringName:
	for recipe in all():
		if recipe.discovery_stage == stage:
			return recipe.id
	return &""

static func collections() -> Array[RecipeCollectionDefinition]:
	_build()
	return _collections.duplicate()

static func collection(id: StringName) -> RecipeCollectionDefinition:
	for entry in collections():
		if entry.id == id:
			return entry
	return null

static func reward(id: String) -> Dictionary:
	_build()
	return rewards.get(id, {}).duplicate(true)

static func validate() -> Dictionary:
	_build()
	var errors: Array[String] = load_errors.duplicate()
	var warnings: Array[String] = []
	var ids := {}
	var numbers := {}
	var stages := {}
	var gameplay_ids := {}
	for object in GameplayObjectCatalog.all():
		gameplay_ids[object.id] = true
	for recipe in all():
		if recipe.id == &"" or ids.has(recipe.id):
			errors.append("Empty or duplicate recipe ID: %s" % recipe.id)
		if recipe.collection_number < 1 or recipe.collection_number > TARGET_COUNT or numbers.has(recipe.collection_number):
			errors.append("Invalid or duplicate collection number: %d" % recipe.collection_number)
		if recipe.discovery_stage < 1 or recipe.discovery_stage > 2000 or stages.has(recipe.discovery_stage):
			errors.append("Invalid or duplicate discovery stage: %d" % recipe.discovery_stage)
		ids[recipe.id] = true
		numbers[recipe.collection_number] = true
		stages[recipe.discovery_stage] = true
		if not rewards.has(recipe.reward_id):
			errors.append("Missing reward: %s" % recipe.reward_id)
		if recipe.gameplay_reference_id != &"" and not gameplay_ids.has(String(recipe.gameplay_reference_id)):
			errors.append("Unknown gameplay reference: %s" % recipe.gameplay_reference_id)
		if LevelLibrary.has_level(recipe.discovery_stage) and LevelLibrary.get_level(recipe.discovery_stage).recipe_unlock_id != recipe.id:
			errors.append("Recipe/stage assignment mismatch: %s" % recipe.id)
		for field in ["name", "alternative_names", "region", "state", "community", "category", "short_description", "ingredients_summary", "interesting_fact"]:
			for locale in ["ms", "en"]:
				if str(recipe.localized_fields.get(field, {}).get(locale, "")).is_empty():
					errors.append("Missing localization recipe.%s.%s (%s)" % [recipe.id, field, locale])
		if recipe.artwork() == null:
			warnings.append("Missing artwork: %s" % recipe.image_path)
		if recipe.research_status != "REVIEWED":
			warnings.append("Cultural review required: %s" % recipe.id)
		if recipe.discovery_stage > LevelLibrary.count():
			warnings.append("Future stage reservation: %d" % recipe.discovery_stage)
	var collection_ids := {}
	for entry in collections():
		if entry.id == &"" or collection_ids.has(entry.id):
			errors.append("Empty or duplicate collection ID: %s" % entry.id)
		collection_ids[entry.id] = true
		var member_ids := {}
		for id in entry.recipe_ids:
			if not ids.has(StringName(id)):
				errors.append("Unknown collection member: %s" % id)
			if member_ids.has(id):
				errors.append("Duplicate collection member: %s" % id)
			member_ids[id] = true
		if not rewards.has(entry.completion_reward_id) or entry.recipe_ids.is_empty():
			errors.append("Invalid collection/reward: %s" % entry.id)
	for reward_id in rewards:
		var definition: Dictionary = rewards[reward_id]
		for field in ["coins", "renovation_stars"]:
			if int(definition.get(field, 0)) < 0:
				errors.append("Negative reward: %s" % reward_id)
		for booster in definition.get("boosters", {}):
			if not SaveManager.DEFAULT_BOOSTERS.has(booster) or int(definition["boosters"][booster]) < 0:
				errors.append("Invalid booster reward: %s" % reward_id)
	var milestone_ids := {}
	var thresholds := {}
	for milestone in milestones:
		if str(milestone.get("id", "")).is_empty() or milestone_ids.has(milestone.id) or thresholds.has(int(milestone.get("threshold", 0))) or int(milestone.get("threshold", 0)) < 1 or int(milestone.get("threshold", 0)) > TARGET_COUNT:
			errors.append("Invalid or duplicate recipe milestone")
		milestone_ids[milestone.id] = true
		thresholds[int(milestone.threshold)] = true
		if not rewards.has(milestone.get("reward_id", "")):
			errors.append("Missing milestone reward")
	for stage in range(10, LevelLibrary.count() + 1, 10):
		if LevelLibrary.get_level(stage).recipe_unlock_id == &"":
			errors.append("Missing authored discovery interval: %d" % stage)
	return {"errors": errors, "warnings": warnings, "published": _recipes.size(), "target": TARGET_COUNT}
