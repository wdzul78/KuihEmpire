extends Node

func _ready() -> void:
	SaveManager.data["recipes"] = []
	SaveManager.data["kuih_seen"] = ["onde_onde"]
	PowerupRecipes.sync_seen_kuih()
	assert(ProgressionManager.is_recipe_unlocked(KuihLibrary.all()[0].recipe_id))
	for entry in PowerupRecipes.ENTRIES:
		PowerupRecipes.introduce(int(entry[0]))
		PowerupRecipes.introduce(int(entry[0]))
	assert(ProgressionManager.unlocked_recipes().size() == 6)
	var book := RecipeBookScreen.new()
	add_child(book)
	await get_tree().process_frame
	book._page = ceili(float(KuihLibrary.count()) / book.PER_SPREAD)
	book.refresh()
	assert(book._grid.get_child_count() > 0)
	print("Recipe discovery: PASS (seen kuih, five power-ups, no duplicates, book pages)")
	get_tree().quit()
