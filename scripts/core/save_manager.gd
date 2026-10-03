extends Node

## Local save system (autoload: `SaveManager`).
##
## MVP is local-only by design (Master Plan section 59). Everything lives in one
## JSON blob at `user://kuih_empire_save.json`, written lazily and debounced so
## progress is never lost after a level.

const DEFAULT_SAVE_PATH := "user://kuih_empire_save.json"
const SAVE_VERSION := 1
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
		"coins": 250,
		"boosters": DEFAULT_BOOSTERS.duplicate(true),
		"levels": {},            # String level id -> { stars, best_moves_left }
		"chapters": ["prologue"], # unlocked chapter ids
		"recipes": [],           # unlocked recipe ids
		"mastery": {},           # recipe id -> collected count
		"gerai": {"level": 1, "cosmetics": []},
		"story_seen": [],
		"story_read": [],
		"tutorial_index": 0,
		"tutorial_done": false,
		"settings": DEFAULT_SETTINGS.duplicate(true),
		"stats": {"levels_played": 0, "levels_won": 0, "moves_played": 0},
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
	clean["coins"] = _number(loaded.get("coins"), clean["coins"])
	clean["tutorial_index"] = _number(loaded.get("tutorial_index"), 0, TutorialLibrary.count())
	if loaded.get("tutorial_done") is bool:
		clean["tutorial_done"] = loaded["tutorial_done"]
	for key in ["boosters", "stats", "settings"]:
		var section: Variant = loaded.get(key)
		if not section is Dictionary:
			continue
		for name in section:
			if not name is String:
				continue
			if key == "settings":
				if section[name] is bool:
					clean[key][name] = section[name]
			elif clean[key].has(name):
				clean[key][name] = _number(section[name], clean[key][name])
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
			}
	var mastery: Variant = loaded.get("mastery")
	if mastery is Dictionary:
		for key in mastery:
			if key is String and not key.is_empty():
				clean["mastery"][key] = _number(mastery[key], 0)
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
	if save_game():
		# Reset is explicit: recovery must never resurrect the erased progress.
		if not _write_atomic(data, save_path + ".bak"):
			_dirty = true
