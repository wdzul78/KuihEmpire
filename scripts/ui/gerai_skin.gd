class_name GeraiSkin
extends RefCounted

## Painted gerai_v1 frames. StyleBoxTexture draws texture margins at 1:1, so each
## frame is resampled once to the scale its slot needs and cached.

const ROOT := "res://assets/ui/gerai_v1/"
## Slice points (left, top, right, bottom) in source pixels, from the asset manifest.
const SLICES := {
	"header_bar": [200, 90, 200, 100], "footer_bar": [250, 90, 250, 80], "name_plate": [240, 60, 240, 60],
	"next_hint": [330, 75, 140, 75], "task_row": [300, 60, 110, 60],
	"tab_active": [80, 32, 80, 32], "tab_idle": [80, 32, 80, 32],
	"price_button": [150, 44, 70, 44], "nav_button": [200, 60, 90, 60],
	"progress_track": [32, 16, 32, 16], "progress_fill": [32, 16, 32, 16],
	"list_panel": [300, 200, 300, 360], "complete_panel": [330, 300, 330, 250],
}
## The list panel's title plaque sits mid-top, so it is cut out of the stretchable
## frame and drawn as a fixed overlay instead.
const PLAQUE := Rect2i(236, 18, 553, 222)
static var _cache: Dictionary = {}

static func texture(key: String, scale: float = 1.0) -> Texture2D:
	var cache_key := "%s@%.3f" % [key, scale]
	if _cache.has(cache_key):
		return _cache[cache_key]
	var source := load(ROOT + key + ".png") as Texture2D
	if is_equal_approx(scale, 1.0) and key != "list_panel":
		_cache[cache_key] = source
		return source
	var image := source.get_image()
	if image.is_compressed():
		image.decompress()
	if key == "list_panel":
		image = image.duplicate()
		# Fill the plaque columns with a plain stretch of the frame's top edge.
		for y in PLAQUE.end.y + 4:
			var c := image.get_pixel(200, y)
			for x in range(PLAQUE.position.x, PLAQUE.end.x):
				image.set_pixel(x, y, c)
	image.resize(maxi(1, roundi(image.get_width() * scale)), maxi(1, roundi(image.get_height() * scale)), Image.INTERPOLATE_LANCZOS)
	var result := ImageTexture.create_from_image(image)
	_cache[cache_key] = result
	return result

static func plaque(scale: float) -> Texture2D:
	var key := "plaque@%.3f" % scale
	if not _cache.has(key):
		var image := (load(ROOT + "list_panel.png") as Texture2D).get_image()
		if image.is_compressed():
			image.decompress()
		image = image.get_region(PLAQUE)
		image.resize(roundi(PLAQUE.size.x * scale), roundi(PLAQUE.size.y * scale), Image.INTERPOLATE_LANCZOS)
		_cache[key] = ImageTexture.create_from_image(image)
	return _cache[key]

## 9-patch stylebox; content is (left, top, right, bottom) in screen pixels.
static func box(key: String, scale: float, content: Array = [0, 0, 0, 0]) -> StyleBoxTexture:
	var style := StyleBoxTexture.new()
	style.texture = texture(key, scale)
	var slices: Array = SLICES[key]
	var sides := [SIDE_LEFT, SIDE_TOP, SIDE_RIGHT, SIDE_BOTTOM]
	for i in 4:
		style.set_texture_margin(sides[i], roundf(slices[i] * scale))
		style.set_content_margin(sides[i], content[i])
	return style

## Applies one painted skin to every visual state of a button.
static func skin_button(button: Button, key: String, scale: float, content: Array = [0, 0, 0, 0]) -> void:
	var style := box(key, scale, content)
	for state in ["normal", "hover", "pressed", "focus", "disabled", "hover_pressed"]:
		button.add_theme_stylebox_override(state, style)

static func icon(key: String) -> TextureRect:
	var view := TextureRect.new()
	view.texture = load(ROOT + key + ".png")
	view.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	view.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	view.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return view

## Framed dialog with its title on the painted plaque, or on the red ribbon when
## celebrating. Returns panel, stack (content column), chrome and content_top; the
## caller places the panel. A celebration dialog must span screen_width so its
## ribbon keeps the painted proportions; extra height only grows the plain middle.
static func dialog(title: String, celebration: bool = false, screen_width: float = .95) -> Dictionary:
	var scale := screen_width * 1080.0 / 1280.0 if celebration else .72
	var content_top := 228.0 * scale if celebration else 212.0
	var side := 82.0 * scale if celebration else 58.0
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", box("complete_panel" if celebration else "list_panel", scale, [side, content_top, side, 79.0 * scale if celebration else 60.0]))
	var margin := UIKit.margin(10)
	panel.add_child(margin)
	var stack := UIKit.vbox(10)
	margin.add_child(stack)
	# Chrome is fitted to the content rect; its children reach back up over the frame.
	var chrome := Control.new()
	chrome.name = "PanelChrome"
	chrome.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(chrome)
	var label := UIKit.label(title, 40 if celebration else 36, Palette.PAPER)
	label.name = "PanelTitle"
	label.add_theme_color_override("font_outline_color", Color("7a1f12") if celebration else Palette.WOOD_DARK)
	label.add_theme_constant_override("outline_size", 10)
	label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.clip_text = true
	if celebration:
		# Title rides on the painted red ribbon.
		label.position = Vector2(330 * scale - side, 88 * scale - content_top)
		label.size = Vector2(620, 92) * scale
		chrome.add_child(label)
	else:
		var board := TextureRect.new()
		board.texture = plaque(.85)
		board.mouse_filter = Control.MOUSE_FILTER_IGNORE
		board.set_anchors_preset(Control.PRESET_CENTER_TOP)
		board.offset_left = -board.texture.get_width() * .5
		board.offset_right = board.texture.get_width() * .5
		board.offset_top = 13 - content_top
		board.offset_bottom = board.offset_top + board.texture.get_height()
		chrome.add_child(board)
		label.position = Vector2(48, 58)
		label.size = Vector2(board.texture.get_width() - 96, 92)
		board.add_child(label)
	return {"panel": panel, "stack": stack, "chrome": chrome, "content_top": content_top}

static func style_progress(bar: ProgressBar, height: float) -> void:
	var scale := height / 64.0
	bar.custom_minimum_size.y = height
	bar.add_theme_stylebox_override("background", box("progress_track", scale))
	var fill := box("progress_fill", scale)
	# Sit the candy fill inside the track's golden groove.
	fill.set_expand_margin_all(-roundf(5 * scale))
	bar.add_theme_stylebox_override("fill", fill)
