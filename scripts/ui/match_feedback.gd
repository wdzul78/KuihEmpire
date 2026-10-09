class_name MatchFeedback
extends Control

## Transient, input-transparent points and cascade feedback above the board.
var _combo: TextureRect
var _score: TextureRect
var _multiplier: Label
var _points: Label
var _tween: Tween

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	z_index = 30
	size = Vector2(440, 180)
	pivot_offset = size * .5
	_combo = TitleArt.create("combo", "Combo")
	_score = TitleArt.create("score", "Score")
	JourneyArt.place(self, _combo, Rect2(.02, 0, .70, .46))
	JourneyArt.place(self, _score, Rect2(.12, .53, .42, .37))
	_multiplier = JourneyArt.label(self, "", Rect2(.72, 0, .28, .46), 62, Palette.PAPER)
	_points = JourneyArt.label(self, "", Rect2(.56, .49, .40, .44), 62, Palette.PAPER)
	for label in [_multiplier, _points]:
		label.add_theme_color_override("font_outline_color", Palette.WOOD_DARK)
		label.add_theme_constant_override("outline_size", 8)
	visible = false

func reset() -> void:
	if _tween != null and _tween.is_valid():
		_tween.kill()
	hide()

func show_clear(points: int, cascade: int, board_size: Vector2, multiplier: float = 1.0, origin: Vector2 = Vector2(-1, -1)) -> void:
	reset()
	size = Vector2(clampf(board_size.x * .48, 220, 440), minf(180, board_size.y * .20))
	pivot_offset = size * .5
	_combo.visible = cascade > 0
	_multiplier.visible = cascade > 0
	_multiplier.text = "x" + ("%.2f" % multiplier).trim_suffix("0").trim_suffix("0").trim_suffix(".")
	var font_size := 62
	while font_size > 32 and _multiplier.get_theme_font("font").get_string_size(_multiplier.text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x > size.x * .26:
		font_size -= 2
	_multiplier.add_theme_font_size_override("font_size", font_size)
	_points.text = "+%d" % points
	var points_font := clampi(roundi(size.x * .14), 28, 62)
	while points_font > 20 and _points.get_theme_font("font").get_string_size(_points.text, HORIZONTAL_ALIGNMENT_LEFT, -1, points_font).x > size.x * .40:
		points_font -= 2
	_points.add_theme_font_size_override("font_size", points_font)
	tooltip_text = "Score +%d" % points
	var focus := origin if origin.x >= 0 else Vector2(board_size.x * .5, board_size.y * .28)
	position = Vector2(clampf(focus.x - size.x * .5, 0, maxf(0, board_size.x - size.x)), clampf(focus.y - size.y, 12, maxf(12, board_size.y - size.y - 12)))
	modulate.a = 1
	scale = Vector2.ONE * .75
	show()
	_tween = create_tween()
	_tween.tween_property(self, "scale", Vector2.ONE, .18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_tween.tween_interval(.42)
	_tween.tween_property(self, "position:y", position.y - 60, .30)
	_tween.parallel().tween_property(self, "modulate:a", 0.0, .30)
	_tween.tween_callback(hide)
