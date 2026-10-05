class_name JourneyStageDisc
extends Control

var fill := Palette.GOLD

class CompletedBadge extends Control:
	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		resized.connect(queue_redraw)
	func _draw() -> void:
		var c := size * .5
		var r := minf(size.x, size.y) * .47
		draw_circle(c, r, Palette.PAPER)
		draw_circle(c, r * .84, Palette.LEAF_DEEP)
		draw_polyline(PackedVector2Array([c + Vector2(-r * .46, 0), c + Vector2(-r * .08, r * .36), c + Vector2(r * .48, -r * .36)]), Palette.PAPER, 6, true)

static func button(caption: String, color: Color) -> Button:
	var result := UIKit.button(caption, 68)
	result.custom_minimum_size = Vector2.ZERO
	for state in ["normal", "hover", "pressed", "disabled"]:
		result.add_theme_stylebox_override(state, StyleBoxEmpty.new())
	var disc := JourneyStageDisc.new()
	disc.fill = color
	disc.show_behind_parent = true
	disc.mouse_filter = Control.MOUSE_FILTER_IGNORE
	disc.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	result.add_child(disc)
	return result

func _ready() -> void:
	resized.connect(queue_redraw)

func _draw() -> void:
	var center := size * .5
	var radius := minf(size.x, size.y) * .47
	draw_circle(center + Vector2(0, 8), radius, Color(.22, .12, .04, .32))
	draw_circle(center, radius, Palette.WOOD_DARK)
	draw_circle(center, radius * .95, Palette.WOOD_LIGHT)
	draw_circle(center, radius * .89, Palette.CREAM)
	draw_circle(center, radius * .84, Palette.WOOD_DARK)
	draw_circle(center, radius * .80, fill)
	for ring in range(24, 0, -1):
		var amount := float(24 - ring) / 24.0
		draw_circle(center - Vector2(radius * .10, radius * .10), radius * .68 * float(ring) / 24.0, fill.lerp(Palette.CREAM, amount * .18))
	draw_arc(center, radius * .73, PI * 1.12, PI * 1.65, 32, Color(1, .97, .80, .75), 6, true)
	draw_arc(center, radius * .73, .10, 1.1, 32, Color(.30, .15, .02, .20), 5, true)
