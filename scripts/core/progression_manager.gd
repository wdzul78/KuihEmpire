extends Node

## Level, star, chapter and recipe progression (autoload: `ProgressionManager`).
##
## Chapters unlock through play only - never through payment
## (Master Plan section 29).

signal gerai_upgraded()

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


## Sequential stage unlocks; any winning star rating opens the next stage.
func is_level_unlocked(level_id: int) -> bool:
	if not LevelLibrary.has_level(level_id):
		return false
	if level_id == FIRST_LEVEL:
		return true
	if stars_for(level_id) > 0:
		return true
	return level_id <= highest_cleared() + 1


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


func record_win(level_id: int, stars: int, moves_left: int, score: int = 0) -> void:
	var reached := current_level()
	var table := _level_table()
	var key := str(level_id)
	var record: Dictionary = table.get(key, {})
	var previous := int(record.get("stars", 0))
	record["stars"] = maxi(previous, clampi(stars, 1, 3))
	record["best_score"] = maxi(int(record.get("best_score", 0)), score)
	record["completed"] = true
	record["first_clear_claimed"] = true
	record["best_moves_left"] = maxi(int(record.get("best_moves_left", 0)), moves_left)
	table[key] = record
	SaveManager.data["levels"] = table
	SaveManager.mark_dirty()

	claim_journey_milestones()
	if LevelLibrary.has_level(level_id + 1) and level_id + 1 > reached:
		level_unlocked.emit(level_id + 1)
	stars_changed.emit(level_id, int(record["stars"]))


func world_state() -> int:
	return LocationManager.structural_level(&"family_stall")


## Existing saves derive the same world state; persistent claim flags prevent
## duplicate grants. HeartManager owns its separate Free Play claims.
func claim_journey_milestones() -> void:
	for stage in JourneyLibrary.MILESTONES:
		if stars_for(stage) <= 0:
			continue
		var flag := StringName("milestone_claim_%d" % stage)
		if story_seen(flag):
			continue
		var info: Dictionary = JourneyLibrary.milestone(stage)
		unlock_recipe(info["recipe"])
		var gerai: Dictionary = SaveManager.data.get("gerai", {})
		var cosmetics: Array = gerai.get("cosmetics", [])
		if not cosmetics.has(info["cosmetic"]):
			cosmetics.append(info["cosmetic"])
		gerai["cosmetics"] = cosmetics
		if stage == 30:
			gerai["level"] = maxi(2, int(gerai.get("level", 1)))
			unlock_chapter(&"school_canteen")
		SaveManager.data["gerai"] = gerai
		mark_story_seen(flag)


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


func upgrade_gerai(_cost: int) -> bool:
	# Compatibility entry point: the authored milestone/cost gate is authoritative.
	return LocationManager.upgrade(&"family_stall")


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
	return TutorialLibrary.resume_index(int(SaveManager.data.get("tutorial_index", 0)))


func tutorial_done() -> bool:
	return bool(SaveManager.data.get("tutorial_done", false))


func needs_tutorial() -> bool:
	return not tutorial_done() or not delivery_unlocked()


func delivery_unlocked() -> bool:
	return bool(SaveManager.data.get("special_unlocks", {}).get("hantar", false))

func unlock_delivery() -> void:
	var unlocks: Dictionary = SaveManager.data.get("special_unlocks", {})
	unlocks["hantar"] = true
	SaveManager.data["special_unlocks"] = unlocks
	SaveManager.mark_dirty()

func save_tutorial_index(index: int) -> void:
	SaveManager.data["tutorial_index"] = TutorialLibrary.resume_index(clampi(index, 1, TutorialLibrary.count()))
	SaveManager.mark_dirty()


func complete_tutorial() -> void:
	unlock_delivery()
	SaveManager.data["tutorial_index"] = TutorialLibrary.ACTIVE_LESSONS.back()
	SaveManager.data["tutorial_done"] = true
	SaveManager.mark_dirty()

func claim_tutorial_reward(index: int) -> bool:
	var claimed: Array = SaveManager.data.get("tutorial_rewarded", [])
	var key := str(index)
	if key in claimed:
		return false
	claimed.append(key)
	SaveManager.data["tutorial_rewarded"] = claimed
	SaveManager.mark_dirty()
	return true


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


func best_score(level_id: int) -> int:
	return int(level_record(level_id).get("best_score", 0))

func first_clear_available(level_id: int) -> bool:
	var record := level_record(level_id)
	return not bool(record.get("first_clear_claimed", stars_for(level_id) > 0))


func total_best_score() -> int:
	var total := 0
	for id in range(1, LevelLibrary.count() + 1):
		if stars_for(id) > 0:
			total += best_score(id)
	return total
