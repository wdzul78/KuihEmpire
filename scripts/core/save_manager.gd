extends Node

## Local save system (autoload: `SaveManager`).
##
## MVP is local-only by design (Master Plan section 59). Everything lives in one
## JSON blob at `user://kuih_empire_save.json`, written lazily and debounced so
## progress is never lost after a level.

const DEFAULT_SAVE_PATH := "user://kuih_empire_save.json"
const SAVE_VERSION := 5
const AUTOSAVE_DELAY := 1.5

## Tests and tools redirect this so they never touch a real player's save.
static var save_path: String = DEFAULT_SAVE_PATH

const DEFAULT_BOOSTERS := {
	"spatula": 3,
	"tray": 2,
	"shuffle": 3,
	"gift": 1,
	"extra_moves": 2,
}

const DEFAULT_SETTINGS := {
	"sfx": true,
	"music": true,
	"haptics": true,
	"show_hints": true,
	"language": "en",
}

var data: Dictionary = {}
var _dirty: bool = false
var _timer: SceneTreeTimer = null


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	load_game()


func _default_data() -> Dictionary:
	return {
		"version": SAVE_VERSION,
		"language_policy": 2,
		"profile": {"name": "Player", "avatar": "aina", "player_id": Crypto.new().generate_random_bytes(16).hex_encode(), "title_id": "Kuih Maker"},
		"achievements": {},
		"owned_decor": [],
		"structural_upgrades": {},
		"location_decor": {},
		"coins": 250,
		"diamonds": 0,
		"hearts": {"current_hearts": 5, "max_hearts": 5, "last_heart_refill_timestamp": 0, "free_play_end_timestamp": 0, "win_streak": 0, "rewarded_heart_ads_used_today": 0, "rewarded_heart_ads_reset_date": "", "milestones": [], "hearts_spent": 0, "coins_spent": 0},
		"boosters": DEFAULT_BOOSTERS.duplicate(true),
		"levels": {},            # Stage records; legacy stars and moves preserved.
		"chapters": ["prologue"], # unlocked chapter ids
		"recipes": [],           # unlocked recipe ids
		"mastery": {},           # recipe id -> collected count
		"gerai": {"level": 1, "cosmetics": []},
		"story_seen": [],
		"story_read": [],
		"tutorial_index": 0,
		"tutorial_done": false,
		"tutorial_rewarded": [],
		"kuih_seen": [],
		"onboarding": {"gift_claimed": false, "shop_intro_done": false, "restored": false},
		"special_unlocks": {"hantar": false},
		"settings": DEFAULT_SETTINGS.duplicate(true),
		"stats": {"levels_played": 0, "levels_won": 0, "moves_played": 0, "orders_served": 0, "specials_used": 0, "special_combos": 0, "unassisted_wins": 0, "achievement_win_streak": 0, "best_win_streak": 0},
	}


func load_game() -> void:
	_dirty = false
	var loaded: Variant = _read_save(save_path)
	if loaded == null:
		loaded = _read_save(save_path + ".bak")
		if loaded != null:
			push_warning("SaveManager: recovered the last good backup.")
			mark_dirty()
		elif FileAccess.file_exists(save_path):
			push_warning("SaveManager: invalid save and no usable backup; using defaults.")
	data = _normalize(loaded if loaded is Dictionary else {})
	if is_instance_valid(get_node_or_null("/root/LocationManager")):
		get_node("/root/LocationManager").reconcile()


func save_game() -> bool:
	_dirty = true
	# Never overwrite the good backup with a truncated/corrupt primary file.
	var previous: Variant = _read_save(save_path)
	if previous is Dictionary:
		if not _write_atomic(_normalize(previous), save_path + ".bak"):
			return false
	if not _write_atomic(data, save_path):
		return false
	_dirty = false
	return true


func _read_save(path: String) -> Variant:
	if not FileAccess.file_exists(path):
		return null
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return null
	var parser := JSON.new()
	var error := parser.parse(file.get_as_text())
	file.close()
	if error != OK:
		return null
	var parsed: Variant = parser.data
	return parsed if parsed is Dictionary else null


## Complete the temporary file in the same directory before replacing a save.
func _write_atomic(payload: Dictionary, path: String) -> bool:
	var temporary := path + ".tmp"
	var file := FileAccess.open(temporary, FileAccess.WRITE)
	if file == null:
		push_warning("SaveManager: could not open temporary save file.")
		return false
	file.store_string(JSON.stringify(payload, "  "))
	file.flush()
	var error := file.get_error()
	file.close()
	if error != OK:
		push_warning("SaveManager: save write failed; keeping previous save.")
		return false
	var renamed := DirAccess.rename_absolute(
		ProjectSettings.globalize_path(temporary), ProjectSettings.globalize_path(path)
	)
	if renamed != OK:
		push_warning("SaveManager: could not replace save; keeping previous save.")
		return false
	return true


