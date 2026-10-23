extends Node

func _ready() -> void:
	var original := SaveManager.data.duplicate(true)
	SaveManager.save_path = "user://stall_accessories_test.json"
	SaveManager.data = SaveManager._normalize({})
	for stage in range(1,31):
		SaveManager.data.levels[str(stage)] = {"stars":3,"completed":true}
	for achievement in AchievementManager.definitions:
		SaveManager.data.achievements[achievement.id] = {"unlocked":true,"reward_claimed":true}
	for key in ["renovate","style","supplies"]:
		assert(RenovationArt.texture(key) != null)
	for item in DecorDefinition.all():
		assert(RenovationArt.texture(item.id) != null)
		var coins := EconomyManager.coins()
		var stars := EconomyManager.stars()
		assert(LocationManager.buy(item.id))
		assert(EconomyManager.stars() == stars - item.cost)
		assert(EconomyManager.coins() == coins)
		var location: StringName = &"school_canteen" if item.institutional else &"family_stall"
		assert(LocationManager.equip(location, item.id))
		assert(not LocationManager.equip(&"family_stall" if item.institutional else &"school_canteen", item.id))
	assert(DecorDefinition.for_location(&"family_stall").size() == 7)
	assert(DecorDefinition.for_location(&"school_canteen").size() == 3)
	assert(DecorDefinition.for_location(&"government_canteen").size() == 3)
	assert(SaveManager.save_game())
	SaveManager.load_game()
	assert(LocationManager.equipped(&"school_canteen").COUNTER_DECOR == "steel_organizer")
	for id in ["family_stall","school_canteen"]:
		SaveManager.data.active_stall_id = id
		var stall := GeraiScreen.new()
		add_child(stall)
		await get_tree().process_frame
		await get_tree().create_timer(.35).timeout
		for hotspot in stall._hotspots.get_children():
			assert(hotspot.has_node("HotspotIcon"))
		if DisplayServer.get_name() != "headless":
			await RenderingServer.frame_post_draw
			get_viewport().get_texture().get_image().save_png("res://.shots/accessories_%s.png" % id)
		stall._show_decor(DecorDefinition.for_location(StringName(id))[0])
		assert(stall._panel.find_child("AccessoryPreview",true,false) != null)
		if DisplayServer.get_name() != "headless":
			await RenderingServer.frame_post_draw
			get_viewport().get_texture().get_image().save_png("res://.shots/accessory_panel_%s.png" % id)
		stall.queue_free()
		await get_tree().process_frame
	for item in DecorDefinition.all():
		var location: StringName = &"school_canteen" if item.institutional else &"family_stall"
		LocationManager.unequip(location, item.slot)
		assert(not LocationManager.equipped(location).has(item.slot))
		assert(LocationManager.owned(item.id))
	assert(SaveManager.save_game())
	SaveManager.load_game()
	assert(LocationManager.equipped(&"school_canteen").is_empty())
	SaveManager.data = original
	print("Stall accessories: PASS (accessory textures, ten purchases, themed equip guards, persistence, scene previews and icon hotspots)")
	get_tree().quit()
