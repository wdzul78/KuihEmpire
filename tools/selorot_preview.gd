extends LevelController

func _notification(what: int) -> void:
	if what in [NOTIFICATION_APPLICATION_PAUSED,NOTIFICATION_APPLICATION_FOCUS_OUT]:
		return
	super._notification(what)

func _ready() -> void:
	SaveManager.save_path = "user://selorot_preview.json"
	SaveManager.reset()
	SaveManager.data["tutorial_done"] = true
	GameManager.pending_tutorial_index = 0
	endless_mode = true
	super._ready()
	demo.call_deferred()

func prepare() -> void:
	board.build(level)
	for row in board.logic.grid:
		for cell in row:
			cell.special = BoardCell.Special.NONE

func capture_after(delay: float, filename: String) -> void:
	await board._wait(delay)
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://.analysis/"+filename+".png")

func demo() -> void:
	await get_tree().create_timer(.4).timeout
	prepare()
	board.logic.get_cell(Vector2i(3,4)).special = BoardCell.Special.TAPAU_VERTICAL
	board._refresh_tiles()
	await get_tree().create_timer(.6).timeout
	await capture_after(.01,"selorot-idle")
	capture_after(.22,"selorot-leaf-sweep")
	await board._play_step(board.logic.activate_specials([Vector2i(3,4)]),0)
	await get_tree().create_timer(.5).timeout
	prepare()
	var a := Vector2i(3,4)
	var b := Vector2i(4,4)
	board.logic.get_cell(a).special = BoardCell.Special.DULANG
	board.logic.get_cell(b).special = BoardCell.Special.TAPAU_VERTICAL
	board._refresh_tiles()
	await get_tree().create_timer(.6).timeout
	var result := board.logic.activate_specials([a,b])
	assert(result.combo == &"badak_vertical")
	capture_after(.55,"pisang-three-column-sweep")
	await board._play_step(result,0)
	assert(ProgressionManager.is_recipe_unlocked(PowerupRecipes.key(PowerupRecipes.PISANG_COMBO)))
	await get_tree().create_timer(.5).timeout
	for entry in PowerupRecipes.ENTRIES:
		PowerupRecipes.introduce(int(entry[0]))
	var book := RecipeBookScreen.new()
	add_child(book)
	book._page = 3
	book.refresh()
	await capture_after(.3,"selorot-pisang-recipe-book")
	print("Selorot rendered preview: PASS single + triple column combo + recipe book")
	get_tree().quit()
