class_name CharacterIcon
extends Control

## Procedural placeholder portraits for the cast.
##
## Aina keeps her hijab + apron look from the character board; customers vary by
## cloth colour, skin tone and headwear. Expressions follow the six poses in the
## design sheet so dialogue scenes feel alive without any animation frames.

enum Cast { AINA, IBU, FRIEND, RIVAL, CUSTOMER }
enum Mood { HAPPY, EXCITED, THINKING, SURPRISED, DETERMINED, CHEEKY }

const OUTLINE := Color("4a2c17")
const AINA_ART = preload("res://assets/characters/fullbody_v2/aina.png")

@export var cast: Cast = Cast.AINA:
	set(value):
		cast = value
		queue_redraw()
@export var customer: CustomerData = null:
	set(value):
		customer = value
		queue_redraw()
@export var expression: Mood = Mood.HAPPY:
	set(value):
		expression = value
		queue_redraw()
## 0 = portrait crop for queue chips, 1 = complete character including feet.
static var _regions: Dictionary = {}
@export_range(0, 1, 1) var framing: int = 1
## Optional foreground counter: conceal the lower body across the entire sprite,
## including portions outside the board's rounded side edges.
var occluding_board: Control = null
## Keep the complete head below active dialogue, even when wrapped text grows.
var dialogue_clearance: Control = null
var story_clearance: Control = null
var compact_portrait := false

func _clearance_y() -> float:
	if compact_portrait:
		return -INF
	var top := -INF
	for bubble in [dialogue_clearance, story_clearance]:
		if is_instance_valid(bubble) and bubble.is_visible_in_tree():
			# Use the resting rectangle so entrance animation cannot push the head up.
			# Side characters sit outside the order bubble's tail. Reserve its
			# rounded body, while story dialogue reserves the complete bubble.
			var body_ratio := .80 if bubble == dialogue_clearance else 1.0
			top = maxf(top, bubble.get_global_transform().origin.y + bubble.size.y * body_ratio + 14)
	return top - get_global_transform().origin.y

func artwork_rect(region: Rect2) -> Rect2:
	var fit := minf(size.x / region.size.x, size.y / region.size.y)
	var fitted := region.size * fit
	var destination := Rect2((size - fitted) * .5, fitted)
	destination.position.y = maxf(destination.position.y, _clearance_y())
	return destination


func _ready() -> void:
	# Only supply a default - callers routinely ask for a bigger portrait and
	# this runs after they set one.
	if custom_minimum_size == Vector2.ZERO:
		custom_minimum_size = Vector2(120, 120)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(queue_redraw)


func setup(p_cast: Cast, p_expression: Mood = Mood.HAPPY, p_customer: CustomerData = null) -> void:
	cast = p_cast
	expression = p_expression
	customer = p_customer


func _cloth() -> Color:
	match cast:
		Cast.AINA:
			return Palette.PINK
		Cast.IBU:
			return Color("7b9ec9")
		Cast.FRIEND:
			return Color("f0a93b")
		Cast.RIVAL:
			return Color("5aa469")
		Cast.CUSTOMER:
			return customer.cloth if customer != null else Palette.PINK
	return Palette.PINK


func _skin() -> Color:
	match cast:
		Cast.AINA:
			return Palette.SKIN
		Cast.IBU:
			return Color("d7a97e")
		Cast.FRIEND:
			return Color("c98d5f")
		Cast.RIVAL:
			return Color("e0b48c")
		Cast.CUSTOMER:
			return customer.skin if customer != null else Palette.SKIN
	return Palette.SKIN


func _headwear() -> int:
	if cast == Cast.CUSTOMER and customer != null:
		return customer.headwear
	return 0


