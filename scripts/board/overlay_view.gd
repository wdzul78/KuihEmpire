class_name OverlayView
extends Control

## Visual for an obstacle sitting on a board cell: leaf, food cover, steamer,
## syrup, packaging box or empty tray (Master Plan section 18).

var kind: int = BlockerSpec.Kind.BANANA_LEAF:
	set(value):
		kind = value
		queue_redraw()
var hp: int = 1:
	set(value):
		hp = value
		queue_redraw()
var max_hp: int = 1:
	set(value):
		max_hp = value
		queue_redraw()
var target_kuih: KuihData = null:
	set(value):
		target_kuih = value
		queue_redraw()
var progress: int = 0:
	set(value):
		progress = value
		queue_redraw()
var need: int = 0:
	set(value):
		need = value
		queue_redraw()


func _ready() -> void:
	# Covers must stay above opaque food sprites, including after a refill.
	z_index = 2
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	pivot_offset = size * 0.5


func is_target() -> bool:
	return BlockerSpec.is_target_kind(kind)


func _draw() -> void:
	var r := Rect2(Vector2.ZERO, size)
	BoardArt.draw_blocker(self, r, kind, hp, max_hp)
	if not is_target():
		if max_hp > 1:
			_draw_count(str(hp))
		return
	if need <= 0:
		return
	# Show the actual requested kuih inside the open container.
	if target_kuih != null and target_kuih.texture != null:
		var edge := minf(size.x, size.y) * .36
		var center := size * Vector2(.48, .63 if kind == BlockerSpec.Kind.PACKAGING_BOX else .5)
		BoardArt.draw_item_texture(self, Rect2(center - Vector2.ONE * edge * .5, Vector2.ONE * edge), target_kuih.texture)
	# progress pip strip along the bottom
	var bar := Rect2(r.size.x * 0.16, r.size.y * 0.86, r.size.x * 0.52, r.size.y * 0.05)
	draw_rect(bar.grow(1.0), Palette.WOOD_DARK)
	draw_rect(bar, Color(0.85, 0.82, 0.76, 0.7))
	var filled := bar.size.x * clampf(float(progress) / float(need), 0.0, 1.0)
	draw_rect(Rect2(bar.position, Vector2(filled, bar.size.y)), Palette.PINK)
	_draw_count(str(maxi(0, need - progress)))


func _draw_count(value: String) -> void:
	var font := get_theme_default_font()
	var font_size := maxi(12, roundi(size.x * .28))
	var width := font.get_string_size(value, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	var at := Vector2(size.x * .94 - width, size.y * .92)
	draw_string_outline(font, at, value, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, 4, Color("4a2c17"))
	draw_string(font, at, value, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color("fff7dd"))
