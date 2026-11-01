extends Node

## Stages already released must stay exactly as players know them. Compares every
## stored level field against a snapshot taken before the library was split.
## `-- --write` replaces the snapshot, for a deliberate rebalance only.

const FIXTURE := "res://tools/fixtures/levels_1_30_snapshot.json"
const SNAPSHOT_LAST := 30

var failures: Array[String] = []

func check(ok: bool, why: String) -> void:
	if not ok:
		failures.append(why)
		push_error(why)

func _ready() -> void:
	run.call_deferred()

func run() -> void:
	SaveManager.save_path = "user://kuih_level_snapshot_test.json"
	SaveManager.reset()
	var current := {}
	for stage in range(1, SNAPSHOT_LAST + 1):
		current[str(stage)] = _encode(LevelLibrary.get_level(stage))
	if OS.get_cmdline_user_args().has("--write"):
		var file := FileAccess.open(FIXTURE, FileAccess.WRITE)
		file.store_string(JSON.stringify(current, "\t", true))
		file.close()
		print("Level snapshot written: %d stages" % current.size())
		get_tree().quit(0)
		return
	var frozen: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(FIXTURE))
	check(frozen.size() == SNAPSHOT_LAST, "snapshot holds every stage")
	for stage in frozen:
		var before: Dictionary = frozen[stage]
		var after: Dictionary = JSON.parse_string(JSON.stringify(current[stage]))
		for field in before:
			check(JSON.stringify(before[field], "", true) == JSON.stringify(after.get(field), "", true), "stage %s changed %s" % [stage, field])
		check(before.size() == after.size(), "stage %s changed its field list" % stage)
	_check_structure()
	print("Level snapshot tests: %s (%d problems)" % ["PASS" if failures.is_empty() else "FAIL", failures.size()])
	get_tree().quit(0 if failures.is_empty() else 1)

func _check_structure() -> void:
	var next := 1
	for chapter in LevelLibrary.chapters():
		check(chapter.FIRST_STAGE == next, "chapters are contiguous at %d" % next)
		next = chapter.LAST_STAGE + 1
	check(LevelLibrary.count() == next - 1, "count follows the chapters")
	check(LevelLibrary.has_level(LevelLibrary.count()) and not LevelLibrary.has_level(LevelLibrary.count() + 1), "has_level follows the chapters")
	check(LevelLibrary.is_chapter_finale(30) and not LevelLibrary.is_chapter_finale(29), "stage 30 closes the Family Stall")
	check(LocationDefinition.find(&"family_stall").playable, "Family Stall is playable")
	check(LocationDefinition.find(&"school_canteen").playable == LevelLibrary.has_level(31), "School Canteen opens with its stages")
	check(not LocationDefinition.find(&"morning_market").playable, "Morning Market has no stages yet")
	check(LevelLibrary.get_level(5).chapter_id == &"family_stall", "stage belongs to its location")
	check(StageChapter.placeholder(45).chapter_id == &"school_canteen", "later stages belong to their location")
	check(StageChapter.placeholder(45).background_id == &"school", "later stages use their location's mood")
	check(StageChapter.placeholder(45).coins == StageChapter.placeholder(31).coins, "coin reward stops growing after stage 30")
	SaveManager.set_setting("language", "ms")
	check(LevelLibrary.display_title(LevelLibrary.get_level(1)) == "Pesanan Pertama", "chapter titles translate")
	var free_play := LevelDefinition.new()
	free_play.title = "Free Play"
	check(LevelLibrary.display_title(free_play) == "Main Bebas", "Free Play translates")
	SaveManager.set_setting("language", "en")
	check(LevelLibrary.display_title(free_play) == "Free Play", "English keeps the authored title")
	for stage in [10, 20, 30, 40, 50, 60]:
		check(not JourneyLibrary.milestone(stage).is_empty(), "milestone %d exists" % stage)
		check(not JourneyLibrary.name_for(stage).is_empty(), "milestone %d is named" % stage)
		check(not JourneyLibrary.completion_text(stage).is_empty(), "milestone %d has text" % stage)
	check(JourneyLibrary.name_for(35) == JourneyLibrary.name_for(40), "stage names its next milestone")
	check(not JourneyLibrary.name_for(75).is_empty(), "stages past the last milestone still have a name")
	check(not JourneyLibrary.completion_text(30).contains("coming"), "milestone 30 no longer promises later content")

func _encode(value: Variant) -> Variant:
	if value is KuihData:
		return String(value.id)
	if value is CustomerData:
		return String(value.id)
	if value is Resource:
		var out := {}
		for property in value.get_property_list():
			if property.usage & PROPERTY_USAGE_STORAGE and property.name != "script" and not String(property.name).begins_with("resource_"):
				out[property.name] = _encode(value.get(property.name))
		return out
	if value is Array or value is PackedInt32Array:
		var out := []
		for item in value:
			out.append(_encode(item))
		return out
	if value is StringName or value is Vector2i:
		return str(value)
	return value
