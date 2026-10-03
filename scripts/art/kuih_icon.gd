class_name KuihIcon
extends Control

## Procedural placeholder art for every kuih.
##
## Final illustrated assets will drop into `res://assets/kuih/` and be assigned
## to [member KuihData.texture]; until then this draws each [enum KuihData.Shape]
## with a bold sticker outline so tiles stay readable at small sizes
## (Master Plan sections 14 and 51).
##
## Every shape owns a distinct silhouette - circle, slab, pyramid, diamond,
## flower, cluster, dome, nest, slices, block, dome-in-cup, ring - because the
## art rule is that a player must know the kuih from a tiny tile alone.
##
## Hard rule from the art bible: kuih stay food. No eyes, mouths, hands or feet.

const OUTLINE := Color("4a2c17")
const OUTLINE_WIDTH := 0.05
const SHADOW := Color(0.25, 0.15, 0.05, 0.18)

@export var kuih: KuihData = null:
	set(value):
		kuih = value
		queue_redraw()
@export var cell_ratio: float = 1.0
@export var show_outline: bool = true
## Slightly bigger drawing used for the Recipe Book and order chips.
@export var detail_level: int = 1


func _ready() -> void:
	# Only supply a default - callers routinely ask for a bigger icon and this
	# runs after they set one.
	if custom_minimum_size == Vector2.ZERO:
		custom_minimum_size = Vector2(64, 64)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(queue_redraw)


func set_kuih(value: KuihData) -> void:
	kuih = value


func _unit() -> Rect2:
	var side := minf(size.x, size.y) * cell_ratio
	var origin := Vector2((size.x - side) * 0.5, (size.y - side) * 0.5)
	return Rect2(origin, Vector2(side, side))


func _u(u: Rect2, x: float, y: float) -> Vector2:
	return u.position + Vector2(x * u.size.x, y * u.size.y)


func _draw() -> void:
	if kuih == null:
		return
	var rect := _unit()
	if kuih.texture != null:
		var texture_size := kuih.texture.get_size()
		var ratio := minf(rect.size.x / texture_size.x, rect.size.y / texture_size.y)
		var art_size := texture_size * ratio
		draw_texture_rect(kuih.texture, Rect2(rect.get_center() - art_size * 0.5, art_size), false)
		return
	# Soft ground shadow keeps every tile readable against the board.
	draw_circle(_u(rect, 0.5, 0.86), rect.size.x * 0.30, SHADOW)
	match kuih.shape:
		KuihData.Shape.ORB:
			_draw_onde_onde(rect)
		KuihData.Shape.LAYER_CAKE:
			_draw_layer_cake(rect)
		KuihData.Shape.PYRAMID:
			_draw_pyramid(rect)
		KuihData.Shape.LEAF_ROLL:
			_draw_leaf_roll(rect)
		KuihData.Shape.FLOWER_RING:
			_draw_flower_ring(rect)
		KuihData.Shape.BALL_RING:
			_draw_ball_cluster(rect)
		KuihData.Shape.PAPER_CUP:
			_draw_paper_cup(rect)
		KuihData.Shape.FLAKY:
			_draw_flaky(rect)
		KuihData.Shape.PICKLE:
			_draw_pickle(rect)
		KuihData.Shape.DARK_SLICE:
			_draw_dark_slice(rect)
		KuihData.Shape.LEAF_CUP:
			_draw_leaf_cup(rect)
		KuihData.Shape.FRIED_RING:
			_draw_fried_ring(rect)


# --- primitives ------------------------------------------------------------

func _disc(center: Vector2, radius: float, color: Color, outlined: bool = true) -> void:
	if show_outline and outlined:
		draw_circle(center, radius * (1.0 + OUTLINE_WIDTH * 2.0), OUTLINE)
	draw_circle(center, radius, color)


func _disc_plain(center: Vector2, radius: float, color: Color) -> void:
	draw_circle(center, radius, color)


func _blob(center: Vector2, radii: Vector2, color: Color, outlined: bool = true) -> void:
	if show_outline and outlined:
		draw_set_transform(center, 0.0, radii * (1.0 + OUTLINE_WIDTH * 2.0))
		draw_circle(Vector2.ZERO, 1.0, OUTLINE)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	draw_set_transform(center, 0.0, radii)
	draw_circle(Vector2.ZERO, 1.0, color)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _poly(points: PackedVector2Array, color: Color, outlined: bool = true, width: float = 1.0) -> void:
	if show_outline and outlined and points.size() >= 3:
		var closed := points.duplicate()
		closed.append(points[0])
		draw_polyline(closed, OUTLINE, maxf(2.0, width * OUTLINE_WIDTH * 20.0), true)
	draw_colored_polygon(points, color)


