class_name StoryScreen
extends Control

## Paged storyline screen (Master Plan section 48: Splash → Home → Journey Map).
##
## Shows a deck of [StoryPage]s: illustration panel, heading and a couple of
## short lines per page. Swipe or tap right to turn the page, tap left to go
## back, and finish with a single clear button into the game.

signal finished()

const PAGE_SWIPE := 60.0

var pages: Array[StoryPage] = []
var index: int = 0

var _backdrop: GeraiBackdrop
var _card: PanelContainer
var _speaker: CharacterIcon
var _heading: Label
var _body: Label
var _props_row: HBoxContainer
var _dots: HBoxContainer
var _next_button: Button
var _skip_button: Button
var _prev_hint: Label


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	UIKit.apply_root_theme(self)
	mouse_filter = Control.MOUSE_FILTER_STOP
	_build()
	# The screen owns no navigation of its own: SceneManager decides where the
	# deck leads. Without this the buttons emit into the void and the player is
	# stuck on the last page forever.
	finished.connect(SceneManager.finish_story)
	_start_deck()


## Waits one frame so the card has a real size before the entry tween measures it.
func _start_deck() -> void:
	await get_tree().process_frame
	if not is_inside_tree():
		return
	var group: StringName = SceneManager.story_group
	if not StoryLibrary.has_pages(group):
		# Opened with nothing queued (scene preview, a stale group id). Stay inert
		# rather than firing `finished`: finishing here would navigate the whole
		# game away from a screen nobody asked to open.
		visible = false
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		return
	play(StoryLibrary.pages_for(group), SceneManager.story_allow_skip)


func _build() -> void:
	_backdrop = GeraiBackdrop.new()
	_backdrop.show_counter = false
	_backdrop.simple = true
	_backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_backdrop)

	var skip_row := UIKit.hbox(0)
	skip_row.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	skip_row.offset_top = 24
	skip_row.offset_right = -24
	add_child(skip_row)
	_skip_button = UIKit.button("Skip", 26, Palette.CREAM_DEEP)
	_skip_button.custom_minimum_size = Vector2(180, 74)
	_skip_button.pressed.connect(_on_skip)
	skip_row.add_child(_skip_button)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	_card = PanelContainer.new()
	_card.add_theme_stylebox_override("panel", UIKit.cream_box())
	_card.custom_minimum_size = Vector2(940, 0)
	center.add_child(_card)

	var stack := UIKit.vbox(12)
	_card.add_child(stack)

	_speaker = CharacterIcon.new()
	_speaker.cast = CharacterIcon.Cast.AINA
	_speaker.custom_minimum_size = Vector2(300, 300)
	_speaker.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	stack.add_child(_speaker)

	_heading = UIKit.title("", 58, Palette.WOOD_DARK)
	_heading.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_heading.custom_minimum_size = Vector2(880, 0)
	stack.add_child(_heading)

	_body = UIKit.wrap_label("", 32, Palette.INK, HORIZONTAL_ALIGNMENT_CENTER)
	_body.custom_minimum_size = Vector2(880, 220)
	stack.add_child(_body)

	_props_row = UIKit.hbox(18)
	_props_row.alignment = BoxContainer.ALIGNMENT_CENTER
	stack.add_child(_props_row)

	_dots = UIKit.hbox(10)
	_dots.alignment = BoxContainer.ALIGNMENT_CENTER
	stack.add_child(_dots)

	_next_button = UIKit.primary_button("Continue")
	_next_button.pressed.connect(_on_next_pressed)
	stack.add_child(_next_button)

	_prev_hint = UIKit.label("", 22, Palette.INK_SOFT)
	stack.add_child(_prev_hint)


func play(deck: Array[StoryPage], allow_skip: bool) -> void:
	pages = deck
	index = 0
	_skip_button.visible = allow_skip
	if pages.is_empty():
		finish()
		return
	show_page(0, false)


func show_page(to_index: int, animate: bool = true) -> void:
	if pages.is_empty():
		return
	index = clampi(to_index, 0, pages.size() - 1)
	var page := pages[index]

	_backdrop.background_id = page.mood
	if not GeraiBackdrop.PRESETS.has(page.mood):
		_backdrop.background_id = &"stall_dawn"

	_speaker.cast = _cast_for(page.speaker)
	_speaker.expression = CharacterIcon.Mood.HAPPY
	_speaker.queue_redraw()
	_heading.text = page.heading
	_body.text = "\n".join(page.lines)

	for child in _props_row.get_children():
		child.queue_free()
	for id in page.props:
		var dish := KuihIcon.new()
		dish.kuih = KuihLibrary.get_kuih(id)
		dish.custom_minimum_size = Vector2(190, 190)
		dish.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		_props_row.add_child(dish)

	for child in _dots.get_children():
		child.queue_free()
	for i in pages.size():
		var dot := ColorRect.new()
		dot.custom_minimum_size = Vector2(20, 20)
		dot.color = Palette.PINK_DARK if i == index else Color(0.80, 0.74, 0.66, 0.7)
		_dots.add_child(dot)

	var last := index == pages.size() - 1
	_next_button.text = "Open the Stall" if last else "Continue"
	_prev_hint.text = "Tap anywhere to turn the page" if not last else ""

	if animate:
		_card.pivot_offset = _card.size * 0.5
		_card.scale = Vector2(0.96, 0.96)
		var tw := create_tween()
		tw.tween_property(_card, "scale", Vector2.ONE, 0.28).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	AudioManager.play(AudioManager.Sfx.TAP, 1.05, -10.0)


static func _cast_for(speaker: int) -> int:
	match speaker:
		StoryBeat.Speaker.AINA:
			return CharacterIcon.Cast.AINA
		StoryBeat.Speaker.IBU:
			return CharacterIcon.Cast.IBU
		StoryBeat.Speaker.FRIEND:
			return CharacterIcon.Cast.FRIEND
		StoryBeat.Speaker.RIVAL:
			return CharacterIcon.Cast.RIVAL
	return CharacterIcon.Cast.AINA


func _gui_input(event: InputEvent) -> void:
	var pressed := false
	var at := Vector2.ZERO
	var released := false
	if event is InputEventScreenTouch:
		pressed = (event as InputEventScreenTouch).pressed
		released = not pressed
		at = (event as InputEventScreenTouch).position
	elif event is InputEventMouseButton:
		pressed = (event as InputEventMouseButton).pressed
		released = not pressed
		at = (event as InputEventMouseButton).position
	if pressed:
		return
	if not released:
		return
	# Tapping the button area should not also flip the page.
	if _next_button.get_global_rect().has_point(at):
		return
	if at.x < size.x * 0.28 and index > 0:
		show_page(index - 1)
	else:
		_turn()


func _turn() -> void:
	if index < pages.size() - 1:
		show_page(index + 1)
	else:
		finish()


func _on_next_pressed() -> void:
	AudioManager.play(AudioManager.Sfx.TAP)
	_turn()


func _on_skip() -> void:
	AudioManager.play(AudioManager.Sfx.TAP, 0.9)
	finish()


func finish() -> void:
	finished.emit()