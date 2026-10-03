class_name UIKit
extends RefCounted

## Shared cozy-UI construction helpers: warm cream panels, wooden buttons,
## rounded cards. Every screen is built from these so the whole game reads as one
## hand-painted gerai (Master Plan section 51).

const RADIUS := 22
const RADIUS_SMALL := 14


static func brand_logo(minimum_size: Vector2) -> TextureRect:
	var logo := TextureRect.new()
	logo.name = "BrandLogo"
	logo.texture = preload("res://assets/ui/logo_temp.png")
	logo.custom_minimum_size = minimum_size
	logo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	logo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	logo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	logo.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return logo

static var _theme: Theme = null
static var _title_font: Font = null
static var _bold_font: Font = null


static func title_font() -> Font:
	if _title_font == null:
		var fv := FontVariation.new()
		fv.base_font = ThemeDB.fallback_font
		fv.variation_embolden = 0.55
		fv.spacing_glyph = 1
		_title_font = fv
	return _title_font


static func bold_font() -> Font:
	if _bold_font == null:
		var fv := FontVariation.new()
		fv.base_font = ThemeDB.fallback_font
		fv.variation_embolden = 0.28
		_bold_font = fv
	return _bold_font


static func theme() -> Theme:
	if _theme != null:
		return _theme
	var t := Theme.new()
	t.default_font_size = 32
	t.default_font = bold_font()

	var normal := wood_box(Palette.WOOD_LIGHT, Palette.WOOD_DARK, 56)
	var hover := wood_box(Palette.jitter(Palette.WOOD_LIGHT, 3, 0.05), Palette.WOOD_DARK, 56)
	var pressed := wood_box(Palette.darken(Palette.WOOD_LIGHT, 0.10), Palette.WOOD, 56)
	var disabled := wood_box(Color("b9a891"), Color("8d8271"), 56)

	t.set_stylebox("normal", "Button", normal)
	t.set_stylebox("hover", "Button", hover)
	t.set_stylebox("pressed", "Button", pressed)
	t.set_stylebox("disabled", "Button", disabled)
	t.set_stylebox("focus", "Button", StyleBoxEmpty.new())
	t.set_color("font_color", "Button", Palette.PAPER)
	t.set_color("font_hover_color", "Button", Palette.WHITE)
	t.set_color("font_pressed_color", "Button", Palette.CREAM_DEEP)
	t.set_color("font_disabled_color", "Button", Color(0.85, 0.82, 0.78, 0.6))
	t.set_font_size("font_size", "Button", 34)
	t.set_font("font", "Button", bold_font())

	t.set_stylebox("panel", "PanelContainer", cream_box())
	t.set_stylebox("panel", "Panel", cream_box())

	t.set_color("font_color", "Label", Palette.INK)
	t.set_font_size("font_size", "Label", 32)

	t.set_stylebox("panel", "ProgressBar", StyleBoxEmpty.new())
	t.set_stylebox("background", "ProgressBar", wood_box(Palette.CREAM_DEEP, Palette.WOOD_LIGHT, 0, 0.4))
	t.set_stylebox("fill", "ProgressBar", wood_box(Palette.PINK, Palette.PINK_DARK, 0, 0.0))

	_theme = t
	return t


static func flat_box(
	bg: Color,
	border: Color = Color.TRANSPARENT,
	height: float = 0.0,
	border_width: int = 0,
	radius: float = RADIUS
) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.corner_radius_top_left = int(radius)
	sb.corner_radius_top_right = int(radius)
	sb.corner_radius_bottom_left = int(radius)
	sb.corner_radius_bottom_right = int(radius)
	if height > 0.0:
		sb.content_margin_top = height * 0.5
		sb.content_margin_bottom = height * 0.5
	sb.content_margin_left = 26
	sb.content_margin_right = 26
	if border_width > 0 and border.a > 0.0:
		sb.border_color = border
		sb.set_border_width_all(border_width)
	sb.shadow_color = Palette.SHADOW
	sb.shadow_size = 6
	sb.shadow_offset = Vector2(0, 3)
	return sb


static func wood_box(
	fill: Color,
	border: Color = Palette.WOOD_DARK,
	height: float = 0.0,
	alpha: float = 1.0
) -> StyleBoxFlat:
	var sb := flat_box(Color(fill.r, fill.g, fill.b, alpha), border, height, 5)
	sb.shadow_size = 8
	sb.shadow_offset = Vector2(0, 4)
	return sb


static func cream_box(alpha: float = 1.0) -> StyleBoxFlat:
	return flat_box(Color(Palette.PAPER.r, Palette.PAPER.g, Palette.PAPER.b, alpha), Palette.WOOD_LIGHT, 0.0, 4)