func _draw() -> void:
	var side := minf(size.x, size.y)
	var origin := Vector2((size.x - side) * 0.5, (size.y - side) * 0.5)
	var u := Rect2(origin, Vector2(side, side))
	u.position.y = maxf(u.position.y, _clearance_y())
	var art: Texture2D = AINA_ART if cast == Cast.AINA else (customer.texture if cast == Cast.CUSTOMER and customer != null else null)
	if compact_portrait:
		draw_circle(size*.5,side*.50,Palette.WOOD_DARK)
		draw_circle(size*.5,side*.47,Palette.GOLD)
		draw_circle(size*.5,side*.42,Palette.CREAM)
		if art != null:
			_draw_compact_art(art, side)
		else:
			var face_size := Vector2.ONE * side * 1.18
			_draw_head(Rect2(size*.5 - Vector2(face_size.x*.5,face_size.y*.34),face_size))
		return
	if art != null:
		_draw_character(art)
		return

	_draw_body(u)
	_draw_head(u)


func _draw_compact_art(art: Texture2D, side: float) -> void:
	# Crop the face, then clip it to the medallion without modifying the asset.
	var region := Rect2(art.get_image().get_used_rect())
	if cast == Cast.AINA:
		region = Rect2(art.get_size()*Vector2(.30,.06),art.get_size()*Vector2(.50,.333))
	else:
		var crop_side := region.size.y*.38
		region = Rect2(Vector2(region.get_center().x-crop_side*.5,region.position.y),Vector2.ONE*crop_side)
	var points := PackedVector2Array()
	var uv := PackedVector2Array()
	for index in 64:
		var direction := Vector2.from_angle(TAU*float(index)/64.0)
		points.append(size*.5 + direction*side*.42)
		uv.append((region.position+(direction*.5+Vector2.ONE*.5)*region.size)/art.get_size())
	draw_polygon(points,PackedColorArray([Color.WHITE]),uv,art)


func _draw_character(art: Texture2D) -> void:
	var key := art.resource_path
	if not _regions.has(key):
		_regions[key] = Rect2(art.get_image().get_used_rect())
	var region: Rect2 = _regions[key]
	if framing == 0:
		region.size.y *= 0.38
		if compact_portrait:
			region.position.x += region.size.x*.025
			region.size.x = minf(region.size.x,region.size.y*1.10)
	var destination := artwork_rect(region)
	if is_instance_valid(occluding_board):
		var edge := occluding_board.get_global_rect().position.y - get_global_rect().position.y
		var visible_height := clampf(edge - destination.position.y, 0, destination.size.y)
		region.size.y *= visible_height / destination.size.y
		destination.size.y = visible_height
	if destination.size.y > 0:
		draw_texture_rect_region(art, destination, region)


func _draw_body(u: Rect2) -> void:
	var cx := u.position.x + u.size.x * 0.5
	var cloth := _cloth()
	# shoulders / blouse
	var shoulders := PackedVector2Array([
		Vector2(cx - u.size.x * 0.42, u.position.y + u.size.y),
		Vector2(cx - u.size.x * 0.30, u.position.y + u.size.y * 0.60),
		Vector2(cx, u.position.y + u.size.y * 0.52),
		Vector2(cx + u.size.x * 0.30, u.position.y + u.size.y * 0.60),
		Vector2(cx + u.size.x * 0.42, u.position.y + u.size.y),
	])
	var closed := shoulders.duplicate()
	closed.append(shoulders[0])
	draw_polyline(closed, OUTLINE, u.size.x * 0.030, true)
	draw_colored_polygon(shoulders, cloth)

	if framing == 1:
		# apron
		var apron := Rect2(
			Vector2(cx - u.size.x * 0.24, u.position.y + u.size.y * 0.68),
			Vector2(u.size.x * 0.48, u.size.y * 0.36)
		)
		draw_rect(apron.grow(u.size.x * 0.022), OUTLINE)
		draw_rect(apron, Palette.CREAM)
		draw_rect(
			Rect2(apron.position + Vector2(apron.size.x * 0.22, apron.size.y * 0.34), Vector2(apron.size.x * 0.56, apron.size.y * 0.40)),
			Palette.CREAM_DEEP
		)
		# strap
		draw_line(
			Vector2(cx - u.size.x * 0.14, u.position.y + u.size.y * 0.56),
			Vector2(cx - u.size.x * 0.20, u.position.y + u.size.y * 0.72),
			Palette.CREAM, u.size.x * 0.035
		)
		draw_line(
			Vector2(cx + u.size.x * 0.14, u.position.y + u.size.y * 0.56),
			Vector2(cx + u.size.x * 0.20, u.position.y + u.size.y * 0.72),
			Palette.CREAM, u.size.x * 0.035
		)
		# flower pin
		_draw_flower(Vector2(cx + u.size.x * 0.22, u.position.y + u.size.y * 0.62), u.size.x * 0.055)


