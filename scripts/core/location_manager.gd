extends Node

signal active_stall_changed(location_id: StringName)
signal location_state_changed(location_id: StringName)
signal stall_upgrade_unlocked(location_id: StringName, level: int)
signal stall_upgraded(location_id: StringName, level: int)
signal decor_equipped(location_id: StringName, slot: String, decor_id: String)
signal decor_unequipped(location_id: StringName, slot: String)
var _known: Dictionary = {}
var _available: Dictionary = {}
var _task_commit_busy := false

func decor_styles(id: StringName) -> Dictionary:
	return SaveManager.data.get("decor_styles", {}).get(String(id), {}).duplicate()

## Task UI confirms once: inventory, design and star debit share a save snapshot.
## Legacy entry points remain compatible for existing callers and saves.
func confirm_task(task: RenovationTaskDefinition, choice: String) -> Dictionary:
	if _task_commit_busy or not stall_unlocked(task.location_id):
		return {"ok": false, "error": "not_available"}
	var id := task.location_id
	var state := structural_level(id)
	if task.kind == RenovationTaskDefinition.Kind.STRUCTURE:
		if task.state_index != state + 1 or not task.available():
			return {"ok": false, "error": "stale_task"}
	elif task.kind == RenovationTaskDefinition.Kind.STYLE:
		if state <= 0 or task.state_index < 1 or task.state_index > state:
			return {"ok": false, "error": "stale_task"}
	else:
		var decor := DecorDefinition.find(task.decor_id)
		if not task.available():
			return {"ok": false, "error": "not_available"}
		if decor == null or not decor.suitable_for(id) or not LocationDefinition.find(id).decor_slots.has(decor.slot):
			return {"ok": false, "error": "invalid_decor"}
	if choice != "none" and not task.choices().has(choice):
		return {"ok": false, "error": "invalid_choice"}
	if choice == "none" and task.kind != RenovationTaskDefinition.Kind.DECOR:
		return {"ok": false, "error": "invalid_choice"}
	var price := 0 if choice == "none" else task.cost()
	if not EconomyManager.can_afford_stars(price):
		return {"ok": false, "error": "insufficient_stars"}
	var before := SaveManager.data.duplicate(true)
	_task_commit_busy = true
	SaveManager.data["stars_spent"] = int(SaveManager.data.get("stars_spent", 0)) + price
	if task.kind in [RenovationTaskDefinition.Kind.STRUCTURE, RenovationTaskDefinition.Kind.STYLE]:
		var choices: Dictionary = SaveManager.data["stall_variants"].get(String(id), {})
		choices[str(task.state_index)] = choice
		SaveManager.data["stall_variants"][String(id)] = choices
		if task.kind == RenovationTaskDefinition.Kind.STRUCTURE:
			SaveManager.data["structural_upgrades"][String(id)] = task.state_index
			if id == &"family_stall":
				SaveManager.data["gerai"]["level"] = maxi(ProgressionManager.gerai_level(), task.state_index + 1)
	else:
		var item := DecorDefinition.find(task.decor_id)
		var slots: Dictionary = equipped(id).duplicate()
		if choice == "none":
			slots.erase(item.slot)
		else:
			if not owned(item.id):
				SaveManager.data["owned_decor"].append(item.id)
			slots[item.slot] = item.id
			var styles: Dictionary = decor_styles(id)
			styles[item.slot] = choice
			SaveManager.data["decor_styles"][String(id)] = styles
		SaveManager.data["location_decor"][String(id)] = slots
	if task.kind != RenovationTaskDefinition.Kind.STYLE and choice != "none" and not SaveManager.data["renovation_tasks_completed"].has(task.id):
		SaveManager.data["renovation_tasks_completed"].append(task.id)
	if not SaveManager.save_game():
		SaveManager.data = before
		_task_commit_busy = false
		return {"ok": false, "error": "save_failed"}
	EconomyManager.stars_changed.emit(EconomyManager.stars())
	location_state_changed.emit(id)
	if task.kind == RenovationTaskDefinition.Kind.STRUCTURE:
		_known[id] = task.state_index
		ProgressionManager.gerai_upgraded.emit()
		stall_upgraded.emit(id, task.state_index)
	elif task.kind == RenovationTaskDefinition.Kind.DECOR:
		var item := DecorDefinition.find(task.decor_id)
		if choice == "none":
			decor_unequipped.emit(id, item.slot)
		else:
			decor_equipped.emit(id, item.slot, item.id)
	_task_commit_busy = false
	return {"ok": true, "spent_stars": price}

