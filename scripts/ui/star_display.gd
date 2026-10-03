class_name StarDisplay
extends Control

## Row of stars used on level results and the journey map.

var filled: int = 0:
	set(value):
		filled = clampi(value, 0, total)
		queue_redraw()
		_pulse()
var total: int = 3:
	set(value):
		total = maxi(1, value)
		custom_minimum_size = Vector2(star_size * float(total) + star_size * 0.5, star_size + star_size * 0.2)
		queue_redraw()
@export var star_size: float = 66.0:
	set(value):
		star_size = value
		custom_minimum_size = Vector2(star_size * float(total) + star_size * 0.5, star_size + star_size * 0.2)
		queue_redraw()


func _ready() -> void:
	custom_minimum_size = Vector2(star_size * float(total) + star_size * 0.5, star_size + star_size * 0.2)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _star_points(center: Vector2, radius: float) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in 10:
		var a := -PI * 0.5 + float(i) * PI / 5.0
		var r := radius if i % 2 == 0 else radius * 0.46
		pts.append(center + Vector2(cos(a), sin(a)) * r)
	return pts


func _draw() -> void:
	var spacing := star_size * 1.08
	var center_y := size.y * 0.5
	for i in total:
		var c := Vector2(spacing * (float(i) + 0.5), center_y)
		var pts := _star_points(c, star_size * 0.46)
		if i < filled:
			draw_colored_polygon(pts, Palette.STAR)
			draw_polyline(pts + PackedVector2Array([pts[0]]), Palette.WOOD_DARK, 4.0, true)
			draw_circle(c - Vector2(star_size * 0.12, star_size * 0.12), star_size * 0.09, Palette.GOLD_PALE)
		else:
			draw_colored_polygon(pts, Color(0.82, 0.78, 0.72, 0.45))
			draw_polyline(pts + PackedVector2Array([pts[0]]), Color(0.62, 0.56, 0.50, 0.55), 3.0, true)


func _pulse() -> void:
	if not is_inside_tree():
		return
	pivot_offset = size * 0.5
	var tw := create_tween()
	tw.tween_property(self, "scale", Vector2(1.08, 1.08), 0.18)
	tw.tween_property(self, "scale", Vector2.ONE, 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
