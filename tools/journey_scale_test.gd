extends Node

## The map must stay correct and light as locations are added. Stages 31-60 are
## pretend data here; School Canteen sections borrow Family Stall worlds until
## their art arrives. Rendered runs save the seams to `.analysis/`.

var failures: Array[String] = []

func check(ok: bool, why: String) -> void:
	if not ok:
		failures.append(why)
		push_error(why)

func _ready() -> void:
	run.call_deferred()

func run() -> void:
	SaveManager.save_path = "user://kuih_journey_scale_test.json"
	SaveManager.reset()
	ProgressionManager.complete_tutorial()
	SaveManager.set_setting("language", "ms")
	_check_sections()
	await _check_released_map()
	await _check_sixty_stage_map()
	LevelLibrary._test_last_stage = 0
	print("Journey scale tests: %s (%d problems)" % ["PASS" if failures.is_empty() else "FAIL", failures.size()])
	get_tree().quit(0 if failures.is_empty() else 1)

func _check_sections() -> void:
	var centers: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(JourneyMap.WORLD_ROOT + "centers.json"))
	var next := 1
	for section in JourneyLibrary.SECTIONS:
		check(section["id"] == next, "sections are contiguous at %d" % next)
		next = section["last"] + 1
		check(centers.has(section["world"]) and centers[section["world"]].size() == 10, "section %d has ten road points" % section["id"])
		check(ResourceLoader.exists(JourneyMap.WORLD_ROOT + String(section["world"]) + ".png"), "section %d has a world" % section["id"])
		var location := LocationDefinition.find(section["location"])
		check(section["id"] >= location.stage_start and section["last"] <= location.stage_end, "section %d is inside its location" % section["id"])
	check(JourneyLibrary.section_for(11)["place_en"] == "Village Market", "stages 11-20 are no longer called Morning Market")
	check(JourneyLibrary.section_for(30)["id"] == 21 and JourneyLibrary.section_for(31)["id"] == 31, "stages map to sections")

func _open_map() -> JourneyMap:
	var map := JourneyMap.new()
	add_child(map)
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().process_frame
	return map

## Today's game: nothing about the Family Stall map may look different.
func _check_released_map() -> void:
	check(LevelLibrary.count() == 30, "only 30 stages are released")
	GameManager.pending_level_id = 5
	var map := await _open_map()
	check(map._sections.size() == 3, "only released sections are shown")
	check(not map._location_arrows[0].visible and not map._location_arrows[1].visible, "no location picker with one location")
	check(map._destination.visible and map._destination.text.begins_with("Kantin Sekolah"), "the sign names the next location")
	check(map._nodes.has(5) and not map._nodes.has(31), "the sign is not a stage")
	check(map._place_label.text == "Gerai Keluarga", "place name follows the view")
	check(map._chapters[0].text == "1–10" and map._chapters[2].text == "21–30", "tabs show the first location")
	map.free()

