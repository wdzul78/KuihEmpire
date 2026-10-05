extends Node

## Renders every screen to PNG so the art direction can be reviewed.
##
##   godot --rendering-driver opengl3 --resolution 540x960 res://tools/screenshot_scene.tscn
##
## Output lands in `res://.shots/`.

const OUT_DIR := "res://.shots"

var scene_root: Node
var index: int = 0


func _ready() -> void:
	SaveManager.save_path = "user://kuih_shot_save.json"
	SaveManager.reset()
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT_DIR))
	scene_root = Node.new()
	scene_root.name = "ShotRoot"
	add_child(scene_root)
	run.call_deferred()


func run() -> void:
	if "--hearts-only" in OS.get_cmdline_user_args():
		var screen := HomeScreen.new()
		scene_root.add_child(screen)
		await _settle(6)
		await _save("five_hearts_full")
		HeartManager.consume_on_failure()
		HeartManager.consume_on_failure()
		await _settle(3)
		await _save("three_hearts_two_empty")
		for i in 3:
			HeartManager.consume_on_failure()
		await _settle(3)
		await _save("five_hearts_empty")
		screen.free()
		get_tree().quit(0)
		return
	if "--special-animation-only" in OS.get_cmdline_user_args():
		GameManager.pending_tutorial_index = 0
		var screen := LevelController.new()
		screen.level_id = 4
		scene_root.add_child(screen)
		screen.story.close()
		await _settle(6)
		var kinds := [BoardCell.Special.TAPAU, BoardCell.Special.TAPAU_VERTICAL, BoardCell.Special.DULANG, BoardCell.Special.ORDER, BoardCell.Special.HANTAR]
		for i in kinds.size():
			screen.board.logic.get_cell(Vector2i(i+1,3)).special = kinds[i]
		screen.board._refresh_tiles()
		await get_tree().create_timer(.4).timeout
		for i in kinds.size():
			var tile: TileView = screen.board._tiles[Vector2i(i+1,3)]
			assert(tile._special_idle_tween.is_valid())
			assert(tile.icon.scale == Vector2.ONE)
			assert(absf(tile.icon.rotation) <= deg_to_rad(2.0))
		await _settle(2)
		await _save("special_slow_wiggle")
		var ordinary: TileView = screen.board._tiles[Vector2i(0,3)]
		assert(ordinary._special_idle_tween == null and ordinary.icon.rotation == 0.0)
		var changed: TileView = screen.board._tiles[Vector2i(1,3)]
		changed.cell.special = BoardCell.Special.NONE
		changed.refresh()
		assert(changed._special_idle_tween == null and changed.icon.scale == Vector2.ONE and changed.icon.rotation == 0.0)
		screen.free()
		get_tree().quit(0)
		return
	if "--directional-only" in OS.get_cmdline_user_args():
		GameManager.pending_tutorial_index = 0
		var screen := LevelController.new()
		screen.level_id = 4
		scene_root.add_child(screen)
		screen.story.close()
		await _settle(6)
		screen.board.logic.get_cell(Vector2i(2,3)).special = BoardCell.Special.TAPAU
		screen.board.logic.get_cell(Vector2i(3,3)).special = BoardCell.Special.TAPAU_VERTICAL
		screen.board._refresh_tiles()
		await _settle(3)
		await _save("directional_tapau_sprites")
		screen.board.attempt_swap(Vector2i(2,3),Vector2i(3,3))
		await get_tree().create_timer(.48).timeout
		assert(screen.board.busy and screen.board.has_node("CrossComboTapauPackage"))
		assert(screen.board._vfx.effects.is_empty(), "cross starts after package transformation")
		await _save("cross_package_transform")
		for frame in 180:
			if not screen.board._vfx.effects.is_empty():
				break
			await get_tree().process_frame
		assert(screen.board._vfx.effects.size() >= 2, "cross beams start after transformation")
		await get_tree().create_timer(.07).timeout
		await RenderingServer.frame_post_draw
		await _save("cross_package_blast")
		await get_tree().create_timer(5).timeout
		assert(not screen.board.has_node("CrossComboTapauPackage"), "transient package is cleaned up")
		screen.free()
		get_tree().quit(0)
		return
	if "--delivery-only" in OS.get_cmdline_user_args():
		var delivery_tutorial := LevelController.new()
		delivery_tutorial.tutorial_index = 9
		scene_root.add_child(delivery_tutorial)
		await _settle(8)
		delivery_tutorial.coach.tap_through()
		await get_tree().create_timer(.4).timeout
		await _save("delivery_square_tutorial")
		await delivery_tutorial.board.attempt_swap(Vector2i(2,1), Vector2i(1,1))
		await get_tree().create_timer(.3).timeout
		await _save("delivery_package_created")
		delivery_tutorial.coach.guide_special_activation(delivery_tutorial.board.logic)
		var cells := delivery_tutorial.coach.hint_cells()
		if cells.size() == 2:
			delivery_tutorial.board.attempt_swap(cells[0], cells[1])
			await get_tree().create_timer(.3).timeout
			await _save("delivery_package_travel")
		await get_tree().create_timer(3).timeout
		delivery_tutorial.free()
		get_tree().quit(0)
		return
	if "--served-order-only" in OS.get_cmdline_user_args():
		var served_tutorial := LevelController.new()
		served_tutorial.tutorial_index = 3
		scene_root.add_child(served_tutorial)
		await _settle(8)
		served_tutorial.coach._advance()
		served_tutorial._on_kuih_collected({&"onde_onde": 3})
		await get_tree().create_timer(1).timeout
		await _save("completed_order_retained")
		served_tutorial.free()
		get_tree().quit(0)
		return
	if "--order-chips-only" in OS.get_cmdline_user_args():
		GameManager.pending_tutorial_index = 0
		var order_screen := LevelController.new()
		order_screen.level_id = 4
		scene_root.add_child(order_screen)
		order_screen.story.close()
		var sample := CustomerOrder.new()
		sample.customer = CustomerLibrary.get_customer(&"makcik")
		sample.target = {&"onde_onde": 8, &"kuih_koci": 6}
		sample.remaining = sample.target.duplicate()
		order_screen.hud.order_panel.bind(sample)
		await _settle(8)
		await _save("order_number_badges")
		sample.collect({&"onde_onde": 8, &"kuih_koci": 2})
		order_screen.hud.order_panel.animate_progress()
		await get_tree().create_timer(.4).timeout
		await _save("order_completion_tick")
		order_screen.free()
		get_tree().quit(0)
		return
	if "--tutorial-transition-only" in OS.get_cmdline_user_args():
		var tutorial := LevelController.new()
		tutorial.tutorial_index = 2
		scene_root.add_child(tutorial)
		await _settle(10)
		while tutorial.coach.index < tutorial.coach.steps.size() - 1:
			tutorial.coach._advance()
		await get_tree().create_timer(.4).timeout
		await _save("tutorial_aina_before_swipe")
		tutorial.board.attempt_swap(Vector2i(1, 2), Vector2i(2, 2))
		await get_tree().create_timer(.35).timeout
		await _save("tutorial_aina_after_swipe")
		await get_tree().create_timer(3).timeout
		tutorial.free()
		get_tree().quit(0)
		return
	if "--layout-editor-only" in OS.get_cmdline_user_args():
		for layout in [GameUILayout.TUTORIAL, GameUILayout.CAMPAIGN]:
			var preview: Control = layout.instantiate()
			scene_root.add_child(preview)
			await _settle(6)
			await _save("editor_" + str(preview.name))
			preview.free()
		get_tree().quit(0)
		return
	if "--header-only" in OS.get_cmdline_user_args():
		await _shot_tutorial(8)
		GameManager.pending_tutorial_index = 0
		var screen := LevelController.new()
		screen.level_id = 4
		scene_root.add_child(screen)
		screen.story.close()
		screen.score.add_points(3450)
		await _settle(8)
		await _save("header_score_progress")
		screen.free()
		get_tree().quit(0)
		return
	if "--stall-only" in OS.get_cmdline_user_args():
		var shop := GeraiScreen.new()
		scene_root.add_child(shop)
		await _settle(5)
		await _save("stall_base")
		EconomyManager.add_coins(4000)
		for id in range(1,31):
			ProgressionManager.record_win(id,2,10,1600)
		for i in 3:
			LocationManager.upgrade(&"family_stall")
		await get_tree().create_timer(3.5).timeout
		await _save("stall_upgraded")
		shop._tab = "DECOR"
		shop._preview_decor = "pink_batik"
		shop._refresh()
		await _settle(5)
		await _save("stall_decor_preview")
		shop._location = &"bazaar_ramadan"
		shop._preview_decor = ""
		shop._refresh()
		await _settle(5)
		await _save("stall_bazaar_preview")
		shop.free()
		await _shot_home()
		get_tree().quit(0)
		return
	if "--achievements-only" in OS.get_cmdline_user_args():
		for id in range(1, 16):
			ProgressionManager.record_win(id, 3 if id < 11 else 2, 8, 4500)
		SaveManager.data["stats"]["orders_served"] = 53
		AchievementManager.refresh()
		var screen := AchievementsScreen.new()
		scene_root.add_child(screen)
		await get_tree().create_timer(3.5).timeout
		await _save("achievements_personal")
		screen._ranking = true
		screen._refresh_options()
		RankingManager.service.set_samples(true)
		await _settle(6)
		await _save("ranking_samples")
		RankingManager.service.set_samples(false)
		await _settle(6)
		await _save("ranking_local")
		screen.free()
		get_tree().quit(0)
		return
	if "--score-only" in OS.get_cmdline_user_args():
		GameManager.pending_tutorial_index = 0
		var screen := LevelController.new()
		screen.level_id = 4
		scene_root.add_child(screen)
		screen.story.close()
		screen.score.add_points(3450)
		await _settle(6)
		await _save("score_hud")
		screen.board.show_score_feedback(120, 2, 1.5)
		await get_tree().create_timer(.2).timeout
		await _save("score_combo")
		for order in screen.orders:
			order.collect(order.target.duplicate())
		screen._win()
		await get_tree().create_timer(3.6).timeout
		await _save("score_result")
		screen.result.show_fail("Order incomplete", false, StageResultCalculator.calculate(false, 10000, 0, screen.level))
		await get_tree().create_timer(.5).timeout
		await _save("score_failed")
		screen.free()
		get_tree().quit(0)
		return
	if "--recipe-only" in OS.get_cmdline_user_args():
		var book := RecipeBookScreen.new()
		scene_root.add_child(book)
		await _settle(6)
		await _save("recipe_locked")
		book._next.pressed.emit()
		await _settle(6)
		assert(book._page == 1 and book._grid.get_child_count() == 4)
		await _save("recipe_page_two")
		book.free()
		await _shot_recipe_book()
		get_tree().quit(0)
		return
	if "--journey-only" in OS.get_cmdline_user_args():
		var map := JourneyMap.new()
		scene_root.add_child(map)
		await _settle(8)
		await _save("journey_fresh")
		map.free()
		for stage in range(1, 4):
			ProgressionManager.record_win(stage, 3, 10)
		GameManager.pending_level_id = 4
		await _shot_journey()
		get_tree().quit(0)
		return
	if "--settings-only" in OS.get_cmdline_user_args():
		await _shot_settings()
		await _shot_settings_reset()
		get_tree().quit(0)
		return
	if "--results-only" in OS.get_cmdline_user_args():
		await _shot_results()
		get_tree().quit(0)
		return
	if "--pause-only" in OS.get_cmdline_user_args():
		process_mode = Node.PROCESS_MODE_ALWAYS
		for tutorial in [true, false]:
			var screen := LevelController.new()
			screen.tutorial_index = 1 if tutorial else 0
			screen.level_id = 1
			scene_root.add_child(screen)
			await get_tree().create_timer(.5).timeout
			if tutorial:
				while screen.coach.can_tap_through():
					screen.coach.tap_through()
			await get_tree().create_timer(.3).timeout
			screen._open_pause_menu()
			assert(get_tree().paused)
			assert(screen._pause_overlay.z_index > 81)
			await _settle(3)
			await _save("pause_tutorial" if tutorial else "pause_stage")
			screen._pause_overlay.resume_pressed.emit()
			assert(not get_tree().paused)
			assert(screen._pause_overlay == null)
			screen.free()
			await get_tree().process_frame
		get_tree().quit(0)
		return
	if "--menu-only" in OS.get_cmdline_user_args():
		await _shot_home()
		get_tree().quit(0)
		return
	if "--gestures-only" in OS.get_cmdline_user_args():
		await _shot_large_gestures()
		get_tree().quit(0)
		return
	await _capture("res://scenes/boot/boot.tscn", 6)
	await _shot_story(0)
	await _shot_story(1)
	await _shot_story(2)
	await _shot_home()
	await _shot_tutorial(1)
	await _shot_tutorial(2)
	await _shot_tutorial(4)
	await _shot_tutorial(6)
	await _shot_tutorial(8)
	await _shot_level(1)
	await _shot_level(10)
	await _shot_level(30)
	await _shot_classic_specials()
	await _shot_recipe_book()
	await _shot_journey()
	await _shot_gerai()
	await _shot_settings()
	await _shot_character_dialogue()
	await _shot_avatar_picker()
	await _shot_results()
	await _shot_hearts()
	await _shot_tap_dialogue()
	await _shot_gesture_fix()
	await _shot_settings_reset()
	print("shots written: %d" % index)
	get_tree().quit(0)


