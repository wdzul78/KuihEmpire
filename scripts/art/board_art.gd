class_name BoardArt
extends RefCounted

## Procedural art for obstacles and special tiles.
##
## Classic Tapau, Dulang and Special Order use PNG artwork.
## Legacy placeholder art:
## Dulang = round golden tray, Special Order = crowned kuih.

const OUTLINE := Color("4a2c17")
const TAPAU_ART = preload("res://assets/specials/directional_v3/tapau_horizontal.png")
const TAPAU_VERTICAL_ART = preload("res://assets/specials/directional_v3/tapau_vertical_blue.png")
const DULANG_ART = preload("res://assets/specials/gold_v2/dulang.png")
const HANTAR_ART = preload("res://assets/specials/delivery_v1/pesanan_hantar.png")
static var _delivery_region := Rect2()
const ORDER_ART = preload("res://assets/specials/cartoon_v2/order.png")


static func special_texture(special: int) -> Texture2D:
	if special == BoardCell.Special.HANTAR:
		return HANTAR_ART
	if special == BoardCell.Special.TAPAU:
		return TAPAU_ART
	if special == BoardCell.Special.TAPAU_VERTICAL:
		return TAPAU_VERTICAL_ART
	if special == BoardCell.Special.DULANG:
		return DULANG_ART
	if special == BoardCell.Special.ORDER:
		return ORDER_ART
	return null


static func draw_delivery(canvas: CanvasItem, rect: Rect2) -> void:
	if _delivery_region.size == Vector2.ZERO:
		_delivery_region = Rect2(HANTAR_ART.get_image().get_used_rect())
	var fit := minf(rect.size.x / _delivery_region.size.x, rect.size.y / _delivery_region.size.y)
	var fitted := _delivery_region.size * fit
	canvas.draw_texture_rect_region(HANTAR_ART, Rect2(rect.position + (rect.size-fitted)*.5, fitted), _delivery_region)

static func draw_blocker(canvas: CanvasItem, rect: Rect2, kind: int, hp: int, max_hp: int) -> void:
	match kind:
		BlockerSpec.Kind.BANANA_LEAF:
			_draw_leaf(canvas, rect)
		BlockerSpec.Kind.FOOD_COVER:
			_draw_food_cover(canvas, rect, hp, max_hp)
		BlockerSpec.Kind.STEAMER:
			_draw_steamer(canvas, rect, hp, max_hp)
		BlockerSpec.Kind.STICKY_SYRUP:
			_draw_syrup(canvas, rect)
		BlockerSpec.Kind.PACKAGING_BOX:
			_draw_packaging_box(canvas, rect)
		BlockerSpec.Kind.EMPTY_TRAY:
			_draw_empty_tray(canvas, rect)


static func draw_special(canvas: CanvasItem, rect: Rect2, special: int) -> void:
	if special_texture(special) != null:
		return
	match special:
		BoardCell.Special.TAPAU:
			pass # The tile's icon draws the illustrated special.
		BoardCell.Special.TAPAU_VERTICAL:
			pass
		BoardCell.Special.DULANG:
			_draw_dulang(canvas, rect)
		BoardCell.Special.ORDER:
			_draw_crown(canvas, rect)


# --- helpers ---------------------------------------------------------------

static func _disc(canvas: CanvasItem, c: Vector2, r: float, col: Color, outline: bool = true) -> void:
	if outline:
		canvas.draw_circle(c, r * 1.08, OUTLINE)
	canvas.draw_circle(c, r, col)


static func _poly(canvas: CanvasItem, pts: PackedVector2Array, col: Color, outline: bool = true, w: float = 5.0) -> void:
	if outline and pts.size() >= 3:
		var closed := pts.duplicate()
		closed.append(pts[0])
		canvas.draw_polyline(closed, OUTLINE, w, true)
	canvas.draw_colored_polygon(pts, col)


# --- obstacles -------------------------------------------------------------

static func _draw_leaf(canvas: CanvasItem, r: Rect2) -> void:
	var inset := r.grow(-r.size.x * 0.12)
	var mid := inset.get_center()
	var half := inset.size.x * 0.5
	var tips := PackedVector2Array([
		mid + Vector2(0, -half * 1.05),
		mid + Vector2(half * 1.05, 0),
		mid + Vector2(0, half * 1.05),
		mid + Vector2(-half * 1.05, 0),
	])
	var closed := tips.duplicate()
	closed.append(tips[0])
	canvas.draw_colored_polygon(closed, OUTLINE)
	var inner := PackedVector2Array([
		mid + Vector2(0, -half * 0.88),
		mid + Vector2(half * 0.88, 0),
		mid + Vector2(0, half * 0.88),
		mid + Vector2(-half * 0.88, 0),
	])
	canvas.draw_colored_polygon(inner, Palette.LEAF_DARK)
	canvas.draw_line(inner[0], inner[2], Palette.LEAF_DEEP, maxf(2.0, r.size.x * 0.05), true)
	canvas.draw_line(inner[1], inner[3], Palette.LEAF_DEEP, maxf(2.0, r.size.x * 0.04), true)
	canvas.draw_circle(mid + Vector2(-half * 0.28, -half * 0.30), r.size.x * 0.09, Palette.LEAF_LIGHT)


