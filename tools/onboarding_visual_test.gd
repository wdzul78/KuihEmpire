extends Node

func _ready() -> void:
	SaveManager.save_path = "user://kuih_onboarding_visual_test.json"
	SaveManager.reset()
	run.call_deferred()

func shot(name: String) -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://.shots"))
	get_viewport().get_texture().get_image().save_png("res://.shots/"+name+".png")

func run() -> void:
	ProgressionManager.complete_tutorial()
	var welcome := OnboardingFinish.new()
	add_child(welcome)
	await shot("tutorial_gift_closed")
	welcome._open_gift()
	await get_tree().create_timer(.9).timeout
	await shot("tutorial_gift_open")
	welcome._next_page()
	await shot("starter_stall_old")
	OnboardingProgress.restore_stall()
	welcome._build()
	await shot("starter_stall_restored")
	welcome._next_page()
	await shot("starter_accessories")
	welcome.free()
	GameManager.pending_tutorial_index = 1
	var lesson: LevelController = load(SceneManager.LEVEL).instantiate()
	add_child(lesson)
	assert(not lesson.board.enabled and lesson.coach.steps.is_empty())
	await shot("meet_onde_onde")
	var intro: KuihIntroduction
	for child in lesson.get_children():
		if child is KuihIntroduction:
			intro = child
	assert(intro != null)
	for i in 3:
		for child in intro.get_children():
			if child is Button:
				child.pressed.emit()
				break
	assert(lesson.board.enabled and not lesson.coach.steps.is_empty())
	lesson.free()
	GameManager.pending_tutorial_index = 0
	GameManager.pending_level_id = 1
	var stage: LevelController = load(SceneManager.LEVEL).instantiate()
	add_child(stage)
	stage.story.close()
	assert(stage.board.logic.width == 3 and stage.board.logic.has_possible_move())
	await shot("campaign_stage_one_3x3")
	stage.free()
	AudioManager.stop_music()
	await get_tree().create_timer(.2).timeout
	print("Onboarding UI: PASS")
	get_tree().quit()
