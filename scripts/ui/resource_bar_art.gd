class_name ResourceBarArt
extends RefCounted

const FONT_SIZE := 36
static var _counter: Texture2D

static func counter_texture() -> Texture2D:
	if _counter == null:
		var source: Texture2D = load("res://assets/menu/resource_v5/counter.png")
		var atlas := AtlasTexture.new()
		atlas.atlas = source
		# Ignore the generated transparent padding and faint edge specks.
		atlas.region = Rect2(85, 145, 1975, 443)
		_counter = atlas
	return _counter

static func draw_frame(canvas: Control, kind: String, plus: bool = false, square_plus: bool = false, pill_shape: bool = false) -> void:
	var extent := canvas.size
	var body := Rect2(Vector2(extent.y * .36, extent.y * .18), Vector2(extent.x - extent.y * .36, extent.y * .66))
	if pill_shape:
		body.position.y = extent.y*.14
		body.size.y = extent.y*.72
	if pill_shape:
		canvas.draw_texture_rect(counter_texture(), body, false)
	else:
		var rounding := int(body.size.y*.5)
		canvas.draw_style_box(UIKit.flat_box(Color(0.20,0.09,0.03,.30),Color.TRANSPARENT,0,0,rounding),Rect2(body.position+Vector2(0,extent.y*.055),body.size))
		canvas.draw_style_box(UIKit.flat_box(Color("d99435"), Color("6b340e"), 0, 3, rounding), body.grow(3))
		canvas.draw_style_box(UIKit.flat_box(Color("fff0cc"), Color("ffcf74"), 0, 3, rounding-2), body)
		canvas.draw_style_box(UIKit.flat_box(Color.TRANSPARENT,Color("fffaf0"),0,2,rounding-4),body.grow(-5))
	var icon: Texture2D
	if kind == "heart":
		icon = ResourceIconArt.texture("heart")
	elif kind == "coin":
		icon = TutorialArt.texture("gold_coin")
	else:
		icon = ResourceIconArt.texture("star") if pill_shape else GameplaySkin.texture("star")
	var slot := Vector2.ONE * extent.y * .96
	# Equal visible height, preserving each icon's natural silhouette.
	var factor := extent.y * .94 / icon.get_height()
	var icon_size := icon.get_size() * factor
	var origin := Vector2(0, extent.y * .02) + (slot - icon_size) * .5
	canvas.draw_texture_rect(icon, Rect2(origin, icon_size), false)
	if plus and not pill_shape:
		var radius := extent.y * .23
		var center := Vector2(extent.x - radius - 5, extent.y * .51)
		if square_plus:
			var box := Rect2(center-Vector2.ONE*radius, Vector2.ONE*radius*2)
			canvas.draw_style_box(UIKit.flat_box(Palette.LEAF, Palette.WOOD_DARK, 0, 3, radius*.4), box.grow(2))
		else:
			canvas.draw_circle(center, radius + 5, Color("a26b20"))
			canvas.draw_circle(center, radius + 3, Color("ffdb79"))
			canvas.draw_circle(center, radius + 2, Palette.WOOD_DARK)
			canvas.draw_circle(center, radius, Color("35be38"))
			# Soft top sheen, kept clear of the plus arms so nothing crowds the sign.
			canvas.draw_arc(center, radius*.80, deg_to_rad(205), deg_to_rad(335), 16, Color("b8ff86"), radius*.12, true)
		var arm := radius * .50
		var stroke := maxf(5.0, radius * .30)
		for axis in [Vector2.RIGHT, Vector2.DOWN]:
			canvas.draw_line(center - axis * arm, center + axis * arm, Palette.PAPER, stroke, true)
			canvas.draw_circle(center - axis * arm, stroke * .5, Palette.PAPER)
			canvas.draw_circle(center + axis * arm, stroke * .5, Palette.PAPER)
