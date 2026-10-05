class_name SpecialSparkle
extends Control

## Generated four-frame transparent overlay; no texture copies or particles.
const SHEET = preload("res://assets/specials/animation_v1/special_sparkle_sheet.png")
const FRAME_TIME := .17
var frame_index := -1
var phase := 0.0
var special_kind := BoardCell.Special.NONE
var period := 2.6

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_process(special_kind != BoardCell.Special.NONE)
	resized.connect(queue_redraw)

func set_special(kind: int) -> void:
	if kind == special_kind:
		return
	special_kind = kind
	period = 2.2 if kind == BoardCell.Special.ORDER else 3.0 if kind == BoardCell.Special.HANTAR else 2.6
	phase = randf()*period
	frame_index = -1
	visible = kind != BoardCell.Special.NONE
	set_process(visible)
	queue_redraw()

func _process(delta: float) -> void:
	phase = fmod(phase+delta, period)
	var next := int(phase/FRAME_TIME) if phase < FRAME_TIME*4 else -1
	if next != frame_index:
		frame_index = next
		queue_redraw()

func _draw() -> void:
	if frame_index < 0 or special_kind == BoardCell.Special.NONE:
		return
	var quadrant := SHEET.get_size()*.5
	var source := Rect2(Vector2(frame_index%2, frame_index >> 1)*quadrant, quadrant)
	draw_texture_rect_region(SHEET, Rect2(size*.03, size*.94), source, Color(1,1,1,.72))