func _draw_head(u: Rect2) -> void:
	var cx := u.position.x + u.size.x * 0.5
	var cy := u.position.y + u.size.y * 0.34
	var r := u.size.x * 0.25
	var skin := _skin()
	var cloth := _cloth()

	# hijab drape behind
	draw_circle(Vector2(cx, cy + r * 0.12), r * 1.34, Palette.darken(cloth, 0.10))
	# face
	draw_circle(Vector2(cx, cy), r * 1.08, OUTLINE)
	draw_circle(Vector2(cx, cy), r, skin)
	# hijab front wrap
	var wrap := PackedVector2Array([
		Vector2(cx - r * 1.16, cy + r * 0.22),
		Vector2(cx - r * 0.92, cy - r * 0.86),
		Vector2(cx, cy - r * 1.24),
		Vector2(cx + r * 0.92, cy - r * 0.86),
		Vector2(cx + r * 1.16, cy + r * 0.22),
		Vector2(cx + r * 0.60, cy - r * 0.52),
		Vector2(cx, cy - r * 0.34),
		Vector2(cx - r * 0.60, cy - r * 0.52),
	])
	draw_colored_polygon(wrap, cloth)
	# hijab opening around the face
	draw_arc(Vector2(cx, cy - r * 0.06), r * 0.94, PI * 0.12, PI * 0.88, 24, Palette.darken(cloth, 0.18), r * 0.16, true)

	match _headwear():
		1:
			_draw_songkok(u, cx, cy, r)
		2:
			_draw_hat(u, cx, cy, r, cloth)
		3:
			_draw_short_hair(u, cx, cy, r)

	_draw_face(u, cx, cy, r)


func _draw_face(u: Rect2, cx: float, cy: float, r: float) -> void:
	var eye_dx := r * 0.38
	var eye_y := cy - r * 0.06
	var eye_r := r * 0.15
	# brows
	var brow_col := Palette.INK
	draw_line(
		Vector2(cx - eye_dx - eye_r, eye_y - r * 0.34),
		Vector2(cx - eye_dx + eye_r, eye_y - r * 0.40),
		brow_col, maxf(1.5, r * 0.07)
	)
	draw_line(
		Vector2(cx + eye_dx - eye_r, eye_y - r * 0.40),
		Vector2(cx + eye_dx + eye_r, eye_y - r * 0.34),
		brow_col, maxf(1.5, r * 0.07)
	)

	var closed := expression == Mood.EXCITED
	var surprised := expression == Mood.SURPRISED
	var oval := r * (0.26 if surprised else 0.20)

	var eye_dirs: Array[float] = [-1.0, 1.0]
	for sign_dir in eye_dirs:
		var ex: float = cx + sign_dir * eye_dx
		if closed:
			draw_arc(Vector2(ex, eye_y), eye_r * 1.15, PI * 1.05, PI * 1.95, 16, Palette.INK, maxf(2.0, r * 0.085), true)
			continue
		draw_circle(Vector2(ex, eye_y), eye_r * 1.35, Palette.INK)
		draw_set_transform(Vector2(ex, eye_y), 0.0, Vector2(1.0, oval / eye_r))
		draw_circle(Vector2.ZERO, eye_r * 0.95, Palette.INK)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		draw_circle(Vector2(ex - eye_r * 0.30, eye_y - eye_r * 0.34), eye_r * 0.34, Palette.WHITE)

	# blush
	draw_circle(Vector2(cx - r * 0.66, cy + r * 0.30), r * 0.16, Color(1, 0.55, 0.60, 0.42))
	draw_circle(Vector2(cx + r * 0.66, cy + r * 0.30), r * 0.16, Color(1, 0.55, 0.60, 0.42))

	var mouth_y := cy + r * 0.36
	match expression:
		Mood.EXCITED:
			draw_arc(Vector2(cx, mouth_y - r * 0.06), r * 0.28, PI * 0.1, PI * 0.9, 18, Palette.INK, maxf(2.0, r * 0.08), true)
			draw_circle(Vector2(cx, mouth_y + r * 0.06), r * 0.14, Palette.PINK_DARK)
		Mood.SURPRISED:
			draw_circle(Vector2(cx, mouth_y), r * 0.16, Palette.PINK_DARK)
		Mood.THINKING:
			draw_arc(Vector2(cx - r * 0.05, mouth_y - r * 0.10), r * 0.20, PI * 0.15, PI * 0.85, 16, Palette.INK, maxf(2.0, r * 0.075), true)
		Mood.CHEEKY:
			draw_arc(Vector2(cx + r * 0.10, mouth_y - r * 0.04), r * 0.22, PI * 0.05, PI * 0.80, 16, Palette.INK, maxf(2.0, r * 0.075), true)
		Mood.DETERMINED:
			draw_line(Vector2(cx - r * 0.20, mouth_y), Vector2(cx + r * 0.20, mouth_y), Palette.INK, maxf(2.0, r * 0.075))
		_:
			draw_arc(Vector2(cx, mouth_y - r * 0.08), r * 0.24, PI * 0.12, PI * 0.88, 18, Palette.INK, maxf(2.0, r * 0.075), true)


