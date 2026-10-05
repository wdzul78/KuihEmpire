class_name GameButton
extends RefCounted

const HEIGHT := 112
const FONT_SIZE := 38
static var _art: Dictionary = {}

static func artwork(role: String) -> Texture2D:
	if role in ["primary", "secondary"]:
		return ResultOverlay.artwork("button_green" if role == "primary" else "button_pink")
	var id := "button_red" if role == "danger" else "button_orange"
	if not _art.has(id):
		var atlas := AtlasTexture.new()
		atlas.atlas = load("res://assets/ui/results_v2/%s.png" % id)
		atlas.region = Rect2(20, 102, 2132, 498) if role == "danger" else Rect2(28, 102, 2115, 503)
		_art[id] = atlas
	return _art[id]

static func apply(button: Button, role: String = "back", font_size: int = FONT_SIZE) -> void:
	ButtonArt.apply(button, artwork(role))
	button.add_theme_font_size_override("font_size", font_size)
	button.add_theme_color_override("font_color", Palette.PAPER)
	button.add_theme_color_override("font_outline_color", Palette.WOOD_DARK)
	button.add_theme_constant_override("outline_size", 2)
	button.add_theme_stylebox_override("focus", UIKit.flat_box(Color.TRANSPARENT, Palette.GOLD, 0, 4, 36))
	button.custom_minimum_size.y = HEIGHT

static func create(caption: String, role: String = "back", font_size: int = FONT_SIZE) -> Button:
	var button := UIKit.button(caption, font_size)
	apply(button, role, font_size)
	return button
