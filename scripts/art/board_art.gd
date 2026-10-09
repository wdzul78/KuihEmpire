class_name BoardArt
extends RefCounted

## Procedural art for obstacles and special tiles.
##
## Classic Tapau, Dulang and Special Order use PNG artwork.
## Legacy placeholder art:
## Dulang = round golden tray, Special Order = crowned kuih.

const OUTLINE := Color("4a2c17")
const TAPAU_ART = preload("res://assets/specials/utensils_v1/spatula.png")
const TAPAU_VERTICAL_ART = preload("res://assets/specials/utensils_v1/fork.png")
const TAPAU_DIRECTION_ART = preload("res://assets/specials/directional_v8/direction_triangle.png")
const DULANG_SPARKLE = preload("res://assets/vfx/kenney/star_04.png")
const DULANG_RAYS = preload("res://assets/specials/gold_v3/rays.png")
const DULANG_ART = preload("res://assets/specials/badak_berendam_v1/badak_berendam.png")
const BADAK_IDLE_BOWL = preload("res://assets/specials/badak_idle_v1/bowl.png")
const BADAK_IDLE_BALLS = preload("res://assets/vfx/coconut_v1/balls.png")
const HANTAR_ART = preload("res://assets/specials/delivery_propeller_v3/rotor_red.png")
const HANTAR_BODY = preload("res://assets/specials/delivery_propeller_v3/body_claw.png")
static var _delivery_food_regions: Dictionary = {}
const ROLLER_ART = preload("res://assets/specials/utensils_v1/roller.png")
const ORDER_ART = preload("res://assets/specials/premium_sarawak_v1/kek_lapis_sarawak.png")
const BLOCKER_ART = {
	BlockerSpec.Kind.BANANA_LEAF: preload("res://assets/obstacles/banana_parcel_v1/banana_leaf.png"),
	BlockerSpec.Kind.FOOD_COVER: preload("res://assets/obstacles/cartoon_v1/food_cover.png"),
	BlockerSpec.Kind.STEAMER: preload("res://assets/obstacles/cartoon_v1/steamer.png"),
	BlockerSpec.Kind.STICKY_SYRUP: preload("res://assets/obstacles/cartoon_v1/sticky_syrup.png"),
	BlockerSpec.Kind.PACKAGING_BOX: preload("res://assets/obstacles/cartoon_v1/packaging_box.png"),
	BlockerSpec.Kind.EMPTY_TRAY: preload("res://assets/obstacles/cartoon_v1/empty_tray.png"),
}
static var _item_regions: Dictionary = {}


static func draw_item_texture(canvas: CanvasItem, rect: Rect2, art: Texture2D) -> void:
	if not _item_regions.has(art):
		_item_regions[art] = Rect2(art.get_image().get_used_rect())
	var source: Rect2 = _item_regions[art]
	if source.size.x <= 0 or source.size.y <= 0:
		return
	var fit := minf(rect.size.x / source.size.x, rect.size.y / source.size.y)
	var fitted := source.size * fit
	canvas.draw_texture_rect_region(art, Rect2(rect.get_center() - fitted * .5, fitted), source)


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


## Independent direction overlays: compact at rest, moving outward on activation.
## Explicit opaque bounds ignore almost-transparent padding without editing PNGs.
static func draw_directional(canvas: CanvasItem, rect: Rect2, vertical: bool, spread: float, arrow_alpha: float = 1.0, seconds: float = 0.0) -> void:
	var edge := minf(rect.size.x,rect.size.y)
	var axis := Vector2.UP if vertical else Vector2.LEFT
	var center := rect.get_center() + axis*sin(seconds*3.0)*edge*.025
	var tint := Color("54dfff") if vertical else Color("ffda36")
	# Separate streaks slide continuously behind the stationary utensil.
	for index in 4:
		var phase := fposmod(seconds*1.8+index*.27,1.0)
		var side := -1.0 if index%2 == 0 else 1.0
		var start := center-axis*edge*(phase*.34)+axis.orthogonal()*edge*(.23+float(index/2)*.08)*side
		var end := start-axis*edge*(.18+.12*spread)*(1-phase*.4)
		var alpha := (.30+.55*sin(phase*PI))*(.45+.55*arrow_alpha)
		canvas.draw_line(start,end,Color(tint,alpha*.22),edge*.12,true)
		canvas.draw_line(start,end,Color(tint,alpha),edge*.055,true)
		canvas.draw_line(start,end,Color("ffffe9",alpha),edge*.02,true)
	draw_utensil(canvas,center,edge*(.94 if vertical else .86),vertical,(-PI*.5 if vertical else PI))


