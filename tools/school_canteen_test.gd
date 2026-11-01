extends Node

## School Canteen as a living location, before its stages are authored: customers,
## story, translations, renovation gates, rewards and the move from the Family
## Stall. Stages 31-60 are pretend data. Rendered runs save screens to `.analysis/`.

const NEW_BEATS := [&"beat_31_canteen", &"beat_38_tart", &"beat_40_done", &"beat_45_recipe", &"beat_50_sports", &"beat_50_done", &"beat_55_pibg", &"beat_60_awards", &"beat_60_done"]
const NEW_CUSTOMERS := [&"cikgu_salmah", &"adik_danish", &"adik_priya", &"pak_mat"]
const NEW_TILES := [&"karipap", &"tart", &"kuih_bom", &"agar_agar_ros"]

var failures: Array[String] = []

func check(ok: bool, why: String) -> void:
	if not ok:
		failures.append(why)
		push_error(why)

func _ready() -> void:
	run.call_deferred()

func run() -> void:
	SaveManager.save_path = "user://kuih_school_canteen_test.json"
	SaveManager.reset()
	ProgressionManager.complete_tutorial()
	for item in KuihLibrary.all():
		SaveManager.data.kuih_seen.append(String(item.id))
	for entry in PowerupRecipes.ENTRIES:
		SaveManager.data.kuih_seen.append("special_intro_%d" % int(entry[0]))
	SaveManager.set_setting("language", "ms")
	_check_text()
	await _check_customer_line_is_malay()
	await _check_popup_before_release()
	LevelLibrary._test_last_stage = 60
	_check_rewards_and_gates()
	await _check_popup_invitation()
	await _check_new_tile_cards()
	await _check_gameplay_backdrop()
	LevelLibrary._test_last_stage = 0
	print("School canteen tests: %s (%d problems)" % ["PASS" if failures.is_empty() else "FAIL", failures.size()])
	get_tree().quit(0 if failures.is_empty() else 1)

func _check_text() -> void:
	for id in CustomerLibrary.all_ids():
		var customer := CustomerLibrary.get_customer(id)
		check(TutorialText.MALAY.has(customer.line), "%s has a Malay line" % id)
	for id in NEW_CUSTOMERS:
		check(CustomerLibrary.all_ids().has(id), "customer %s exists" % id)
	for id in NEW_BEATS:
		check(BeatLibrary.all_ids().has(id), "beat %s is listed" % id)
	for id in BeatLibrary.all_ids():
		var beat := BeatLibrary.get_beat(id)
		check(beat != null, "beat %s exists" % id)
		if beat != null:
			check(beat.lines.size() >= 2, "beat %s has lines" % id)
			for line in beat.lines:
				check(TutorialText.MALAY.has(line), "beat %s line has Malay: %s" % [id, line])
	for id in NEW_TILES:
		check(KuihLibrary.has(id), "tile %s is registered" % id)
		check(KuihIntroduction.NOTES.has(String(id)), "tile %s has a card note" % id)
	var screen_text: Dictionary = load("res://scripts/ui/achievements_screen.gd").MS_TEXT
	for definition in AchievementManager.definitions:
		check(screen_text.has(definition.id), "achievement %s has Malay text" % definition.id)

func _check_customer_line_is_malay() -> void:
	GameManager.pending_tutorial_index = 0
	var screen := LevelController.new()
	screen.level_id = 3
	add_child(screen)
	for _i in 4:
		await get_tree().process_frame
	var line: Label = screen.find_child("InstructionText", true, false)
	check(line != null and TutorialText.MALAY.values().has(line.text), "order panel speaks Malay (%s)" % (line.text if line != null else "none"))
	screen.free()
	get_tree().paused = false

func _check_popup_before_release() -> void:
	SaveManager.data["levels"]["30"] = {"stars": 3, "completed": true}
	var popup := JourneyMilestonePopup.new()
	add_child(popup)
	popup.show_milestone(30)
	await get_tree().process_frame
	check(popup.find_child("ActivateNextStallButton", true, false) == null, "no invitation while the canteen has no stages")
	popup.free()

