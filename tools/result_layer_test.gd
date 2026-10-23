extends Node

func _ready() -> void:
	var screen := Control.new()
	add_child(screen)
	var board := MatchBoard.new()
	board.size = Vector2(500,500)
	screen.add_child(board)
	board.build(TutorialLibrary.get_stage(8))
	var pos := Vector2i(2,4)
	board.logic.get_cell(pos).blocker_kind = BlockerSpec.Kind.FOOD_COVER
	board.logic.get_cell(pos).blocker_hp = 2
	board._sync_overlay(pos)
	var result := ResultOverlay.new()
	screen.add_child(result)
	assert(result.z_index > board._overlays[pos].z_index)
	assert(result.z_index > board._vfx.z_index)
	assert(result.z_index > board._combo_praise.z_index)
	assert(not board.clip_contents)
	screen.free()
	print("Result layering: PASS (popup covers blockers and VFX, board effects stay unclipped)")
	get_tree().quit()