func _number(value: Variant, fallback: int, maximum: int = 2147483647) -> int:
	if typeof(value) not in [TYPE_INT, TYPE_FLOAT]:
		return fallback
	if not is_finite(float(value)):
		return fallback
	return int(clampf(float(value), 0.0, float(maximum)))


func _strings(value: Variant, fallback: Array = []) -> Array:
	if not value is Array:
		return fallback.duplicate()
	var result: Array = []
	for entry in value:
		if entry is String and not entry.is_empty() and not result.has(entry):
			result.append(entry)
	return result


## JSON containers and every value consumed by progression are type checked.
## Missing fields retain defaults, so older/partial saves stay compatible.
func _normalize(loaded: Dictionary) -> Dictionary:
	var clean := _default_data()
	clean["kuih_seen"] = _strings(loaded.get("kuih_seen"))
	var onboarding: Variant = loaded.get("onboarding")
	if onboarding is Dictionary:
		for field in clean["onboarding"]:
			clean["onboarding"][field] = onboarding.get(field) is bool and onboarding[field]
	elif loaded.get("tutorial_done") is bool and loaded["tutorial_done"]:
		clean["onboarding"]["gift_claimed"] = true
		clean["onboarding"]["shop_intro_done"] = true
	var profile: Variant = loaded.get("profile")
	if profile is Dictionary and AvatarLibrary.valid(profile.get("avatar")):
		clean["profile"]["avatar"] = profile["avatar"]
	if profile is Dictionary and profile.get("name") is String:
		var player_name: String = profile["name"].strip_edges().left(24)
		if not player_name.is_empty():
			clean["profile"]["name"] = player_name
	if profile is Dictionary:
		for field in ["player_id", "title_id"]:
			if profile.get(field) is String and not profile[field].strip_edges().is_empty():
				clean["profile"][field] = profile[field].strip_edges().left(64)
	var achievements: Variant = loaded.get("achievements")
	if achievements is Dictionary:
		for definition in AchievementDefinition.all():
			var record: Variant = achievements.get(definition.id)
			if record is Dictionary:
				clean["achievements"][definition.id] = {
					"progress": _number(record.get("progress"), 0, definition.target),
					"unlocked": record.get("unlocked", false) == true,
					"reward_claimed": record.get("reward_claimed", false) == true,
					"unlocked_at": _number(record.get("unlocked_at"), 0),
				}
	clean["coins"] = _number(loaded.get("coins"), clean["coins"])
	clean["diamonds"] = _number(loaded.get("diamonds"), 0)
	var hearts: Variant = loaded.get("hearts")
	if hearts is Dictionary:
		for field in ["current_hearts", "last_heart_refill_timestamp", "free_play_end_timestamp", "win_streak", "rewarded_heart_ads_used_today", "hearts_spent", "coins_spent"]:
			clean["hearts"][field] = _number(hearts.get(field), clean["hearts"][field])
		clean["hearts"]["current_hearts"] = mini(5, clean["hearts"]["current_hearts"])
		clean["hearts"]["milestones"] = _strings(hearts.get("milestones"))
		if hearts.get("rewarded_heart_ads_reset_date") is String:
			clean["hearts"]["rewarded_heart_ads_reset_date"] = hearts["rewarded_heart_ads_reset_date"]
	var special_unlocks: Variant = loaded.get("special_unlocks")
	if special_unlocks is Dictionary:
		clean["special_unlocks"]["hantar"] = special_unlocks.get("hantar", false) == true
	clean["tutorial_index"] = _number(loaded.get("tutorial_index"), 0, TutorialLibrary.count())
	if loaded.get("tutorial_done") is bool:
		clean["tutorial_done"] = loaded["tutorial_done"]
	clean["tutorial_rewarded"] = _strings(loaded.get("tutorial_rewarded"))
	if not loaded.has("tutorial_rewarded"):
		# Preserve rewards already earned in the historical lesson order.
		for lesson in [1, 2, 3, 4, 5, 7, 8, 9]:
			if clean["tutorial_done"] or lesson < int(clean["tutorial_index"]):
				clean["tutorial_rewarded"].append(str(lesson))
	for key in ["boosters", "stats", "settings"]:
		var section: Variant = loaded.get(key)
		if not section is Dictionary:
			continue
		for name in section:
			if not name is String:
				continue
			if key == "settings":
				if name == "language" and section[name] in ["ms", "en"]:
					clean[key][name] = section[name]
				elif name != "language" and section[name] is bool:
					clean[key][name] = section[name]
			elif clean[key].has(name):
				clean[key][name] = _number(section[name], clean[key][name])
	# Older MVP saves inherited Malay automatically. Adopt English once for
	# this build, then preserve future explicit language selections.
	if loaded.get("language_policy", 0) != 2:
		clean["settings"]["language"] = "en"
	for key in ["chapters", "recipes", "story_seen", "story_read"]:
		clean[key] = _strings(loaded.get(key), clean[key])
	if not clean["chapters"].has("prologue"):
		clean["chapters"].push_front("prologue")
	var gerai: Variant = loaded.get("gerai")
	if gerai is Dictionary:
		clean["gerai"]["level"] = maxi(1, _number(gerai.get("level"), 1))
		clean["gerai"]["cosmetics"] = _strings(gerai.get("cosmetics"))
	var levels: Variant = loaded.get("levels")
	if levels is Dictionary:
		for key in levels:
			if not key is String or not key.is_valid_int():
				continue
			var id := int(key)
			var record: Variant = levels[key]
			if not LevelLibrary.has_level(id) or not record is Dictionary:
				continue
			clean["levels"][str(id)] = {
				"stars": _number(record.get("stars"), 0, 3),
				"best_moves_left": _number(record.get("best_moves_left"), 0),
				"best_score": _number(record.get("best_score"), 0),
				"completed": _number(record.get("stars"), 0, 3) > 0 or record.get("completed", false) == true,
				"first_clear_claimed": record.get("first_clear_claimed", _number(record.get("stars"), 0, 3) > 0 or record.get("completed", false) == true) == true,
			}
	var upgrades: Variant = loaded.get("structural_upgrades")
	for location in LocationDefinition.all():
		var bought := 0
		if upgrades is Dictionary:
			bought = _number(upgrades.get(String(location.id)), 0, 3)
		elif _number(loaded.get("version"), 0) < 5:
			# Preserve milestone visuals already earned before paid structural upgrades.
			for state in range(1, 4):
				var stage: int = location.requirement(state).stage
				if clean["levels"].get(str(stage), {}).get("stars", 0) > 0:
					bought = state
		clean["structural_upgrades"][String(location.id)] = bought
	var owned: Array = _strings(loaded.get("owned_decor"))
	for item in DecorDefinition.all():
		if owned.has(item.id):
			clean["owned_decor"].append(item.id)
	var equipped: Variant = loaded.get("location_decor")
	if equipped is Dictionary:
		for location in LocationDefinition.all():
			var slots: Variant = equipped.get(String(location.id))
			if not slots is Dictionary:
				continue
			var valid: Dictionary = {}
			for slot in slots:
				if slots[slot] is String:
					var item := DecorDefinition.find(slots[slot])
					if item != null and item.slot == slot and location.decor_slots.has(slot) and clean["owned_decor"].has(item.id):
						valid[slot] = item.id
			clean["location_decor"][String(location.id)] = valid
	var mastery: Variant = loaded.get("mastery")
	if mastery is Dictionary:
		for key in mastery:
			if key is String and not key.is_empty():
				clean["mastery"][key] = _number(mastery[key], 0)
	# Preserve progression when the approved normal-food set changes.
	var recipes: Array = clean["recipes"]
	var counts: Dictionary = clean["mastery"]
	var replacements := {"seri_muka": "ang_ku_kueh", "lapis_pandan": "ang_ku_kueh", "vadai": "keria"}
	for old_id in replacements:
		var new_id: String = replacements[old_id]
		if recipes.has(old_id):
			recipes.erase(old_id)
			if not recipes.has(new_id):
				recipes.append(new_id)
		if counts.has(old_id):
			counts[new_id] = maxi(int(counts.get(new_id, 0)), int(counts[old_id]))
			counts.erase(old_id)
	return clean


