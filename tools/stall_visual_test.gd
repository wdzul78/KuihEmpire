extends Node

func _ready() -> void:
	var original := SaveManager.data.duplicate(true)
	SaveManager.save_path = "user://stall_visual_test.json"
	SaveManager.data = SaveManager._default_data()
	for achievement in AchievementManager.definitions:
		SaveManager.data.achievements[achievement.id] = {"unlocked":true,"reward_claimed":true}
	for stage in range(1, 11):
		SaveManager.data.levels[str(stage)] = {"stars": 3}
	var stall := GeraiScreen.new()
	add_child(stall)
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://.shots/stall_renovation.png")
	stall._show_upgrade()
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://.shots/stall_upgrade_panel.png")
	SaveManager.data = original
	print("Stall visual capture: PASS")
	get_tree().quit()
