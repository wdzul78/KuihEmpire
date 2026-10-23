extends Node
func _ready() -> void:
	run.call_deferred()
func wait_transition() -> void:
	var frames := 0
	while SceneManager._busy and frames < 15000:
		await get_tree().process_frame
		OS.delay_msec(1)
		frames += 1
	assert(not SceneManager._busy)
func run() -> void:
	SaveManager.save_path = "user://menu_routing_test.json"
	SaveManager.reset()
	ProgressionManager.complete_tutorial()
	OnboardingProgress.finish_intro()
	ProgressionManager.record_win(1,1,0)
	var home := HomeScreen.new()
	get_tree().root.add_child(home)
	get_tree().current_scene = home
	await get_tree().process_frame
	home._on_play()
	await wait_transition()
	assert(get_tree().current_scene.scene_file_path == SceneManager.LEVEL)
	assert(GameManager.pending_level_id == 2)
	GameManager.go_journey()
	await wait_transition()
	assert(get_tree().current_scene.scene_file_path == SceneManager.JOURNEY)
	print("Menu routing: PASS (Play opens next stage 2 directly, Journey opens map)")
	get_tree().quit()