func _shot_large_gestures() -> void:
	for lesson in [7, 3, 1, 2]:
		var screen := LevelController.new()
		screen.tutorial_index = lesson
		scene_root.add_child(screen)
		await get_tree().create_timer(.5).timeout
		if lesson in [1, 2, 3]:
			while screen.coach.can_tap_through():
				screen.coach.tap_through()
			await get_tree().create_timer(.4).timeout
		await _settle(3)
		await _save("large_gesture_%d" % lesson)
		screen.free()
		await get_tree().process_frame


func _shot_gesture_fix() -> void:
	for tutorial in [2, 3]:
		var screen := LevelController.new()
		screen.tutorial_index = tutorial
		scene_root.add_child(screen)
		await _settle(5)
		while screen.coach.can_tap_through():
			screen.coach.tap_through()
		await _settle(5)
		var gesture := screen.board._swipe_indicator
		gesture.set_process(false)
		gesture._clock = .95
		gesture.frame_index = 3
		gesture.queue_redraw()
		await _settle(2)
		await _save("gesture_fixed_%d" % tutorial)
		screen.free()


func _shot_settings_reset() -> void:
	var settings := SettingsScreen.new()
	scene_root.add_child(settings)
	await _settle(5)
	await _save("settings_toggle_mobile")
	settings._on_reset()
	await _settle(5)
	await _save("reset_confirmation_mobile")
	settings.free()