func _draw_songkok(u: Rect2, cx: float, cy: float, r: float) -> void:
	var cap := PackedVector2Array([
		Vector2(cx - r * 1.02, cy - r * 0.60),
		Vector2(cx - r * 0.60, cy - r * 1.34),
		Vector2(cx + r * 0.60, cy - r * 1.34),
		Vector2(cx + r * 1.02, cy - r * 0.60),
	])
	draw_colored_polygon(cap, Palette.INK)
	draw_circle(Vector2(cx, cy - r * 1.42), r * 0.09, Palette.INK)


func _draw_hat(u: Rect2, cx: float, cy: float, r: float, cloth: Color) -> void:
	draw_circle(Vector2(cx, cy - r * 0.66), r * 1.34, Palette.INK)
	draw_circle(Vector2(cx, cy - r * 0.90), r * 0.94, Palette.lighten(cloth, 0.35))


func _draw_short_hair(u: Rect2, cx: float, cy: float, r: float) -> void:
	var hair := PackedVector2Array([
		Vector2(cx - r * 1.06, cy + r * 0.10),
		Vector2(cx - r * 0.94, cy - r * 0.94),
		Vector2(cx, cy - r * 1.26),
		Vector2(cx + r * 0.94, cy - r * 0.94),
		Vector2(cx + r * 1.06, cy + r * 0.10),
		Vector2(cx + r * 0.74, cy - r * 0.42),
		Vector2(cx - r * 0.74, cy - r * 0.42),
	])
	draw_colored_polygon(hair, Palette.INK)
	# spectacles
	var lens := r * 0.26
	draw_arc(Vector2(cx - r * 0.38, cy - r * 0.06), lens, 0.0, TAU, 20, Palette.INK, maxf(2.0, r * 0.06), true)
	draw_arc(Vector2(cx + r * 0.38, cy - r * 0.06), lens, 0.0, TAU, 20, Palette.INK, maxf(2.0, r * 0.06), true)
	draw_line(Vector2(cx - r * 0.12, cy - r * 0.06), Vector2(cx + r * 0.12, cy - r * 0.06), Palette.INK, maxf(2.0, r * 0.055))


func _draw_flower(center: Vector2, r: float) -> void:
	for i in 5:
		var a := -PI * 0.5 + float(i) * TAU / 5.0
		draw_circle(center + Vector2(cos(a), sin(a)) * r * 0.7, r * 0.55, Palette.PINK_LIGHT)
	draw_circle(center, r * 0.42, Palette.GOLD)
