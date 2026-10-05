class_name ResourceBarArt
extends RefCounted

const FONT_SIZE := 36

static func draw_frame(canvas: Control, kind: String, plus: bool = false, square_plus: bool = false, pill_shape: bool = false) -> void:
	var extent := canvas.size
	var body := Rect2(Vector2(extent.y * .36, extent.y * .18), Vector2(extent.x - extent.y * .36, extent.y * .66))
	if pill_shape:
		body.position.y = extent.y*.14
		body.size.y = extent.y*.72
	canvas.draw_style_box(UIKit.flat_box(Color("fff0ca"), Color("c58b42"), 0, 3, int(body.size.y*.5 if pill_shape else extent.y*.30)), body)
	var icon: Texture2D
	if kind == "heart":
		icon = ResourceIconArt.texture("heart")
	elif kind == "coin":
		icon = TutorialArt.texture("gold_coin")
	else:
		icon = GameplaySkin.texture("star")
	var slot := Vector2.ONE * extent.y * .96
	# Equal visible height, preserving each icon's natural silhouette.
	var factor := extent.y * .86 / icon.get_height()
	var icon_size := icon.get_size() * factor
	var origin := Vector2(0, extent.y * .02) + (slot - icon_size) * .5
	canvas.draw_texture_rect(icon, Rect2(origin, icon_size), false)
	if plus:
		var radius := extent.y * .23
		var center := Vector2(extent.x - radius - 5, extent.y * .51)
		if square_plus:
			var box := Rect2(center-Vector2.ONE*radius, Vector2.ONE*radius*2)
			canvas.draw_style_box(UIKit.flat_box(Palette.LEAF, Palette.WOOD_DARK, 0, 3, radius*.4), box.grow(2))
		else:
			canvas.draw_circle(center, radius + 3, Palette.WOOD_DARK)
			canvas.draw_circle(center, radius, Palette.LEAF)
		canvas.draw_line(center - Vector2(radius * .48, 0), center + Vector2(radius * .48, 0), Palette.PAPER, 5, true)
		canvas.draw_line(center - Vector2(0, radius * .48), center + Vector2(0, radius * .48), Palette.PAPER, 5, true)