static func _draw_food_cover(canvas: CanvasItem, r: Rect2, hp: int, max_hp: int) -> void:
	var inset := r.grow(-r.size.x * 0.16)
	var c := inset.get_center()
	var radius := inset.size.x * 0.5
	canvas.draw_circle(c, radius, OUTLINE)
	canvas.draw_circle(c, radius * 0.88, Palette.CREAM)
	canvas.draw_circle(c, radius * 0.66, Palette.WOOD_LIGHT)
	canvas.draw_arc(c, radius * 0.78, PI * 1.08, PI * 1.82, 22, Palette.GOLD, maxf(3.0, r.size.x * 0.07), true)
	canvas.draw_circle(c, radius * 0.26, Palette.WOOD_DARK)
	for i in maxi(0, max_hp - hp):
		canvas.draw_circle(
			c + Vector2(0, radius * 1.05 + float(i) * r.size.x * 0.13),
			r.size.x * 0.055,
			Palette.PINK_DARK
		)


static func _draw_steamer(canvas: CanvasItem, r: Rect2, hp: int, max_hp: int) -> void:
	var body := Rect2(r.position + r.size * 0.20, r.size * 0.60)
	_poly(canvas, PackedVector2Array([
		body.position + Vector2(body.size.x * 0.06, 0),
		body.position + Vector2(body.size.x * 0.94, 0),
		body.position + body.size,
		body.position,
	]), Palette.WOOD_LIGHT, true, r.size.x * 0.05)
	for i in 3:
		var y := body.position.y + body.size.y * (0.26 + float(i) * 0.24)
		canvas.draw_line(
			Vector2(body.position.x + body.size.x * 0.08, y),
			Vector2(body.position.x + body.size.x * 0.92, y),
			Palette.WOOD_DARK,
			maxf(2.0, r.size.x * 0.035),
			true
		)
	var lid := PackedVector2Array([
		body.position + Vector2(-body.size.x * 0.05, body.size.y * 0.06),
		body.position + Vector2(body.size.x * 0.5, -body.size.y * 0.12),
		body.position + Vector2(body.size.x * 1.05, body.size.y * 0.06),
	])
	_poly(canvas, lid, Palette.WOOD_PALE, true, r.size.x * 0.045)
	for i in maxi(0, max_hp - hp):
		canvas.draw_circle(
			body.position + Vector2(body.size.x * (0.32 + float(i) * 0.36), body.size.y * 0.62),
			r.size.x * 0.05,
			Palette.PINK_DARK
		)


static func _draw_syrup(canvas: CanvasItem, r: Rect2) -> void:
	var c := r.get_center()
	canvas.draw_circle(c, r.size.x * 0.50, OUTLINE)
	canvas.draw_circle(c, r.size.x * 0.44, Color(0.96, 0.68, 0.18, 0.88))
	canvas.draw_circle(c + Vector2(-r.size.x * 0.12, -r.size.y * 0.14), r.size.x * 0.14, Color(1, 1, 1, 0.42))
	for i in 3:
		var a := PI * 0.15 + float(i) * PI * 0.35
		var from := c + Vector2(cos(a), sin(a)) * r.size.x * 0.42
		var to := c + Vector2(cos(a), sin(a)) * r.size.x * 0.56
		canvas.draw_line(from, to, Color(0.96, 0.68, 0.18, 0.9), maxf(2.0, r.size.x * 0.09), true)


static func _draw_packaging_box(canvas: CanvasItem, r: Rect2) -> void:
	var body := Rect2(r.position + r.size * 0.16, r.size * 0.68)
	_poly(canvas, PackedVector2Array([
		body.position + Vector2(body.size.x * 0.10, 0),
		body.position + Vector2(body.size.x * 0.90, 0),
		body.position + body.size,
		body.position,
	]), Palette.PAPER, true, r.size.x * 0.055)
	# lid flap
	_poly(canvas, PackedVector2Array([
		body.position + Vector2(0, -body.size.y * 0.22),
		body.position + Vector2(body.size.x * 0.5, -body.size.y * 0.36),
		body.position + Vector2(body.size.x, -body.size.y * 0.22),
		body.position + Vector2(body.size.x, 0),
		body.position,
	]), Palette.CREAM_DEEP, true, r.size.x * 0.05)
	canvas.draw_circle(body.get_center(), body.size.x * 0.16, Palette.PINK_PALE)
	canvas.draw_circle(body.get_center(), body.size.x * 0.09, Palette.PINK)


