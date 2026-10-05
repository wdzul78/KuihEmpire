extends Node

func _ready() -> void:
	SaveManager.save_path = "user://kuih_special_chain_test.json"
	SaveManager.reset()
	run.call_deferred()

func state() -> BoardState:
	var value := BoardState.new()
	value.setup(7, 7, KuihLibrary.starter_set(), 83)
	return value

func run() -> void:
	# A hit carries each special's own shape into the next wave, including
	# specials outside the initial 3x3. Overlap must never fire a tile twice.
	var chained := state()
	var positions := [Vector2i(2,2), Vector2i(3,2), Vector2i(5,2), Vector2i(5,5), Vector2i(4,5)]
	var kinds := [BoardCell.Special.DULANG, BoardCell.Special.TAPAU,
		BoardCell.Special.TAPAU_VERTICAL, BoardCell.Special.DULANG, BoardCell.Special.TAPAU]
	for i in positions.size():
		chained.get_cell(positions[i]).special = kinds[i]
	var result := chained.activate_specials([positions[0]])
	assert(result.activated.size() == 5)
	assert(result.combo == &"")
	for i in positions.size():
		var entry: Dictionary = result.activated[i]
		assert(entry.pos == positions[i] and entry.kind == kinds[i] and entry.chain_depth == i)
		assert(result.cleared.has(positions[i]))
	assert(result.cleared.has(Vector2i(5,0)))
	assert(result.cleared.has(Vector2i(0,5)))
	# Every kind can be activated by a dulang hit, not only directional ones.
	for kind in [BoardCell.Special.TAPAU, BoardCell.Special.TAPAU_VERTICAL,
		BoardCell.Special.DULANG, BoardCell.Special.ORDER, BoardCell.Special.HANTAR]:
		var sample := state()
		sample.get_cell(Vector2i(2,2)).special = BoardCell.Special.DULANG
		var next := sample.get_cell(Vector2i(3,3))
		next.special = kind
		next.order_kuish = next.kuish_id()
		var hit := sample.activate_specials([Vector2i(2,2)])
		assert(hit.activated.size() == 2)
		assert(hit.activated[1].kind == kind and hit.activated[1].chain_depth == 1)
	# Four overlapping dulang areas form a cycle; each executes exactly once.
	var cycle := state()
	for pos in [Vector2i(2,2),Vector2i(3,2),Vector2i(2,3),Vector2i(3,3)]:
		cycle.get_cell(pos).special = BoardCell.Special.DULANG
	assert(cycle.activate_specials([Vector2i(2,2)]).activated.size() == 4)
	# Visual wave 1 must not fire before wave 0's gold has reached its slots.
	var board := MatchBoard.new()
	board.size = Vector2(900,900)
	add_child(board)
	board.build(TutorialLibrary.get_stage(5))
	board.logic.get_cell(Vector2i(1,1)).special = BoardCell.Special.DULANG
	board.logic.get_cell(Vector2i(2,1)).special = BoardCell.Special.TAPAU
	board._refresh_tiles()
	var hit := board.logic.activate_specials([Vector2i(1,1)])
	board._play_step(hit,0)
	await get_tree().create_timer(.12).timeout
	assert(not board._vfx.effects.any(func(e: Dictionary) -> bool: return e.kind == "beam"))
	await get_tree().create_timer(.44).timeout
	assert(board._vfx.effects.any(func(e: Dictionary) -> bool: return e.kind == "beam"))
	await get_tree().create_timer(1.3).timeout
	assert(board._vfx.effects.is_empty() and board._vfx.particles.is_empty())
	board.free()
	AudioManager.stop_music()
	for player in AudioManager._voices:
		player.stop()
		player.stream = null
	print("Special chain: PASS (five waves, all kinds, native directions, overlap deduplication, visual order and cleanup)")
	get_tree().quit()
