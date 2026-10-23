extends Node

func _ready() -> void:
	var original := SaveManager.data.duplicate(true)
	SaveManager.save_path = "user://stall_generated_visual_test.json"
	SaveManager.data = SaveManager._default_data()
	for achievement in AchievementManager.definitions:
		SaveManager.data.achievements[achievement.id] = {"unlocked":true,"reward_claimed":true}
	for stage in range(1,31):
		SaveManager.data.levels[str(stage)] = {"stars":3,"completed":true}
	for index in range(4):
		SaveManager.data.structural_upgrades.family_stall = index
		var home := HomeScreen.new()
		add_child(home)
		await get_tree().process_frame
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("res://.shots/generated_home_%d.png" % index)
		home.queue_free()
		await get_tree().process_frame
	SaveManager.data.structural_upgrades.family_stall = 3
	var stall := GeraiScreen.new()
	add_child(stall)
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://.shots/generated_stall_complete.png")
	stall.queue_free()
	await get_tree().process_frame
	SaveManager.data.active_stall_id = "school_canteen"
	var school := HomeScreen.new()
	add_child(school)
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://.shots/generated_home_school.png")
	school.queue_free()
	await get_tree().process_frame
	SaveManager.data.active_stall_id = "family_stall"
	GameManager.pending_tutorial_index = 0
	var game := LevelController.new()
	game.level_id = 1
	add_child(game)
	await get_tree().create_timer(.4).timeout
	game.story.hide()
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://.shots/generated_gameplay.png")
	game.queue_free()
	await get_tree().process_frame
	SaveManager.data = original
	print("Generated artwork visual capture: PASS")
	get_tree().quit()