func active_stall_id() -> StringName:
	var id := StringName(SaveManager.data.get("active_stall_id", "family_stall"))
	return id if stall_unlocked(id) else &"family_stall"

func stall_unlocked(id: StringName) -> bool:
	var location := LocationDefinition.find(id)
	return location.id == id and (location.stage_start == 1 or ProgressionManager.stars_for(location.stage_start - 1) > 0)

func set_active_stall(id: StringName) -> bool:
	if not stall_unlocked(id):
		return false
	SaveManager.data["active_stall_id"] = String(id)
	SaveManager.mark_dirty()
	SaveManager.save_game()
	active_stall_changed.emit(id)
	return true

func variant_for(id: StringName, state: int = -1) -> String:
	var index := structural_level(id) if state < 0 else state
	return str(SaveManager.data.get("stall_variants", {}).get(String(id), {}).get(str(index), "classic"))

func select_variant(id: StringName, variant: String) -> bool:
	var index := structural_level(id)
	if not stall_unlocked(id) or not StallDefinition.find(id).state(index).variants.has(variant):
		return false
	var table: Dictionary = SaveManager.data.get("stall_variants", {})
	var choices: Dictionary = table.get(String(id), {})
	choices[str(index)] = variant
	table[String(id)] = choices
	SaveManager.data["stall_variants"] = table
	SaveManager.mark_dirty()
	SaveManager.save_game()
	location_state_changed.emit(id)
	return true

func stall_snapshot(id: StringName = &"") -> Dictionary:
	if id == &"":
		id = active_stall_id()
	var definition := StallDefinition.find(id)
	var completed := completed_stages(id)
	var state := structural_level(id)
	return {"id": id, "stage": mini(30, completed + 1), "milestone": mini(3, completed / 10), "visual_state": definition.state(state).id, "state_index": state, "variant": variant_for(id)}


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

func upgrade(id: StringName, variant: String = "classic") -> bool:
	var current := structural_level(id)
	if not stall_unlocked(id) or current >= 3 or available_level(id) <= current:
		return false
	var location := LocationDefinition.find(id)
	var requirement := location.requirement(current + 1)
	if not StallDefinition.find(id).state(current + 1).variants.has(variant):
		return false
	if not EconomyManager.spend_stars(int(requirement.stars)):
		return false
	SaveManager.data["structural_upgrades"][String(id)] = current + 1
	SaveManager.data["gerai"]["level"] = maxi(ProgressionManager.gerai_level(), current + 2) if id == &"family_stall" else ProgressionManager.gerai_level()
	var choices: Dictionary = SaveManager.data["stall_variants"].get(String(id), {})
	choices[str(current + 1)] = variant
	SaveManager.data["stall_variants"][String(id)] = choices
	SaveManager.mark_dirty()
	SaveManager.save_game()
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
	active_stall_changed.emit(active_stall_id())
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
	if not decor.prerequisite.is_empty() and not owned(decor.prerequisite):
		return false
	if not EconomyManager.spend_stars(decor.cost):
		return false
	SaveManager.data["owned_decor"].append(decor_id)
	SaveManager.mark_dirty()
	return true

func equip(id: StringName, decor_id: String) -> bool:
	var decor := DecorDefinition.find(decor_id)
	if decor == null or not decor.suitable_for(id) or not owned(decor_id) or not stall_unlocked(id) or not LocationDefinition.find(id).decor_slots.has(decor.slot):
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
