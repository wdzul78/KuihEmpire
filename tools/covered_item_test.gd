extends Node
func _ready() -> void:
	for kind in [BlockerSpec.Kind.BANANA_LEAF,BlockerSpec.Kind.FOOD_COVER,BlockerSpec.Kind.STEAMER]:
		await run_case(kind)
	print("Covered items: PASS (leaf, food cover, steamer hidden until final hit)")
	get_tree().quit()

func run_case(kind: int) -> void:
	var screen := LevelController.new()
	screen.level_id = 20
	add_child(screen)
	await get_tree().create_timer(.4).timeout
	screen.story.hide()
	var board := screen.board
	board.auto_hints = false
	var pos := Vector2i(3,3)
	var cell: BoardCell = board.logic.get_cell(pos)
	cell.blocker_kind = kind
	cell.blocker_hp = 1
	board._refresh_tiles()
	board._sync_overlay(pos)
	assert(not board._tiles[pos].icon.visible)
	if DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("res://.shots/banana_leaf_pack.png")
	var hit := BoardState.BlockerHit.new()
	hit.pos = pos
	hit.kind = kind
	hit.removed = true
	cell.remove_obstacle()
	await board._play_blockers([hit])
	assert(board._tiles[pos].icon.visible)
	assert(not board._overlays.has(pos))
	await get_tree().create_timer(.6).timeout
	assert(is_equal_approx(board._tiles[pos].icon.rotation,0.0))
	assert(board._tiles[pos].icon.scale.is_equal_approx(Vector2.ONE))
	cell.blocker_kind = BlockerSpec.Kind.PACKAGING_BOX
	cell.target_need = 7
	board._tiles[pos].set_cell(cell)
	assert(not board._tiles[pos].icon.visible)
	screen.queue_free()
	await get_tree().process_frame
