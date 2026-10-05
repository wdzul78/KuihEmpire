extends Node

## Runtime smoke test for the view layer (node construction, signals, tweens).
##
##   godot --headless res://tools/smoke_scene.tscn
##
## Runs inside the normal main loop so the autoloads exist. The balance harness
## in `test_runner.gd` covers the rules; this covers "does the screen actually
## build and play without throwing".

const TIMEOUT_MS := 8000

var problems: Array[String] = []
var scene_root: Node


## Waits until the board finishes animating, or gives up and records a problem.
## Returns false if the board never settled, so callers stop poking it instead of
## piling bogus follow-up failures onto a cascade that is still running.
func _wait_idle(screen: LevelController, context: String, timeout_ms: int = TIMEOUT_MS) -> bool:
	var deadline := Time.get_ticks_msec() + timeout_ms
	while screen.board != null and (screen.board.busy or screen._serving):
		if Time.get_ticks_msec() > deadline:
			problems.append("%s: board stuck busy for %d ms" % [context, timeout_ms])
			return false
		await get_tree().process_frame
		await get_tree().process_frame
	# Let any follow-up animation frames land.
	for _i in 12:
		await get_tree().process_frame
	return true


## How long a stage is allowed to keep animating.
##
## One cascade step costs roughly CLEAR + FALL + SPAWN + SETTLE, and every blocker
## batch adds a beat on top. A flat timeout starved the late stages: stage 30
## legitimately needs more than the default before it goes idle.
func _settle_budget(level_id: int) -> int:
	var level := LevelLibrary.get_level(level_id)
	return TIMEOUT_MS + 400 * level.blockers.size() + 12 * level.width * level.height


func _ready() -> void:
	# Never touch the player's real save, and never inherit the last run's state:
	# leftover boosters made every run start from a different inventory.
	SaveManager.save_path = "user://kuih_test_save.json"
	SaveManager.reset()
	scene_root = Node.new()
	scene_root.name = "SmokeRoot"
	add_child(scene_root)
	run.call_deferred()


func run() -> void:
	_check_scene_paths()
	await _check_scene("res://scenes/boot/boot.tscn", 3)
	await _check_scene("res://scenes/menu/home.tscn", 3)
	await _check_scene("res://scenes/world/journey_map.tscn", 3)
	await _check_scene("res://scenes/ui/recipe_book.tscn", 3)
	await _check_scene("res://scenes/stall/gerai_screen.tscn", 3)
	await _check_scene("res://scenes/ui/settings_screen.tscn", 3)
	await _check_story_flow()
	await _walk_tutorial()
	await _play_level(1)
	await _play_level(7)
	await _play_level(30)

	print("")
	print("Smoke test")
	print("----------")
	print("problems: %d" % problems.size())
	for problem in problems:
		print("  ! " + problem)
	print("result: %s" % ("PASS" if problems.is_empty() else "FAIL"))
	for _i in 6:
		await get_tree().process_frame
	get_tree().quit(0 if problems.is_empty() else 1)


## Every path the game navigates to must exist and load.
func _check_scene_paths() -> void:
	var paths := [
		SceneManager.BOOT,
		SceneManager.HOME,
		SceneManager.LEVEL,
		SceneManager.JOURNEY,
		SceneManager.GERAI,
		SceneManager.RECIPE_BOOK,
		SceneManager.SETTINGS,
	]
	for path in paths:
		if not ResourceLoader.exists(path):
			problems.append("SceneManager path does not resolve: %s" % path)
			continue
		if load(path) == null:
			problems.append("SceneManager path failed to load: %s" % path)


func _check_scene(path: String, frames: int) -> void:
	if not ResourceLoader.exists(path):
		problems.append("missing scene %s" % path)
		return
	var packed: PackedScene = load(path)
	if packed == null:
		problems.append("could not load %s" % path)
		return
	var node := packed.instantiate()
	if node == null:
		problems.append("could not instantiate %s" % path)
		return
	scene_root.add_child(node)
	for _i in frames:
		await get_tree().process_frame
	scene_root.remove_child(node)
	node.queue_free()
	await get_tree().process_frame