func _round_rect(rect: Rect2, radius: float, color: Color, outlined: bool = true, width: float = 1.0) -> void:
	if show_outline and outlined:
		draw_rect(rect.grow(radius * 0.7 + width * 2.0), OUTLINE)
	draw_rect(rect, color, true)


func _highlight(center: Vector2, radius: float) -> void:
	draw_circle(center, radius, Color(1, 1, 1, 0.55))


func _noise01(index: int, salt: int) -> float:
	var n := sin(float(index) * 12.9898 + float(salt) * 78.233) * 43758.5453
	n = n - floor(n)
	return n


# --- shapes ----------------------------------------------------------------

## Onde-onde: a green ball rolled in coconut. Circle silhouette.
func _draw_onde_onde(u: Rect2) -> void:
	var leaf := PackedVector2Array([
		_u(u, 0.05, 0.80), _u(u, 0.50, 0.70), _u(u, 0.95, 0.80),
		_u(u, 0.86, 0.95), _u(u, 0.14, 0.95),
	])
	_poly(leaf, Palette.LEAF_DARK, true, u.size.x * 0.022)

	var center := _u(u, 0.5, 0.44)
	var radius := u.size.x * 0.37
	_blob(center, Vector2(radius, radius * 1.02), kuih.color)
	# A darker leaf-pad ring frames the ball so green-on-green never happens.
	if show_outline:
		draw_arc(center, radius * 1.02, 0.0, TAU, 40, OUTLINE, radius * 0.10, true)
	var flakes := 14 if detail_level > 0 else 8
	for i in flakes:
		var a := _noise01(i, 3) * TAU
		var r := sqrt(_noise01(i, 7)) * radius * 0.80
		_disc_plain(center + Vector2(cos(a), sin(a)) * r, radius * (0.085 + _noise01(i, 11) * 0.05), kuih.detail)
	_highlight(center + Vector2(-radius * 0.36, -radius * 0.42), radius * 0.24)


## Kuih Lapis: a rectangular slab of stacked coloured layers.
func _draw_layer_cake(u: Rect2) -> void:
	var bands := [kuih.color, kuih.accent, kuih.detail, kuih.color]
	var left := 0.12
	var right := 0.88
	var top := 0.16
	var bottom := 0.80
	var band_h := (bottom - top) / float(bands.size())
	for i in bands.size():
		# Each layer is a hair narrower, which reads as a pressed stack.
		var inset := float(i) * 0.018
		var rect := Rect2(
			_u(u, left + inset, top + band_h * float(i)),
			Vector2((right - left - inset * 2.0) * u.size.x, band_h * u.size.y)
		)
		_round_rect(rect, u.size.x * 0.05, bands[i], true, u.size.x * 0.014)
	# leaf sliver peeking out underneath
	_poly(PackedVector2Array([
		_u(u, 0.06, 0.86), _u(u, 0.50, 0.78), _u(u, 0.94, 0.86), _u(u, 0.80, 0.97),
		_u(u, 0.20, 0.97),
	]), Palette.LEAF_DARK, true, u.size.x * 0.018)
	_highlight(_u(u, 0.32, 0.24), u.size.x * 0.075)


## Seri Muka: a pink custard pyramid standing in a banana leaf cup.
func _draw_pyramid(u: Rect2) -> void:
	# leaf cup
	_poly(PackedVector2Array([
		_u(u, 0.05, 0.66), _u(u, 0.95, 0.66), _u(u, 0.82, 0.97), _u(u, 0.18, 0.97),
	]), Palette.LEAF_DEEP, true, u.size.x * 0.026)
	_poly(PackedVector2Array([
		_u(u, 0.11, 0.68), _u(u, 0.89, 0.68), _u(u, 0.80, 0.90), _u(u, 0.20, 0.90),
	]), Palette.LEAF, false)
	# pyramid
	_poly(PackedVector2Array([
		_u(u, 0.5, 0.07), _u(u, 0.86, 0.70), _u(u, 0.14, 0.70),
	]), kuih.color, true, u.size.x * 0.026)
	_poly(PackedVector2Array([
		_u(u, 0.5, 0.07), _u(u, 0.86, 0.70), _u(u, 0.5, 0.70),
	]), Palette.darken(kuih.color, 0.12), false)
	# custard face
	_poly(PackedVector2Array([
		_u(u, 0.5, 0.14), _u(u, 0.72, 0.46), _u(u, 0.28, 0.46),
	]), kuih.detail, false)
	_disc_plain(_u(u, 0.5, 0.28), u.size.x * 0.055, Palette.GOLD)
	_highlight(_u(u, 0.34, 0.58), u.size.x * 0.05)


