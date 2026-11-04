extends Node

## Plays stages 31, 40, 50 and 60 to a real win on the real screen, then walks the
## win screen, recipe card and milestone popup. Moves are topped up because this
## checks the flow; difficulty belongs to `stage_balance_sim`. Rendered runs save
## screens to `.analysis/`.

const STAGES := [31, 40, 50, 60]
const MAX_SWAPS := 200
const SETTLE_MS := 30000

var failures: Array[String] = []

func check(ok: bool, why: String) -> void:
	if not ok:
		failures.append(why)
		push_error(why)

func _ready() -> void:
	run.call_deferred()

func run() -> void:
	SaveManager.save_path = "user://kuih_stage_win_flow_test.json"
	SaveManager.reset()
	ProgressionManager.complete_tutorial()
	for item in KuihLibrary.all():
		SaveManager.data.kuih_seen.append(String(item.id))
	for entry in PowerupRecipes.ENTRIES:
		SaveManager.data.kuih_seen.append("special_intro_%d" % int(entry[0]))
	SaveManager.set_setting("language", "ms")
	Engine.time_scale = 4.0
	var cleared := 0
	for stage in STAGES:
		for earlier in range(cleared + 1, stage):
			ProgressionManager.record_win(earlier, 3, 0)
		cleared = stage
		await _play_to_win(stage)
	Engine.time_scale = 1.0
	check(ProgressionManager.highest_cleared() == 60, "stage 60 counts as cleared")
	check(ProgressionManager.current_level() == 60, "the next stage stays within the game")
	check(not ProgressionManager.is_level_unlocked(61), "no stage after 60")
	print("Stage win flow: %s (%d problems)" % ["PASS" if failures.is_empty() else "FAIL", failures.size()])
	get_tree().quit(0 if failures.is_empty() else 1)

func _play_to_win(id: int) -> void:
	var coins := EconomyManager.coins()
	var screen := LevelController.new()
	screen.level_id = id
	add_child(screen)
	for _i in 4:
		await get_tree().process_frame
	for _beat in 3:
		if screen.story.visible:
			screen.story.close()
			await get_tree().process_frame
	var swaps := 0
	while not screen.finished and swaps < MAX_SWAPS:
		if not await _board_ready(screen):
			check(false, "stage %d: board never became playable" % id)
			break
		if screen.finished:
			break
		var move := _best_move(screen)
		if move.is_empty():
			await get_tree().process_frame
			swaps += 1
			continue
		screen.moves_left = maxi(screen.moves_left, 3)
		screen.board.attempt_swap(move.a, move.b)
		swaps += 1
		await get_tree().process_frame
	check(screen.finished, "stage %d: never finished after %d swaps" % [id, swaps])
	if screen.finished:
		await _check_win(screen, id, coins)
	get_tree().paused = false
	screen.free()
	await get_tree().process_frame

func _board_ready(screen: LevelController) -> bool:
	var deadline := Time.get_ticks_msec() + SETTLE_MS
	while screen.board.busy or screen._serving or not screen.board.enabled:
		if screen.finished:
			return true
		# The game pauses when its window loses focus, which is not a stuck board.
		get_tree().paused = false
		if Time.get_ticks_msec() > deadline:
			return false
		await get_tree().process_frame
	return true

func _check_win(screen: LevelController, id: int, coins: int) -> void:
	var deadline := Time.get_ticks_msec() + SETTLE_MS
	while screen._victory_bonus != null and Time.get_ticks_msec() < deadline:
		get_tree().paused = false
		await get_tree().process_frame
	await get_tree().process_frame
	check(screen.result.visible and screen.result.is_win, "stage %d: win screen shows" % id)
	check(ProgressionManager.stars_for(id) >= 1, "stage %d: stars are saved" % id)
	check(EconomyManager.coins() > coins, "stage %d: coins are paid" % id)
	check(ProgressionManager.is_level_unlocked(id + 1) == LevelLibrary.has_level(id + 1), "stage %d: the next stage opens" % id)
	await _capture("win-flow-%d-result" % id)
	var recipe := LevelLibrary.get_level(id).recipe_unlock_id
	if recipe != &"":
		check(RecipeBookManager.is_recipe_discovered(recipe), "stage %d: discovers %s" % [id, recipe])
		var card := screen.get_node_or_null("RecipeDiscoveryOverlay")
		check(card != null, "stage %d: the recipe card shows" % id)
		await _capture("win-flow-%d-recipe" % id)
	if JourneyLibrary.milestone(id).is_empty():
		return
	await _close_recipe_cards(screen)
	check(screen.result._subtitle.text.contains("Main Bebas"), "stage %d: the Free Play bonus shows inside the card" % id)
	check(screen.result.get_node_or_null("FreePlayReward") == null, "stage %d: no bonus text over Aina" % id)
	await _capture("win-flow-%d-card" % id)
	# Continuing past a stage without a milestone would leave this scene.
	screen._on_result_continue()
	await get_tree().process_frame
	var popup: JourneyMilestonePopup = null
	for child in screen.get_children():
		if child is JourneyMilestonePopup:
			popup = child
	check(popup != null, "stage %d: the milestone popup shows" % id)
	await _capture("win-flow-%d-milestone" % id)

func _close_recipe_cards(screen: LevelController) -> void:
	for _card in 4:
		var card := screen.get_node_or_null("RecipeDiscoveryOverlay")
		if card == null:
			return
		card._close()
		await get_tree().process_frame

func _best_move(screen: LevelController) -> Dictionary:
	var logic: BoardState = screen.board.logic
	var order := screen.active_order()
	var needed: Dictionary = order.remaining if order != null else {}
	var best := {}
	var best_value := -1.0
	for option in logic.find_possible_moves(200):
		var value := _rate(logic, option.a, option.b, needed)
		if value > best_value:
			best_value = value
			best = option
	return best

func _rate(logic: BoardState, a: Vector2i, b: Vector2i, needed: Dictionary) -> float:
	if logic.get_cell(a).special != BoardCell.Special.NONE or logic.get_cell(b).special != BoardCell.Special.NONE:
		return 12.0
	logic.swap_cells(a, b)
	var value := 0.0
	for group in logic.find_matches([a, b]):
		for pos in group.cells:
			value += 3.0 if int(needed.get(logic.get_cell(pos).kuish_id(), 0)) > 0 else .5
			for dir in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
				var near := logic.get_cell(pos + dir)
				if near != null and (near.has_obstacle() or near.is_target()):
					value += 2.0
	logic.swap_cells(a, b)
	return value

func _capture(capture_name: String) -> void:
	if DisplayServer.get_name() == "headless":
		return
	for _i in 6:
		await get_tree().process_frame
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://.analysis"))
	get_viewport().get_texture().get_image().save_png("res://.analysis/%s.png" % capture_name)