func _shot_character_dialogue() -> void:
	var screen := LevelController.new()
	screen.level_id = 18
	scene_root.add_child(screen)
	await _settle(10)
	for order in screen.orders:
		screen.hud.order_panel.bind(order)
		await _settle(20)
		await _save("customer_%s" % order.customer.id)
	var rider_order := CustomerOrder.new()
	rider_order.customer = CustomerLibrary.get_customer(&"runner")
	rider_order.target = {&"kuih_koci": 8}
	rider_order.remaining = rider_order.target.duplicate()
	screen.hud.order_panel.bind(rider_order)
	await _settle(20)
	await _save("customer_runner")
	scene_root.remove_child(screen)
	screen.queue_free()
	await get_tree().process_frame
	screen = LevelController.new()
	screen.level_id = 21
	scene_root.add_child(screen)
	await _settle(20)
	await _save("steamer_intro_21")
	scene_root.remove_child(screen)
	screen.queue_free()
	await get_tree().process_frame


## One page of the prologue deck, so the storyline screen can be reviewed.
func _shot_story(page_index: int) -> void:
	var deck := StoryLibrary.pages_for(StoryLibrary.PROLOGUE)
	if page_index >= deck.size():
		return
	var screen := StoryScreen.new()
	scene_root.add_child(screen)
	await _settle(6)
	screen.play(deck, true)
	# Jump straight to the requested page.
	for _i in page_index:
		screen.show_page(screen.index + 1, false)
	await _settle(8)
	await _save("story_page_%d" % (page_index + 1))
	scene_root.remove_child(screen)
	screen.queue_free()
	await get_tree().process_frame


