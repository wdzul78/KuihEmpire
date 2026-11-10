class_name GulaMelakaSyrup
extends RefCounted

## Gula melaka syrup: a glossy puddle that spreads UNDER the kuih and merges
## across neighbouring cells. Nothing is drawn over the kuih.
## The surface is a painted syrup texture (assets/blockers/syrup_v1), mapped in
## puddle space so overlapping cell blobs and bridges join without seams.

const OUTLINE := Color("7a3a10")
const RIM := Color("b8621f")
const INNER := Color("f6b85c")
const SURFACE := preload("res://assets/blockers/syrup_v1/syrup_texture.png")
## The texture never shows less than this many cells across, so small
## puddles keep a natural scale of swirls and bubbles.
const MIN_SPAN_CELLS := 2.6
const CORNER_STEPS := 6


## Every syrup cell with how "full" its puddle is (0..1), keyed by cell.
## `rect_of` maps a cell to its rectangle on `canvas`.
static func draw_puddle(canvas: CanvasItem, amounts: Dictionary, rect_of: Callable, _seconds: float = 0.0) -> void:
	if amounts.is_empty():
		return
	var any: Vector2i = amounts.keys()[0]
	var cell: float = (rect_of.call(any) as Rect2).size.x
	var bounds := rect_of.call(any) as Rect2
	for pos in amounts:
		bounds = bounds.merge(rect_of.call(pos))
	var span := maxf(maxf(bounds.size.x, bounds.size.y), cell * MIN_SPAN_CELLS)
	var mapping := Rect2(bounds.get_center() - Vector2.ONE * span * .5, Vector2.ONE * span)
	# Soft shadow, dark edge, warm rim, then the glossy syrup surface. Each layer
	# is the union of rounded cell blobs and bridges, so neighbours flow together.
	_layer(canvas, amounts, rect_of, cell * .13, Color(.30, .14, .03, .22), null, mapping, Vector2(0, cell * .05))
	_layer(canvas, amounts, rect_of, cell * .11, OUTLINE, null, mapping)
	_layer(canvas, amounts, rect_of, cell * .085, RIM, null, mapping)
	_layer(canvas, amounts, rect_of, cell * .05, Color.WHITE, SURFACE, mapping)


static func _layer(canvas: CanvasItem, amounts: Dictionary, rect_of: Callable, grow: float, color: Color, texture: Texture2D, mapping: Rect2, offset: Vector2 = Vector2.ZERO) -> void:
	for pos in amounts:
		var amount: float = amounts[pos]
		if amount <= .02:
			continue
		var rect: Rect2 = rect_of.call(pos)
		var size := (rect.size + Vector2.ONE * grow * 2.0) * amount
		var blob := Rect2(rect.get_center() - size * .5 + offset, size)
		if blob.size.x <= 2.0:
			continue
		# Near-square per cell, so the puddle follows the tile grid; only the
		# outer corners show this modest rounding.
		var radii := PackedFloat32Array([blob.size.x * .18, blob.size.x * .16, blob.size.x * .19, blob.size.x * .17])
		_fill(canvas, _rounded(blob, radii), color, texture, mapping)
		# Bridges to the right and downward join touching puddles.
		for step in [Vector2i.RIGHT, Vector2i.DOWN]:
			var other: Vector2i = pos + step
			if not amounts.has(other):
				continue
			var joined: float = minf(amount, amounts[other])
			if joined <= .02:
				continue
			var a := rect.get_center()
			var b := (rect_of.call(other) as Rect2).get_center()
			# Full thickness: merged runs keep straight edges along the tiles.
			var thickness := (rect.size.x + grow * 2.0) * joined
			var bridge := Rect2(a, b - a).abs().grow_individual(
				thickness * .5 if step == Vector2i.DOWN else 0.0,
				thickness * .5 if step == Vector2i.RIGHT else 0.0,
				thickness * .5 if step == Vector2i.DOWN else 0.0,
				thickness * .5 if step == Vector2i.RIGHT else 0.0)
			bridge.position += offset
			_fill(canvas, PackedVector2Array([bridge.position, Vector2(bridge.end.x, bridge.position.y), bridge.end, Vector2(bridge.position.x, bridge.end.y)]), color, texture, mapping)


## Same puddle-space UVs for every piece, so the texture lines up across them.
static func _fill(canvas: CanvasItem, points: PackedVector2Array, color: Color, texture: Texture2D, mapping: Rect2) -> void:
	if texture == null:
		canvas.draw_colored_polygon(points, color)
		return
	var uvs := PackedVector2Array()
	for point in points:
		uvs.append(((point - mapping.position) / mapping.size).clamp(Vector2.ZERO, Vector2.ONE))
	canvas.draw_colored_polygon(points, color, uvs, texture)


## Rounded rectangle outline; radii are top-left, top-right, bottom-right, bottom-left.
static func _rounded(rect: Rect2, radii: PackedFloat32Array) -> PackedVector2Array:
	var points := PackedVector2Array()
	var limit := minf(rect.size.x, rect.size.y) * .5
	var corners := [
		[Vector2(rect.position.x, rect.position.y), PI],
		[Vector2(rect.end.x, rect.position.y), PI * 1.5],
		[Vector2(rect.end.x, rect.end.y), 0.0],
		[Vector2(rect.position.x, rect.end.y), PI * .5],
	]
	for i in 4:
		var r := minf(radii[i], limit)
		var corner: Vector2 = corners[i][0]
		var inward := Vector2(r if i in [0, 3] else -r, r if i in [0, 1] else -r)
		var center := corner + inward
		var start: float = corners[i][1]
		for s in CORNER_STEPS + 1:
			var angle := start + PI * .5 * float(s) / CORNER_STEPS
			points.append(center + Vector2(cos(angle), sin(angle)) * r)
	return points
