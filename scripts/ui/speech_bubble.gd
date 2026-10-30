class_name SpeechBubble
extends PanelContainer

const ART_PATH := "res://assets/ui/dialogue_v1/speech_bubble.png"
## Compact HUD portraits sit above the dialogue. Flip artwork only, never text.
var tail_on_top := false:
	set(value):
		tail_on_top = value
		queue_redraw()

var _bubble_style: StyleBoxTexture
## Overrides the size-derived art scale when the tail must read at a small height.
var art_scale := 0.0

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
	var art := AtlasTexture.new()
	art.atlas = load(ART_PATH)
	art.region = Rect2(51,55,2071,600)
	_bubble_style = StyleBoxTexture.new()
	_bubble_style.texture = art
	# The complete tail is contained in the lower-left fixed corner. Stretch
	# only the central strips, never the tail or the rounded highlights.
	_bubble_style.set_texture_margin(SIDE_LEFT,365)
	_bubble_style.set_texture_margin(SIDE_RIGHT,240)
	_bubble_style.set_texture_margin(SIDE_TOP,210)
	_bubble_style.set_texture_margin(SIDE_BOTTOM,210)
	resized.connect(queue_redraw)

func _draw() -> void:
	var rect := Rect2(Vector2.ZERO, size)
	if _bubble_style == null or size.x <= 0 or size.y <= 0:
		return
	# Mirror independently towards the active speaker and its vertical position.
	var scale_factor := art_scale if art_scale > 0.0 else minf(40.0,size.y*.18)/210.0
	var origin := Vector2(0 if speaker_on_left else size.x,size.y if tail_on_top else 0.0)
	var direction := Vector2(1 if speaker_on_left else -1,-1 if tail_on_top else 1)
	draw_set_transform(origin,0,direction*scale_factor)
	draw_style_box(_bubble_style,Rect2(rect.position/scale_factor,rect.size/scale_factor))
	draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)


# Text stays inside the authored safe area, above the painted bubble's tail.
# Keep the scene font as the maximum, and refit when copy or geometry changes.
## Phone floor: below this a 1080-wide design renders under ~10sp on a handset.
const MIN_FONT := 26
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
	# Measure with the label's own layout (line spacing, font ascent and the
	# clip box), not a bare string size: the bare measurement accepted sizes at
	# which the clipped label then showed zero lines, so names and second lines vanished.
	var fitted: int = record.maximum
	label.add_theme_font_size_override("font_size", fitted)
	while fitted > MIN_FONT and label.get_visible_line_count() < label.get_line_count():
		fitted -= 1
		label.add_theme_font_size_override("font_size", fitted)