## Kuih Ketayap: a pandan leaf folded into a diamond parcel.
func _draw_leaf_roll(u: Rect2) -> void:
	var mid := _u(u, 0.5, 0.5)
	var r := u.size.x * 0.42
	var points := PackedVector2Array([
		mid + Vector2(0, -r), mid + Vector2(r, 0), mid + Vector2(0, r), mid + Vector2(-r, 0),
	])
	_poly(points, kuih.color, true, u.size.x * 0.026)
	# folded halves
	_poly(PackedVector2Array([
		mid + Vector2(0, -r), mid + Vector2(r, 0), mid + Vector2(0, r * 0.08),
	]), Palette.darken(kuih.color, 0.14), false)
	_poly(PackedVector2Array([
		mid + Vector2(0, -r * 0.86), mid + Vector2(-r * 0.16, 0), mid + Vector2(r * 0.72, 0),
	]), Palette.lighten(kuih.accent, 0.10), false)
	# glutinous filling peeking at the fold
	_poly(PackedVector2Array([
		_u(u, 0.44, 0.50), _u(u, 0.62, 0.62), _u(u, 0.36, 0.62),
	]), Palette.CREAM, false)
	draw_line(mid + Vector2(0, -r * 0.9), mid + Vector2(0, r * 0.9), Palette.LEAF_DEEP, maxf(2.0, u.size.x * 0.022), true)
	_highlight(_u(u, 0.36, 0.34), u.size.x * 0.06)


## Ang Ku Kueh: a tortoise-shell flower biscuit. Five rounded petals.
func _draw_flower_ring(u: Rect2) -> void:
	var center := _u(u, 0.5, 0.5)
	var petal := u.size.x * 0.20
	var orbit := u.size.x * 0.24
	var count := 5
	for i in count:
		var a := -PI * 0.5 + float(i) * TAU / float(count)
		_blob(center + Vector2(cos(a), sin(a)) * orbit, Vector2(petal, petal * 1.12), kuih.color)
	for i in count:
		var a := -PI * 0.5 + float(i) * TAU / float(count)
		_disc_plain(
			center + Vector2(cos(a), sin(a)) * (orbit + petal * 0.34),
			petal * 0.30,
			kuih.detail
		)
	_disc(center, u.size.x * 0.14, kuih.accent)
	_highlight(center + Vector2(-u.size.x * 0.05, -u.size.x * 0.06), u.size.x * 0.04)


## Vadai: a cluster of golden fritter balls.
func _draw_ball_cluster(u: Rect2) -> void:
	var balls := [Vector2(0.28, 0.68), Vector2(0.68, 0.66), Vector2(0.50, 0.34)]
	var radius := u.size.x * 0.215
	for i in balls.size():
		var p: Vector2 = balls[i]
		_disc(_u(u, p.x, p.y), radius, kuih.color)
	for i in balls.size():
		var p: Vector2 = balls[i]
		_disc_plain(_u(u, p.x, p.y) + Vector2(-radius * 0.30, -radius * 0.34), radius * 0.34, kuih.detail)
	# a couple of crisp flecks so it does not read as three dots
	draw_circle(_u(u, 0.36, 0.60), radius * 0.16, Palette.darken(kuih.accent, 0.05))
	draw_circle(_u(u, 0.62, 0.44), radius * 0.13, Palette.darken(kuih.accent, 0.05))


## Penyaram: a brown cake dome in a pleated paper cup.
func _draw_paper_cup(u: Rect2) -> void:
	var top_y := 0.56
	var top_left := _u(u, 0.08, top_y)
	var top_right := _u(u, 0.92, top_y)
	var bottom_right := _u(u, 0.79, 0.98)
	var bottom_left := _u(u, 0.21, 0.98)
	_poly(PackedVector2Array([top_left, top_right, bottom_right, bottom_left]), kuih.accent, true, u.size.x * 0.024)
	for i in range(1, 5):
		var t := float(i) / 5.0
		draw_line(
			top_left.lerp(top_right, t), bottom_left.lerp(bottom_right, t),
			Palette.darken(kuih.accent, 0.14), maxf(2.0, u.size.x * 0.022)
		)
	_blob(_u(u, 0.5, 0.44), Vector2(u.size.x * 0.40, u.size.x * 0.34), kuih.color)
	_highlight(_u(u, 0.34, 0.32), u.size.x * 0.075)


