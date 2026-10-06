extends Node

var problems := 0
func check(ok: bool, message: String) -> void:
	if not ok:
		problems += 1
		push_error(message)

func board() -> BoardState:
	var state := BoardState.new()
	state.setup(6,6,KuihLibrary.starter_set(),19)
	return state

func _ready() -> void:
	for special in [BoardCell.Special.TAPAU,BoardCell.Special.TAPAU_VERTICAL,BoardCell.Special.DULANG,BoardCell.Special.HANTAR,BoardCell.Special.ORDER]:
		for guard in [BlockerSpec.Kind.BANANA_LEAF,BlockerSpec.Kind.FOOD_COVER,BlockerSpec.Kind.STEAMER,BlockerSpec.Kind.STICKY_SYRUP]:
			for hp in [1,2]:
				var state := board()
				var origin := Vector2i(2,2)
				var target := origin+(Vector2i.DOWN if special == BoardCell.Special.TAPAU_VERTICAL else Vector2i.RIGHT)
				state.get_cell(origin).special = special
				var cell := state.get_cell(target)
				cell.blocker_kind = guard
				cell.blocker_hp = hp
				state.get_cell(origin).order_kuish = cell.kuish_id()
				var food := cell.kuih
				var result := state.activate_specials([origin])
				check(result.activated[0].cells.has(target),"guard is included in special footprint")
				check(result.direct_blocker_hits.has(target),"special directly hits guard")
				check(cell.blocker_hp == hp-1 and cell.has_overlay() == (hp>1),"one hit removes one guard layer")
				check(cell.kuih == food and not result.cleared.has(target),"guard absorbs hit and preserves kuih underneath")
				var hits := result.blockers.filter(func(hit): return hit.pos == target)
				check(hits.size() == 1,"direct and neighbouring damage do not double-count")
	var cross := board()
	var a := Vector2i(2,2)
	var b := Vector2i(3,2)
	cross.get_cell(a).special = BoardCell.Special.TAPAU
	cross.get_cell(b).special = BoardCell.Special.TAPAU_VERTICAL
	var target := Vector2i(5,2)
	cross.get_cell(target).clear_kuish()
	cross.get_cell(target).blocker_kind = BlockerSpec.Kind.STEAMER
	cross.get_cell(target).blocker_hp = 1
	var hit := cross.activate_specials([a,b])
	check(hit.combo_cells.has(target) and not cross.get_cell(target).has_overlay(),"directional combo removes even an empty guarded slot")
	var objective := board()
	objective.get_cell(a).special = BoardCell.Special.DULANG
	objective.apply_blockers([BlockerSpec.make_target(BlockerSpec.Kind.PACKAGING_BOX,[b],&"onde_onde",99)])
	objective.activate_specials([a])
	check(objective.get_cell(b).is_target(),"collection objectives still require their requested kuih")
	print("Special guard tests: %s (%d problems)" % ["PASS" if problems == 0 else "FAIL",problems])
	get_tree().quit(0 if problems == 0 else 1)
