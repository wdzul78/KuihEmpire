class_name StoryPopup
extends Control

## Inline dialogue card for story beats (Master Plan section 21).
##
## Portrait, name, two to four short lines, tap to continue. Deliberately
## lightweight so it can appear between stages without breaking flow.

signal finished()
signal speaker_changed(speaker: int)

const SPEAKER_NAMES := {
	StoryBeat.Speaker.AINA: "Aina",
	StoryBeat.Speaker.IBU: "Ibu",
	StoryBeat.Speaker.FRIEND: "Farah",
	StoryBeat.Speaker.RIVAL: "Daniel",
	StoryBeat.Speaker.CUSTOMER: "Customer",
	StoryBeat.Speaker.NARRATOR: "",
}

const SPEAKER_CAST := {
	StoryBeat.Speaker.AINA: CharacterIcon.Cast.AINA,
	StoryBeat.Speaker.IBU: CharacterIcon.Cast.IBU,
	StoryBeat.Speaker.FRIEND: CharacterIcon.Cast.FRIEND,
	StoryBeat.Speaker.RIVAL: CharacterIcon.Cast.RIVAL,
	StoryBeat.Speaker.CUSTOMER: CharacterIcon.Cast.CUSTOMER,
	StoryBeat.Speaker.NARRATOR: CharacterIcon.Cast.AINA,
}

var inline_mode: bool = false
var highlighted_character: Control
var customer_name: String = "Customer"

var _card: PanelContainer
var _portrait: CharacterIcon
var _name_label: Label
var _line_label: Label
var _tap_indicator: TapIndicator
var _beat: StoryBeat = null
var _line: int = 0


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	# Stays hidden until a beat is actually played.
	visible = false
	UIKit.apply_root_theme(self)
	_build()
	gui_input.connect(_on_input)


func _build() -> void:
	var stack := UIKit.vbox(8)
	stack.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	stack.offset_left = 40
	stack.offset_right = -40
	stack.offset_top = -460
	stack.offset_bottom = -60
	if inline_mode:
		stack.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
		stack.anchor_left = 0.22
		stack.offset_left = 0
		stack.anchor_right = 0.78
		stack.offset_right = 0
		stack.anchor_top = 0.10
		stack.offset_top = 0
		stack.anchor_bottom = 0.215
		stack.offset_bottom = 0
	add_child(stack)

	_card = SpeechBubble.new()
	if inline_mode:
		var space := StyleBoxEmpty.new()
		space.content_margin_left = 28
		space.content_margin_right = 28
		space.content_margin_top = 18
		space.content_margin_bottom = 58
		_card.add_theme_stylebox_override("panel", space)
	stack.add_child(_card)

	var row := UIKit.hbox(18)
	_card.add_child(row)

	_portrait = CharacterIcon.new()
	_portrait.cast = CharacterIcon.Cast.AINA
	_portrait.custom_minimum_size = Vector2(190, 190)
	_portrait.visible = not inline_mode
	row.add_child(_portrait)

	var col := UIKit.vbox(8)
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(col)

	_name_label = UIKit.label("", 30, Palette.PINK_DARK, HORIZONTAL_ALIGNMENT_LEFT)
	col.add_child(_name_label)

	_line_label = UIKit.wrap_label("", 26, Palette.INK, HORIZONTAL_ALIGNMENT_LEFT)
	_line_label.custom_minimum_size = Vector2(0, 140)
	if inline_mode:
		_line_label.custom_minimum_size.y = 60
		_line_label.add_theme_font_size_override("font_size", 23)
		_name_label.add_theme_font_size_override("font_size", 24)
		col.add_theme_constant_override("separation", 4)
	_line_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	col.add_child(_line_label)

	_tap_indicator = TapIndicator.new()
	_tap_indicator.target = _card
	add_child(_tap_indicator)
	var spotlight := DialogueSpotlight.new()
	spotlight.name = "DialogueSpotlight"
	spotlight.target = _card
	if highlighted_character != null:
		spotlight.characters.append(highlighted_character)
	add_child(spotlight)
	_card.gui_input.connect(_on_input)


func play(beat: StoryBeat) -> void:
	_beat = beat
	_line = 0
	if beat == null or beat.lines.is_empty():
		visible = false
		finished.emit()
		return
	visible = true
	_portrait.cast = SPEAKER_CAST.get(beat.speaker, CharacterIcon.Cast.AINA)
	_portrait.expression = CharacterIcon.Mood.HAPPY
	_portrait.queue_redraw()
	_name_label.text = SPEAKER_NAMES.get(beat.speaker, "")
	_show_line()
	modulate.a = 0.0
	_card.pivot_offset = _card.size * 0.5
	_card.scale = Vector2(0.92, 0.92)
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(self, "modulate:a", 1.0, 0.22)
	tw.tween_property(_card, "scale", Vector2.ONE, 0.34).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _show_line() -> void:
	var speaker := int(_beat.speaker)
	if _line < _beat.line_speakers.size():
		speaker = _beat.line_speakers[_line]
	_name_label.text = customer_name if speaker == StoryBeat.Speaker.CUSTOMER else SPEAKER_NAMES.get(speaker, "")
	_portrait.cast = SPEAKER_CAST.get(speaker, CharacterIcon.Cast.AINA)
	(_card as SpeechBubble).speaker_on_left = not inline_mode or (speaker != StoryBeat.Speaker.AINA and speaker != StoryBeat.Speaker.NARRATOR)
	speaker_changed.emit(speaker)
	_line_label.text = TutorialText.text(String(_beat.lines[_line]))
	if beat_is_final():
		_portrait.expression = CharacterIcon.Mood.EXCITED
		_line_label.modulate.a = 0.0
		var tw := create_tween()
		tw.tween_property(_line_label, "modulate:a", 1.0, 0.3)
	else:
		_line_label.modulate.a = 1.0


func beat_is_final() -> bool:
	return _beat != null and _line == _beat.lines.size() - 1


func _on_input(event: InputEvent) -> void:
	var pressed := false
	if event is InputEventScreenTouch:
		pressed = (event as InputEventScreenTouch).pressed
	elif event is InputEventMouseButton:
		pressed = (event as InputEventMouseButton).pressed
	if not pressed:
		return
	advance()
	accept_event()


func advance() -> void:
	if _beat == null:
		return
	AudioManager.play(AudioManager.Sfx.TAP, randf_range(0.95, 1.1), -8.0)
	_line += 1
	if _line >= _beat.lines.size():
		close()
		return
	_show_line()


func close() -> void:
	visible = false
	finished.emit()
