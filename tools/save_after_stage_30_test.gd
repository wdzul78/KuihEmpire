extends Node

## A player who finished the 30-stage game must keep everything when stages are
## added, and stage 31 must open as soon as it exists.

const FIXTURE := "res://tools/fixtures/save_after_stage_30.json"

var failures: Array[String] = []

func check(ok: bool, why: String) -> void:
	if not ok:
		failures.append(why)
		push_error(why)

func _ready() -> void:
	run.call_deferred()

func run() -> void:
	var text := FileAccess.get_file_as_string(FIXTURE)
	var frozen: Dictionary = JSON.parse_string(text)
	SaveManager.save_path = "user://kuih_stage30_fixture_test.json"
	for path in [SaveManager.save_path, SaveManager.save_path + ".bak"]:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	var file := FileAccess.open(SaveManager.save_path, FileAccess.WRITE)
	file.store_string(text)
	file.close()
	SaveManager.load_game()
	check(SaveManager.data["profile"]["name"] == "Fixture", "profile kept")
	check(SaveManager.get_setting("language") == "ms", "language kept")
	check(EconomyManager.coins() == int(frozen["coins"]), "coins kept")
	check(int(SaveManager.data["stars_spent"]) == int(frozen["stars_spent"]), "spent stars kept")
	for stage in range(1, 31):
		var record: Dictionary = frozen["levels"][str(stage)]
		check(ProgressionManager.stars_for(stage) == int(record["stars"]), "stage %d stars kept" % stage)
		check(int(ProgressionManager.level_record(stage)["best_score"]) == int(record["best_score"]), "stage %d score kept" % stage)
		check(ProgressionManager.is_level_unlocked(stage), "stage %d still open" % stage)
	check(ProgressionManager.highest_cleared() == 30, "highest cleared stage kept")
	check(ProgressionManager.current_level() == mini(31, LevelLibrary.count()), "next stage offered")
	check(ProgressionManager.is_level_unlocked(31) == LevelLibrary.has_level(31), "stage 31 opens only when it exists")
	check(LocationManager.structural_level(&"family_stall") == 3, "stall upgrades kept")
	check(LocationManager.equipped(&"family_stall") == frozen["location_decor"]["family_stall"], "equipped decor kept")
	check(LocationManager.stall_unlocked(&"school_canteen"), "School Canteen unlocked")
	check(SaveManager.data["owned_decor"] == frozen["owned_decor"], "owned decor kept")
	# Milestones already claimed must not pay out again after the update.
	var cosmetics: Array = SaveManager.data["gerai"]["cosmetics"].duplicate()
	var coins := EconomyManager.coins()
	ProgressionManager.claim_journey_milestones()
	check(SaveManager.data["gerai"]["cosmetics"] == cosmetics, "milestone cosmetics not granted twice")
	check(EconomyManager.coins() == coins, "milestones do not pay twice")
	# The loaded save survives a write and a second load.
	var before: Dictionary = SaveManager.data.duplicate(true)
	check(SaveManager.save_game(), "save writes")
	SaveManager.load_game()
	check(JSON.stringify(SaveManager.data, "", true) == JSON.stringify(before, "", true), "save round trip")
	print("Stage 30 save tests: %s (%d problems)" % ["PASS" if failures.is_empty() else "FAIL", failures.size()])
	get_tree().quit(0 if failures.is_empty() else 1)