func _check_rewards_and_gates() -> void:
	for stage in range(1, 61):
		SaveManager.data["levels"].erase(str(stage))
	var school := &"school_canteen"
	check(LocationDefinition.find(school).playable, "School Canteen is playable once stages exist")
	check(not LocationManager.accessible(school), "School Canteen waits for stage 30")
	for stage in range(1, 31):
		ProgressionManager.record_win(stage, 3, 0)
	check(LocationManager.accessible(school), "stage 30 opens the School Canteen")
	check(LocationManager.available_level(school) == 0, "no canteen upgrade before stage 40")
	var levels := {39: 0, 40: 1, 49: 1, 50: 2, 59: 2, 60: 3}
	for stage in range(31, 61):
		ProgressionManager.record_win(stage, 3, 0)
		if levels.has(stage):
			check(LocationManager.available_level(school) == levels[stage], "upgrade level after stage %d" % stage)
	for stage in [40, 50, 60]:
		SaveManager.data["hearts"]["milestones"].erase(str(stage))
		var bonus := HeartManager.reward_win(stage)
		check(bonus >= 1800, "milestone %d gives Free Play" % stage)
		check(SaveManager.data["hearts"]["milestones"].has(str(stage)), "milestone %d is claimed" % stage)
	SaveManager.data["hearts"]["win_streak"] = 0
	check(HeartManager.reward_win(40) == 0, "milestone Free Play is paid once")
	check(not SaveManager.data["gerai"]["cosmetics"].is_empty() and SaveManager.data["gerai"]["cosmetics"].has("school_canteen_complete"), "canteen milestones are claimed")
	AchievementManager.refresh()
	var values := AchievementManager.metrics()
	check(values["stories"] == 2, "two stories complete (%d)" % values["stories"])
	for id in ["story_2", "stars_120", "stars_180"]:
		check(AchievementManager.state(id).get("unlocked", false), "achievement %s unlocks" % id)

func _check_popup_invitation() -> void:
	check(LocationManager.set_active_stall(&"family_stall"), "family stall is active")
	var popup := JourneyMilestonePopup.new()
	add_child(popup)
	popup.show_milestone(30)
	await get_tree().process_frame
	var activate: Button = popup.find_child("ActivateNextStallButton", true, false)
	check(activate != null and not activate.disabled, "stage 30 offers the canteen as the active stall")
	await _capture("school-popup-30")
	if activate != null:
		activate.pressed.emit()
		check(LocationManager.active_stall_id() == &"school_canteen" and activate.disabled, "the invitation sets the active stall")
	popup.free()
	check(LocationManager.set_active_stall(&"family_stall"), "family stall is active again")
	popup = JourneyMilestonePopup.new()
	add_child(popup)
	popup.show_milestone(40)
	await get_tree().process_frame
	await _capture("school-popup-40")
	check(popup.find_child("ActivateNextStallButton", true, false) == null, "mid-location milestones do not invite")
	var names := popup.find_children("*", "Label", true, false).map(func(label: Label) -> String: return label.text)
	check(names.has("Kantin Sekolah"), "the popup names the School Canteen")
	popup.free()
	# Renovate opens the milestone's location, not the active stall.
	GeraiScreen.requested_location = &"school_canteen"
	var stall := GeraiScreen.new()
	add_child(stall)
	check(stall._location == &"school_canteen" and GeraiScreen.requested_location == &"", "the Gerai screen opens the requested location once")
	await get_tree().process_frame
	stall.free()

func _check_new_tile_cards() -> void:
	var host := Control.new()
	host.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(host)
	var tiles: Array[KuihData] = []
	for id in NEW_TILES:
		SaveManager.data.kuih_seen.erase(String(id))
		tiles.append(KuihLibrary.get_kuih(id))
	var finished := [false]
	KuihIntroduction.present(host, tiles, func() -> void: finished[0] = true)
	var cards := 0
	while host.has_node("KuihIntroductionOverlay") and cards < 8:
		await get_tree().process_frame
		var button := host.find_child("AcknowledgeKuihButton", true, false)
		if button != null:
			if cards == 0:
				await _capture("school-tile-card")
			button.pressed.emit()
			cards += 1
		await get_tree().process_frame
	check(finished[0] and cards == NEW_TILES.size(), "each new tile shows one card (%d)" % cards)
	check(KuihIntroduction.unseen(tiles).is_empty(), "new tiles are only introduced once")
	host.free()

func _check_gameplay_backdrop() -> void:
	GameManager.pending_tutorial_index = 0
	var screen := LevelController.new()
	screen.level_id = 35
	add_child(screen)
	for _i in 4:
		await get_tree().process_frame
	check(screen.backdrop.location_id == &"school_canteen", "stage 35 plays at the School Canteen")
	check(screen.backdrop._authored_background, "the School Canteen has a gameplay background")
	if screen.story.visible:
		screen.story.close()
	await get_tree().create_timer(4.0).timeout
	get_tree().paused = false
	await _capture("school-gameplay-%d" % DisplayServer.window_get_size().x)
	screen.free()
	# New customers have no painted art yet and must still draw.
	var icon := CharacterIcon.new()
	icon.cast = CharacterIcon.Cast.CUSTOMER
	icon.customer = CustomerLibrary.get_customer(&"cikgu_salmah")
	add_child(icon)
	await get_tree().process_frame
	icon.free()

func _capture(label: String) -> void:
	if DisplayServer.get_name() == "headless":
		return
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://.analysis/%s.png" % label)
