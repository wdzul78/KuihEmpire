extends Node

## Freezes a save from a player who finished the 30-stage game. Rerun only if the
## starting point itself must change; later versions must keep loading this file.
## Run: godot --headless --path . res://tools/make_stage30_fixture_scene.tscn

const OUTPUT := "res://tools/fixtures/save_after_stage_30.json"

func _ready() -> void:
	run.call_deferred()

func run() -> void:
	SaveManager.save_path = "user://kuih_stage30_fixture_source.json"
	SaveManager.reset()
	SaveManager.data["profile"]["name"] = "Fixture"
	SaveManager.set_setting("language", "ms")
	ProgressionManager.complete_tutorial()
	for stage in range(1, 31):
		ProgressionManager.record_win(stage, 3 if stage % 3 else 2, 4, 1000 + stage * 50)
	EconomyManager.add_coins(4321)
	for level in range(1, 4):
		assert(LocationManager.upgrade(&"family_stall"), "family stall upgrade %d" % level)
	for decor in DecorDefinition.all():
		if decor.suitable_for(&"family_stall") and decor.prerequisite.is_empty() and LocationManager.buy(decor.id):
			assert(LocationManager.equip(&"family_stall", decor.id))
			break
	assert(not LocationManager.equipped(&"family_stall").is_empty(), "fixture owns equipped decor")
	assert(SaveManager.save_game())
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT.get_base_dir()))
	var file := FileAccess.open(OUTPUT, FileAccess.WRITE)
	file.store_string(JSON.stringify(SaveManager.data, "  ", true))
	file.close()
	print("Stage 30 fixture written")
	get_tree().quit()
