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

@export var dark_style: bool = false
@export var illustrated_style: bool = false
@export var uniform_bar_height: bool = false
@export var show_plus: bool = true
@export var square_plus: bool = false
@export var pill_shape: bool = false

@export var icon_size: float = 74.0:
	set(value):
		icon_size = value
		custom_minimum_size = Vector2(icon_size + 130.0, icon_size)
		queue_redraw()


func _ready() -> void:
	custom_minimum_size = Vector2.ZERO if uniform_bar_height else Vector2(icon_size + 130.0, icon_size)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(queue_redraw)


func _draw() -> void:
	if illustrated_style:
		ResourceBarArt.draw_frame(self, "coin", show_plus, square_plus, pill_shape)
		var font := UIKit.bold_font()
		var font_size := ResourceBarArt.FONT_SIZE
		var text_rect := Rect2(size.y * .98, 0, size.x - size.y * (1.57 if show_plus else 1.10), size.y)
		while font_size > 20 and font.get_string_size(str(amount), HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x > text_rect.size.x:
			font_size -= 1
		var baseline := (size.y - font.get_height(font_size)) * .5 + font.get_ascent(font_size)
		draw_string(font, Vector2(text_rect.position.x, baseline), str(amount), HORIZONTAL_ALIGNMENT_CENTER, text_rect.size.x, font_size, Palette.WOOD_DARK)
		return
	var font := UIKit.bold_font()
	var size_px := int(icon_size * 0.42)
	var c := Vector2(icon_size * 0.5, size.y * 0.5)
	var r := icon_size * 0.46
	# pill background
	var pill := Rect2(Vector2(0, c.y - r), Vector2(size.x - 8.0, r * 2.0))
	if dark_style:
		draw_style_box(UIKit.wood_box(Palette.WOOD_DARK, Palette.WOOD_LIGHT, 0), pill)
	else:
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
		Palette.PAPER if dark_style else Palette.INK
	)


func _pop() -> void:
	pivot_offset = size * 0.5
	scale = Vector2(1.12, 1.12)
	var tw := create_tween()
	tw.tween_property(self, "scale", Vector2.ONE, 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
