class_name CoinDisplay
extends Control

## Coin counter pill for the HUD and menus.

var amount: int = 0:
	set(value):
		if amount == value:
			return
		amount = value
		_pop()
		queue_redraw()

@export var icon_size: float = 74.0:
	set(value):
		icon_size = value
		custom_minimum_size = Vector2(icon_size + 130.0, icon_size)
		queue_redraw()


func _ready() -> void:
	custom_minimum_size = Vector2(icon_size + 130.0, icon_size)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _draw() -> void:
	var font := UIKit.bold_font()
	var size_px := int(icon_size * 0.42)
	var c := Vector2(icon_size * 0.5, size.y * 0.5)
	var r := icon_size * 0.46
	# pill background
	var pill := Rect2(Vector2(0, c.y - r), Vector2(size.x - 8.0, r * 2.0))
	draw_rect(pill, Palette.CREAM_DEEP)
	draw_rect(pill, Palette.WOOD_LIGHT, false, 4.0)
	# coin
	draw_circle(c, r * 0.94, Palette.WOOD_DARK)
	draw_circle(c, r * 0.84, Palette.COIN)
	draw_circle(c - Vector2(r * 0.28, r * 0.30), r * 0.30, Palette.GOLD_PALE)
	var text := str(amount)
	draw_string(
		font,
		Vector2(c.x + r * 0.9, c.y + size_px * 0.36),
		text,
		HORIZONTAL_ALIGNMENT_LEFT,
		-1,
		size_px,
		Palette.INK
	)


func _pop() -> void:
	pivot_offset = size * 0.5
	scale = Vector2(1.12, 1.12)
	var tw := create_tween()
	tw.tween_property(self, "scale", Vector2.ONE, 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