## Plays the whole tutorial the way a player would and checks the coach never
## soft-locks: every stage must reach its win screen using only real board
## moves and tap-throughs on the coach card.
## Plays a real deck from the first page to the exit button.
##
## The screen used to build perfectly while loading no pages at all, and nothing
## connected its `finished` signal, so Continue and Skip both did nothing and the
## player was stranded on a blank card. Building the scene is not enough to catch
## that - the deck has to be walked.
func _check_story_flow() -> void:
	var deck := StoryLibrary.pages_for(StoryLibrary.PROLOGUE)
	if deck.is_empty():
		problems.append("story: the prologue deck is empty")
		return

	# `manual` keeps SceneManager from navigating away mid-test.
	SceneManager.story_group = StoryLibrary.PROLOGUE
	SceneManager.story_allow_skip = false
	SceneManager.manual = true
	SceneManager.story_next = SceneManager.HOME
	SceneManager.story_next_tutorial = 0
	var closed := [false]
	SceneManager.story_finished.connect(func() -> void: closed[0] = true, CONNECT_ONE_SHOT)

	var screen: StoryScreen = load("res://scenes/story/story_screen.tscn").instantiate()
	add_child(screen)
	for _i in 4:
		await get_tree().process_frame

	if screen.pages.size() != deck.size():
		problems.append("story: loaded %d pages, expected %d" % [screen.pages.size(), deck.size()])
		screen.queue_free()
		return
	if screen._heading.text.strip_edges() == "":
		problems.append("story: page 1 has no heading")
	if screen._body.text.strip_edges() == "":
		problems.append("story: page 1 has no body text")
	if screen._skip_button.visible:
		problems.append("story: Skip is offered before the prologue has ever been read")

	var guard := 0
	while not closed[0] and guard < 32:
		guard += 1
		screen._on_next_pressed()
		await get_tree().process_frame
	if not closed[0]:
		problems.append("story: the deck never finished after %d Continue presses" % guard)
	if closed[0] and screen.index != deck.size() - 1:
		problems.append("story: finished early on page %d of %d" % [screen.index + 1, deck.size()])

	screen.queue_free()
	SceneManager.manual = false
	await get_tree().process_frame
	print("story deck walked ok  (%d pages)" % deck.size())


func _walk_tutorial() -> void:
	ProgressionManager.reset_tutorial()
	for index in TutorialLibrary.ACTIVE_LESSONS:
		var screen := LevelController.new()
		screen.tutorial_index = index
		scene_root.add_child(screen)
		for _i in 4:
			await get_tree().process_frame

		if not screen.is_tutorial:
			problems.append("tutorial %d: controller did not enter tutorial mode" % index)
			screen.queue_free()
			continue
		if screen.board == null or screen.board.logic == null:
			problems.append("tutorial %d: board never built" % index)
			screen.queue_free()
			continue
		if screen.coach == null:
			problems.append("tutorial %d: no coach attached" % index)
			screen.queue_free()
			continue
		if screen.board.cell_size < 40.0:
			problems.append("tutorial %d: tiles are tiny (%.0f px)" % [index, screen.board.cell_size])
		_check_tiles_fit(screen.board, index)

		# Tap through intro cards, then play real moves until the stage resolves.
		# The loop counter counts loop passes (mostly animation waits); the move
		# counter is what actually bounds how long a stage may drag on.
		var moves_made := 0
		var spins := 0
		while not screen.finished and spins < 6000:
			spins += 1
			if screen.board.busy or screen._serving:
				await get_tree().process_frame
				continue
			if screen.coach != null and screen.coach.can_tap_through():
				screen.coach.tap_through()
				for _i in 2:
					await get_tree().process_frame
				continue
			var choice := _pick_teaching_move(screen)
			if choice.is_empty():
				break
			moves_made += 1
			if moves_made > 45:
				break
			screen.board.attempt_swap(choice["a"], choice["b"])
			for _i in 3:
				await get_tree().process_frame
			# Only meaningful once the board is idle: mid-cascade a kuih has left
			# its cell but its view has not been re-keyed yet.
			if screen.board != null and not screen.board.busy:
				_check_view_sync(screen.board, "tutorial %d move %d" % [index, moves_made])

		# Let the win animation land.
		for _i in 30:
			await get_tree().process_frame
			if screen.finished:
				break
		if not screen.finished:
			problems.append("tutorial %d: coach never completed (soft-lock?)" % index)
			if screen.coach != null:
				print("      diag: step ", screen.coach.index, " of ", screen.coach.steps.size(),
					" done=", screen.coach.is_done(),
					" busy=", screen.board.busy,
					" moves=", moves_made,
					" spins=", spins,
					" orders=", screen.orders.size(),
					" active=", screen.active_index)
		else:
			if not screen.result.visible or not screen.result.is_win:
				problems.append("tutorial %d: win screen is hidden" % index)
			if index in [4, 5] and not screen.coach.is_done():
				problems.append("tutorial %d: special lesson never received its event" % index)
			print("tutorial %2d walked ok  (%dx%d, %d moves)" % [
				index, screen.level.width, screen.level.height, moves_made
			])
		scene_root.remove_child(screen)
		screen.queue_free()
		await get_tree().process_frame