func _shot_tutorial(index: int) -> void:
	var screen := LevelController.new()
	screen.tutorial_index = index
	scene_root.add_child(screen)
	await _settle(10)
	# Land on the last coaching step so the card shows real copy, then capture
	# BEFORE playing a move - playing it would satisfy the gate and hide the coach.
	if screen.coach != null:
		while not screen.coach.is_done() and screen.coach.index < screen.coach.steps.size() - 1:
			screen.coach._advance()
	await _settle(6)
	await _save("tutorial_%02d_%dx%d" % [index, screen.level.width, screen.level.height])
	scene_root.remove_child(screen)
	screen.queue_free()
	await get_tree().process_frame


func _shot_classic_specials() -> void:
	var screen := LevelController.new()
	screen.level_id = 1
	scene_root.add_child(screen)
	await _settle(10)
	screen.story.close()
	screen.board.logic.get_cell(Vector2i(2, 2)).special = BoardCell.Special.TAPAU
	screen.board.logic.get_cell(Vector2i(4, 2)).special = BoardCell.Special.TAPAU
	screen.board.logic.get_cell(Vector2i(2, 4)).special = BoardCell.Special.DULANG
	screen.board.logic.get_cell(Vector2i(4, 4)).special = BoardCell.Special.ORDER
	var sample_order := CustomerOrder.new()
	sample_order.customer = CustomerLibrary.get_customer(&"makcik")
	sample_order.target = {&"onde_onde": 10, &"kuih_lapis": 8, &"kuih_koci": 6}
	sample_order.remaining = {&"onde_onde": 4, &"kuih_lapis": 5, &"kuih_koci": 5}
	screen.hud.order_panel.bind(sample_order)
	screen.hud.set_order_progress(10, 24)
	# Show all six normal sprites together in the review fixture.
	var sample := KuihLibrary.starter_set()
	for i in sample.size():
		screen.board.logic.get_cell(Vector2i(i + 1, 0)).kuih = sample[i]
	screen.board._refresh_tiles()
	await _settle(6)
	await _save("classic_specials")
	scene_root.remove_child(screen)
	screen.queue_free()
	await get_tree().process_frame


