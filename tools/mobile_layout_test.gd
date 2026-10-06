extends Node

var problems := 0
func check(ok: bool, message: String) -> void:
	if not ok:
		problems += 1
		push_error(message)

func _ready() -> void:
	run.call_deferred()

func run() -> void:
	SaveManager.save_path = "user://mobile_layout_test.json"
	var pixels := Vector2(get_window().size)
	var viewport := get_viewport().get_visible_rect().size
	check(absf(pixels.aspect()-viewport.aspect()) < .002,"viewport expands to device ratio without letterboxing")
	var full := Vector2(1080,2400)
	var safe := Rect2(0,90,1080,2250)
	var insets := MobileLayout.inset_offsets(full,safe,Vector4(0,0,1,1))
	check(insets == Vector4(0,90,0,-60),"notch and bottom navigation safe insets")
	check(MobileLayout.inset_offsets(full,Rect2(Vector2.ZERO,full),Vector4(.1,.2,.9,.95)) == Vector4.ZERO,"no inset on unobstructed device")
	for tutorial in [0,8]:
		var screen := LevelController.new()
		screen.level_id = 1
		screen.tutorial_index = tutorial
		add_child(screen)
		await get_tree().create_timer(.35).timeout
		var board := screen.board
		var rect := Rect2(board.get_global_rect().position+board.board_origin,Vector2(board.cell_size*board.logic.width,board.cell_size*board.logic.height))
		check(get_viewport().get_visible_rect().encloses(rect),"board entirely inside viewport")
		check(board.cell_size > 0,"cells remain usable")
		check(screen.hud.booster_bar.get_global_rect().end.y <= viewport.y+1,"boosters fit vertically")
		for pos in [Vector2i.ZERO,Vector2i(board.logic.width-1,board.logic.height-1)]:
			check(board.pos_to_cell(board._cell_center(pos)) == pos,"touch mapping remains correct at board corners")
		if DisplayServer.get_name() != "headless":
			await RenderingServer.frame_post_draw
			get_viewport().get_texture().get_image().save_png("res://.shots/mobile_%dx%d_%s.png" % [pixels.x,pixels.y,"tutorial" if tutorial > 0 else "campaign"])
		screen.free()
	var home := HomeScreen.new()
	add_child(home)
	await get_tree().create_timer(.35).timeout
	check(get_viewport().get_visible_rect().encloses(home._play_button.get_global_rect()),"main menu Play fits viewport")
	check(home.get_node("BackgroundLayer").get_global_rect().size == viewport,"menu background covers entire viewport")
	home.free()
	AudioManager.stop_music()
	print("Mobile layout %dx%d: %s (%d problems)" % [pixels.x,pixels.y,"PASS" if problems == 0 else "FAIL",problems])
	get_tree().quit(0 if problems == 0 else 1)
