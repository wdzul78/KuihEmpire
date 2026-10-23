extends Node

func _ready() -> void:
	var original := SaveManager.data.duplicate(true)
	SaveManager.save_path = "user://institutional_canteen_visual_test.json"
	SaveManager.data = SaveManager._normalize({})
	for stage in range(1,241):
		SaveManager.data.levels[str(stage)] = {"stars":3,"completed":true}
	for achievement in AchievementManager.definitions:
		SaveManager.data.achievements[achievement.id] = {"unlocked":true,"reward_claimed":true}
	for id in ["school_canteen", "government_canteen"]:
		SaveManager.data.active_stall_id = id
		for index in range(4):
			SaveManager.data.structural_upgrades[id] = index
			var stall := GeraiScreen.new()
			add_child(stall)
			await get_tree().process_frame
			await get_tree().process_frame
			await get_tree().create_timer(.35).timeout
			await RenderingServer.frame_post_draw
			assert(stall._preview._authored_background)
			assert(stall._preview.location_id == StringName(id))
			assert(stall._preview.structural_state == index)
			get_viewport().get_texture().get_image().save_png("res://.shots/%s_%d.png" % [id,index])
			stall.queue_free()
			await get_tree().process_frame
		var home := HomeScreen.new()
		add_child(home)
		await get_tree().process_frame
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("res://.shots/home_%s.png" % id)
		home.queue_free()
		await get_tree().process_frame
	SaveManager.data = original
	print("Institutional canteen mobile preview: PASS (8 states, 2 menu compositions)")
	get_tree().quit()
