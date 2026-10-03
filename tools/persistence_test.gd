extends Node

var problems: Array[String] = []
const TEST_PATH := "user://kuih_persistence_test.json"


func check(condition: bool, message: String) -> void:
	if not condition:
		problems.append(message)


func write_raw(text: String) -> void:
	var file := FileAccess.open(TEST_PATH, FileAccess.WRITE)
	file.store_string(text)
	file.close()


func _ready() -> void:
	SaveManager.save_path = TEST_PATH
	SaveManager.reset()
	# Round trip through JSON (numbers become floats) and repeated replacement.
	SaveManager.data["coins"] = 777
	SaveManager.data["levels"] = {"3": {"stars": 2, "best_moves_left": 8}}
	check(SaveManager.save_game(), "first atomic save failed")
	SaveManager.load_game()
	check(EconomyManager.coins() == 777 and ProgressionManager.stars_for(3) == 2, "round trip lost progress")
	SaveManager.data["coins"] = 888
	check(SaveManager.save_game(), "replacement save failed")
	check(not FileAccess.file_exists(TEST_PATH + ".tmp"), "successful save left pending temporary file")
	write_raw("{truncated")
	SaveManager.load_game()
	check(EconomyManager.coins() == 777 and ProgressionManager.stars_for(3) == 2, "corrupt primary did not recover last good save")
	check(SaveManager.save_game(), "recovered save could not be rewritten")
	write_raw(JSON.stringify({
		"coins": "bad", "boosters": [], "settings": {"sfx": "yes", "music": false},
		"levels": {"1": "bad", "2": {"stars": 99, "best_moves_left": -8}, "31": {"stars": 3}},
		"mastery": {"onde_onde": "bad"}, "gerai": {"level": -5, "cosmetics": [42, "pink", "pink"]},
		"stats": {"levels_played": "bad", "moves_played": 12},
		"recipes": [null, 42, "onde_onde", "onde_onde"], "story_read": "bad", "chapters": null,
		"tutorial_index": 999, "tutorial_done": "true"
	}))
	SaveManager.load_game()
	check(EconomyManager.coins() == 250, "invalid coin type was not defaulted")
	check(EconomyManager.booster_count(EconomyManager.Booster.SPATULA) == 3, "invalid booster container was not defaulted")
	check(GameManager.setting("sfx") == true and GameManager.setting("music") == false, "settings normalization lost defaults or valid setting")
	check(ProgressionManager.stars_for(1) == 0 and ProgressionManager.stars_for(2) == 3, "level records were not sanitized")
	check(not SaveManager.data["levels"].has("31"), "invalid stage survived normalization")
	check(ProgressionManager.mastery(&"onde_onde") == 0 and ProgressionManager.gerai_level() == 1, "invalid nested values survived")
	check(ProgressionManager.unlocked_recipes() == ["onde_onde"], "recipe list not filtered/deduplicated")
	check(ProgressionManager.tutorial_index() == 8 and not ProgressionManager.tutorial_done(), "tutorial normalization failed")
	check(ProgressionManager.stats()["moves_played"] == 12, "partial stats lost valid values")
	# Reset must also replace the recovery copy, not resurrect erased progress.
	SaveManager.reset()
	write_raw("broken")
	SaveManager.load_game()
	check(ProgressionManager.total_stars() == 0 and EconomyManager.coins() == 250, "reset backup resurrected progress")
	SaveManager.data["coins"] = 432
	SaveManager.mark_dirty()
	SaveManager._notification(NOTIFICATION_APPLICATION_PAUSED)
	SaveManager.load_game()
	check(EconomyManager.coins() == 432, "application pause did not flush pending progress")
	# An unwritable/missing parent must keep dirty state for a later retry.
	SaveManager.save_path = "user://missing_save_test_%d/save.json" % Time.get_ticks_usec()
	check(not SaveManager.save_game() and SaveManager._dirty, "failed write cleared dirty flag")
	SaveManager.save_path = TEST_PATH
	SaveManager._flush()
	check(not SaveManager._dirty, "retry did not clear dirty flag after successful write")
	print("Persistence tests: %s (%d problems; recovery/write warnings above are expected)" % ["PASS" if problems.is_empty() else "FAIL", problems.size()])
	for problem in problems:
		print("  ! " + problem)
	get_tree().quit(0 if problems.is_empty() else 1)
