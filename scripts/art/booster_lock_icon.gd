class_name BoosterLockIcon
extends Control

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(queue_redraw)

func _draw() -> void:
	var side := minf(size.x, size.y) * .8
	var origin := (size - Vector2(side, side)) * .5
	var center := origin + Vector2(side * .5, side * .38)
	var outline := Color("514c47")
	var metal := Color("d8d6cf")
	draw_arc(center, side * .24, PI, TAU, 32, outline, side * .13, true)
	draw_arc(center, side * .24, PI, TAU, 32, metal, side * .065, true)
	var body := Rect2(origin + Vector2(side * .15, side * .36), Vector2(side * .7, side * .52))
	draw_style_box(UIKit.flat_box(Color("bab9b3"), outline, 0, 4, side * .07), body)
	draw_line(body.position + Vector2(side * .10, side * .08), body.position + Vector2(side * .58, side * .08), Color("efeee8"), side * .04, true)
	var key := origin + Vector2(side * .5, side * .58)
	draw_circle(key, side * .065, outline)
	draw_colored_polygon(PackedVector2Array([key, key + Vector2(-side * .05, side * .16), key + Vector2(side * .05, side * .16)]), outline)
