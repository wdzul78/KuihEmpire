extends Node

signal changed()
signal recipe_discovered(recipe_id: StringName)
signal reward_claimed(claim_id: String)
var _transaction_busy := false

func is_recipe_discovered(id: StringName) -> bool:
	return String(id) in SaveManager.data.get("discovered_recipe_ids", [])

func get_discovered_count() -> int:
	var count := 0
	for recipe in RecipeCatalog.all():
		if is_recipe_discovered(recipe.id):
			count += 1
	return count

func get_total_recipe_count() -> int:
	return RecipeCatalog.all().size()

func get_collection_progress(id: StringName) -> Dictionary:
	var entry := RecipeCatalog.collection(id)
	if entry == null:
		return {"discovered": 0, "total": 0, "complete": false, "claimed": false}
	var count := 0
	for recipe_id in entry.recipe_ids:
		if is_recipe_discovered(StringName(recipe_id)):
			count += 1
	return {"discovered": count, "total": entry.recipe_ids.size(), "complete": count == entry.recipe_ids.size() and count > 0, "claimed": String(id) in SaveManager.data.get("claimed_collection_rewards", [])}

func discover_recipe(id: StringName, source: String = "stage", completed_stage: int = 0) -> Dictionary:
	var recipe := RecipeCatalog.find(id)
	if recipe == null:
		return {"ok": false, "error": "unknown_recipe"}
	if _transaction_busy:
		return {"ok": false, "error": "busy"}
	if is_recipe_discovered(id):
		return {"ok": true, "newly_discovered": false}
	# Future event code must provide its own eligibility gate before using event.
	if source == "stage":
		if not LevelLibrary.has_level(completed_stage) or ProgressionManager.stars_for(completed_stage) <= 0 or LevelLibrary.get_level(completed_stage).recipe_unlock_id != id:
			return {"ok": false, "error": "stage_not_eligible"}
	elif source != "event":
		return {"ok": false, "error": "invalid_source"}
	var reward := RecipeCatalog.reward(recipe.reward_id)
	if reward.is_empty():
		return {"ok": false, "error": "missing_reward"}
	var before := SaveManager.data.duplicate(true)
	SaveManager.data["discovered_recipe_ids"].append(String(id))
	SaveManager.data["recipe_discovery_count"] = SaveManager.data["discovered_recipe_ids"].size()
	SaveManager.data["claimed_recipe_discovery_rewards"].append(String(id))
	SaveManager.data["recipe_discovery_records"][String(id)] = {"source": source, "stage": completed_stage, "coins": int(reward.get("coins", 0))}
	SaveManager.data["pending_recipe_presentations"].append(String(id))
	_apply_reward(reward)
	if not _commit(before):
		return {"ok": false, "error": "save_failed"}
	recipe_discovered.emit(id)
	return {"ok": true, "newly_discovered": true, "reward": reward}

## A kuih the player has met is in the book from then on, so no later stage
## announces it as new. Silent: the introduction card is the announcement.
func record_introduced(id: StringName) -> void:
	if _transaction_busy or RecipeCatalog.find(id) == null or is_recipe_discovered(id):
		return
	var before := SaveManager.data.duplicate(true)
	SaveManager.data["discovered_recipe_ids"].append(String(id))
	SaveManager.data["recipe_discovery_count"] = SaveManager.data["discovered_recipe_ids"].size()
	SaveManager.data["claimed_recipe_discovery_rewards"].append(String(id))
	SaveManager.data["recipe_discovery_records"][String(id)] = {"source": "introduction", "stage": 0, "coins": 0}
	if _commit(before):
		recipe_discovered.emit(id)

func claim_milestone_reward(id: String) -> Dictionary:
	RecipeCatalog.all()
	for milestone in RecipeCatalog.milestones:
		if str(milestone.id) == id:
			if get_discovered_count() < int(milestone.threshold):
				return {"ok": false, "error": "not_eligible"}
			return _claim("claimed_recipe_milestone_rewards", id, str(milestone.reward_id))
	return {"ok": false, "error": "unknown_milestone"}

func claim_collection_reward(id: StringName) -> Dictionary:
	var entry := RecipeCatalog.collection(id)
	if entry == null or not get_collection_progress(id).complete:
		return {"ok": false, "error": "not_eligible"}
	return _claim("claimed_collection_rewards", String(id), entry.completion_reward_id)

