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
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	pivot_offset = size * 0.5


func is_target() -> bool:
	return BlockerSpec.is_target_kind(kind)


func _draw() -> void:
	var r := Rect2(Vector2.ZERO, size)
	BoardArt.draw_blocker(self, r, kind, hp, max_hp)
	if not is_target():
		return
	if need <= 0:
		return
	# little reminder of which kuih this target wants
	if target_kuih != null:
		draw_circle(Vector2(r.size.x * 0.5, r.size.y * 0.36), r.size.x * 0.16, Palette.WOOD_DARK)
		draw_circle(Vector2(r.size.x * 0.5, r.size.y * 0.36), r.size.x * 0.13, target_kuih.color)
	# progress pip strip along the bottom
	var bar := Rect2(r.size.x * 0.16, r.size.y * 0.80, r.size.x * 0.68, r.size.y * 0.12)
	draw_rect(bar.grow(3.0), Palette.WOOD_DARK)
	draw_rect(bar, Color(0.85, 0.82, 0.76, 0.7))
	var filled := bar.size.x * clampf(float(progress) / float(need), 0.0, 1.0)
	draw_rect(Rect2(bar.position, Vector2(filled, bar.size.y)), Palette.PINK)