func _check_sixty_stage_map() -> void:
	LevelLibrary._test_last_stage = 60
	for stage in range(1, 59):
		SaveManager.data["levels"][str(stage)] = {"stars": 2, "completed": true}
	GameManager.pending_level_id = 58
	var map := await _open_map()
	check(map._sections.size() == 6, "every section appears")
	check(map._location_arrows[0].visible, "the location picker appears with two locations")
	check(map.selected_stage == 58 and map._nodes.has(58), "the map opens on the selected stage")
	check(absf(map._scroll.scroll_vertical - (map._point(57).y - map._scroll.size.y * .56)) < 2.0, "the selected stage is centred")
	check(map._place_label.text == "Padang Sekolah", "place name follows the view")
	check(map._chapters[0].text == "31–40" and map._chapters[2].text == "51–60", "tabs show the location in view")
	check(not map._destination.text.begins_with("Kantin"), "the sign moves on to the next location")
	check(map._destination.text.begins_with("Pasar Pagi"), "the sign names the Morning Market")
	# Only the two buttons that changed are replaced.
	var untouched: Control = map._nodes[57]
	var previous: Control = map._nodes[58]
	map._select_stage(56)
	check(map._nodes[57] == untouched, "other stage buttons are kept")
	check(map._nodes[58] != previous and map._nodes[56].size.x > untouched.size.x, "selection updates its buttons")
	check(map._grid.get_node("Stage58") == map._nodes[58], "replacement keeps the node name")
	# The road climbs without a jump, including over the location seam.
	for stage in range(1, 60):
		var step: float = map._point(stage - 1).y - map._point(stage).y
		check(step > 0.0 and step < map._chapter_height * .25, "road step from stage %d to %d is smooth (%d)" % [stage, stage + 1, step])
	# The whole route: nothing heavy piles up, and the visible stage always exists.
	var limit: float = map._scroll.get_v_scroll_bar().max_value - map._scroll.size.y
	var most_layers := 0
	var most_nodes := 0
	var most_textures := 0
	var scroll := limit
	while scroll > 0.0:
		map._scroll.scroll_vertical = int(scroll)
		most_layers = maxi(most_layers, map._world_layers.size())
		most_nodes = maxi(most_nodes, map._nodes.size())
		most_textures = maxi(most_textures, map._world_textures.size())
		for section in map._window:
			check(map._world_layers.has(section), "section %d has its world" % section)
		var view_stage: Dictionary = map._sections[map._view_section]
		check(map._nodes.has(view_stage["id"]), "stage %d exists when in view" % view_stage["id"])
		scroll -= map._chapter_height * .1
	check(most_layers <= 2, "at most two worlds are drawn (%d)" % most_layers)
	check(most_nodes <= 20, "at most twenty stage buttons exist (%d)" % most_nodes)
	check(most_textures <= 3, "at most three world images are held (%d)" % most_textures)
	await get_tree().process_frame
	# The location picker and tabs jump between sections.
	map._scroll.scroll_vertical = 0
	check(map._location_arrows[1].disabled and not map._location_arrows[0].disabled, "last location has no next arrow")
	map._location_arrows[0].pressed.emit()
	check(map._view_section == 0 and map._place_label.text == "Gerai Keluarga", "the arrow opens the previous location")
	check(map._location_arrows[0].disabled, "first location has no previous arrow")
	map._location_arrows[1].pressed.emit()
	check(map._view_section == 3 and map._place_label.text == "Pintu Sekolah", "the arrow opens the next location")
	map._chapters[1].pressed.emit()
	check(map._view_section == 4, "a tab opens its section in this location")
	# Memories follow the section of the selected stage.
	var progress := map.stop_progress(JourneyLibrary.section_for(35))
	check(progress["first"] == 31 and progress["last"] == 40 and progress["cleared"] == 10, "progress counts its own section")
	map._select_stage(35)
	map._show_stop(JourneyLibrary.section_for(map.selected_stage))
	check(map.get_node("StopPopup/StopBanner").get_child(0).text == "Kantin Sekolah · Hari Pertama", "the memories title follows the section")
	map.get_node("StopPopup").free()
	if DisplayServer.get_name() != "headless":
		await get_tree().create_timer(6.0).timeout # Lets the achievement toast clear.
		for stage in [29, 30, 31, 40, 41, 60]:
			map._scroll.scroll_vertical = int(map._point(stage - 1).y - map._scroll.size.y * .5)
			await get_tree().create_timer(.3).timeout
			await RenderingServer.frame_post_draw
			get_viewport().get_texture().get_image().save_png("res://.analysis/journey-scale-%d.png" % stage)
	map.free()
	await get_tree().process_frame
	# A location with one released section still works.
	LevelLibrary._test_last_stage = 35
	GameManager.pending_level_id = 35
	var partial := await _open_map()
	check(partial._sections.size() == 4 and partial._nodes.has(35) and not partial._nodes.has(36), "a partly released section stops at the last stage")
	check(partial._chapters[0].visible and not partial._chapters[1].visible, "unreleased tabs stay hidden")
	partial.free()
