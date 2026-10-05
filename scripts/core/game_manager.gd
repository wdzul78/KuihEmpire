extends Node

## Session hub (autoload: `GameManager`).
##
## Owns input map setup, the level currently being played, and the reward
## hand-off between the puzzle screen, the result screen and the meta screens.
## Keeps gameplay free of any monetization logic (Master Plan section 55).

signal level_finished(level_id: int, won: bool)

const INPUT_ACTIONS := {
	"restart_level": [KEY_R],
	"show_hint": [KEY_H],
	"go_back": [KEY_ESCAPE],
	"debug_board": [KEY_F1],
}

## Populated by the level screen when a stage is cleared.
var pending_level_id: int = 0
var pending_start_specials: Array[int] = []
var pending_stars: int = 0
var pending_moves_left: int = 0
var pending_score: int = 0
var pending_coins: int = 0
## Recipe / kuih ids revealed by the last cleared level, shown on the result screen.
var pending_unlocks: Array[StringName] = []
## > 0 loads a tutorial stage instead of a campaign stage.
var pending_tutorial_index: int = 0
var is_first_session: bool = true


func _ready() -> void:
	_register_actions()
	AudioManager.apply_settings(SaveManager.data.get("settings", {}))
	is_first_session = int(ProgressionManager.stats().get("levels_played", 0)) == 0
	process_mode = Node.PROCESS_MODE_ALWAYS


func _register_actions() -> void:
	for action in INPUT_ACTIONS:
		if not InputMap.has_action(action):
			InputMap.add_action(action)
		for key in INPUT_ACTIONS[action]:
			var event := InputEventKey.new()
			event.physical_keycode = key
			InputMap.action_add_event(action, event)


func play_level(level_id: int) -> void:
	if not LevelLibrary.has_level(level_id) or not ProgressionManager.is_level_unlocked(level_id):
		return
	pending_level_id = level_id
	pending_start_specials.clear()
	pending_tutorial_index = 0
	SceneManager.goto(SceneManager.JOURNEY)


func start_selected_stage() -> void:
	if ProgressionManager.needs_tutorial():
		play_next()
		return
	if not LevelLibrary.has_level(pending_level_id) or not ProgressionManager.is_level_unlocked(pending_level_id):
		return
	if not HeartManager.can_start_stage():
		HeartRefillDialog.open(get_tree().current_scene)
		return
	if SceneManager._busy:
		return
	for booster in pending_start_specials:
		if not EconomyManager.has_booster(booster):
			return
	pending_tutorial_index = 0
	SceneManager.goto(SceneManager.LEVEL)


## Plays a tutorial stage, showing the matching story deck first if it has one.
func play_tutorial(index: int) -> void:
	index = TutorialLibrary.resume_index(clampi(index, 1, TutorialLibrary.count()))
	pending_tutorial_index = index
	ProgressionManager.save_tutorial_index(index)
	SceneManager.goto(SceneManager.LEVEL)


## Where PLAY should send the player right now.
func next_play_target() -> Dictionary:
	if ProgressionManager.needs_tutorial():
		return {"tutorial": 9 if ProgressionManager.tutorial_done() and not ProgressionManager.delivery_unlocked() else maxi(1, ProgressionManager.tutorial_index())}
	if OnboardingProgress.pending():
		return {"welcome": true}
	return {"level": ProgressionManager.current_level()}


func play_next() -> void:
	var target := next_play_target()
	if target.has("tutorial"):
		play_tutorial(int(target["tutorial"]))
	elif target.has("welcome"):
		SceneManager.goto(SceneManager.WELCOME)
	else:
		play_level(int(target["level"]))


func go_home() -> void:
	pending_level_id = 0
	pending_start_specials.clear()
	pending_tutorial_index = 0
	pending_unlocks.clear()
	SceneManager.goto(SceneManager.HOME)


func go_journey() -> void:
	SceneManager.goto(SceneManager.JOURNEY)


func clear_pending() -> void:
	pending_unlocks.clear()
	pending_score = 0
	pending_coins = 0
	pending_stars = 0
	pending_moves_left = 0


## Called by the level screen once a level ends.
func report_result(won: bool) -> void:
	level_finished.emit(pending_level_id, won)
	if won:
		is_first_session = false


func setting(key: String, fallback: Variant = null) -> Variant:
	return SaveManager.get_setting(key, fallback)


func set_setting(key: String, value: Variant) -> void:
	SaveManager.set_setting(key, value)
	AudioManager.apply_settings(SaveManager.data.get("settings", {}))