## Marks the save dirty and flushes shortly after, so a burst of star awards
## during the result screen costs one write instead of five.
func mark_dirty() -> void:
	_dirty = true
	if _timer != null and _timer.time_left > 0.0:
		return
	_timer = get_tree().create_timer(AUTOSAVE_DELAY)
	_timer.timeout.connect(_flush)


func _flush() -> void:
	if _dirty:
		save_game()


func _notification(what: int) -> void:
	if what in [NOTIFICATION_WM_CLOSE_REQUEST, NOTIFICATION_PREDELETE, NOTIFICATION_APPLICATION_PAUSED]:
		_flush()


func get_setting(key: String, fallback: Variant = null) -> Variant:
	return (data.get("settings", {}) as Dictionary).get(key, fallback)


func set_setting(key: String, value: Variant) -> void:
	var settings: Dictionary = data.get("settings", {})
	settings[key] = value
	data["settings"] = settings
	mark_dirty()


## Wipes the save back to a fresh game.
func reset() -> void:
	data = _default_data()
	if is_instance_valid(get_node_or_null("/root/LocationManager")):
		get_node("/root/LocationManager").reconcile()
	if save_game():
		# Reset is explicit: recovery must never resurrect the erased progress.
		if not _write_atomic(data, save_path + ".bak"):
			_dirty = true
