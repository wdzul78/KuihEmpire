extends Node

## Level, star, chapter and recipe progression (autoload: `ProgressionManager`).
##
## Chapters unlock through play only - never through payment
## (Master Plan section 29).

signal stars_changed(level_id: int, stars: int)
signal level_unlocked(level_id: int)
signal recipe_unlocked(recipe_id: StringName)
signal chapter_unlocked(chapter_id: StringName)

const FIRST_LEVEL := 1


func _level_table() -> Dictionary:
	return SaveManager.data.get("levels", {})


func level_record(level_id: int) -> Dictionary:
	return _level_table().get(str(level_id), {})


func stars_for(level_id: int) -> int:
	return int(level_record(level_id).get("stars", 0))


## Cozy gating: everything up to two levels past the last clear is open, plus
## anything already cleared for replay. No harsh walls.
func is_level_unlocked(level_id: int) -> bool:
	if level_id <= FIRST_LEVEL:
		return true
	if stars_for(level_id) > 0:
		return true
	return level_id <= highest_cleared() + 2


func current_level() -> int:
	var best := FIRST_LEVEL
	for key in _level_table():
		var id := int(String(key))
		if int(_level_table()[key].get("stars", 0)) > 0:
			best = maxi(best, id + 1)
	return mini(best, LevelLibrary.count())


func highest_cleared() -> int:
	var best := 0
	for key in _level_table():
		var id := int(String(key))
		if int(_level_table()[key].get("stars", 0)) > 0:
			best = maxi(best, id)
	return best


func total_stars() -> int:
	var total := 0
	for key in _level_table():
		total += int(_level_table()[key].get("stars", 0))
	return total


func record_win(level_id: int, stars: int, moves_left: int) -> void:
	var reached := current_level()
	var table := _level_table()
	var key := str(level_id)
	var record: Dictionary = table.get(key, {})
	var previous := int(record.get("stars", 0))
	record["stars"] = maxi(previous, stars)
	record["best_moves_left"] = maxi(int(record.get("best_moves_left", 0)), moves_left)
	table[key] = record
	SaveManager.data["levels"] = table
	SaveManager.mark_dirty()

	if level_id + 1 > reached:
		level_unlocked.emit(level_id + 1)
	stars_changed.emit(level_id, int(record["stars"]))


func record_attempt() -> void:
	var stats: Dictionary = SaveManager.data.get("stats", {})
	stats["levels_played"] = int(stats.get("levels_played", 0)) + 1
	SaveManager.data["stats"] = stats
	SaveManager.mark_dirty()


func record_moves(count: int) -> void:
	var stats: Dictionary = SaveManager.data.get("stats", {})
	stats["moves_played"] = int(stats.get("moves_played", 0)) + count
	stats["levels_won"] = int(stats.get("levels_won", 0))
	SaveManager.data["stats"] = stats
	SaveManager.mark_dirty()


func record_win_count() -> void:
	var stats: Dictionary = SaveManager.data.get("stats", {})
	stats["levels_won"] = int(stats.get("levels_won", 0)) + 1
	SaveManager.data["stats"] = stats
	SaveManager.mark_dirty()


func stats() -> Dictionary:
	return SaveManager.data.get("stats", {})


# --- Chapters --------------------------------------------------------------

func unlocked_chapters() -> Array:
	return SaveManager.data.get("chapters", ["prologue"])


func is_chapter_unlocked(chapter_id: StringName) -> bool:
	return unlocked_chapters().has(String(chapter_id))


func unlock_chapter(chapter_id: StringName) -> void:
	var list: Array = unlocked_chapters()
	if list.has(String(chapter_id)):
		return
	list.append(String(chapter_id))
	SaveManager.data["chapters"] = list
	SaveManager.mark_dirty()
	chapter_unlocked.emit(chapter_id)


# --- Recipe book -----------------------------------------------------------

func unlocked_recipes() -> Array:
	return SaveManager.data.get("recipes", [])


func is_recipe_unlocked(recipe_id: StringName) -> bool:
	if recipe_id == &"":
		return false
	return unlocked_recipes().has(String(recipe_id))


