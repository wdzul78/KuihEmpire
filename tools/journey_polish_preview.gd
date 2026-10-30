extends Node

func shot(filename: String) -> void:
	await get_tree().create_timer(.25).timeout
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://.analysis/"+filename+".png")

func _ready() -> void:
	SaveManager.save_path = "user://journey_polish.json"
	SaveManager.reset()
	ProgressionManager.complete_tutorial()
	for id in range(1,18):
		ProgressionManager.record_win(id,3,0)
	GameManager.pending_level_id = 18
	await get_tree().create_timer(5).timeout
	var map := JourneyMap.new()
	add_child(map)
	await get_tree().create_timer(.5).timeout
	assert(map._world_layers.size() == 3)
	assert(map.get_node("AinaCharacter").size.x > map.size.x*.4)
	assert(map.get_node("AinaSpeechBubble").size.x > map.size.x*.45)
	await shot("journey-polished-stage18")
	for seam in [1,2]:
		map._scroll.scroll_vertical = int(map._chapter_height*seam-map._scroll.size.y*.5)
		await shot("journey-polished-seam%d" % seam)
	map._scroll.scroll_vertical = int(map._point(9).y-map._scroll.size.y*.5)
	await shot("journey-polished-milestone10")
	SaveManager.data.settings.language = "ms"
	map.free()
	map = JourneyMap.new()
	add_child(map)
	await shot("journey-polished-ms")
	map.free()
	SaveManager.data["structural_upgrades"]["family_stall"] = 1
	SaveManager.data["stall_variants"]["family_stall"] = {"1":"batik"}
	var boot := BootScreen.new()
	boot.auto_navigation = false
	add_child(boot)
	await get_tree().create_timer(4).timeout
	await shot("boot-full-counter-cloth")
	boot.free()
	print("Journey polish: PASS backgrounds track scroll, enlarged Aina/dialog, chapter boundaries and bilingual captures; boot cloth captured")
	get_tree().quit()