func _shot_home() -> void:
	await _capture("res://scenes/menu/home.tscn", 6)


func _shot_recipe_book() -> void:
	ProgressionManager.unlock_recipe(&"onde_onde")
	ProgressionManager.unlock_recipe(&"kuih_koci")
	ProgressionManager.unlock_recipe(&"ang_ku_kueh")
	ProgressionManager.unlock_recipe(&"kuih_ketayap")
	ProgressionManager.unlock_recipe(&"kuih_lapis")
	ProgressionManager.add_mastery(&"onde_onde", 34)
	ProgressionManager.add_mastery(&"ang_ku_kueh", 12)
	await _capture("res://scenes/ui/recipe_book.tscn", 6)


func _shot_journey() -> void:
	ProgressionManager.record_win(7, 2, 8)
	await _capture("res://scenes/world/journey_map.tscn", 6)
	ProgressionManager.mark_story_read(StoryLibrary.PROLOGUE)
	ProgressionManager.mark_story_seen(&"beat_01_open")
	var map := JourneyMap.new()
	scene_root.add_child(map)
	await _settle(4)
	map._show_stop(JourneyMap.ROUTE[0])
	await _settle(4)
	await _save("map_memories")
	map._replay_memory(map.memories_for(JourneyMap.ROUTE[0])[1])
	await _settle(12)
	await _save("map_memory_replay")
	scene_root.remove_child(map)
	map.queue_free()
	await get_tree().process_frame