## Picks the swap that best advances whatever the coach is currently waiting for,
## so the walkthrough behaves like a player who is paying attention.
func _pick_teaching_move(screen: LevelController) -> Dictionary:
	var logic := screen.board.logic
	var gate := TutorialStepData.Gate.SWAP_ANY
	if screen.coach != null and not screen.coach.is_done():
		for step in screen.level.tutorial_steps:
			if step.gate != TutorialStepData.Gate.INTRO:
				gate = step.gate
	var wanted := &""
	var order := screen.active_order()
	if gate in [TutorialStepData.Gate.COLLECTED, TutorialStepData.Gate.SERVED] and order != null:
		var ids := order.item_ids()
		if not ids.is_empty():
			wanted = ids[0]

	var best: Dictionary = {}
	var best_score := -1.0
	for pair in logic.find_possible_moves(4096):
		var a: Vector2i = pair["a"]
		var b: Vector2i = pair["b"]
		var snapshot := logic.snapshot()
		if logic.try_swap(a, b) == BoardState.SwapOutcome.INVALID:
			_restore(logic, snapshot)
			continue
		var result := logic.resolve([a, b])
		var score := 0.0
		match gate:
			TutorialStepData.Gate.SWAP_VERTICAL:
				score = 4.0 if a.x == b.x else 0.0
			TutorialStepData.Gate.SWAP_HORIZONTAL:
				score = 4.0 if a.y == b.y else 0.0
			TutorialStepData.Gate.CREATED_TAPAU:
				if (_has(result, BoardCell.Special.TAPAU) or _has(result, BoardCell.Special.TAPAU_VERTICAL)):
					score = 20.0
			TutorialStepData.Gate.CREATED_DULANG:
				if _has(result, BoardCell.Special.DULANG):
					score = 20.0
			TutorialStepData.Gate.BLOCKER_OPENED:
				for hit in result.blockers:
					if hit.removed:
						score += 6.0
			TutorialStepData.Gate.COLLECTED:
				var totals := result.collected_totals()
				score = float(totals.get(wanted, 0)) * 8.0
			TutorialStepData.Gate.SERVED:
				var totals := result.collected_totals()
				score = float(result.collected_count())
				if order != null and not wanted.is_empty() and totals.has(wanted):
					score += 20.0
			_:
				score = float(result.collected_count())
		score += float(result.collected_count()) * 0.1
		_restore(logic, snapshot)
		if score > best_score:
			best_score = score
			best = {"a": a, "b": b}
	if best.is_empty():
		var fallback := logic.find_possible_moves(1)
		if not fallback.is_empty():
			return fallback[0]
	return best


