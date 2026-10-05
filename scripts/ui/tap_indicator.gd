class_name TapIndicator
extends Control

## Four evenly spaced frames from the supplied transparent sprite sheet.
const SHEET := preload("res://assets/ui/gestures/finger_tap.png")
const FRAME_SECONDS := 0.18
var target: Control
var anchor_ratio := Vector2(.5, 1.0)
var anchor_offset := Vector2(0, -6)
var _clock := 0.0
var frame_index := 0

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	size = Vector2(180, 240)
	z_index = 90

func _process(delta: float) -> void:
	if not visible or not is_instance_valid(target):
		return
	_clock += delta
	# Hold the resting frame briefly after each tap cycle.
	var tick := int(_clock / FRAME_SECONDS) % 7
	frame_index = tick if tick < 4 else 0
	var bubble := target.get_global_rect()
	global_position = bubble.position + bubble.size * anchor_ratio + anchor_offset - Vector2(size.x * .5, 0)
	queue_redraw()

func _draw() -> void:
	var width := SHEET.get_width() / 4.0
	draw_texture_rect_region(SHEET, Rect2(Vector2.ZERO, size), Rect2(frame_index * width, 0, width, SHEET.get_height()))
