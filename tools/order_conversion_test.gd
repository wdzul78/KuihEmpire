extends Node

var problems := 0
func check(ok: bool, message: String) -> void:
	if not ok:
		problems += 1
		push_error(message)

func make_board(seed_value: int = 84) -> BoardState:
	var board := BoardState.new()
	board.setup(7,7,KuihLibrary.starter_set(),seed_value)
	return board

func _ready() -> void:
	run.call_deferred()

func run() -> void:
	var random_types: Dictionary = {}
	for kind in [BoardCell.Special.DULANG,BoardCell.Special.TAPAU,BoardCell.Special.TAPAU_VERTICAL,BoardCell.Special.HANTAR]:
		for reverse in [false,true]:
			for seed_value in range(20,28):
				var board := make_board(seed_value)
				var a := Vector2i(2,2)
				var b := Vector2i(3,2)
				board.get_cell(a).special = BoardCell.Special.ORDER
				board.get_cell(a).order_kuish = &"onde_onde"
				board.get_cell(b).special = kind
				board.get_cell(Vector2i.ZERO).blocker_kind = BlockerSpec.Kind.STEAMER
				board.get_cell(Vector2i.ZERO).blocker_hp = 2
				board.get_cell(Vector2i(6,6)).special = BoardCell.Special.DULANG
				var pair := [b,a] if reverse else [a,b]
				check(board.try_swap(pair[0],pair[1]) == BoardState.SwapOutcome.ACTIVATED_SPECIAL,"either swap direction accepts Order combo")
				var ordinary: Dictionary = {}
				for y in board.height:
					for x in board.width:
						var pos := Vector2i(x,y)
						var cell := board.get_cell(pos)
						if cell.is_playable() and cell.special == BoardCell.Special.NONE:
							ordinary[pos] = cell.kuish_id()
				var result := board.activate_specials(pair)
				random_types[result.conversion_kuih] = true
				check(result.combo == &"order_conversion" and result.conversion_kind == kind,"combo inherits partner kind")
				check(not result.converted.is_empty(),"random type always exists on board")
				for pos in ordinary:
					check(result.converted.has(pos) == (ordinary[pos] == result.conversion_kuih),"all and only chosen ordinary type converts")
				check(not result.converted.has(Vector2i.ZERO) and not result.converted.has(Vector2i(6,6)),"blocked kuih and existing specials do not convert")
				var seen: Dictionary = {}
				for activation in result.activated:
					check(not seen.has(activation.pos),"every special fires once despite overlapping blasts")
					seen[activation.pos] = activation
				for pos in result.converted:
					check(seen.has(pos) and seen[pos].kind == kind and result.cleared[pos].source == kind,"every converted special executes")
					if kind == BoardCell.Special.DULANG:
						for hit in seen[pos].cells:
							check(absi(hit.x-pos.x) <= 1 and absi(hit.y-pos.y) <= 1,"Dulang keeps native 3x3 footprint")
					if kind == BoardCell.Special.TAPAU:
						for hit in seen[pos].cells:
							check(hit.y == pos.y,"horizontal Tapau remains horizontal")
					if kind == BoardCell.Special.TAPAU_VERTICAL:
						for hit in seen[pos].cells:
							check(hit.x == pos.x,"vertical Tapau remains vertical")
	check(random_types.size() > 1,"chosen type varies across seeds")
	var view := MatchBoard.new()
	view.size = Vector2(400,400)
	add_child(view)
	view.build(TutorialLibrary.get_stage(8))
	view.logic.get_cell(Vector2i(2,2)).special = BoardCell.Special.ORDER
	view.logic.get_cell(Vector2i(3,2)).special = BoardCell.Special.DULANG
	view._refresh_tiles()
	var result := view.logic.activate_specials([Vector2i(2,2),Vector2i(3,2)])
	view._play_step(result,0)
	await get_tree().create_timer(.35).timeout
	for pos in result.converted:
		check(view._tiles[pos].icon.special_kind == BoardCell.Special.DULANG,"conversion graphic appears before explosions")
	await get_tree().create_timer(5).timeout
	view.free()
	AudioManager.stop_music()
	print("Order conversion tests: %s (%d problems)" % ["PASS" if problems == 0 else "FAIL",problems])
	get_tree().quit(0 if problems == 0 else 1)
