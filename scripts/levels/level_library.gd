class_name LevelLibrary
extends RefCounted

## Public access to every campaign stage. Stages are authored in
## `scripts/levels/chapters/`, one file per location, so adding content never
## touches the engine.

const COMMON_TITLES_MS := {
	"Free Play": "Main Bebas",
}
static var _cache: Dictionary = {}
## Tests set this to exercise screens with stages that are not authored yet.
static var _test_last_stage := 0


## Registered in stage order. Each chapter starts right after the previous one.
static func chapters() -> Array:
	return [FamilyStallChapter, SchoolCanteenChapter]


## Player-facing stage name in the current language.
static func display_title(level: LevelDefinition) -> String:
	if SaveManager.get_setting("language", "en") == "en":
		return level.title
	for chapter in chapters():
		if chapter.TITLES_MS.has(level.title):
			return chapter.TITLES_MS[level.title]
	return COMMON_TITLES_MS.get(level.title, level.title)


static func count() -> int:
	return _test_last_stage if _test_last_stage > 0 else chapters().back().LAST_STAGE


static func get_level(level_id: int) -> LevelDefinition:
	if _cache.has(level_id):
		return _cache[level_id]
	var level := _build(level_id)
	level.recipe_unlock_id = RecipeCatalog.for_stage(level_id)
	if level.base_coin_reward < 0:
		level.base_coin_reward = level.coins
	_cache[level_id] = level
	return level


static func has_level(level_id: int) -> bool:
	return level_id >= 1 and level_id <= count()


static func all() -> Array[LevelDefinition]:
	var out: Array[LevelDefinition] = []
	for id in range(1, count() + 1):
		out.append(get_level(id))
	return out


## True for the last stage of a chapter.
static func is_chapter_finale(level_id: int) -> bool:
	var chapter = _chapter_for(level_id)
	return chapter != null and chapter.LAST_STAGE == level_id


static func _chapter_for(level_id: int) -> Variant:
	for chapter in chapters():
		if level_id >= chapter.FIRST_STAGE and level_id <= chapter.LAST_STAGE:
			return chapter
	return null


static func _build(level_id: int) -> LevelDefinition:
	var chapter = _chapter_for(level_id)
	return chapter.build(level_id) if chapter != null else StageChapter.placeholder(level_id)


# --- editor support --------------------------------------------------------

## Writes every level to `res://resources/levels/level_XXX.tres` so designers can
## hand-tune them in the editor (Master Plan sections 57 and 58).
static func export_all() -> int:
	var written := 0
	for level in all():
		var path := "res://resources/levels/level_%03d.tres" % level.id
		var err := ResourceSaver.save(level, path)
		if err == OK:
			written += 1
		else:
			push_error("LevelLibrary: could not save %s (%d)" % [path, err])
	return written
