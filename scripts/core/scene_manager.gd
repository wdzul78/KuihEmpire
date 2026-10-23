extends CanvasLayer

## Scene flow with a warm fade (autoload: `SceneManager`).

const FADE_OUT := 0.22
const FADE_IN := 0.28

const BOOT := "res://scenes/boot/boot.tscn"
const WELCOME := "res://scenes/ui/onboarding_finish.tscn"
const HOME := "res://scenes/menu/home.tscn"
const ENDLESS := "res://scenes/game/endless_screen.tscn"
const LEVEL := "res://scenes/game/level_screen.tscn"
const STORY := "res://scenes/story/story_screen.tscn"
const JOURNEY := "res://scenes/world/journey_map.tscn"
const GERAI := "res://scenes/stall/gerai_screen.tscn"
const RECIPE_BOOK := "res://scenes/ui/recipe_book.tscn"
const ACHIEVEMENTS := "res://scenes/ui/achievements_screen.tscn"
const SETTINGS := "res://scenes/ui/settings_screen.tscn"

## Which storyline deck is queued for the next [method goto_story] call.
var story_group: StringName = &""
## Whether the story screen offers its Skip button.
var story_allow_skip: bool = true
## Where [signal story_finished] should send the player.
var story_next: String = HOME
## Tutorial stage (1-based) queued for the next [method goto_tutorial] call.
var story_next_tutorial: int = 0

signal story_finished()

var _veil: ColorRect
var _busy: bool = false
var _loading_box: VBoxContainer
var _loading_bar: ProgressBar
var _loading_caption: Label
var _warmed: Dictionary = {}

func warm_scene(path: String) -> void:
	if _warmed.has(path):
		return
	if ResourceLoader.load_threaded_get_status(path) == ResourceLoader.THREAD_LOAD_INVALID_RESOURCE:
		ResourceLoader.load_threaded_request(path,"PackedScene")

func warm_progress(path: String) -> float:
	if _warmed.has(path):
		return 1.0
	var progress: Array = []
	var status := ResourceLoader.load_threaded_get_status(path,progress)
	if status == ResourceLoader.THREAD_LOAD_LOADED:
		_warmed[path] = ResourceLoader.load_threaded_get(path)
		return 1.0
	return float(progress[0]) if not progress.is_empty() else 0.0


func _ready() -> void:
	layer = 128
	_veil = ColorRect.new()
	_veil.color = Color(0.98, 0.90, 0.78, 0.0)
	_veil.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_veil.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_veil)
	_loading_box = VBoxContainer.new()
	_loading_box.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	_loading_box.position = Vector2(-150,-25)
	_loading_box.size = Vector2(300,65)
	_veil.add_child(_loading_box)
	_loading_caption = Label.new()
	_loading_caption.text = "Loading…"
	_loading_caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_loading_caption.add_theme_color_override("font_color",Color("4a2c17"))
	_loading_box.add_child(_loading_caption)
	_loading_bar = ProgressBar.new()
	_loading_bar.custom_minimum_size = Vector2(300,14)
	_loading_bar.show_percentage = false
	_loading_box.add_child(_loading_bar)
	_loading_box.hide()
	process_mode = Node.PROCESS_MODE_ALWAYS