## Kuih must stay inside their own tile.
##
## Two things used to break this: the hint pulse scaled the tile to 1.12, and
## since adjacent tiles sit exactly one pitch apart that made neighbouring kuih
## overlap; and the icon was drawn at 0.92 of the cell while the recess only
## reaches 0.91, leaving no visible gap.
## The tile views must mirror [BoardState] exactly: one view per occupied cell,
## and no view node that the board has forgotten about.
##
## Gravity once looked its falling tile up by the destination cell instead of the
## source, which orphaned the view - the cell rendered blank and the next refill
## stacked a second kuih on the stranded one.
func _check_view_sync(board: MatchBoard, context: String) -> void:
	var occupied := 0
	for y in board.logic.height:
		for x in board.logic.width:
			var cell := board.logic.get_cell(Vector2i(x, y))
			if cell != null and cell.has_kuish():
				occupied += 1
	if board._tiles.size() != occupied:
		problems.append(
			"%s: %d tile views for %d occupied cells" % [context, board._tiles.size(), occupied]
		)

	var tracked := {}
	for key in board._tiles:
		tracked[board._tiles[key]] = true
	for child in board.get_children():
		if child is TileView and not tracked.has(child):
			problems.append("%s: an orphaned tile view is still on the board" % context)


func _check_tiles_fit(board: MatchBoard, tutorial_index: int) -> void:
	for child in board.get_children():
		if not (child is TileView):
			continue
		var tile: TileView = child
		if tile.icon == null:
			problems.append("tutorial %d: a tile has no icon" % tutorial_index)
			continue
		if not is_equal_approx(tile.scale.x, 1.0) or not is_equal_approx(tile.scale.y, 1.0):
			problems.append(
				"tutorial %d: tile is scaled to %s, which pushes it into its neighbour"
				% [tutorial_index, str(tile.scale)]
			)
		if tile.icon.cell_ratio > 0.86:
			problems.append(
				"tutorial %d: icon fills %.0f%% of the cell, the recess only reaches 91%%"
				% [tutorial_index, tile.icon.cell_ratio * 100.0]
			)


func _has(result: BoardState.ClearResult, kind: int) -> bool:
	for entry in result.created:
		if int(entry["special"]) == kind:
			return true
	return false


func _restore(logic: BoardState, snapshot: Array) -> void:
	for y in logic.height:
		for x in logic.width:
			var cell := logic.get_cell(Vector2i(x, y))
			var data: Dictionary = snapshot[y][x]
			cell.kuih = KuihLibrary.get_kuih(data["kuih"])
			cell.special = data["special"]
			cell.order_kuish = data["order_kuish"]
			cell.blocker_kind = data["blocker"]
			cell.blocker_hp = data["hp"]
			cell.target_kuish = data["target"]
			cell.target_progress = data["target_progress"]
			cell.target_need = data["target_need"]