# --- factories -------------------------------------------------------------

static func label(
	text: String,
	size_px: int = 32,
	color: Color = Palette.INK,
	align: int = HORIZONTAL_ALIGNMENT_CENTER
) -> Label:
	var l := Label.new()
	l.text = text
	l.horizontal_alignment = align
	l.add_theme_font_size_override("font_size", size_px)
	l.add_theme_color_override("font_color", color)
	l.add_theme_font_override("font", bold_font())
	l.autowrap_mode = TextServer.AUTOWRAP_OFF
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l


static func title(text: String, size_px: int = 72, color: Color = Palette.WOOD_DARK) -> Label:
	var l := label(text, size_px, color)
	l.add_theme_font_override("font", title_font())
	return l


static func wrap_label(
	text: String,
	size_px: int = 30,
	color: Color = Palette.INK,
	align: int = HORIZONTAL_ALIGNMENT_CENTER
) -> Label:
	var l := label(text, size_px, color, align)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.custom_minimum_size = Vector2(0, 0)
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return l


static func button(
	text: String,
	size_px: int = 40,
	fill: Color = Palette.WOOD_LIGHT,
	border: Color = Palette.WOOD_DARK
) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(0, 88)
	b.add_theme_font_size_override("font_size", size_px)
	b.add_theme_stylebox_override("normal", wood_box(fill, border, 18))
	b.add_theme_stylebox_override("hover", wood_box(Palette.jitter(fill, 7, 0.06), border, 18))
	b.add_theme_stylebox_override("pressed", wood_box(Palette.darken(fill, 0.10), border, 18))
	b.add_theme_stylebox_override("disabled", wood_box(Color("b9a891"), Color("8d8271"), 18))
	b.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	b.add_theme_color_override("font_color", Palette.PAPER)
	b.add_theme_color_override("font_hover_color", Palette.WHITE)
	b.add_theme_color_override("font_pressed_color", Palette.CREAM_DEEP)
	b.add_theme_font_override("font", bold_font())
	b.focus_mode = Control.FOCUS_NONE
	return b


static func primary_button(text: String, size_px: int = 44) -> Button:
	var b := button(text, size_px, Palette.PINK, Palette.PINK_DARK)
	b.custom_minimum_size = Vector2(420, 112)
	return b


static func card(min_size: Vector2 = Vector2.ZERO) -> PanelContainer:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", cream_box())
	p.custom_minimum_size = min_size
	return p


static func spacer(min_size: Vector2) -> Control:
	var c := Control.new()
	c.custom_minimum_size = min_size
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return c


static func vbox(separation: int = 16) -> VBoxContainer:
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", separation)
	return v


static func hbox(separation: int = 16) -> HBoxContainer:
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", separation)
	return h


static func margin(all_sides: int) -> MarginContainer:
	var m := MarginContainer.new()
	m.add_theme_constant_override("margin_left", all_sides)
	m.add_theme_constant_override("margin_right", all_sides)
	m.add_theme_constant_override("margin_top", all_sides)
	m.add_theme_constant_override("margin_bottom", all_sides)
	return m


static func apply_root_theme(node: Control) -> void:
	node.theme = theme()


## Largest font size at or below [param base_size] that keeps [param text]
## inside [param max_width]. Stops at [param min_size] so long strings stay
## readable instead of being clipped mid-word.
static func fit_font_size(
	text: String,
	max_width: float,
	base_size: int,
	min_size: int = 10
) -> int:
	var font := bold_font()
	var size_px := base_size
	while size_px > min_size:
		if font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, size_px).x <= max_width:
			return size_px
		size_px -= 1
	return min_size


# --- decorative bits -------------------------------------------------------

static func sparkle_burst(parent: Control, at: Vector2, color: Color = Palette.WHITE, count: int = 10) -> void:
	for i in count:
		var angle := float(i) * TAU / float(count) + randf() * 0.4
		var dist := randf_range(50.0, 160.0)
		var dot := ColorRect.new()
		dot.color = color
		dot.custom_minimum_size = Vector2(10, 10)
		dot.size = Vector2(10, 10)
		dot.pivot_offset = Vector2(5, 5)
		dot.mouse_filter = Control.MOUSE_FILTER_IGNORE
		parent.add_child(dot)
		dot.position = at
		var tw := dot.create_tween()
		tw.set_parallel(true)
		tw.tween_property(dot, "position", at + Vector2(cos(angle), sin(angle)) * dist, 0.45)
		tw.tween_property(dot, "modulate:a", 0.0, 0.45)
		tw.tween_property(dot, "scale", Vector2(0.2, 0.2), 0.45)
		tw.chain().tween_callback(dot.queue_free)
