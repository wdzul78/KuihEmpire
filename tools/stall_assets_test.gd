extends Node

func _ready() -> void:
	var original := SaveManager.data.duplicate(true)
	SaveManager.save_path = "user://stall_assets_test.json"
	SaveManager.data = SaveManager._default_data()
	var checked := 0
	for location in LocationDefinition.all():
		var definition := StallDefinition.find(location.id)
		var previous := ""
		for index in range(4):
			var state := definition.state(index)
			for context in ["menu","gameplay","renovation","journey"]:
				var path := state.background_path(context)
				assert(ResourceLoader.exists(path), "Missing asset: " + path)
				checked += 1
			assert(state.menu_background != previous)
			previous = state.menu_background
			var scene := GeraiBackdrop.new()
			scene.size = Vector2(1080, 2400)
			add_child(scene)
			scene.debug_preview(location.id, index)
			assert(scene._authored_background and scene._background != null)
			assert(scene.texture_path == state.renovation_background)
			scene.free()
	SaveManager.data = original
	print("Generated stall assets: PASS (%d context slots, %d distinct state masters, authored rendering at tall viewport)" % [checked, checked / 4])
	get_tree().quit()
