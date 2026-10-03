extends Node

## Coin and booster economy (autoload: `EconomyManager`).
##
## One currency only (coins) plus boosters - no gems, no premium tokens
## (Master Plan section 36).

signal coins_changed(amount: int)
signal boosters_changed()

enum Booster { SPATULA, TRAY, SHUFFLE, GIFT, EXTRA_MOVES }

const BOOSTER_IDS := {
	Booster.SPATULA: "spatula",
	Booster.TRAY: "tray",
	Booster.SHUFFLE: "shuffle",
	Booster.GIFT: "gift",
	Booster.EXTRA_MOVES: "extra_moves",
}

const BOOSTER_NAMES := {
	Booster.SPATULA: "Sudip",
	Booster.TRAY: "Dulang",
	Booster.SHUFFLE: "Shuffle",
	Booster.GIFT: "Tapau",
	Booster.EXTRA_MOVES: "+5 Moves",
}


func coins() -> int:
	return int(SaveManager.data.get("coins", 0))


func add_coins(amount: int) -> void:
	if amount == 0:
		return
	var value := maxi(0, coins() + amount)
	SaveManager.data["coins"] = value
	SaveManager.mark_dirty()
	coins_changed.emit(value)


func can_afford(amount: int) -> bool:
	return coins() >= amount


func spend_coins(amount: int) -> bool:
	if amount <= 0:
		return true
	if not can_afford(amount):
		return false
	add_coins(-amount)
	return true


func booster_id(booster: Booster) -> String:
	return BOOSTER_IDS.get(booster, "shuffle")


func booster_name(booster: Booster) -> String:
	return BOOSTER_NAMES.get(booster, "Booster")


func booster_count(booster: Booster) -> int:
	var table: Dictionary = SaveManager.data.get("boosters", {})
	return int(table.get(booster_id(booster), 0))


func has_booster(booster: Booster) -> bool:
	return booster_count(booster) > 0


func use_booster(booster: Booster) -> bool:
	if not has_booster(booster):
		return false
	var table: Dictionary = SaveManager.data.get("boosters", {})
	var id := booster_id(booster)
	table[id] = maxi(0, int(table.get(id, 0)) - 1)
	SaveManager.data["boosters"] = table
	SaveManager.mark_dirty()
	boosters_changed.emit()
	return true


func grant_booster(booster: Booster, amount: int = 1) -> void:
	var table: Dictionary = SaveManager.data.get("boosters", {})
	var id := booster_id(booster)
	table[id] = maxi(0, int(table.get(id, 0)) + amount)
	SaveManager.data["boosters"] = table
	SaveManager.mark_dirty()
	boosters_changed.emit()


## Free boosters handed out as level rewards so nobody is ever stuck.
func grant_starter_pack() -> void:
	grant_booster(Booster.SPATULA, 1)
	grant_booster(Booster.TRAY, 1)
	grant_booster(Booster.SHUFFLE, 1)


func booster_table() -> Dictionary:
	return SaveManager.data.get("boosters", {}).duplicate()
