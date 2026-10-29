extends Node

func _ready() -> void:
	SaveManager.save_path = "user://kuih_stall_test.json"
	SaveManager.reset()
	run.call_deferred()

func run() -> void:
	assert(LocationDefinition.all().size() == 8)
	assert(LocationDefinition.for_stage(211).id == &"government_canteen")
	assert(LocationDefinition.for_stage(181).id == &"bazaar_ramadan")
	assert(LocationManager.structural_level(&"family_stall") == 0)
	var coins := EconomyManager.coins()
	assert(not LocationManager.upgrade(&"family_stall") and EconomyManager.coins() == coins)
	EconomyManager.add_coins(10000)
	assert(not LocationManager.upgrade(&"family_stall")) # Currency cannot skip milestone.
	var wallpaper := GeraiBackdrop.new()
	add_child(wallpaper)
	assert(wallpaper.structural_state == 0)
	for id in range(1, 11):
		ProgressionManager.record_win(id, 1, 0, id*100)
	assert(LocationManager.available_level(&"family_stall") == 1 and wallpaper.structural_state == 0)
	assert(ProgressionManager.is_level_unlocked(11)) # Buying structure does not block story.
	var before_score := ProgressionManager.total_best_score()
	ProgressionManager.record_win(1, 1, 0, 50)
	assert(ProgressionManager.total_best_score() == before_score)
	ProgressionManager.record_win(1, 2, 0, 200)
	assert(ProgressionManager.total_best_score() == before_score + 100)
	var stars := ProgressionManager.total_stars()
	var reward := [0]
	AchievementManager.achievement_unlocked.connect(func(definition: AchievementDefinition) -> void: reward[0] += definition.reward_coins)
	# Structural upgrades are paid in stars; coins only move by achievement rewards.
	var before_purchase := EconomyManager.coins()
	var spendable := EconomyManager.stars()
	assert(LocationManager.upgrade(&"family_stall"))
	assert(EconomyManager.coins() == before_purchase + reward[0])
	assert(EconomyManager.stars() == spendable - int(LocationDefinition.find(&"family_stall").requirement(1).stars))
	assert(wallpaper.structural_state == 1 and ProgressionManager.total_stars() == stars)
	assert(AchievementManager.state("first_renovation").unlocked)
	assert(not LocationManager.upgrade(&"family_stall"))
	var structural := wallpaper.structural_state
	var money := EconomyManager.coins()
	var preview: Dictionary = {"PLANT_1":"hibiscus"}
	wallpaper.apply_environment(&"family_stall",preview)
	assert(not LocationManager.owned("hibiscus") and LocationManager.equipped(&"family_stall").is_empty() and EconomyManager.coins() == money)
	wallpaper.apply_environment(&"family_stall")
	spendable = EconomyManager.stars()
	var decor_cost := DecorDefinition.find("hibiscus").cost
	assert(LocationManager.buy("hibiscus"))
	assert(EconomyManager.coins() == money and EconomyManager.stars() == spendable - decor_cost)
	assert(LocationManager.buy("hibiscus") and EconomyManager.stars() == spendable - decor_cost) # Owned decor is never charged twice.
	assert(LocationManager.equip(&"family_stall","hibiscus"))
	assert(wallpaper._decor.get("PLANT_1") == "hibiscus" and wallpaper.structural_state == structural)
	LocationManager.unequip(&"family_stall","PLANT_1")
	assert(wallpaper._decor.is_empty() and wallpaper.structural_state == structural)
	assert(LocationManager.equip(&"family_stall","hibiscus"))
	for id in range(11,31):
		ProgressionManager.record_win(id,3,0,1000) # Enough stars for both remaining upgrades.
	assert(LocationManager.upgrade(&"family_stall") and LocationManager.upgrade(&"family_stall"))
	assert(wallpaper.structural_state == 3)
	money = EconomyManager.coins()
	assert(not LocationManager.upgrade(&"family_stall") and EconomyManager.coins() == money)
	assert(not LocationManager.upgrade(&"bazaar_ramadan") and not LocationManager.equip(&"bazaar_ramadan","hibiscus"))
	assert(SaveManager.save_game())
	SaveManager.load_game()
	assert(LocationManager.structural_level(&"family_stall") == 3 and LocationManager.equipped(&"family_stall").PLANT_1 == "hibiscus")
	var legacy := SaveManager._normalize({"version":3,"coins":777,"gerai":{"level":6},"levels":{"10":{"stars":1},"20":{"stars":2}}})
	assert(legacy.coins == 777 and legacy.gerai.level == 6 and legacy.structural_upgrades.family_stall == 2)
	var invalid := SaveManager._normalize({"version":5,"structural_upgrades":{"family_stall":99},"owned_decor":["hibiscus","fake"],"location_decor":{"family_stall":{"PLANT_1":"fake","LIGHTING_1":"hibiscus"}}})
	assert(invalid.structural_upgrades.family_stall == 3 and invalid.owned_decor == ["hibiscus"] and invalid.location_decor.family_stall.is_empty())
	var shop := GeraiScreen.new()
	add_child(shop)
	await get_tree().process_frame
	assert(shop._preview.structural_state == wallpaper.structural_state)
	# Browsing the design list and previewing a choice must never touch the save.
	var snapshot := JSON.stringify(SaveManager.data)
	shop._show_design()
	assert(shop._panel != null and is_instance_valid(shop._panel))
	for task in shop._tasks():
		if task.kind == RenovationTaskDefinition.Kind.DECOR and task.available() and task.choices().size() > 1:
			shop._open_choices(task)
			shop._select_choice(task.choices()[1])
			break
	assert(JSON.stringify(SaveManager.data) == snapshot)
	shop._close_panel()
	shop._location = &"bazaar_ramadan"
	shop._refresh()
	# Bazaar (stage 181) has no StallDefinition yet, so it previews with Family art; it must stay locked.
	assert(shop._design_button.disabled and not LocationManager.stall_unlocked(&"bazaar_ramadan"))
	shop.free()
	wallpaper.free()
	SaveManager.reset()
	assert(LocationManager.structural_level(&"family_stall") == 0 and LocationManager.equipped(&"family_stall").is_empty())
	print("PASS stall A-H: milestone/star gates, shared wallpaper, decor preview/buy/equip, no double charge, migration, future Bazaar, score total and save/reset")
	get_tree().quit(0)
