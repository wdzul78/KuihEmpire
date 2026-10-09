extends Node

var problems := 0
var falling := false
var bonus_playing := false
var bonus_points := 0

func check(value: bool, message: String) -> void:
	if not value:
		problems += 1
		push_error(message)

func _ready() -> void:
	SaveManager.save_path = "user://gameplay_feel_test.json"
	SaveManager.reset()
	run.call_deferred()

func fall(board: MatchBoard) -> void:
	falling = true
	await board._play_fall_and_refill()
	falling = false

func play_bonus(bonus: VictoryBonus, board: MatchBoard, moves: int) -> void:
	bonus_playing = true
	await bonus.play(board, moves, 100)
	bonus_playing = false

func snapshot(board: MatchBoard) -> Array:
	var result: Array = [board.logic.rng.state]
	for y in board.logic.height:
		for x in board.logic.width:
			var cell := board.logic.get_cell(Vector2i(x,y))
			result.append([cell.kuish_id(), cell.special, cell.order_kuish, cell.blocker_hp])
	return result

func shot(name_text: String) -> void:
	if DisplayServer.get_name() == "headless":
		return
	await RenderingServer.frame_post_draw
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://.shots"))
	get_viewport().get_texture().get_image().save_png("res://.shots/gameplay_feel_" + name_text + ".png")

func run() -> void:
	var board := MatchBoard.new()
	board.size = Vector2(700,700)
	add_child(board)
	board.build(TutorialLibrary.get_stage(8))
	await get_tree().process_frame
	await get_tree().process_frame
	var top: TileView = board._tiles[Vector2i.ZERO]
	var previous_position := top.position
	for x in [0,1,2]:
		for y in range(board.logic.height-2,board.logic.height):
			var pos := Vector2i(x,y)
			board.logic.get_cell(pos).clear_kuish()
			board._tiles[pos].queue_free()
			board._tiles.erase(pos)
	fall(board)
	check(board._tiles[Vector2i(0,2)] == top, "existing tile keeps its identity through gravity")
	var fresh: TileView = board._tiles[Vector2i.ZERO]
	check(fresh.modulate.a == 1 and fresh.scale == Vector2.ONE, "new kuih enter as full-size pieces")
	check(fresh.position.y < board.cell_to_pos(Vector2i.ZERO).y, "new kuih start above their destination")
	await get_tree().create_timer(.08).timeout
	check(top.position.y > previous_position.y and fresh.position.y < board.cell_to_pos(Vector2i.ZERO).y, "existing and fresh kuih fall concurrently")
	while falling:
		await get_tree().process_frame
	check(board._tiles.size() == board.logic.width*board.logic.height, "no missing or duplicate views after refill")
	for pos in board._tiles:
		var tile: TileView = board._tiles[pos]
		check(tile.position.is_equal_approx(board.cell_to_pos(pos)) and tile.scale.is_equal_approx(Vector2.ONE), "all columns finish and settle before returning")
		check(tile.cell == board.logic.get_cell(pos), "view and model remain aligned")
	for y in board.logic.height:
		var pos := Vector2i(4,y)
		board.logic.get_cell(pos).clear_kuish()
		board._tiles[pos].queue_free()
		board._tiles.erase(pos)
	await board._play_fall_and_refill()
	for y in board.logic.height:
		var pos := Vector2i(4,y)
		check(board._tiles[pos].position.is_equal_approx(board.cell_to_pos(pos)), "a whole empty column enters in order and lands completely")
	board.logic.get_cell(Vector2i(1,1)).special = BoardCell.Special.HANTAR
	board._refresh_tiles()
	var before := snapshot(board)
	var coins := EconomyManager.coins()
	var bonus := VictoryBonus.new()
	board.add_child(bonus)
	bonus.steps_converted.connect(func(_remaining: int, points: int) -> void: bonus_points += points)
	play_bonus(bonus,board,17)
	while bonus_playing:
		await get_tree().process_frame
	check(bonus_points == 1700, "grouped bonus accounts for every remaining move exactly once")
	check(snapshot(board) == before and EconomyManager.coins() == coins, "bonus never changes board state, RNG or coins")
	for tile in board._tiles.values():
		check(tile.visible, "original board restored after bonus")
	bonus.free()
	bonus_points = 0
	bonus = VictoryBonus.new()
	board.add_child(bonus)
	bonus.steps_converted.connect(func(_remaining: int, points: int) -> void: bonus_points += points)
	play_bonus(bonus,board,30)
	bonus.get_node("SkipBonus").pressed.emit()
	while bonus_playing:
		await get_tree().process_frame
	check(bonus_points == 3000 and snapshot(board) == before, "skip retains the full bonus without model changes")
	bonus.free()
	board.free()
	ProgressionManager.complete_tutorial()
	GameManager.pending_tutorial_index = 0
	var live := LevelController.new()
	live.level_id = 1
	add_child(live)
	await get_tree().process_frame
	live.story.close()
	live.moves_left = 7
	live.score.add_points(500)
	for order in live.orders:
		order.collect(order.target.duplicate())
	live._on_settled()
	check(is_instance_valid(live._victory_bonus) and not live.result.visible and not live.board.enabled, "bonus gates the result and player input")
	var paid := EconomyManager.coins()
	var expected := live.stage_result.final_score
	live._on_settled()
	check(EconomyManager.coins() == paid, "win notification cannot pay twice during animation")
	await get_tree().create_timer(.30).timeout
	await shot("bonus")
	var deadline := Time.get_ticks_msec()+7000
	while not live.result.visible and Time.get_ticks_msec()<deadline:
		await get_tree().process_frame
	check(live.result.visible and live.score.total == expected and live.hud.score_progress.score == expected, "natural completion reaches the saved final score")
	check(EconomyManager.coins() == paid and GameManager.pending_moves_left == 7, "saved coins and remaining-move stats survive animation")
	await get_tree().create_timer(.4).timeout
	await shot("result")
	live._start_level()
	live.story.close()
	live.moves_left = 5
	for order in live.orders:
		order.collect(order.target.duplicate())
	live._on_settled()
	check(is_instance_valid(live._victory_bonus), "replay starts its own bonus")
	live._start_level()
	await get_tree().process_frame
	await get_tree().process_frame
	check(not live.finished and not live.result.visible and live.score.total == 0, "restart cancels old bonus without leaking points or opening stale results")
	live.free()
	AudioManager.stop_music()
	for voice in AudioManager._voices:
		voice.stop()
		voice.stream = null
	await get_tree().process_frame
	print("Gameplay feel: %s (%d problems)" % ["PASS" if problems == 0 else "FAIL",problems])
	get_tree().quit(0 if problems == 0 else 1)