static func draw_utensil(canvas: CanvasItem, at: Vector2, cell: float, vertical: bool, direction_angle: float, alpha: float = 1.0) -> void:
	var source := Rect2(880,789,468,1001) if vertical else Rect2(8,22,1240,1204)
	var art: Texture2D = TAPAU_VERTICAL_ART if vertical else TAPAU_ART
	var extent := source.size*(cell/maxf(source.size.x,source.size.y))
	# The upright fork and diagonal spatula each align with their travel axis.
	var rotation := direction_angle+(PI*.5 if vertical else PI*.75)
	canvas.draw_set_transform(at,rotation)
	canvas.draw_texture_rect_region(art,Rect2(-extent*.5,extent),source,Color(1,1,1,alpha))
	canvas.draw_set_transform(Vector2.ZERO)


static func draw_direction_marker(canvas: CanvasItem, at: Vector2, cell: float, angle: float, alpha: float = 1.0) -> void:
	var vertical := absf(sin(angle))>.5
	draw_utensil(canvas,at,cell*(.94 if vertical else .86),vertical,angle,alpha)


static func draw_roller(canvas: CanvasItem, at: Vector2, cell: float, angle: float = 0.0, alpha: float = 1.0, roll_phase: float = 0.0) -> void:
	# The pin's long axis stays perpendicular to its travel, like rolling dough.
	canvas.draw_set_transform(at,angle+PI*.75)
	canvas.draw_texture_rect_region(ROLLER_ART,Rect2(Vector2.ONE*-cell*.5,Vector2.ONE*cell),Rect2(40,66,1176,1120),Color(1,1,1,alpha))
	canvas.draw_set_transform(Vector2.ZERO)
	var direction := Vector2.from_angle(angle)
	var axle := direction.orthogonal()
	var shine_at := at+direction*sin(roll_phase)*cell*.14
	var shine := maxf(0.0,cos(roll_phase))*alpha
	canvas.draw_line(shine_at-axle*cell*.24,shine_at+axle*cell*.24,Color("fff1a8",shine*.40),cell*.09,true)
	canvas.draw_line(shine_at-axle*cell*.24,shine_at+axle*cell*.24,Color("ffffff",shine*.75),cell*.025,true)


static func draw_order(canvas: CanvasItem, rect: Rect2, seconds: float, activation: float = 0.0) -> void:
	var edge := minf(rect.size.x,rect.size.y)
	var center := rect.get_center()
	for front in [false,true]:
		if front:
			var source := Rect2(60,36,1200,1166)
			var extent := source.size*(edge*.88/maxf(source.size.x,source.size.y))
			var charge := sin(clampf(activation,0.0,1.0)*PI)
			# Keep the patterned cake intact while it charges; the old tiffin
			# separation would cut the cake into unrelated rectangular pieces.
			var turn := sin(seconds*8.0)*.055*charge
			var grow := 1.0+.10*charge
			canvas.draw_set_transform(center,turn,Vector2.ONE*grow)
			canvas.draw_texture_rect_region(ORDER_ART,Rect2(-extent*.5,extent),source)
			canvas.draw_set_transform(Vector2.ZERO)
			for glint in 3:
				var phase := seconds*2.0+glint*TAU/3.0
				var at := center+Vector2(cos(phase),sin(phase))*edge*.39
				var shine := .5+.5*sin(phase*1.7)
				var star_edge := edge*(.035+.025*shine+.035*charge)
				canvas.draw_texture_rect(DULANG_SPARKLE,Rect2(at-Vector2.ONE*star_edge*.5,Vector2.ONE*star_edge),false,Color(1,1,.85,.3+.5*shine))
		for arm in 2:
			var points := PackedVector2Array()
			for index in 20:
				var angle := seconds*2.6+arm*PI+float(index)*.035
				var is_front := sin(angle)>0
				if is_front == front:
					points.append(center+Vector2(cos(angle)*edge*.47,sin(angle)*edge*.20)+Vector2(0,(arm-.5)*edge*.24))
			if points.size()>1:
				canvas.draw_polyline(points,Color("ffcf26",.18),edge*.10,true)
				canvas.draw_polyline(points,Color("ffdd42",.9),edge*.043,true)
				canvas.draw_polyline(points,Color("fffbe6"),edge*.017,true)