func _shot_gerai() -> void:
	await _capture("res://scenes/stall/gerai_screen.tscn", 6)


func _shot_settings() -> void:
	await _capture("res://scenes/ui/settings_screen.tscn", 6)


func _shot_avatar_picker() -> void:
	var screen := SettingsScreen.new()
	scene_root.add_child(screen)
	screen._show_avatars()
	await _settle(6)
	await _save("avatar_picker")
	scene_root.remove_child(screen)
	screen.queue_free()


func _shot_results() -> void:
	var screen := LevelController.new()
	screen.level_id = 3
	scene_root.add_child(screen)
	await _settle(8)
	screen.story.close()
	screen.board.enabled = false
	screen.result.stage_number = 3
	screen.result.show_win("Stage 3", 3, 60, [], false)
	await get_tree().create_timer(.5).timeout
	await _settle(3)
	await _save("stage_success")
	screen.result.show_fail("Still need 3 Onde-onde", true)
	await get_tree().create_timer(.5).timeout
	await _settle(3)
	await _save("stage_failed")
	screen.result._show_recovery()
	await _settle(3)
	await _save("result_recovery")
	scene_root.remove_child(screen)
	screen.queue_free()


func _shot_hearts() -> void:
	SaveManager.data["tutorial_done"] = true
	SaveManager.data["levels"] = {}
	for id in range(1, 4):
		ProgressionManager.record_win(id, 3, 8)
	GameManager.pending_level_id = 4
	GameManager.pending_tutorial_index = 0
	var map := JourneyMap.new()
	scene_root.add_child(map)
	await _settle(8)
	await _save("journey_stage_4")
	HeartManager.start_free_play(900)
	await _settle(8)
	await _save("journey_free_play")
	HeartManager.state()["free_play_end_timestamp"] = 0
	HeartManager.state()["current_hearts"] = 0
	HeartManager.state()["last_heart_refill_timestamp"] = HeartManager.now()
	HeartManager.changed.emit()
	HeartRefillDialog.open(map)
	await _settle(8)
	await _save("hearts_empty")
	scene_root.remove_child(map)
	map.queue_free()
	await get_tree().process_frame

func _shot_tap_dialogue() -> void:
	HeartManager.full_refill()
	var screen := LevelController.new()
	screen.tutorial_index = 5
	scene_root.add_child(screen)
	await get_tree().create_timer(.5).timeout
	await _settle(8)
	await _save("tap_dialogue_highlight")
	scene_root.remove_child(screen)
	screen.queue_free()
	await get_tree().process_frame


func _shot_level(level_id: int) -> void:
	var screen := LevelController.new()
	screen.level_id = level_id
	scene_root.add_child(screen)
	await _settle(10)
	if screen.coach != null:
		screen.coach.visible = false
	# Fire a few moves so specials and overlays appear on the board.
	for _n in 3:
		var moves := screen.board.logic.find_possible_moves(1)
		if moves.is_empty():
			break
		var pair: Dictionary = moves[0]
		screen.board.attempt_swap(pair["a"], pair["b"])
		for _i in 8:
			await get_tree().process_frame
	await _settle(6)
	await _save("stage_%02d" % level_id)
	scene_root.remove_child(screen)
	screen.queue_free()
	await get_tree().process_frame


func _capture(path: String, frames: int) -> void:
	var packed: PackedScene = load(path)
	var node := packed.instantiate()
	scene_root.add_child(node)
	await _settle(frames)
	var name := path.get_file().replace(".tscn", "")
	await _save(name)
	scene_root.remove_child(node)
	node.queue_free()
	await get_tree().process_frame


func _settle(frames: int) -> void:
	for _i in frames:
		await get_tree().process_frame
	await RenderingServer.frame_post_draw


func _save(label: String) -> void:
	var image := get_viewport().get_texture().get_image()
	if image == null:
		print("no viewport image for %s" % label)
		return
	index += 1
	var path := "%s/%02d_%s.png" % [OUT_DIR, index, label]
	image.save_png(path)
	print("saved %s" % path)
