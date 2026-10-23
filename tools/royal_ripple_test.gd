extends Node

func _ready() -> void:
	run.call_deferred()

func run() -> void:
	var board := MatchBoard.new()
	board.size = Vector2(480,480)
	add_child(board)
	var level := LevelDefinition.new()
	level.width = 8
	level.height = 8
	level.kuih = KuihLibrary.starter_set()
	board.build(level)
	var center := Vector2i(3,3)
	var result := board.logic.clear_booster(center,&"royal")
	board._clear_royal_wave(result,board._cell_center(center))
	await board._wait(.25)
	assert(not board._tiles[center].visible)
	assert(board._tiles[Vector2i(7,7)].visible, "Far item remains until the circular wave reaches it")
	await board._wait(.70)
	for tile in board._tiles.values():
		assert(not tile.visible)
	board.free()
	AudioManager.stop_music()
	print("Royal ripple: PASS (near-to-far clear, all items hidden before refill)")
	get_tree().quit()