func goto(path: String, instant: bool = false) -> void:
	if _busy:
		return
	if not ResourceLoader.exists(path):
		push_error("SceneManager: missing scene %s" % path)
		return
	_busy = true
	warm_scene(path)
	if not instant:
		await fade_out()
	_loading_bar.value = 0
	_loading_caption.text = "Loading…"
	_loading_box.show()
	await get_tree().process_frame
	while not _warmed.has(path):
		_loading_bar.value = warm_progress(path)*100.0
		if ResourceLoader.load_threaded_get_status(path) == ResourceLoader.THREAD_LOAD_FAILED:
			push_error("SceneManager: loading failed %s" % path)
			_loading_box.hide()
			await fade_in()
			_busy = false
			return
		await get_tree().process_frame
	_loading_bar.value = 100
	_loading_caption.text = "Preparing…"
	await get_tree().process_frame
	get_tree().change_scene_to_packed(_warmed[path])
	if path == STORY and story_group == StoryLibrary.PROLOGUE:
		AudioManager.play_music(OpeningStory.SAD_MUSIC)
	else:
		AudioManager.play_music(AudioManager.GAMEPLAY_MUSIC if path in [LEVEL, ENDLESS] else AudioManager.MENU_MUSIC)
	AudioManager.set_music_ducked(false)
	# Let the new scene build before revealing it.
	await get_tree().process_frame
	await get_tree().process_frame
	_loading_box.hide()
	if not instant:
		await fade_in()
	_busy = false


func fade_out(duration: float = FADE_OUT) -> void:
	_veil.mouse_filter = Control.MOUSE_FILTER_STOP
	var tw := create_tween()
	tw.tween_property(_veil, "color:a", 1.0, duration)
	await tw.finished


func fade_in(duration: float = FADE_IN) -> void:
	var tw := create_tween()
	tw.tween_property(_veil, "color:a", 0.0, duration)
	await tw.finished
	_veil.mouse_filter = Control.MOUSE_FILTER_IGNORE


func fade_to_color(color: Color, duration: float) -> void:
	var tw := create_tween()
	tw.tween_property(_veil, "color", color, duration)
	await tw.finished


func fade_from_color(color: Color, duration: float) -> void:
	_veil.color = color
	var tw := create_tween()
	tw.tween_property(_veil, "color:a", 0.0, duration)
	await tw.finished
	_veil.color = Color(0.98, 0.90, 0.78, 0.0)
	_veil.mouse_filter = Control.MOUSE_FILTER_IGNORE


## Shows a storyline deck, then hands off to the next screen.
func goto_story(group_id: StringName, allow_skip: bool = true, next_scene: String = HOME) -> void:
	story_group = group_id
	story_allow_skip = allow_skip
	story_next = next_scene
	story_next_tutorial = 0
	manual = false
	await goto(STORY)


## Shows a storyline deck, then drops the player into a tutorial stage.
func goto_story_then_tutorial(group_id: StringName, tutorial_index: int, allow_skip: bool = true) -> void:
	story_group = group_id
	story_allow_skip = allow_skip
	story_next = LEVEL
	story_next_tutorial = tutorial_index
	manual = false
	await goto(STORY)


## Opens a deck purely to be read. [signal story_finished] is left to the caller.
func goto_story_manual(group_id: StringName) -> void:
	story_group = group_id
	story_allow_skip = true
	manual = true
	await goto(STORY)


func goto_tutorial(index: int) -> void:
	GameManager.pending_tutorial_index = index
	await goto(LEVEL)


## Called by [StoryScreen] when the player reaches the end of a deck.
## When [member manual] is set the screen does not navigate by itself and the
## caller decides what happens on [signal story_finished].
var manual: bool = false

func finish_story() -> void:
	if StoryLibrary.has_pages(story_group):
		ProgressionManager.mark_story_read(story_group)
	story_finished.emit()
	if manual:
		return
	var next := story_next
	var tutorial := story_next_tutorial
	story_group = &""
	story_next_tutorial = 0
	if next == LEVEL and tutorial > 0:
		await goto_tutorial(tutorial)
	elif ResourceLoader.exists(next):
		await goto(next)
	else:
		await goto(HOME)


## True when [param node] belongs to the scene that is currently running.
## Screens that navigate on their own use this so a test harness (or a preview
## in the editor) can never hijack the flow.
static func is_current(node: Node) -> bool:
	var tree := node.get_tree()
	if tree == null:
		return false
	var current := tree.current_scene
	if current == null:
		return false
	var walker: Node = node
	while walker != null:
		if walker == current:
			return true
		walker = walker.get_parent()
	return false