static func _draw_empty_tray(canvas: CanvasItem, r: Rect2) -> void:
	var body := Rect2(r.position + r.size * 0.10, r.size * 0.80)
	_poly(canvas, PackedVector2Array([
		body.position,
		body.position + Vector2(body.size.x, 0),
		body.position + Vector2(body.size.x * 0.86, body.size.y),
		body.position + Vector2(body.size.x * 0.14, body.size.y),
	]), Palette.GOLD, true, r.size.x * 0.055)
	canvas.draw_rect(
		Rect2(body.position + Vector2(body.size.x * 0.12, body.size.y * 0.18), body.size * Vector2(0.76, 0.30)),
		Palette.GOLD_PALE
	)
	for i in 3:
		canvas.draw_circle(
			body.position + Vector2(body.size.x * (0.28 + float(i) * 0.22), body.size.y * 0.62),
			body.size.x * 0.055,
			Palette.CREAM
		)


# --- specials --------------------------------------------------------------

static func _draw_gift_box(canvas: CanvasItem, r: Rect2) -> void:
	var body := Rect2(r.position + r.size * 0.18, r.size * 0.62)
	_poly(canvas, PackedVector2Array([
		body.position + Vector2(body.size.x * 0.08, 0),
		body.position + Vector2(body.size.x * 0.92, 0),
		body.position + body.size,
		body.position,
	]), Palette.PINK, true, r.size.x * 0.055)
	canvas.draw_rect(
		Rect2(body.position + Vector2(body.size.x * 0.38, 0), Vector2(body.size.x * 0.24, body.size.y)),
		Palette.PINK_PALE
	)
	# bow
	var c := body.position + Vector2(body.size.x * 0.5, 0)
	canvas.draw_circle(c + Vector2(-body.size.x * 0.16, -body.size.y * 0.06), body.size.x * 0.14, Palette.PINK_PALE)
	canvas.draw_circle(c + Vector2(body.size.x * 0.16, -body.size.y * 0.06), body.size.x * 0.14, Palette.PINK_PALE)
	canvas.draw_circle(c + Vector2(0, -body.size.y * 0.02), body.size.x * 0.09, Palette.PINK_DARK)
	# sparkle
	_draw_sparkle(canvas, body.position + Vector2(body.size.x * 0.78, -r.size.y * 0.10), r.size.x * 0.10)


static func _draw_dulang(canvas: CanvasItem, r: Rect2) -> void:
	var c := r.get_center()
	canvas.draw_circle(c, r.size.x * 0.50, OUTLINE)
	canvas.draw_circle(c, r.size.x * 0.44, Palette.GOLD_DARK)
	canvas.draw_circle(c, r.size.x * 0.36, Palette.GOLD)
	canvas.draw_circle(c, r.size.x * 0.22, Palette.GOLD_PALE)
	canvas.draw_arc(c, r.size.x * 0.30, PI * 1.05, PI * 1.85, 20, Palette.CREAM, maxf(2.0, r.size.x * 0.05), true)
	_draw_sparkle(canvas, c + Vector2(r.size.x * 0.26, -r.size.x * 0.26), r.size.x * 0.11)


static func _draw_crown(canvas: CanvasItem, r: Rect2) -> void:
	var c := r.get_center()
	canvas.draw_circle(c, r.size.x * 0.48, Color(0.99, 0.87, 0.45, 0.55))
	canvas.draw_circle(c, r.size.x * 0.36, Palette.GOLD_PALE)
	var s := r.size.x
	var pts := PackedVector2Array([
		c + Vector2(-s * 0.22, s * 0.06),
		c + Vector2(-s * 0.22, -s * 0.18),
		c + Vector2(-s * 0.09, -s * 0.02),
		c + Vector2(0, -s * 0.24),
		c + Vector2(s * 0.09, -s * 0.02),
		c + Vector2(s * 0.22, -s * 0.18),
		c + Vector2(s * 0.22, s * 0.06),
	])
	_poly(canvas, pts, Palette.GOLD, true, s * 0.05)
	canvas.draw_rect(Rect2(c + Vector2(-s * 0.22, s * 0.06), Vector2(s * 0.44, s * 0.09)), Palette.GOLD_DARK)
	_draw_sparkle(canvas, c + Vector2(s * 0.30, -s * 0.24), s * 0.10)


static func _draw_sparkle(canvas: CanvasItem, c: Vector2, r: float) -> void:
	var pts := PackedVector2Array([
		c + Vector2(0, -r), c + Vector2(r * 0.32, -r * 0.32), c + Vector2(r, 0),
		c + Vector2(r * 0.32, r * 0.32), c + Vector2(0, r), c + Vector2(-r * 0.32, r * 0.32),
		c + Vector2(-r, 0), c + Vector2(-r * 0.32, -r * 0.32),
	])
	canvas.draw_colored_polygon(pts, Palette.WHITE)
