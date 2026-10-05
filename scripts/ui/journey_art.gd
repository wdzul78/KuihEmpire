class_name JourneyArt
extends RefCounted

static func texture(id: String) -> Texture2D:
	var source: Texture2D = load("res://assets/ui/journey_v1/%s.png" % id)
	if id == "background":
		return source
	var atlas := AtlasTexture.new()
	atlas.atlas = source
	atlas.region = source.get_image().get_used_rect()
	return atlas

static func place(parent: Control, node: Control, rect: Rect2) -> Control:
	parent.add_child(node)
	node.anchor_left = rect.position.x
	node.anchor_top = rect.position.y
	node.anchor_right = rect.end.x
	node.anchor_bottom = rect.end.y
	return node

static func painted_button(art: Texture2D, caption: String, font_size: int = 36) -> Button:
	var button := UIKit.button(caption, font_size, Palette.LEAF)
	button.custom_minimum_size = Vector2.ZERO
	if art is AtlasTexture and "results_v1" in art.atlas.resource_path:
		ButtonArt.apply(button, art)
	else:
		for key in ["normal", "hover", "pressed", "disabled"]:
			var box := StyleBoxTexture.new()
			box.texture = art
			box.modulate_color = Color(.65, .65, .65) if key == "disabled" else Color(.88, .88, .88) if key == "pressed" else Color.WHITE
			button.add_theme_stylebox_override(key, box)
	return button

static func label(parent: Control, text: String, rect: Rect2, font_size: int, color: Color = Palette.WOOD_DARK) -> Label:
	var result := UIKit.label(text, font_size, color)
	result.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	place(parent, result, rect)
	return result

static func localized(ms: String, en: String) -> String:
	return en if SaveManager.get_setting("language", "en") == "en" else ms
