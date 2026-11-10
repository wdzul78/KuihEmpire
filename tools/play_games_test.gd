extends Node

## Google Play Games glue on a PC: everything stays off, the cloud save packs
## and unpacks, the "cloud is ahead" check, and restoring a cloud copy.

var failures: Array[String] = []

func check(ok: bool, why: String) -> void:
	if not ok:
		failures.append(why)
		push_error(why)

func _ready() -> void:
	run.call_deferred()

func run() -> void:
	SaveManager.save_path = "user://kuih_play_games_test.json"
	SaveManager.reset()
	check(not PlayGames.available and not PlayGames.signed_in, "Play Games stays off on a PC")
	PlayGames.sign_in()
	PlayGames.show_achievements()
	PlayGames.show_leaderboards()
	check(not PlayGames.signed_in, "calls without the plugin do nothing")

	var local := SaveManager.data.duplicate(true)
	local["levels"] = {"1": {"stars": 3}, "2": {"stars": 2}}
	var cloud := local.duplicate(true)
	cloud["levels"]["3"] = {"stars": 1}
	cloud["profile"]["name"] = "Cloud Aina ★"
	check(PlayGames.progress_of(cloud) == Vector2i(3, 6), "progress counts the furthest stage and the stars")
	check(PlayGames.cloud_is_ahead(cloud, local), "a further stage in the cloud is ahead")
	check(not PlayGames.cloud_is_ahead(local, cloud), "a shorter cloud copy is not ahead")
	check(not PlayGames.cloud_is_ahead(local, local), "the same progress is not ahead")
	var more_stars := local.duplicate(true)
	more_stars["levels"]["2"] = {"stars": 3}
	check(PlayGames.cloud_is_ahead(more_stars, local), "more stars on the same stage is ahead")

	var packed := PlayGames.pack(cloud)
	for byte in packed:
		if byte > 127:
			check(false, "the packed save is plain ASCII")
			break
	var back := PlayGames.unpack(packed)
	check(back.get("profile", {}).get("name") == "Cloud Aina ★", "the packed save comes back the same")
	check(PlayGames.unpack("rubbish".to_ascii_buffer()).is_empty(), "a broken cloud copy is ignored")
	check(PlayGames.unpack(PackedByteArray()).is_empty(), "an empty cloud copy is ignored")

	SaveManager.set_setting("language", "ms")
	check(SaveManager.restore(back), "a cloud copy can be restored")
	check(ProgressionManager.highest_cleared() == 3 and ProgressionManager.total_stars() == 6, "the restored progress is in use")
	check(SaveManager.data["profile"]["name"] == "Cloud Aina ★", "the restored profile is in use")
	check(SaveManager.get_setting("language") == "ms", "this phone's settings survive a restore")
	check(FileAccess.file_exists(SaveManager.save_path + ".before_cloud"), "the replaced progress is kept aside")
	SaveManager.load_game()
	check(ProgressionManager.highest_cleared() == 3, "the restored progress was written to disk")

	SaveManager.reset()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(SaveManager.save_path + ".before_cloud"))
	print("Play Games: %s (%d problems)" % ["PASS" if failures.is_empty() else "FAIL", failures.size()])
	get_tree().quit(0 if failures.is_empty() else 1)
