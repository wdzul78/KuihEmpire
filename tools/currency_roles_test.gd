extends Node

func _ready() -> void:
	var original := SaveManager.data.duplicate(true)
	SaveManager.data = SaveManager._default_data()
	for stage in range(1, 11):
		SaveManager.data.levels[str(stage)] = {"stars": 3}
	SaveManager.data.coins = 2000
	assert(EconomyManager.stars() == 30)
	assert(LocationManager.buy("hibiscus"))
	assert(EconomyManager.stars() == 28 and EconomyManager.coins() == 2000)
	assert(LocationManager.buy("hibiscus") and EconomyManager.stars() == 28)
	assert(LocationManager.upgrade(&"family_stall"))
	assert(EconomyManager.stars() == 23 and ProgressionManager.total_stars() == 30)
	assert(ProgressionManager.stars_for(10) == 3)
	assert(not EconomyManager.spend_stars(24))
	assert(EconomyManager.stars() == 23)
	var normalized := SaveManager._normalize(SaveManager.data)
	assert(normalized.stars_spent == 7)
	SaveManager.data.stars_spent = 30
	assert(not LocationManager.buy("rattan_lamp"))
	assert(not LocationManager.owned("rattan_lamp"))
	assert(EconomyManager.spend_coins(EconomyManager.EXTRA_MOVES_COST))
	assert(EconomyManager.stars() == 0)
	# Achievement listeners may award coins on the first balance change.
	SaveManager.data.coins = 1100
	assert(EconomyManager.spend_coins(EconomyManager.EXTRA_MOVES_COST))
	assert(not EconomyManager.spend_coins(EconomyManager.EXTRA_MOVES_COST))
	var stall := GeraiScreen.new()
	add_child(stall)
	assert(stall._coins.text == "0")
	stall.free()
	var pause := PauseOverlay.new()
	pause.extra_coin_purchase = true
	pause.extra_available = true
	add_child(pause)
	assert(_has_caption(pause, "900 coins"))
	pause.free()
	SaveManager.data = original
	print("Currency roles: PASS (star purchases, preserved stage ratings, persistence, insufficient funds, coin moves)")
	get_tree().quit()

func _has_caption(node: Node, caption: String) -> bool:
	if node is Button and caption in node.text:
		return true
	for child in node.get_children():
		if _has_caption(child, caption):
			return true
	return false
