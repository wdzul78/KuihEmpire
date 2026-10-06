class_name ScoreProgress
extends Control

var number_font_size := 36
var score := 0
var two_star := 800
var three_star := 1400
var _number: Label
var _star_art: Texture2D

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_number = JourneyArt.label(self, "0", Rect2(.08, .065, .84, .43), 36, Palette.WOOD_DARK)
	_number.name = "ScoreValue"
	var caption := JourneyArt.label(self, "Score", Rect2(.08,.055,.84,.19),22,Palette.WOOD_DARK)
	caption.name = "ScoreCaption"
	_number.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_star_art = GameplaySkin.texture("star")
	resized.connect(_refresh)
	_refresh()

func configure(level: LevelDefinition) -> void:
	two_star = maxi(1, level.score_two_star)
	three_star = maxi(two_star + 1, level.score_three_star)
	_refresh()

func set_score(value: int) -> void:
	score = maxi(0, value)
	_refresh()

func _refresh() -> void:
	if _number != null:
		_number.text = str(score)
		var px := number_font_size
		while px > 24 and _number.get_theme_font("font").get_string_size(_number.text, HORIZONTAL_ALIGNMENT_LEFT, -1, px).x > size.x * .82:
			px -= 1
		_number.add_theme_font_size_override("font_size", px)
	tooltip_text = "Complete orders to win. Targets: 2 stars %d; 3 stars %d." % [two_star, three_star]
	queue_redraw()

func _draw() -> void:
	if size.x <= 0 or size.y <= 0:
		return
	# A compact resource pill above a separate progress rail leaves the header airy.
	var pill := Rect2(size.x * .015, size.y * .04, size.x * .97, size.y * .54)
	draw_style_box(UIKit.flat_box(Color("fff0ca"), Color("c58b42"), 0, 3, int(pill.size.y * .5)), pill)
	var bar := Rect2(size.x * .08, size.y * .77, size.x * .82, size.y * .09)
	draw_style_box(UIKit.flat_box(Color("f2d4a2"), Palette.WOOD_LIGHT, 0, 2, 8), bar)
	var filled := bar
	filled.size.x *= clampf(float(score) / three_star, 0, 1)
	if filled.size.x > 0:
		draw_style_box(UIKit.flat_box(Palette.LEAF, Color.TRANSPARENT, 0, 0, 8), filled)
	if _star_art == null:
		return
	var side := size.y * .28
	for threshold in [two_star, three_star]:
		var x: float = bar.position.x + bar.size.x * float(threshold) / three_star
		var tint := Color.WHITE if score >= threshold else Color(.80, .67, .45)
		draw_texture_rect(_star_art, Rect2(Vector2(x - side * .5, bar.get_center().y - side * .5), Vector2.ONE * side), false, tint)
