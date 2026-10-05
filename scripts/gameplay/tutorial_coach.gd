class_name TutorialCoach
extends Control

## Step-driven coaching for the tutorial stages.
##
## Scripted special lessons preserve the teaching layout until the guided swap.
## It explains one idea and offers a nudge if the player stalls. Wrong moves bounce like any
## invalid swap - no penalty, no lock-out, no lost moves (Master Plan section
## 3.1: a player must understand the puzzle within a minute).

signal step_changed(index: int, step: TutorialStepData)
signal gate_satisfied(index: int)
signal finished()

const HINT_AFTER := 5.0

var steps: Array[TutorialStepData] = []
var index: int = 0
var dialogue_host: OrderPanel

var _card: PanelContainer
var _portrait: CharacterIcon
var _title: Label
var _body: Label
var _dots: HBoxContainer
var _nudge: Label
var _tap_indicator: TapIndicator
var _spotlight: DialogueSpotlight

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

func _input(event: InputEvent) -> void:
	if not can_tap_through() or not is_visible_in_tree() or get_tree().paused:
		return
	var tapped := false
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		tapped = true
	elif event is InputEventScreenTouch and event.pressed:
		tapped = true
	if tapped:
		# Consume the tap before GUI controls receive it: tapping over the board,
		# settings or boosters advances only the introductory dialogue.
		get_viewport().set_input_as_handled()
		tap_through()


func _build() -> void:
	if dialogue_host != null:
		dialogue_host.set_coaching(true)
		_card = dialogue_host._bubble
		_portrait = dialogue_host._aina
		_title = dialogue_host._name_label
		_body = dialogue_host._line_label
		_dots = HBoxContainer.new()
		_dots.visible = false
		add_child(_dots)
		_nudge = Label.new()
		_nudge.visible = false
		add_child(_nudge)
		return
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
	modulate.a = 1.0
	if dialogue_host != null:
		dialogue_host.set_coaching(true)
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

	_title.text = TutorialText.text(step.title)
	_body.text = TutorialText.text(step.body)
	if _tap_indicator == null:
		_tap_indicator = TapIndicator.new()
		_tap_indicator.target = _card
		add_child(_tap_indicator)
	_tap_indicator.visible = step.gate == TutorialStepData.Gate.INTRO
	if _spotlight == null:
		_spotlight = DialogueSpotlight.new()
		_spotlight.name = "DialogueSpotlight"
		_spotlight.target = _card
		_spotlight.characters.append(_portrait)
		if dialogue_host != null:
			_spotlight.characters.append(dialogue_host._card)
		add_child(_spotlight)
	_spotlight.visible = step.gate == TutorialStepData.Gate.INTRO
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
			_nudge.text = "Match four with a sideways swipe to make a horizontal Tapau."
		TutorialStepData.Gate.CREATED_VERTICAL:
			_nudge.text = "Match four with an up or down swipe to make a vertical Tapau."
		TutorialStepData.Gate.ACTIVATED_CROSS:
			_nudge.text = "Swap the two highlighted packages together."
		TutorialStepData.Gate.CREATED_HANTAR:
			_nudge.text = "Make a square of four matching kuih to create Pesanan Hantar."
		TutorialStepData.Gate.CREATED_DULANG:
			_nudge.text = "An L or a T shape makes a Dulang."
		TutorialStepData.Gate.BLOCKER_OPENED:
			_nudge.text = "Match right beside the cover to lift it."
		TutorialStepData.Gate.COLLECTED:
			_nudge.text = "Collect the kuih your customer asked for."
		TutorialStepData.Gate.SERVED:
			_nudge.text = "Fill the order to serve the customer."
		_:
			_nudge.text = ""
	_nudge.text = TutorialText.text(_nudge.text)
	if step.nudge_gesture != "":
		_nudge.text += "  (%s)" % step.nudge_gesture
	if dialogue_host != null and not _nudge.text.is_empty():
		_body.text = _nudge.text


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
				_nudge.text = TutorialText.text("That was a sideways slide. Try up and down.")
				if dialogue_host != null:
					_body.text = _nudge.text
				_nudge.modulate.a = 1.0
		TutorialStepData.Gate.SWAP_HORIZONTAL:
			if not accepted:
				return
			if a.y == b.y:
				_advance()
			else:
				_portrait.expression = CharacterIcon.Mood.THINKING
				_nudge.text = TutorialText.text("That was a vertical slide. Try left and right.")
				if dialogue_host != null:
					_body.text = _nudge.text
				_nudge.modulate.a = 1.0
		_:
			return