## Builds a level, plays real swaps through [MatchBoard], then exercises every
## booster and the pause menu.
func _play_level(level_id: int) -> void:
	var level_screen := LevelController.new()
	level_screen.level_id = level_id
	scene_root.add_child(level_screen)
	for _i in 4:
		await get_tree().process_frame

	var board: MatchBoard = level_screen.board
	if board == null or board.logic == null:
		problems.append("stage %d: board never built" % level_id)
		level_screen.queue_free()
		return
	if board.logic == null:
		problems.append("stage %d: board never built" % level_id)
		level_screen.queue_free()
		return

	# A real swap through the same entry point the player's swipe uses.
	var moves := board.logic.find_possible_moves(1)
	if moves.is_empty():
		problems.append("stage %d: find_possible_moves returned nothing" % level_id)
	else:
		var pair: Dictionary = moves[0]
		board.attempt_swap(pair["a"], pair["b"])
		var settled := await _wait_idle(
			level_screen, "stage %d swap" % level_id, _settle_budget(level_id)
		)
		_check_view_sync(board, "stage %d after swap" % level_id)

		# An invalid swap must not consume a move or throw.
		level_screen.moves_left = 10
		var before := level_screen.moves_left
		board.attempt_swap(Vector2i(0, 0), Vector2i(7, 7))
		for _i in 30:
			await get_tree().process_frame
		if level_screen.moves_left != before:
			problems.append("stage %d: an invalid swap cost a move" % level_id)

		# Hints and targeting mode.
		if not board.show_hint():
			problems.append("stage %d: hint found no move" % level_id)
		board.clear_hints()
		board.begin_targeting(0)
		board.cancel_targeting()

		# Boosters. These all drive the board, so they are only meaningful once it
		# has actually gone idle.
		if settled:
			level_screen.finished = false
			board.enabled = true
			level_screen.result.visible = false
			# This section tests booster behavior, so keep objectives open even
			# when a gift/refill cascade would otherwise win the short first stage.
			for order in level_screen.orders:
				for id in order.remaining:
					order.remaining[id] = 10000
			EconomyManager.grant_booster(EconomyManager.Booster.SPATULA, 2)
			EconomyManager.grant_booster(EconomyManager.Booster.TRAY, 2)
			EconomyManager.grant_booster(EconomyManager.Booster.SHUFFLE, 2)
			EconomyManager.grant_booster(EconomyManager.Booster.GIFT, 2)
			EconomyManager.grant_booster(EconomyManager.Booster.EXTRA_MOVES, 2)
			level_screen.hud.booster_bar.refresh()

			await _boost(level_screen, EconomyManager.Booster.SHUFFLE, Vector2i(-1, -1))
			await _boost(level_screen, EconomyManager.Booster.EXTRA_MOVES, Vector2i(-1, -1))
			await _boost(level_screen, EconomyManager.Booster.GIFT, Vector2i(-1, -1))
			await _boost(level_screen, EconomyManager.Booster.SPATULA, _first_playable(board))
			await _boost(level_screen, EconomyManager.Booster.TRAY, _centre(board))
		else:
			print("      diag: stage %d boosters skipped, board never settled" % level_id)

	# Pause menu, restart and the result overlay.
	level_screen._open_pause_menu()
	await get_tree().process_frame
	if not get_tree().paused:
		problems.append("stage %d: pause menu did not pause gameplay" % level_id)
	level_screen._resume_level()
	level_screen._on_restart()
	for _i in 30:
		await get_tree().process_frame
	level_screen.result.show_win("Stage %d" % level_id, 3, 120, [&"onde_onde"], true)
	await get_tree().process_frame
	level_screen.result.show_fail("Still need: 3 Onde-onde", true)
	await get_tree().process_frame

	print("stage %2d played ok" % level_id)
	level_screen.queue_free()
	await get_tree().process_frame


func _boost(screen: LevelController, booster: int, target: Vector2i) -> void:
	# The preceding invalid swap can still be bouncing back at high frame rates.
	if not await _wait_idle(screen, "before booster %d" % booster):
		return
	var start_moves := screen.moves_left
	var start_count := EconomyManager.booster_count(booster)
	screen._on_booster_requested(booster)
	# Sudip and Dulang enter targeting mode first, then wait for a tap.
	if target.x >= 0:
		for _i in 8:
			await get_tree().process_frame
		if screen.board.targeting >= 0:
			screen._on_booster_targeted(booster, target)
	await _wait_idle(screen, "booster %d" % booster, _settle_budget(screen.level_id) * 2)
	if start_count > 0 and EconomyManager.booster_count(booster) >= start_count:
		problems.append("booster %d was not consumed" % booster)
	if booster == EconomyManager.Booster.EXTRA_MOVES and screen.moves_left <= start_moves:
		problems.append("+5 moves booster granted no moves")


func _first_playable(board: MatchBoard) -> Vector2i:
	for y in board.logic.height:
		for x in board.logic.width:
			if board.logic.is_playable(Vector2i(x, y)):
				return Vector2i(x, y)
	return Vector2i(-1, -1)


func _centre(board: MatchBoard) -> Vector2i:
	return Vector2i(board.logic.width / 2, board.logic.height / 2)