func unlock_recipe(recipe_id: StringName) -> bool:
	if recipe_id == &"" or is_recipe_unlocked(recipe_id):
		return false
	var list: Array = unlocked_recipes()
	list.append(String(recipe_id))
	SaveManager.data["recipes"] = list
	SaveManager.mark_dirty()
	recipe_unlocked.emit(recipe_id)
	return true


## Recipe mastery is collection progress, never a stat boost
## (Master Plan section 25).
func mastery(recipe_id: StringName) -> int:
	return int((SaveManager.data.get("mastery", {}) as Dictionary).get(String(recipe_id), 0))


func mastery_stars(recipe_id: StringName) -> int:
	return clampi(int(mastery(recipe_id) / 10), 0, 5)


func add_mastery(recipe_id: StringName, amount: int) -> void:
	if recipe_id == &"" or amount <= 0:
		return
	var table: Dictionary = SaveManager.data.get("mastery", {})
	var key := String(recipe_id)
	var before := int(table.get(key, 0))
	var after := before + amount
	table[key] = after
	SaveManager.data["mastery"] = table
	SaveManager.mark_dirty()
	if int(before / 10) < int(after / 10):
		SaveManager.mark_dirty()


# --- Story -----------------------------------------------------------------

func story_seen(beat_id: StringName) -> bool:
	return (SaveManager.data.get("story_seen", []) as Array).has(String(beat_id))


func mark_story_seen(beat_id: StringName) -> void:
	if beat_id == &"" or story_seen(beat_id):
		return
	var list: Array = SaveManager.data.get("story_seen", [])
	list.append(String(beat_id))
	SaveManager.data["story_seen"] = list
	SaveManager.mark_dirty()


# --- Gerai -----------------------------------------------------------------

func gerai_level() -> int:
	return int((SaveManager.data.get("gerai", {}) as Dictionary).get("level", 1))


func upgrade_gerai(cost: int) -> bool:
	if not EconomyManager.spend_coins(cost):
		return false
	var gerai: Dictionary = SaveManager.data.get("gerai", {})
	gerai["level"] = gerai_level() + 1
	SaveManager.data["gerai"] = gerai
	SaveManager.mark_dirty()
	return true


static func gerai_stage_name(level: int) -> String:
	var names := [
		"Small Wooden Stall", "Better Counter", "Display Cabinet",
		"New Signage", "Larger Stall", "Market Booth", "Festival Booth",
	]
	if level <= 0:
		return names[0]
	return names[mini(level - 1, names.size() - 1)]


static func gerai_upgrade_cost(level: int) -> int:
	return 400 + (level - 1) * 350


## Wipes progress. Used by the settings screen.
func reset_all() -> void:
	SaveManager.reset()


# --- Tutorial (separate from the 30-stage campaign) -------------------------

## 0 means the player has not started the tutorial yet.
func tutorial_index() -> int:
	return int(SaveManager.data.get("tutorial_index", 0))


func tutorial_done() -> bool:
	return bool(SaveManager.data.get("tutorial_done", false))


func needs_tutorial() -> bool:
	return not tutorial_done()


func save_tutorial_index(index: int) -> void:
	SaveManager.data["tutorial_index"] = clampi(index, 1, TutorialLibrary.count())
	SaveManager.mark_dirty()


func complete_tutorial() -> void:
	SaveManager.data["tutorial_index"] = TutorialLibrary.count()
	SaveManager.data["tutorial_done"] = true
	SaveManager.mark_dirty()


## Lets the player replay lessons from Home or the journey map.
func reset_tutorial() -> void:
	SaveManager.data["tutorial_index"] = 0
	SaveManager.data["tutorial_done"] = false
	SaveManager.mark_dirty()


# --- Story pages -----------------------------------------------------------

func story_read(group_id: StringName) -> bool:
	return (SaveManager.data.get("story_read", []) as Array).has(String(group_id))


func mark_story_read(group_id: StringName) -> void:
	if group_id == &"" or story_read(group_id):
		return
	var list: Array = SaveManager.data.get("story_read", [])
	list.append(String(group_id))
	SaveManager.data["story_read"] = list
	SaveManager.mark_dirty()