## Kuih Cina: a golden nest of fried pastry strands.
func _draw_flaky(u: Rect2) -> void:
	var center := _u(u, 0.5, 0.52)
	var width := maxf(3.0, u.size.x * 0.085)
	for i in 7:
		var a := float(i) * 0.44 - 0.6
		var r := u.size.x * (0.36 - float(i % 3) * 0.04)
		var pts := PackedVector2Array()
		for s in 12:
			var t := float(s) / 11.0 * TAU
			pts.append(center + Vector2(cos(t + a) * r, sin(t + a) * r * 0.80))
		draw_polyline(pts, Palette.darken(kuih.accent, 0.05) if i % 2 == 0 else kuih.color, width, true)
	_highlight(center + Vector2(-u.size.x * 0.11, -u.size.y * 0.13), u.size.x * 0.06)


## Acar: sliced cucumber pickle on a leaf.
func _draw_pickle(u: Rect2) -> void:
	_poly(PackedVector2Array([
		_u(u, 0.04, 0.80), _u(u, 0.50, 0.66), _u(u, 0.96, 0.80), _u(u, 0.50, 0.98),
	]), Palette.LEAF_DARK, true, u.size.x * 0.022)
	var slices := [Vector2(0.30, 0.42), Vector2(0.66, 0.36), Vector2(0.48, 0.70)]
	for i in slices.size():
		var p: Vector2 = slices[i]
		_blob(_u(u, p.x, p.y), Vector2(u.size.x * 0.25, u.size.x * 0.25), kuih.color)
		_disc_plain(_u(u, p.x, p.y), u.size.x * 0.085, kuih.detail)
	_poly(PackedVector2Array([
		_u(u, 0.70, 0.70), _u(u, 0.88, 0.80), _u(u, 0.72, 0.88),
	]), Palette.PINK_DARK)


## Dodol: a dense brown slice.
func _draw_dark_slice(u: Rect2) -> void:
	var rect := Rect2(_u(u, 0.10, 0.26), Vector2(u.size.x * 0.80, u.size.y * 0.56))
	_round_rect(rect, u.size.x * 0.10, kuih.color, true, u.size.x * 0.016)
	var swirl := PackedVector2Array()
	for s in 16:
		var t := float(s) / 15.0
		swirl.append(_u(u, 0.18 + t * 0.64, 0.44 + sin(t * PI * 2.0) * 0.07))
	draw_polyline(swirl, kuih.detail, maxf(3.0, u.size.x * 0.05), true)
	_highlight(_u(u, 0.30, 0.33), u.size.x * 0.065)


## Kuih Kukus: a soft flower cake set in a leaf cup.
func _draw_leaf_cup(u: Rect2) -> void:
	_poly(PackedVector2Array([
		_u(u, 0.05, 0.72), _u(u, 0.95, 0.72), _u(u, 0.82, 0.98), _u(u, 0.18, 0.98),
	]), kuih.accent, true, u.size.x * 0.024)
	var center := _u(u, 0.5, 0.44)
	var petal := u.size.x * 0.17
	var count := 6
	for i in count:
		var a := -PI * 0.5 + float(i) * TAU / float(count)
		_blob(center + Vector2(cos(a), sin(a)) * u.size.x * 0.19, Vector2(petal, petal), kuih.color)
	_disc(center, u.size.x * 0.14, kuih.detail)
	_disc_plain(center, u.size.x * 0.06, Palette.GOLD_PALE)
	_highlight(center + Vector2(-u.size.x * 0.07, -u.size.x * 0.09), u.size.x * 0.04)


## Kuih Goreng: a golden fried dough ring.
func _draw_fried_ring(u: Rect2) -> void:
	var center := _u(u, 0.5, 0.52)
	var radius := u.size.x * 0.31
	var thickness := u.size.x * 0.26
	if show_outline:
		draw_arc(center, radius, 0.0, TAU, 44, OUTLINE, thickness * (1.0 + OUTLINE_WIDTH * 2.0), true)
	draw_arc(center, radius, 0.0, TAU, 44, kuih.color, thickness, true)
	draw_arc(center, radius, PI * 1.05, PI * 1.75, 22, kuih.detail, thickness * 0.40, true)
	draw_arc(center, radius, -PI * 0.35, PI * 0.15, 14, kuih.detail, thickness * 0.22, true)
