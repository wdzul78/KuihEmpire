extends Node

func _ready() -> void:
	SaveManager.save_path = "user://order_electric_test.json"
	SaveManager.reset()
	run.call_deferred()

func shot(name_text: String) -> void:
	if DisplayServer.get_name() == "headless":
		return
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://.shots/order_"+name_text+".png")

func run() -> void:
	var screen := LevelController.new()
	screen.tutorial_index = 8
	add_child(screen)
	screen.coach.index = 3
	screen.coach._show_step()
	var board := screen.board
	board.clear_hints()
	var center := Vector2i(3,3)
	var wanted := board.logic.pool[0].id
	board.logic.get_cell(center).special = BoardCell.Special.ORDER
	board.logic.get_cell(center).order_kuish = wanted
	board._refresh_tiles()
	await get_tree().process_frame
	var result := board.logic.activate_specials([center])
	var target: TileView
	for pos in result.cleared:
		if pos != center:
			target = board._tiles[pos]
			break
	assert(target != null)
	var destination := board.cell_to_pos(center)
	var distance_before := target.position.distance_to(destination)
	board._play_step(result,0)
	await get_tree().create_timer(.16).timeout
	assert(board._vfx.effects.any(func(e: Dictionary) -> bool: return e.kind == "order_electric"))
	assert(target.position.distance_to(destination) == distance_before)
	await shot("connected")
	await get_tree().create_timer(.24).timeout
	assert(target.position.distance_to(destination) < distance_before)
	assert(target.scale.x < 1)
	await shot("pull")
	await get_tree().create_timer(1.3).timeout
	assert(not is_instance_valid(target))
	assert(board._vfx.effects.is_empty())
	var points := PackedVector2Array()
	for i in 64:
		points.append(Vector2(i%8,i/8)*50)
	board._vfx.order_electric(Vector2.ZERO,points,50)
	assert(board._vfx.effects.size() == 1 and board._vfx.effects[0].points.size() == 64)
	screen.free()
	AudioManager.stop_music()
	for player in AudioManager._voices:
		player.stop()
		player.stream = null
	await get_tree().create_timer(.15).timeout
	print("Special Order electric: PASS (connection, inward motion, shrink, cleanup and 64-target group)")
	get_tree().quit()