## Keep the tray fixed while the separate sunburst turns behind it.
static func draw_dulang_animated(canvas: CanvasItem, rect: Rect2, seconds: float, charged: bool = false, flip_angle: float = 0.0) -> void:
	var edge := minf(rect.size.x,rect.size.y)
	var center := rect.get_center()
	var pulse := .5+.5*sin(seconds*(12.0 if charged else 3.2))
	var ray_edge := edge*(.98+.035*pulse)
	if charged:
		canvas.draw_set_transform(center,seconds*1.8)
		canvas.draw_texture_rect_region(DULANG_RAYS,Rect2(Vector2.ONE*-ray_edge*.5,Vector2.ONE*ray_edge),Rect2(24,22,1207,1201),Color(1,1,1,.55+.4*pulse))
	canvas.draw_set_transform(Vector2.ZERO)
	var source := Rect2(14,47,1224,1160)
	var extent := source.size*(edge*.90/maxf(source.size.x,source.size.y))
	var perspective := cos(flip_angle)
	# Flip around the tray's horizontal axis, rather than spin in the screen plane.
	canvas.draw_set_transform(center,0.0,Vector2(1.0,perspective))
	if charged or not is_zero_approx(flip_angle):
		canvas.draw_texture_rect_region(DULANG_ART,Rect2(-extent*.5,extent),source)
	else:
		canvas.draw_texture_rect_region(BADAK_IDLE_BOWL,Rect2(-extent*.5,extent),source)
		# Individual balls rise in sequence, orbit into their final places,
		# settle, wiggle together, then sink back into the coconut milk.
		var phase := fposmod(seconds,6.3)
		var rotation := TAU*smoothstep(.0,2.6,phase)
		var wiggle := 0.0
		if phase >= 3.2 and phase < 4.1:
			var t := (phase-3.2)/.9
			wiggle = sin(t*TAU*2)*sin(t*PI)*.12
		var slot := BADAK_IDLE_BALLS.get_size()/Vector2(4,2)
		var order := [1,2,4,5,3,0,6]
		var bowl_center := center+Vector2(0,-edge*.055)
		for index in 7:
			var rise := smoothstep(index*.16,index*.16+.38,phase)
			var sink := smoothstep(4.5+index*.08,4.95+index*.08,phase)
			var visibility := rise*(1.0-sink)
			if visibility <= .001:
				continue
			var angle := -PI*.5+index*TAU/6.0+rotation+wiggle
			var offset := Vector2(cos(angle)*edge*.23,sin(angle)*edge*.19) if index < 6 else Vector2.ZERO
			var at := bowl_center+offset+Vector2(0,edge*.06*(1.0-visibility))
			var ball_edge := edge*.245*lerpf(.45,1.0,visibility)
			var id: int = order[index]
			var region := Rect2(Vector2(id%4,id/4)*slot,slot)
			canvas.draw_set_transform(at,wiggle*.5)
			canvas.draw_texture_rect_region(BADAK_IDLE_BALLS,Rect2(Vector2.ONE*-ball_edge*.5,Vector2.ONE*ball_edge),region,Color(1,1,1,visibility))

	canvas.draw_set_transform(Vector2.ZERO)
	# Moving rim glints brighten and fade independently of the rotating rays.
	if not charged:
		return
	for index in 4:
		var angle := seconds*.9+index*TAU/4.0
		var at := center+Vector2(cos(angle)*edge*.36,sin(angle)*edge*.26*perspective)
		var shine := .5+.5*sin(seconds*4.0+index*1.7)
		var star_edge := edge*(.065+.07*shine)
		canvas.draw_texture_rect(DULANG_SPARKLE,Rect2(at-Vector2.ONE*star_edge*.5,Vector2.ONE*star_edge),false,Color(1,1,.8,.35+.65*shine))