func notify_special_created(kind: int) -> void:
	var step := _current()
	if step.gate == TutorialStepData.Gate.CREATED_TAPAU and kind in [BoardCell.Special.TAPAU, BoardCell.Special.TAPAU_VERTICAL]:
		_advance()
	elif step.gate == TutorialStepData.Gate.CREATED_HANTAR and kind == BoardCell.Special.HANTAR:
		_advance()
	elif step.gate == TutorialStepData.Gate.CREATED_DULANG and kind == BoardCell.Special.DULANG:
		_advance()
	elif step.gate == TutorialStepData.Gate.CREATED_VERTICAL and kind == BoardCell.Special.TAPAU_VERTICAL:
		_advance()

func notify_combo(combo: StringName) -> void:
	if _current().gate == TutorialStepData.Gate.ACTIVATED_CROSS and combo == &"sweet_cross":
		_advance()


func notify_blocker_opened(count: int) -> void:
	var step := _current()
	if step.gate != TutorialStepData.Gate.BLOCKER_OPENED:
		return
	_progress_blockers += count
	if _progress_blockers >= maxi(1, step.gate_value):
		_advance()


func notify_special_activated(kind: int) -> void:
	if _current().gate == TutorialStepData.Gate.ACTIVATED_SPECIAL and kind == _current().gate_value:
		_advance()


func guide_special_activation(logic: BoardState) -> void:
	if _finished or _current().gate != TutorialStepData.Gate.ACTIVATED_SPECIAL:
		return
	for y in logic.height:
		for x in logic.width:
			var pos := Vector2i(x, y)
			var cell := logic.get_cell(pos)
			if cell.special != _current().gate_value or not cell.is_playable():
				continue
			var directions := [Vector2i.RIGHT, Vector2i.LEFT, Vector2i.DOWN, Vector2i.UP]
			if cell.special == BoardCell.Special.DULANG:
				# The blast follows the swapped destination. Teach the full nine
				# tiles by moving inward, rather than clipping it at the board edge.
				directions.sort_custom(func(a: Vector2i, b: Vector2i):
					return _edge_distance(pos + a, logic) > _edge_distance(pos + b, logic))
			for delta in directions:
				var neighbour: Vector2i = pos + delta
				if logic.is_playable(neighbour):
					_hint_cells.assign([pos, neighbour])
					return


static func _edge_distance(pos: Vector2i, logic: BoardState) -> int:
	return mini(mini(pos.x, logic.width - 1 - pos.x), mini(pos.y, logic.height - 1 - pos.y))


func notify_collected(totals: Dictionary) -> void:
	var step := _current()
	if step.gate != TutorialStepData.Gate.COLLECTED:
		return
	for id in totals:
		if id == _step_kuih_id:
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
	if not _finished and _current().gate != TutorialStepData.Gate.INTRO and _hint_cells.size() == 2:
		return _hint_cells
	if not _hinted or _hint_cells.is_empty():
		return [] as Array[Vector2i]
	return _hint_cells


## The hint button follows this lesson, including its introductory explanation.
func guided_cells() -> Array[Vector2i]:
	if _finished or steps.is_empty():
		return [] as Array[Vector2i]
	var step := _current()
	if step.gate == TutorialStepData.Gate.INTRO and index + 1 < steps.size():
		step = steps[index + 1]
	return step.highlight


func allows_swap(a: Vector2i, b: Vector2i) -> bool:
	if _finished or steps.is_empty():
		return true
	var step := _current()
	if step.gate == TutorialStepData.Gate.INTRO:
		return false
	if step.gate == TutorialStepData.Gate.ACTIVATED_SPECIAL:
		return _hint_cells.size() == 2 and ((a == _hint_cells[0] and b == _hint_cells[1]) or (b == _hint_cells[0] and a == _hint_cells[1]))
	if step.gate in [TutorialStepData.Gate.CREATED_TAPAU, TutorialStepData.Gate.CREATED_DULANG, TutorialStepData.Gate.CREATED_HANTAR, TutorialStepData.Gate.CREATED_VERTICAL, TutorialStepData.Gate.ACTIVATED_CROSS] and step.highlight.size() == 2:
		return (a == step.highlight[0] and b == step.highlight[1]) or (b == step.highlight[0] and a == step.highlight[1])
	return true


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
	if _tap_indicator != null:
		_tap_indicator.visible = false
	if _spotlight != null:
		_spotlight.visible = false
	if dialogue_host != null:
		dialogue_host.set_coaching(false, true)
	modulate.a = 0.0
	visible = false
	finished.emit()
