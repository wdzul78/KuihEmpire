class_name TutorialCoach
extends Control

## Step-driven coaching for the tutorial stages.
##
## The coach never blocks input. It explains one idea, waits for the player to
## do that thing, and offers a nudge if they stall. Wrong moves bounce like any
## invalid swap - no penalty, no lock-out, no lost moves (Master Plan section
## 3.1: a player must understand the puzzle within a minute).

signal step_changed(index: int, step: TutorialStepData)
signal gate_satisfied(index: int)
signal finished()

const HINT_AFTER := 5.0

var steps: Array[TutorialStepData] = []
var index: int = 0

var _card: PanelContainer
var _portrait: CharacterIcon
var _title: Label
var _body: Label
var _dots: HBoxContainer
var _nudge: Label

var _progress_blockers: int = 0
var _progress_collected: int = 0
var _hint_timer: float = 0.0
var _hinted: bool = false
var _hint_cells: Array[Vector2i] = []
var _finished: bool = false
## For a COLLECTED step: which kuih the coach is counting.
var _step_kuih_id: StringName = &""


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	UIKit.apply_root_theme(self)
	_build()


func _process(delta: float) -> void:
	if _finished or steps.is_empty():
		return
	if _current().gate == TutorialStepData.Gate.INTRO:
		return
	_hint_timer += delta
	if _hint_timer >= HINT_AFTER and not _hinted:
		_hinted = true
		show_nudge()
		_nudge.modulate.a = 0.0
		var tw := create_tween()
		tw.tween_property(_nudge, "modulate:a", 1.0, 0.25)


func _build() -> void:
	var stack := UIKit.hbox(16)
	# BOTTOM_WIDE, not CENTER_BOTTOM: with centre anchors the horizontal offsets
	# are measured from the middle of the screen and the card flies off-screen.
	stack.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	stack.offset_left = 24
	stack.offset_right = -24
	stack.offset_top = -252
	stack.offset_bottom = -24
	stack.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(stack)

	_portrait = CharacterIcon.new()
	_portrait.cast = CharacterIcon.Cast.AINA
	_portrait.custom_minimum_size = Vector2(170, 170)
	_portrait.size_flags_vertical = Control.SIZE_SHRINK_END
	stack.add_child(_portrait)

	_card = PanelContainer.new()
	_card.add_theme_stylebox_override("panel", UIKit.cream_box())
	_card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_card.size_flags_vertical = Control.SIZE_SHRINK_END
	stack.add_child(_card)

	var col := UIKit.vbox(6)
	_card.add_child(col)

	_dots = UIKit.hbox(8)
	col.add_child(_dots)

	_title = UIKit.label("", 30, Palette.PINK_DARK, HORIZONTAL_ALIGNMENT_LEFT)
	col.add_child(_title)

	_body = UIKit.wrap_label("", 26, Palette.INK, HORIZONTAL_ALIGNMENT_LEFT)
	_body.custom_minimum_size = Vector2(0, 90)
	col.add_child(_body)

	_nudge = UIKit.label("", 22, Palette.WOOD, HORIZONTAL_ALIGNMENT_LEFT)
	col.add_child(_nudge)


func begin(new_steps: Array[TutorialStepData]) -> void:
	steps.clear()
	for step in new_steps:
		steps.append(step)
	index = 0
	_finished = steps.is_empty()
	visible = not _finished
	if _finished:
		finished.emit()
		return
	_show_step()


func _current() -> TutorialStepData:
	if index < 0 or index >= steps.size():
		return TutorialStepData.new()
	return steps[index]


func _show_step() -> void:
	var step := _current()
	_progress_blockers = 0
	_progress_collected = 0
	_hint_timer = 0.0
	_hinted = false
	_hint_cells.clear()
	for cell in step.highlight:
		_hint_cells.append(cell)

	_title.text = step.title
	_body.text = step.body
	_nudge.text = ""
	_portrait.expression = CharacterIcon.Mood.DETERMINED if step.gate == TutorialStepData.Gate.INTRO else CharacterIcon.Mood.HAPPY

	for child in _dots.get_children():
		child.queue_free()
	for i in steps.size():
		var dot := ColorRect.new()
		dot.custom_minimum_size = Vector2(34, 12)
		dot.color = Palette.PINK_DARK if i <= index else Color(0.80, 0.74, 0.66, 0.55)
		_dots.add_child(dot)

	_card.pivot_offset = _card.size * Vector2(0.0, 1.0)
	_card.scale = Vector2(1.0, 0.92)
	var tw := create_tween()
	tw.tween_property(_card, "scale", Vector2.ONE, 0.26).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	step_changed.emit(index, step)


