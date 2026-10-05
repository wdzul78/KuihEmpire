class_name HeartDisplay
extends Button

var _count: Label
var _timer: Label
var refill_enabled := true
## Compact main-menu meter: heart icon, count and refill plus in one pill.
var compact_count := false
var square_plus := false
var pill_shape := false

func _ready() -> void:
	name = "HeartDisplay"
	custom_minimum_size = Vector2.ZERO
	for key in ["normal", "hover", "pressed", "disabled"]:
		add_theme_stylebox_override(key, StyleBoxEmpty.new())
	resized.connect(_layout_labels)
	_count = JourneyArt.label(self, "", Rect2(.0, .16, .29, .66), ResourceBarArt.FONT_SIZE, Palette.PAPER)
	_count.add_theme_color_override("font_outline_color", Palette.WOOD_DARK)
	_count.add_theme_constant_override("outline_size", 3)
	_timer = JourneyArt.label(self, "", Rect2(.31, .16, .43, .66), ResourceBarArt.FONT_SIZE, Palette.WOOD_DARK)
	HeartManager.changed.connect(_refresh)
	mouse_filter = Control.MOUSE_FILTER_STOP if refill_enabled else Control.MOUSE_FILTER_IGNORE
	focus_mode = Control.FOCUS_ALL if refill_enabled else Control.FOCUS_NONE
	pressed.connect(func() -> void:
		if refill_enabled:
			HeartRefillDialog.open(get_tree().current_scene)
	)
	_refresh()
	_layout_labels()

func _layout_labels() -> void:
	if _count != null:
		_count.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
		_count.position = Vector2.ZERO
		_count.size = Vector2(size.y * .96, size.y)
	if _timer != null:
		_timer.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
		_timer.position = Vector2(size.y * .98, 0)
		_timer.size = Vector2(maxf(0, size.x - size.y * (1.57 if refill_enabled else 1.10)), size.y)
	if compact_count and _count != null and _timer != null:
		_count.hide()
		_timer.add_theme_font_size_override("font_size", UIKit.fit_font_size(_timer.text, mini(26, roundi(size.y*.36)), maxf(0, _timer.size.x-8)))
	queue_redraw()

func _draw() -> void:
	ResourceBarArt.draw_frame(self, "heart", refill_enabled, square_plus, pill_shape)

func _refresh() -> void:
	_count.text = "∞" if HeartManager.is_free_play_active() else str(HeartManager.current())
	var seconds := HeartManager.get_free_play_remaining()
	if compact_count:
		_timer.text = "∞" if seconds > 0 else str(HeartManager.current())
		tooltip_text = "Free Play " + HeartManager.time_text(seconds) if seconds > 0 else "%d / 5 hearts" % HeartManager.current()
		if seconds <= 0 and HeartManager.current() < HeartManager.MAX_HEARTS:
			tooltip_text += " · +1 " + HeartManager.time_text(HeartManager.get_next_refill_remaining())
		accessibility_name = tooltip_text
		_layout_labels()
		return
	if seconds > 0:
		_timer.add_theme_font_size_override("font_size", 24)
		_timer.text = "Free Play\n" + HeartManager.time_text(seconds)
	elif HeartManager.current() == HeartManager.MAX_HEARTS:
		_timer.add_theme_font_size_override("font_size", ResourceBarArt.FONT_SIZE)
		_timer.text = JourneyArt.localized("Penuh", "Full")
	else:
		_timer.add_theme_font_size_override("font_size", 26)
		_timer.text = "+1  " + HeartManager.time_text(HeartManager.get_next_refill_remaining())
