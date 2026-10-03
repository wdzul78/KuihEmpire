extends Node

## Renders every screen to PNG so the art direction can be reviewed.
##
##   godot --rendering-driver opengl3 --resolution 540x960 res://tools/screenshot_scene.tscn
##
## Output lands in `res://.shots/`.

const OUT_DIR := "res://.shots"

var scene_root: Node
var index: int = 0


func _ready() -> void:
	SaveManager.save_path = "user://kuih_shot_save.json"
	SaveManager.reset()
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT_DIR))
	scene_root = Node.new()
	scene_root.name = "ShotRoot"
	add_child(scene_root)
	run.call_deferred()


func run() -> void:
	await _capture("res://scenes/boot/boot.tscn", 6)
	await _shot_story(0)
	await _shot_story(1)
	await _shot_story(2)
	await _shot_home()
	await _shot_tutorial(1)
	await _shot_tutorial(2)
	await _shot_tutorial(4)
	await _shot_tutorial(6)
	await _shot_tutorial(8)
	await _shot_level(1)
	await _shot_level(10)
	await _shot_level(30)
	await _shot_recipe_book()
	await _shot_journey()
	await _shot_gerai()
	await _shot_settings()
	print("shots written: %d" % index)
	get_tree().quit(0)


## One page of the prologue deck, so the storyline screen can be reviewed.
func _shot_story(page_index: int) -> void:
	var deck := StoryLibrary.pages_for(StoryLibrary.PROLOGUE)
	if page_index >= deck.size():
		return
	var screen := StoryScreen.new()
	scene_root.add_child(screen)
	await _settle(6)
	screen.play(deck, true)
	# Jump straight to the requested page.
	for _i in page_index:
		screen.show_page(screen.index + 1, false)
	await _settle(8)
	await _save("story_page_%d" % (page_index + 1))
	scene_root.remove_child(screen)
	screen.queue_free()
	await get_tree().process_frame


func _shot_tutorial(index: int) -> void:
	var screen := LevelController.new()
	screen.tutorial_index = index
	scene_root.add_child(screen)
	await _settle(10)
	# Land on the last coaching step so the card shows real copy, then capture
	# BEFORE playing a move - playing it would satisfy the gate and hide the coach.
	if screen.coach != null:
		while not screen.coach.is_done() and screen.coach.index < screen.coach.steps.size() - 1:
			screen.coach._advance()
	await _settle(6)
	await _save("tutorial_%02d_%dx%d" % [index, screen.level.width, screen.level.height])
	scene_root.remove_child(screen)
	screen.queue_free()
	await get_tree().process_frame


func _shot_home() -> void:
	await _capture("res://scenes/menu/home.tscn", 6)


func _shot_recipe_book() -> void:
	ProgressionManager.unlock_recipe(&"onde_onde")
	ProgressionManager.unlock_recipe(&"kuih_lapis")
	ProgressionManager.unlock_recipe(&"seri_muka")
	ProgressionManager.unlock_recipe(&"kuih_ketayap")
	ProgressionManager.unlock_recipe(&"ang_ku_kueh")
	ProgressionManager.add_mastery(&"onde_onde", 34)
	ProgressionManager.add_mastery(&"seri_muka", 12)
	await _capture("res://scenes/ui/recipe_book.tscn", 6)


func _shot_journey() -> void:
	ProgressionManager.record_win(7, 2, 8)
	await _capture("res://scenes/world/journey_map.tscn", 6)


func _shot_gerai() -> void:
	await _capture("res://scenes/stall/gerai_screen.tscn", 6)


func _shot_settings() -> void:
	await _capture("res://scenes/ui/settings_screen.tscn", 6)


func _shot_level(level_id: int) -> void:
	var screen := LevelController.new()
	screen.level_id = level_id
	scene_root.add_child(screen)
	await _settle(10)
	if screen.coach != null:
		screen.coach.visible = false
	# Fire a few moves so specials and overlays appear on the board.
	for _n in 3:
		var moves := screen.board.logic.find_possible_moves(1)
		if moves.is_empty():
			break
		var pair: Dictionary = moves[0]
		screen.board.attempt_swap(pair["a"], pair["b"])
		for _i in 8:
			await get_tree().process_frame
	await _settle(6)
	await _save("stage_%02d" % level_id)
	scene_root.remove_child(screen)
	screen.queue_free()
	await get_tree().process_frame


func _capture(path: String, frames: int) -> void:
	var packed: PackedScene = load(path)
	var node := packed.instantiate()
	scene_root.add_child(node)
	await _settle(frames)
	var name := path.get_file().replace(".tscn", "")
	await _save(name)
	scene_root.remove_child(node)
	node.queue_free()
	await get_tree().process_frame


func _settle(frames: int) -> void:
	for _i in frames:
		await get_tree().process_frame
	await RenderingServer.frame_post_draw


func _save(label: String) -> void:
	var image := get_viewport().get_texture().get_image()
	if image == null:
		print("no viewport image for %s" % label)
		return
	index += 1
	var path := "%s/%02d_%s.png" % [OUT_DIR, index, label]
	image.save_png(path)
	print("saved %s" % path)