## Nudge text is a plain-language hint, never a spoiler for the answer cell.
func show_nudge() -> void:
	var step := _current()
	match step.gate:
		TutorialStepData.Gate.SWAP_VERTICAL:
			_nudge.text = "Try sliding one kuih up or down."
		TutorialStepData.Gate.SWAP_HORIZONTAL:
			_nudge.text = "Try sliding one kuih left or right."
		TutorialStepData.Gate.CREATED_TAPAU:
			_nudge.text = "Line four up and they wrap themselves in a tapau pack."
		TutorialStepData.Gate.CREATED_DULANG:
			_nudge.text = "An L or a T shape makes a dulang."
		TutorialStepData.Gate.BLOCKER_OPENED:
			_nudge.text = "Match right beside the cover to lift it."
		TutorialStepData.Gate.COLLECTED:
			_nudge.text = "Collect the kuih your customer asked for."
		TutorialStepData.Gate.SERVED:
			_nudge.text = "Fill the order to serve the customer."
		_:
			_nudge.text = ""
	if step.nudge_gesture != "":
		_nudge.text += "  (%s)" % step.nudge_gesture


## --- events from the level screen ----------------------------------------

func notify_swap(a: Vector2i, b: Vector2i, accepted: bool) -> void:
	var step := _current()
	match step.gate:
		TutorialStepData.Gate.INTRO:
			return
		TutorialStepData.Gate.SWAP_ANY:
			if accepted:
				_advance()
			return
		TutorialStepData.Gate.SWAP_VERTICAL:
			if not accepted:
				return
			if a.x == b.x:
				_advance()
			else:
				_portrait.expression = CharacterIcon.Mood.THINKING
				_nudge.text = "That was a sideways slide. Try up and down."
				_nudge.modulate.a = 1.0
		TutorialStepData.Gate.SWAP_HORIZONTAL:
			if not accepted:
				return
			if a.y == b.y:
				_advance()
			else:
				_portrait.expression = CharacterIcon.Mood.THINKING
				_nudge.text = "That was a vertical slide. Try left and right."
				_nudge.modulate.a = 1.0
		_:
			return


func notify_special_created(kind: int) -> void:
	var step := _current()
	if step.gate == TutorialStepData.Gate.CREATED_TAPAU and kind == BoardCell.Special.TAPAU:
		_advance()
	elif step.gate == TutorialStepData.Gate.CREATED_DULANG and kind == BoardCell.Special.DULANG:
		_advance()


func notify_blocker_opened(count: int) -> void:
	var step := _current()
	if step.gate != TutorialStepData.Gate.BLOCKER_OPENED:
		return
	_progress_blockers += count
	if _progress_blockers >= maxi(1, step.gate_value):
		_advance()


func notify_collected(totals: Dictionary) -> void:
	var step := _current()
	if step.gate != TutorialStepData.Gate.COLLECTED:
		return
	for id in totals:
		if step.gate_value > 0 and id == _step_kuih_id:
			_progress_collected += int(totals[id])
	if _progress_collected >= maxi(1, step.gate_value):
		_advance()


func notify_served() -> void:
	if _current().gate == TutorialStepData.Gate.SERVED:
		_advance()


func watch_kuih(kuih_id: StringName) -> void:
	_step_kuih_id = kuih_id


## Which cells the coach wants the board to point at right now.
func hint_cells() -> Array[Vector2i]:
	if not _hinted or _hint_cells.is_empty():
		return [] as Array[Vector2i]
	return _hint_cells


## True when the current step is an intro card the player can tap past.
## Gated steps deliberately ignore taps - the player must do the thing.
func can_tap_through() -> bool:
	if _finished or steps.is_empty():
		return false
	return _current().gate == TutorialStepData.Gate.INTRO


func tap_through() -> void:
	if _finished or not can_tap_through():
		return
	_advance()


## True once every step has been satisfied.
func is_done() -> bool:
	return _finished


func _advance() -> void:
	gate_satisfied.emit(index)
	index += 1
	if index >= steps.size():
		_finish()
		return
	_show_step()


func _finish() -> void:
	_finished = true
	modulate.a = 0.0
	visible = false
	finished.emit()