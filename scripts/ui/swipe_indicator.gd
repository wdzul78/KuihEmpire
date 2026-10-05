class_name SwipeIndicator
extends Control

const SHEETS := {
	"left": preload("res://assets/ui/gestures/swipe_left.png"),
	"right": preload("res://assets/ui/gestures/swipe_right.png"),
	"up": preload("res://assets/ui/gestures/swipe_up.png"),
	"down": preload("res://assets/ui/gestures/swipe_down.png"),
}
const TIPS := {
	"left": [Vector2(160, 245), Vector2(164, 245), Vector2(158, 245), Vector2(303, 245)],
	"right": [Vector2(171, 239), Vector2(314, 239), Vector2(397, 239), Vector2(374, 242)],
	"down": [Vector2(293, 153), Vector2(294, 303), Vector2(277, 399), Vector2(230, 459)],
	"up": [Vector2(267, 413), Vector2(267, 390), Vector2(265, 338), Vector2(240, 150)],
}
## The right-hand sheet is not divided into equal cells: its third hand
## extends past x=1629. Equal quarters include that hand in the last frame.
const RIGHT_REGIONS := [Rect2(0, 0, 543, 724), Rect2(543, 0, 562, 724), Rect2(1105, 0, 600, 724), Rect2(1705, 0, 467, 724)]

func frame_region() -> Rect2:
	if direction == "right":
		return RIGHT_REGIONS[frame_index]
	var sheet: Texture2D = SHEETS[direction]
	var width := sheet.get_width() / 4.0
	return Rect2(frame_index * width, 0, width, sheet.get_height())

var board: MatchBoard
var from_cell := Vector2i.ZERO
var to_cell := Vector2i.ZERO
var direction := "right"
var frame_index := 0
var _clock := 0.0

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	z_index = 25
	visible = false

func show_swipe(from: Vector2i, to: Vector2i) -> void:
	from_cell = from
	to_cell = to
	var delta := to - from
	direction = "right" if delta.x > 0 else "left" if delta.x < 0 else "down" if delta.y > 0 else "up"
	_clock = 0.0
	frame_index = 3 if direction == "left" else 0
	visible = true
	queue_redraw()

func _process(delta: float) -> void:
	if not visible:
		return
	_clock += delta
	var frame := mini(3, int(fmod(_clock, 1.65) / .24))
	frame_index = 3 - frame if direction == "left" else frame
	queue_redraw()

func _draw() -> void:
	if not is_instance_valid(board) or not visible or board.busy or not board.enabled:
		return
	var sheet: Texture2D = SHEETS[direction]
	var region := frame_region()
	var phase := fmod(_clock, 1.65)
	var progress := clampf(phase / .90, 0, 1)
	var start := board.cell_to_pos(from_cell) + Vector2.ONE * board.cell_size * .5
	var end := board.cell_to_pos(to_cell) + Vector2.ONE * board.cell_size * .5
	var contact := start.lerp(end, smoothstep(0, 1, progress))
	var factor := board.cell_size * .0024
	var tip: Vector2 = TIPS[direction][frame_index]
	if direction == "right":
		tip.x += frame_index * (sheet.get_width() / 4.0) - region.position.x
	var destination := Rect2(contact - tip * factor, region.size * factor)
	var fade := 1.0 if phase < 1.30 else clampf((1.65 - phase) / .35, 0, 1)
	draw_texture_rect_region(sheet, destination, region, Color(1, 1, 1, fade))
