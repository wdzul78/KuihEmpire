class_name FiveHeartDisplay
extends Button

const FULL_ART = preload("res://assets/ui/hearts_v2/heart_full.png")
const EMPTY_ART = preload("res://assets/ui/hearts_v2/heart_empty.png")
static var _full_texture: AtlasTexture
static var _empty_texture: AtlasTexture
var _hearts: Array[TextureRect] = []
var _timer: Label
var refill_enabled := true
var _free_play := false

static func _texture(full: bool) -> AtlasTexture:
	if (full and _full_texture == null) or (not full and _empty_texture == null):
		var source: Texture2D = FULL_ART if full else EMPTY_ART
		var cropped := AtlasTexture.new()
		cropped.atlas = source
		cropped.region = Rect2(source.get_image().get_used_rect())
		cropped.filter_clip = true
		if full:
			_full_texture = cropped
		else:
			_empty_texture = cropped
	return _full_texture if full else _empty_texture

func _ready() -> void:
	name = "FiveHeartDisplay"
	custom_minimum_size = Vector2.ZERO
	for key in ["normal", "hover", "pressed", "disabled"]:
		add_theme_stylebox_override(key, StyleBoxEmpty.new())
	for index in HeartManager.MAX_HEARTS:
		var heart := TextureRect.new()
		heart.name = "HealthHeart%d" % (index+1)
		heart.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		heart.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		heart.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(heart)
		_hearts.append(heart)
	_timer = UIKit.label("", 22, Palette.WOOD_DARK)
	_timer.name = "RefillStatus"
	_timer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_timer)
	resized.connect(_layout_hearts)
	HeartManager.changed.connect(_refresh)
	mouse_filter = Control.MOUSE_FILTER_STOP if refill_enabled else Control.MOUSE_FILTER_IGNORE
	focus_mode = Control.FOCUS_ALL if refill_enabled else Control.FOCUS_NONE
	pressed.connect(func() -> void:
		if refill_enabled:
			HeartRefillDialog.open(get_tree().current_scene)
	)
	_refresh()

func _layout_hearts() -> void:
	if _hearts.is_empty():
		return
	var row_width := maxf(0, size.x - (size.y*.55 if _free_play and not refill_enabled else 0.0))
	var gap := minf(size.y*.08, row_width*.018)
	var width := maxf(0, (row_width-gap*4)/5.0)
	for index in _hearts.size():
		_hearts[index].position = Vector2(index*(width+gap), 0)
		_hearts[index].size = Vector2(width, size.y)
	if _free_play and not refill_enabled:
		_timer.position = Vector2(row_width, 0)
		_timer.size = Vector2(size.x-row_width, size.y)
		_timer.add_theme_font_size_override("font_size", 28)
	else:
		_timer.position = Vector2(0, size.y)
		_timer.size = Vector2(size.x, size.y*.45)
		_timer.add_theme_font_size_override("font_size", 22)

func _refresh() -> void:
	if _hearts.is_empty():
		return
	var count := clampi(HeartManager.current(), 0, HeartManager.MAX_HEARTS)
	var seconds := HeartManager.get_free_play_remaining()
	_free_play = seconds > 0
	for index in _hearts.size():
		var full := _free_play or index < count
		_hearts[index].texture = _texture(full)
		_hearts[index].accessibility_name = "Heart %d: %s" % [index+1, "full" if full else "empty"]
	if _free_play:
		_timer.text = "Free Play " + HeartManager.time_text(seconds) if refill_enabled else "∞"
		_timer.visible = true
		tooltip_text = "Free Play: " + HeartManager.time_text(seconds)
	elif count < HeartManager.MAX_HEARTS:
		_timer.text = "+1 " + HeartManager.time_text(HeartManager.get_next_refill_remaining())
		_timer.visible = refill_enabled
		tooltip_text = "%d / %d hearts · %s" % [count, HeartManager.MAX_HEARTS, _timer.text]
	else:
		_timer.visible = false
		tooltip_text = "5 / 5 hearts"
	accessibility_name = tooltip_text
	_layout_hearts()