static func draw_delivery(canvas: CanvasItem, rect: Rect2, angle: float = 0.0, flying: bool = false, payload: Texture2D = null) -> void:
	var edge := minf(rect.size.x,rect.size.y)
	var center := rect.get_center()
	if flying:
		var body_source := Rect2(118,80,782,1330)
		var body_size := Vector2(edge*.38,edge*.65)
		var body_at := center+Vector2(-body_size.x*.5,-edge*.12)
		if payload != null:
			if not _delivery_food_regions.has(payload):
				_delivery_food_regions[payload] = Rect2(payload.get_image().get_used_rect())
			var source: Rect2 = _delivery_food_regions[payload]
			var food_size := source.size * (edge*.29/maxf(source.size.x,source.size.y))
			canvas.draw_texture_rect_region(payload,Rect2(center+Vector2(0,edge*.39)-food_size*.5,food_size),source)
		canvas.draw_texture_rect_region(HANTAR_BODY,Rect2(body_at,body_size),body_source)
		center.y -= edge*.18
	# Rotate around the actual hub, rather than the PNG canvas centre.
	var fit := edge/1220.0
	var source := Rect2(38,88,1172,1046)
	var hub := Vector2(625,680)
	canvas.draw_set_transform(center,angle,Vector2(1,.42) if flying else Vector2.ONE)
	canvas.draw_texture_rect_region(HANTAR_ART,Rect2((source.position-hub)*fit,source.size*fit),source)
	canvas.draw_set_transform(Vector2.ZERO)

static func draw_blocker(canvas: CanvasItem, rect: Rect2, kind: int, hp: int, max_hp: int) -> void:
	if kind == BlockerSpec.Kind.BANANA_LEAF:
		draw_item_texture(canvas,rect,BLOCKER_ART[kind])
		return
	if BLOCKER_ART.has(kind):
		draw_item_texture(canvas, rect.grow(-minf(rect.size.x, rect.size.y) * .05), BLOCKER_ART[kind])
		return
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

static func _draw_leaf_pack(canvas: CanvasItem, rect: Rect2) -> void:
	var edge := minf(rect.size.x,rect.size.y)
	var at := rect.position
	var points := PackedVector2Array([at+Vector2(.10,.06)*edge,at+Vector2(.90,.06)*edge,at+Vector2(.97,.94)*edge,at+Vector2(.03,.94)*edge])
	canvas.draw_colored_polygon(points,Color("246d25"))
	var border := points.duplicate()
	border.append(points[0])
	canvas.draw_polyline(border,Color("164b21"),edge*.035,true)
	canvas.draw_colored_polygon(PackedVector2Array([points[0],points[1],at+Vector2(.50,.52)*edge]),Color("69ab32"))
	canvas.draw_colored_polygon(PackedVector2Array([points[3],points[2],at+Vector2(.50,.48)*edge]),Color("438f29"))
	for line in range(1,9):
		var y := edge*(.10+line*.087)
		canvas.draw_line(at+Vector2(edge*.13,y),at+Vector2(edge*.87,y-edge*.02),Color("b8d764",.20),edge*.009,true)
	canvas.draw_line(at+Vector2(.08,.92)*edge,at+Vector2(.50,.50)*edge,Color("b4dd66"),edge*.017,true)
	canvas.draw_line(at+Vector2(.92,.92)*edge,at+Vector2(.50,.50)*edge,Color("1c5921"),edge*.025,true)
	# Two pale ties and a small knot make the rectangular parcel readable.
	canvas.draw_line(at+Vector2(.35,.08)*edge,at+Vector2(.35,.92)*edge,Color("d2df90"),edge*.028,true)
	canvas.draw_line(at+Vector2(.66,.08)*edge,at+Vector2(.66,.92)*edge,Color("d2df90"),edge*.028,true)
	canvas.draw_circle(at+Vector2(.66,.51)*edge,edge*.035,Color("eff1b1"))

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
