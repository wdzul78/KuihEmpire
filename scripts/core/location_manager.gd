extends Node

signal location_state_changed(location_id: StringName)
signal stall_upgrade_unlocked(location_id: StringName, level: int)
signal stall_upgraded(location_id: StringName, level: int)
signal decor_equipped(location_id: StringName, slot: String, decor_id: String)
signal decor_unequipped(location_id: StringName, slot: String)
var _known: Dictionary = {}
var _available: Dictionary = {}

func _ready() -> void:
	for location in LocationDefinition.all():
		_known[location.id] = structural_level(location.id)
		_available[location.id] = available_level(location.id)
	ProgressionManager.stars_changed.connect(_progress_changed)

func structural_level(id: StringName) -> int:
	return clampi(int(SaveManager.data.get("structural_upgrades", {}).get(String(id), 0)), 0, 3)

func available_level(id: StringName) -> int:
	var location := LocationDefinition.find(id)
	var result := 0
	for level in range(1, 4):
		if ProgressionManager.stars_for(location.requirement(level).stage) > 0:
			result = level
	return result

func upgrade(id: StringName) -> bool:
	var current := structural_level(id)
	if not accessible(id) or current >= 3 or available_level(id) <= current:
		return false
	var location := LocationDefinition.find(id)
	var requirement := location.requirement(current + 1)
	if ProgressionManager.total_stars() < int(requirement.stars) or not EconomyManager.spend_coins(int(requirement.coins)):
		return false
	SaveManager.data["structural_upgrades"][String(id)] = current + 1
	SaveManager.data["gerai"]["level"] = maxi(ProgressionManager.gerai_level(), current + 2) if id == &"family_stall" else ProgressionManager.gerai_level()
	SaveManager.mark_dirty()
	_known[id] = current + 1
	ProgressionManager.gerai_upgraded.emit()
	location_state_changed.emit(id)
	stall_upgraded.emit(id, current + 1)
	return true

func completed_stages(id: StringName) -> int:
	var location := LocationDefinition.find(id)
	var count := 0
	for stage in range(location.stage_start, location.stage_end + 1):
		if ProgressionManager.stars_for(stage) > 0:
			count += 1
	return count

func accessible(id: StringName) -> bool:
	var location := LocationDefinition.find(id)
	return location.id == id and location.playable and (location.stage_start == 1 or ProgressionManager.stars_for(location.stage_start - 1) > 0)

func _progress_changed(_id: int, _stars: int) -> void:
	for location in LocationDefinition.all():
		var available := available_level(location.id)
		var previous := int(_available.get(location.id, 0))
		_available[location.id] = available
		if available > previous:
			stall_upgrade_unlocked.emit(location.id, available)
		location_state_changed.emit(location.id)

func reconcile() -> void:
	# Save reset/reload refreshes visuals, without replaying an upgrade ceremony.
	for location in LocationDefinition.all():
		_known[location.id] = structural_level(location.id)
		_available[location.id] = available_level(location.id)
		location_state_changed.emit(location.id)

func equipped(id: StringName) -> Dictionary:
	return SaveManager.data.get("location_decor", {}).get(String(id), {})

func owned(decor_id: String) -> bool:
	return SaveManager.data.get("owned_decor", []).has(decor_id)

func buy(decor_id: String) -> bool:
	var decor := DecorDefinition.find(decor_id)
	if decor == null:
		return false
	if owned(decor_id):
		return true
	if not EconomyManager.spend_coins(decor.cost):
		return false
	SaveManager.data["owned_decor"].append(decor_id)
	SaveManager.mark_dirty()
	return true

func equip(id: StringName, decor_id: String) -> bool:
	var decor := DecorDefinition.find(decor_id)
	if decor == null or not owned(decor_id) or not accessible(id) or not LocationDefinition.find(id).decor_slots.has(decor.slot):
		return false
	var all_decor: Dictionary = SaveManager.data["location_decor"]
	var slots: Dictionary = all_decor.get(String(id), {})
	slots[decor.slot] = decor_id
	all_decor[String(id)] = slots
	SaveManager.mark_dirty()
	decor_equipped.emit(id, decor.slot, decor_id)
	location_state_changed.emit(id)
	return true

func unequip(id: StringName, slot: String) -> void:
	var slots := equipped(id)
	if not slots.has(slot):
		return
	slots.erase(slot)
	SaveManager.mark_dirty()
	decor_unequipped.emit(id, slot)
	location_state_changed.emit(id)

func effective_background(location: LocationDefinition, level: int) -> String:
	if location.backgrounds.is_empty():
		if OS.has_feature("debug"):
			push_warning("Location art not authored: %s; using layered concept fallback" % location.id)
		return ""
	for index in range(mini(level, location.backgrounds.size() - 1), -1, -1):
		var path := location.backgrounds[index]
		if not path.is_empty() and ResourceLoader.exists(path):
			if index != level and location.backgrounds.size() > 1 and OS.has_feature("debug"):
				push_warning("Location art fallback: %s state %d -> %d" % [location.id, level, index])
			return path
	if OS.has_feature("debug"):
		push_warning("Location art missing: %s; using layered fallback" % location.id)
	return ""
