class_name BlockerPicture
extends Control

## A large, clear picture of one obstacle on a board tile, shown with Aina's
## explanation the first time the obstacle appears.

var kind: int = -1:
	set(value):
		kind = value
		queue_redraw()
var _clock := 0.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _process(delta: float) -> void:
	if visible:
		_clock += delta
		queue_redraw()


func _draw() -> void:
	if kind < 0:
		return
	var edge := minf(size.x, size.y)
	var bob := sin(_clock * 2.4) * edge * .015
	var card := Rect2((size - Vector2.ONE * edge) * .5 + Vector2(0, bob), Vector2.ONE * edge)
	# Glow ring, cream plate and wooden rim so it reads like a board tile.
	var pulse := .5 + .5 * sin(_clock * 3.0)
	draw_circle(card.get_center(), edge * (.50 + .02 * pulse), Color(1, .93, .62, .35 + .25 * pulse))
	var plate := StyleBoxFlat.new()
	plate.bg_color = Color("fff3d6")
	plate.border_color = Color("8a5a2b")
	plate.set_border_width_all(int(edge * .035))
	plate.set_corner_radius_all(int(edge * .16))
	plate.shadow_color = Color(0, 0, 0, .35)
	plate.shadow_size = int(edge * .04)
	plate.shadow_offset = Vector2(0, edge * .03)
	plate.anti_aliasing = true
	draw_style_box(plate, card.grow(-edge * .06))
	var cell := card.grow(-edge * .17)
	var kuih_rect := cell.grow(-edge * .07)
	if kind == BlockerSpec.Kind.STICKY_SYRUP:
		# A wide puddle with a smaller kuih sitting in it, so the syrup reads.
		# Four uneven quarter-blobs merge into one natural-looking spill.
		var quarter := cell.size * .5
		var spill := {Vector2i(0, 0): .95, Vector2i(1, 0): .8, Vector2i(0, 1): .85, Vector2i(1, 1): 1.0}
		GulaMelakaSyrup.draw_puddle(self, spill, func(pos: Vector2i) -> Rect2:
			return Rect2(cell.position + Vector2(pos) * quarter, quarter), _clock)
		kuih_rect = cell.grow(-edge * .15)
	var kuih := KuihLibrary.get_kuih(&"onde_onde")
	if not BlockerSpec.is_target_kind(kind) and kuih != null and kuih.texture != null:
		BoardArt.draw_item_texture(self, kuih_rect, kuih.texture)
	BoardArt.draw_blocker(self, cell, kind, 1, 1, _clock)