func _claim(field: String, id: String, reward_id: String) -> Dictionary:
	if _transaction_busy:
		return {"ok": false, "error": "busy"}
	if id in SaveManager.data[field]:
		return {"ok": false, "error": "already_claimed"}
	var reward := RecipeCatalog.reward(reward_id)
	if reward.is_empty():
		return {"ok": false, "error": "missing_reward"}
	var before := SaveManager.data.duplicate(true)
	SaveManager.data[field].append(id)
	_apply_reward(reward)
	if not _commit(before):
		return {"ok": false, "error": "save_failed"}
	reward_claimed.emit(id)
	return {"ok": true, "reward": reward}

func _apply_reward(reward: Dictionary) -> void:
	SaveManager.data["coins"] += int(reward.get("coins", 0))
	SaveManager.data["recipe_star_credits"] += int(reward.get("renovation_stars", 0))
	for id in reward.get("boosters", {}):
		SaveManager.data["boosters"][id] = int(SaveManager.data["boosters"].get(id, 0)) + int(reward["boosters"][id])

func _commit(before: Dictionary) -> bool:
	_transaction_busy = true
	if not SaveManager.save_game():
		SaveManager.data = before
		_transaction_busy = false
		return false
	# Consumers only observe successfully persisted grants.
	EconomyManager.coins_changed.emit(EconomyManager.coins())
	EconomyManager.stars_changed.emit(EconomyManager.stars())
	EconomyManager.boosters_changed.emit()
	changed.emit()
	_transaction_busy = false
	return true

func acknowledge(id: StringName) -> bool:
	if _transaction_busy:
		return false
	var before := SaveManager.data.duplicate(true)
	SaveManager.data["pending_recipe_presentations"].erase(String(id))
	return _commit(before)

## Normalizes and migrates cultural state independently of legacy board aliases.
## Called from SaveManager; contains no runtime grants or signals.
static func normalize(loaded: Dictionary, clean: Dictionary) -> void:
	var discovered: Array = SaveManager._strings(loaded.get("discovered_recipe_ids"))
	var claims: Array = SaveManager._strings(loaded.get("claimed_recipe_discovery_rewards"))
	var records: Dictionary = {}
	var raw_records: Variant = loaded.get("recipe_discovery_records", {})
	if raw_records is Dictionary:
		for id in raw_records:
			if id is String and raw_records[id] is Dictionary:
				var row: Dictionary = raw_records[id]
				records[id] = {"source": str(row.get("source", "import")), "stage": SaveManager._number(row.get("stage"), 0), "coins": SaveManager._number(row.get("coins"), 0)}
	if loaded.get("recipe_book_schema", 0) != 1:
		var legacy: Array = SaveManager._strings(loaded.get("recipes"))
		legacy.append_array(SaveManager._strings(loaded.get("kuih_seen")))
		for recipe in RecipeCatalog.all():
			var stage_record: Dictionary = clean["levels"].get(str(recipe.discovery_stage), {})
			if String(recipe.id) in legacy or int(stage_record.get("stars", 0)) > 0:
				if not discovered.has(String(recipe.id)):
					discovered.append(String(recipe.id))
				records[String(recipe.id)] = {"source": "migration", "stage": 0, "coins": 0}
	# Saves from before introductions fed the book: kuih already met are owned.
	for id in SaveManager._strings(loaded.get("kuih_seen")):
		if not discovered.has(id) and RecipeCatalog.find(StringName(id)) != null:
			discovered.append(id)
			records[id] = {"source": "migration", "stage": 0, "coins": 0}
	# A malformed/partial claim ledger never makes an owned recipe payable again.
	for id in discovered:
		if not claims.has(id):
			claims.append(id)
	clean["recipe_book_schema"] = 1
	clean["discovered_recipe_ids"] = discovered
	clean["recipe_discovery_count"] = discovered.size()
	clean["recipe_discovery_records"] = records
	clean["claimed_recipe_discovery_rewards"] = claims
	clean["claimed_recipe_milestone_rewards"] = SaveManager._strings(loaded.get("claimed_recipe_milestone_rewards"))
	clean["claimed_collection_rewards"] = SaveManager._strings(loaded.get("claimed_collection_rewards"))
	clean["recipe_star_credits"] = SaveManager._number(loaded.get("recipe_star_credits"), 0)
	var pending: Array = []
	for id in SaveManager._strings(loaded.get("pending_recipe_presentations")):
		if id in discovered and RecipeCatalog.find(StringName(id)) != null:
			pending.append(id)
	clean["pending_recipe_presentations"] = pending
