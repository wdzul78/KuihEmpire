class_name SpeechBubble
extends PanelContainer

## Flip only the painted bubble; native dialogue text keeps its reading direction.
var speaker_on_left := false:
	set(value):
		speaker_on_left = value
		queue_redraw()

func _init() -> void:
	var space := StyleBoxEmpty.new()
	space.content_margin_left = 24
	space.content_margin_top = 12
	space.content_margin_right = 24
	space.content_margin_bottom = 28
	add_theme_stylebox_override("panel", space)

func _ready() -> void:
	resized.connect(queue_redraw)

func _draw() -> void:
	var rect := Rect2(Vector2.ZERO, size)
	if speaker_on_left:
		draw_set_transform(Vector2(size.x, 0), 0, Vector2(-1, 1))
	draw_texture_rect(GameplaySkin.texture("speech_bubble"), rect, false)
	draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)


# Text stays inside the authored safe area, above the painted bubble's tail.
# Keep the scene font as the maximum, and refit when copy or geometry changes.
var _text_fit: Dictionary = {}

func configure_text_fit(label: Label, maximum: int) -> void:
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.clip_text = true
	_text_fit[label] = {"maximum": maximum, "signature": ""}
	_fit_text(label)

func _process(_delta: float) -> void:
	for label: Label in _text_fit:
		if is_instance_valid(label):
			_fit_text(label)

func _fit_text(label: Label) -> void:
	var record: Dictionary = _text_fit[label]
	var signature := "%s|%s" % [label.text, label.size]
	if signature == record.signature or label.size.x <= 1 or label.size.y <= 1:
		return
	record.signature = signature
	var font := label.get_theme_font("font")
	var fitted: int = record.maximum
	while fitted > 12:
		var extent := font.get_multiline_string_size(label.text,HORIZONTAL_ALIGNMENT_CENTER,label.size.x-4,fitted,-1,TextServer.BREAK_MANDATORY | TextServer.BREAK_WORD_BOUND | TextServer.BREAK_ADAPTIVE)
		if extent.y <= label.size.y-4:
			break
		fitted -= 1
	label.add_theme_font_size_override("font_size", fitted)
