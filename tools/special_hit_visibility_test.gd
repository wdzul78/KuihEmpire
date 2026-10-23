extends Node

func _ready() -> void:
	run.call_deferred()

func run() -> void:
	for kind in [BoardCell.Special.TAPAU,BoardCell.Special.TAPAU_VERTICAL,BoardCell.Special.DULANG,BoardCell.Special.ORDER]:
		var board := MatchBoard.new()
		board.size = Vector2(480,480)
		add_child(board)
		var level := LevelDefinition.new()
		level.width = 8
		level.height = 8
		level.kuih = KuihLibrary.starter_set()
		board.build(level)
		var origin := Vector2i(3,3)
		board.logic.get_cell(origin).special = kind
		board.logic.get_cell(origin).order_kuish = &"onde_onde"
		board._refresh_tiles()
		var result := board.logic.activate_specials([origin])
		var context := {"pending":1}
		board._play_activation_wave(result,result.activated,0,{},context)
		await board._wait(.52 if kind == BoardCell.Special.TAPAU_VERTICAL else .22)
		assert(not board._tiles[origin].visible,"Origin disappears when activated, while its VFX is still running")
		for activation in result.activated:
			for pos in activation.cells:
				if result.cleared.has(pos):
					assert(not board._tiles[pos].visible,"Affected item disappears with activation VFX")
		while context.pending > 0:
			await get_tree().process_frame
		board.free()
	AudioManager.stop_music()
	print("Special hit visibility: PASS (horizontal, vertical, Badak, Lapis clear during VFX)")
	get_tree().quit()
