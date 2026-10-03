class_name StoryPopup
extends Control

## Inline dialogue card for story beats (Master Plan section 21).
##
## Portrait, name, two to four short lines, tap to continue. Deliberately
## lightweight so it can appear between stages without breaking flow.

signal finished()

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

var _card: PanelContainer
var _portrait: CharacterIcon
var _name_label: Label
var _line_label: Label
var _continue: Label
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
	var dim := ColorRect.new()
	dim.color = Color(0.18, 0.11, 0.05, 0.45)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(dim)

	var stack := UIKit.vbox(8)
	stack.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	stack.offset_left = 40
	stack.offset_right = -40
	stack.offset_top = -460
	stack.offset_bottom = -60
	add_child(stack)

	_card = PanelContainer.new()
	_card.add_theme_stylebox_override("panel", UIKit.cream_box())
	stack.add_child(_card)

	var row := UIKit.hbox(18)
	_card.add_child(row)

	_portrait = CharacterIcon.new()
	_portrait.cast = CharacterIcon.Cast.AINA
	_portrait.custom_minimum_size = Vector2(190, 190)
	row.add_child(_portrait)

	var col := UIKit.vbox(8)
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(col)

	_name_label = UIKit.label("", 30, Palette.PINK_DARK, HORIZONTAL_ALIGNMENT_LEFT)
	col.add_child(_name_label)

	_line_label = UIKit.wrap_label("", 32, Palette.INK, HORIZONTAL_ALIGNMENT_LEFT)
	_line_label.custom_minimum_size = Vector2(0, 140)
	_line_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	col.add_child(_line_label)

	_continue = UIKit.label("Tap to continue  ▾", 22, Palette.INK_SOFT, HORIZONTAL_ALIGNMENT_RIGHT)
	col.add_child(_continue)


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
	_line_label.text = String(_beat.lines[_line])
	_continue.text = "Tap to continue  ▾" if _line < _beat.lines.size() - 1 else "Tap to close  ♥"
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
