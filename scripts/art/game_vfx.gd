class_name GameVfx
extends Control

const ANIMATION_PACE = preload("res://scripts/gameplay/animation_pace.gd")

## One bounded, input-transparent canvas. Inherits pause and dies with its owner.
const MAX_PARTICLES := 240
const MAX_EFFECTS := 48
const SPARKLE := preload("res://assets/vfx/kenney/star_04.png")
const GLOW := preload("res://assets/vfx/kenney/light_02.png")
const COCONUT = preload("res://scripts/art/coconut_art.gd")
const BLUE_SPLASH = preload("res://assets/vfx/badak_combine_v1/blue_splash.png")
const SELOROT_UNWRAP = preload("res://assets/vfx/selorot_unwrap_v1/unwrap_sheet.png")
const SELOROT_TRAVEL := .38
const SELOROT_LIFE := .76
const KETUPAT_ART = preload("res://assets/vfx/ketupat_raya_v1/ketupat.png")
const KETUPAT_SEQUENCE = preload("res://assets/vfx/ketupat_raya_v2/unwrap_sheet.png")
const KARIPAP_SEQUENCE = preload("res://assets/vfx/karipap_oxygen_v1/burst_sheet.png")
const KARIPAP_HOLD := .48
const KARIPAP_RELEASE := .58
const KETUPAT_TRAVEL := .16
const KETUPAT_RAYA_HOLD := 2.20
const KETUPAT_COMBO_HOLD := .85
const KETUPAT_COMBO_EDGE := 1.60
const KETUPAT_RELEASE := .64
static var _ketupat_body: AtlasTexture

static func ketupat_body() -> Texture2D:
	if _ketupat_body == null:
		_ketupat_body = AtlasTexture.new()
		_ketupat_body.atlas = KETUPAT_ART
		_ketupat_body.region = Rect2(165,470,850,800)
	return _ketupat_body

const SOLAR_ENERGY = preload("res://assets/vfx/pisang_solar_v1/energy.png")
const SOLAR_FLARE = preload("res://assets/vfx/pisang_solar_v1/flare.png")
const SOLAR_FRITTERS = preload("res://assets/vfx/pisang_solar_v1/fritters.png")
const SEPiT_GUST = preload("res://assets/vfx/sepit_gust_v1/gust_sheet.png")
const ROYAL_CAKE = preload("res://assets/specials/kek_lapis_diraja_v1/kek_lapis_diraja.png")
static var _gust_frames: SpriteFrames
const ORDER_CHAIN_COLORS := [Color("ffda36"),Color("54dcff"),Color("fc79dc"),Color("9af46b"),Color("b692ff"),Color("ff9870"),Color("69f0d5"),Color("ec7474")]
var _order_chain_index := 0
var _order_origin_colors: Dictionary = {}
const ROYAL_WAVE_TIME := .75

static func royal_wave_radius(at: Vector2, bounds: Rect2, cell: float) -> float:
	var radius := 0.0
	for corner in [bounds.position,bounds.end,Vector2(bounds.end.x,bounds.position.y),Vector2(bounds.position.x,bounds.end.y)]:
		radius = maxf(radius,at.distance_to(corner))
	return radius + cell*.4

func begin_order_chain() -> void:
	_order_chain_index = 0
	_order_origin_colors.clear()

func order_origin_color(at: Vector2) -> Color:
	return _order_origin_colors.get(at,ORDER_CHAIN_COLORS[0])

func royal_cake_bomb(at: Vector2, cell: float, bounds: Rect2, direction: Vector2) -> void:
	_effect("royal_cake_bomb",at,Vector2.ZERO,Color("ffe36c"),cell,2.30)
	effects.back()["bounds"] = bounds
	effects.back()["orbit_direction"] = direction

func _draw_royal_cake_bomb(e: Dictionary) -> void:
	var age: float = e.age
	var cell: float = e.width
	var direction: Vector2 = e.orbit_direction
	if age < .86:
		var front := 0 if COCONUT.orbit_position(e.a,cell,age,0,direction).y >= e.a.y else 1
		for index in [1-front,front]:
			var trail := PackedVector2Array()
			for i in 16:
				trail.append(COCONUT.orbit_position(e.a,cell,maxf(0,age-(15-i)*.008),index,direction))
			draw_polyline(trail,Color(1,.78,.18,.55),cell*.09,true)
			draw_polyline(trail,Color(1,.98,.75,.90),cell*.025,true)
			var at := COCONUT.orbit_position(e.a,cell,age,index,direction)
			COCONUT.sprite(self,BoardArt.ORDER_ART,at,cell*1.12,1.0-smoothstep(.72,.86,age))
	if age >= .76:
		var reveal := smoothstep(.76,1.00,age)
		var fade := 1.0-smoothstep(1.40,1.65,age)
		var pulse := 1.0+.04*sin(age*24.0)*smoothstep(1.00,1.36,age)
		_glow(e.a,cell*4.0*reveal,Color(1,.84,.28,.40*fade))
		COCONUT.sprite(self,ROYAL_CAKE,e.a,cell*2.8*lerpf(.20,1.0,reveal)*pulse,fade,sin(age*12)*.018)
		for i in 6:
			var phase := age*2.0+i*TAU/6.0
			_star(e.a+Vector2(cos(phase),sin(phase))*cell*1.5,cell*.14,Color(1,1,.8,fade),phase)
	if age >= 1.38:
		var travel := clampf((age-1.38)/ROYAL_WAVE_TIME,0.0,1.0)
		var fade := 1.0-smoothstep(2.10,2.30,age)
		var bounds: Rect2 = e.bounds
		var radius := royal_wave_radius(e.a,bounds,cell)*travel
		for ring in 3:
			var base := radius-ring*cell*.34
			if base <= 0:
				continue
			var ripple := PackedVector2Array()
			for point in 129:
				var theta := float(point)*TAU/128.0
				var wobble := cell*.065*sin(theta*10.0-age*18.0+ring*.7)*minf(1.0,travel*5)
				ripple.append(e.a+Vector2.from_angle(theta)*(base+wobble))
			var alpha := fade*(1.0-ring*.23)
			draw_polyline(ripple,Color(1,.67,.10,alpha*.25),cell*.32,true)
			draw_polyline(ripple,Color(1,.87,.35,alpha),cell*.10,true)
			draw_polyline(ripple,Color(1,1,.88,alpha),cell*.025,true)
		for i in 24:
			var phase := i*TAU/24.0
			_star(e.a+Vector2.from_angle(phase)*radius,cell*.16,Color(1,.9,.5,fade),phase)

func pisang_solar(at: Vector2, cell: float, bounds: Rect2) -> void:
	_effect("pisang_solar",at,Vector2.ZERO,Color.WHITE,cell,1.25)
	effects.back()["bounds"] = bounds

func _draw_pisang_solar(e: Dictionary) -> void:
	var age: float = e.age*1.32
	var cell: float = e.width
	var fade := 1.0-smoothstep(1.15,1.65,age)
	var grow := smoothstep(0,.3,age)
	var slot := SOLAR_ENERGY.get_size()/Vector2(2,2)
	var frame := int(age*18)%4
	var extent := Vector2.ONE*cell*4.2*lerpf(.55,1.0,grow)
	draw_texture_rect_region(SOLAR_ENERGY,Rect2(e.a-extent*.5,extent),Rect2(Vector2(frame%2,frame/2)*slot,slot),Color(1,1,1,fade))
	for bolt in 6:
		var angle := bolt*TAU/6.0+age*.7
		var path := PackedVector2Array()
		for step in 7:
			var theta := angle+float(step)*.09
			var radius := cell*(1.35+float(step)*.10+.12*sin(age*45+step*2+bolt))
			path.append(e.a+Vector2.from_angle(theta)*radius)
		draw_polyline(path,Color(1,.85,.10,fade),cell*.055,true)
		draw_polyline(path,Color(1,1,.85,fade),cell*.018,true)
	COCONUT.sprite(self,SOLAR_FRITTERS,e.a,cell*1.55*lerpf(.5,1,grow),fade,sin(age*45)*.018)
	if age >= .65:
		var travel := smoothstep(.65,1.10,age)
		var bounds: Rect2 = e.bounds
		var cover := bounds.size.length()*2.0
		COCONUT.sprite(self,SOLAR_FLARE,e.a,lerpf(cell*.8,cover,travel),fade*.90)
		var wave_radius := lerpf(cell*.4,cover*.5,travel)
		draw_arc(e.a,wave_radius,0,TAU,72,Color(1,.82,.12,fade*(1-travel)),cell*.10,true)
		draw_arc(e.a,wave_radius,0,TAU,72,Color(1,1,.85,fade*(1-travel)),cell*.025,true)
	COCONUT.sprite(self,SOLAR_FRITTERS,e.a,cell*3.2*lerpf(.5,1,grow),fade,sin(age*45)*.018)
var particles: Array[Dictionary] = []
var effects: Array[Dictionary] = []
var clock := 0.0

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_process(false)

func reset() -> void:
	begin_order_chain()
	for child in get_children():
		if child.has_meta("karipap_effect") or child is SepitFlight or child.has_meta("sepit_gust") or child.has_meta("ketupat_effect") or child.has_meta("pisang_effect"):
			child.queue_free()
	particles.clear()
	effects.clear()
	set_process(false)
	queue_redraw()

func _effect(kind: String, a: Vector2, b: Vector2, color: Color, width: float, life: float, delay: float = 0.0) -> void:
	if effects.size() >= MAX_EFFECTS:
		effects.pop_front()
	effects.append({"kind": kind, "a": a, "b": b, "color": color, "width": width, "life": life, "age": -delay})
	set_process(true)

func burst(at: Vector2, color: Color, count: int = 12, radius: float = 80.0, confetti: bool = false) -> void:
	for i in mini(count, MAX_PARTICLES - particles.size()):
		var angle := randf() * TAU
		var speed := randf_range(radius * 1.2, radius * 2.5)
		particles.append({"at": at, "velocity": Vector2.from_angle(angle) * speed,
			"color": color, "age": 0.0, "life": randf_range(.45, .85) if not confetti else randf_range(1.2, 2.0),
			"radius": randf_range(5, 12), "angle": angle, "confetti": confetti,
			"shape": i % 3})
	set_process(true)

func line_clear(a: Vector2, b: Vector2, cell: float, color: Color = Color("ffe38a"), powered: bool = false) -> void:
	_effect("beam", a, b, color, cell * (.16 if powered else .055), .50)
	if powered:
		burst(a,color,5,cell*.35)
	else:
		burst((a + b) * .5, color, 8, cell * .7)


## One bounded batch gives every cleared item a gold glow and colored fragments,
## including a full 10x10 wipe without hitting the shared particle pool cap.
func kuih_dissolve(items: Array[Dictionary], cell: float, delay: float = .08) -> void:
	if items.is_empty():
		return
	_effect("kuih_dissolve", Vector2.ZERO, Vector2.ZERO, Color.WHITE, cell, .70, delay)
	effects.back()["items"] = items.duplicate(true)


func special_formation(at: Vector2, points: PackedVector2Array, cell: float, kind: int) -> void:
	var color := Color("a9f56b")
	match kind:
		BoardCell.Special.TAPAU_VERTICAL: color = Color("65d9ff")
		BoardCell.Special.DULANG: color = Color("ffd966")
		BoardCell.Special.ORDER: color = Color("efb0ff")
		BoardCell.Special.HANTAR: color = Color("ff9688")
	_effect("special_formation", at, Vector2.ZERO, color, cell, .28)
	effects.back()["points"] = points


func _draw_special_formation(effect: Dictionary) -> void:
	var cell: float = effect.width
	var gather := smoothstep(.08, .22, effect.age)
	var fade := 1.0 - smoothstep(.22, .28, effect.age)
	var pulse := sin(clampf(effect.age / .10, 0, 1) * PI * .5)
	for point in effect.points:
		var at: Vector2 = point.lerp(effect.a, gather)
		_match_glow(at, cell * (1.05 - gather * .45), pulse * fade)
		for sign_value in [-1, 1]:
			var offset := Vector2(sign_value * cell * .24, -sign_value * cell * .16) * (1.0-gather)
			_star(at + offset, cell * .24, Color("fff6d7", pulse * fade), effect.age * 2)
	_match_glow(effect.a, cell * (1.0 + gather * .65), gather * fade)


## Light-only gradient: the stock glow texture has dark translucent pixels.
## Use pale yellow layers so match light cannot shade the slot underneath.
func _match_glow(at: Vector2, edge: float, intensity: float) -> void:
	for layer in range(14, 0, -1):
		var fraction := float(layer) / 14.0
		var color := Color("fff18a").lerp(Color("ffffe5"), 1.0-fraction)
		color.a = intensity * (.025 + .075 * (1.0-fraction))
		draw_circle(at, edge * .5 * fraction, color)
	draw_circle(at, edge * .14, Color("fffed5", intensity * .45))


func _draw_kuih_dissolve(effect: Dictionary) -> void:
	var t: float = clampf((effect.age - .10) / (effect.life - .10), 0, 1)
	var cell: float = effect.width
	var fade := 1.0 - smoothstep(.12, 1.0, t)
	for index in effect.items.size():
		var item: Dictionary = effect.items[index]
		var glow := sin(clampf(effect.age / .08, 0, 1) * PI * .5) * (1.0 - smoothstep(.18, .42, effect.age))
		_match_glow(item.at, cell * 1.30, glow * 1.20)
		if effect.age < .10:
			continue
		# Staggered directions/speeds fill a cloud rather than a thin ring.
		var fragments := clampi(960 / maxi(1, effect.items.size()), 8, 40)
		for spark in fragments:
			var tint: Color = item.get("color", Color("ffbd27")).lerp(Color("fff4b8"), .45)
			if spark % 3 == 0:
				tint = Color("fff07a")
			if spark % 4 == 0:
				tint = Color("fffce3")
			tint.a = fade
			var angle: float = spark * 2.39996323
			var reach: float = .30 + float(spark % 5) * .17
			var distance := cell * (.08 + reach * (1.0 - pow(1.0-t, 2)))
			var at: Vector2 = item.at + Vector2.from_angle(angle) * distance
			at.y -= cell * .12 * t * t
			var edge := cell * (.18 if spark % 3 == 0 else .125) * (1.0-t*.65)
			if spark % 3 == 0:
				_star(at, edge * 1.8, tint, angle + t)
			else:
				draw_set_transform(at, angle + t * 3)
				draw_colored_polygon(PackedVector2Array([
					Vector2(-edge*.5,-edge*.25), Vector2(edge*.25,-edge*.45),
					Vector2(edge*.5,edge*.25), Vector2(-edge*.25,edge*.5)]), tint)
				draw_set_transform(Vector2.ZERO)

func scoop(at: Vector2, cell: float) -> void:
	_effect("scoop", at, at - Vector2(0, cell * 1.3), Color("fff1ad"), cell * .55, .55)
	burst(at, Color("fff0bd"), 10, cell * .6)


func tapau_lane(a: Vector2, b: Vector2, cell: float, color: Color) -> void:
	_effect("beam",a,b,color,cell*.96,.42)
	effects.back()["tapau"] = true
	effects.back()["cell"] = cell
	burst(a,color,5,cell*.35)

func shuffle(bounds: Rect2, cell: float) -> void:
	_effect("swirl", bounds.get_center(), Vector2.ZERO, Color("b7ef77"), bounds.size.x * .43, .75)
	burst(bounds.get_center(), Color("ffe7a0"), 18, cell * 1.4)

func special(at: Vector2, kind: int, affected: PackedVector2Array, cell: float) -> void:
	if kind == BoardCell.Special.TAPAU_VERTICAL:
		column_sweep(at,affected,cell,false)
		return
	if kind == BoardCell.Special.DULANG:
		dulang_burst(at, affected, cell)
		return
	if kind == BoardCell.Special.ORDER:
		order_electric(at, affected, cell)
		return
	var color := Color("ffda36") if kind == BoardCell.Special.TAPAU or kind == BoardCell.Special.TAPAU_VERTICAL else Color("ffca62")
	if kind == BoardCell.Special.TAPAU_VERTICAL:
		color = Color("55cfff")
	_effect("ring", at, Vector2.ZERO, color, cell * (1.45 if kind == BoardCell.Special.DULANG else .65), .55)
	_effect("flash", at, Vector2.ZERO, color, cell * 1.8, .35)
	burst(at, color, 22, cell * 1.4)
	if kind == BoardCell.Special.TAPAU or kind == BoardCell.Special.TAPAU_VERTICAL:
		_effect("tapau_slots",at,Vector2.ZERO,color,cell,.64)
		effects.back()["points"] = affected
		effects.back()["vertical"] = kind == BoardCell.Special.TAPAU_VERTICAL
		var low := at
		var high := at
		for p in affected:
			low = low.min(p)
			high = high.max(p)
		if kind == BoardCell.Special.TAPAU:
			tapau_lane(at,Vector2(low.x-cell*.45,at.y),cell,color)
			tapau_lane(at,Vector2(high.x+cell*.45,at.y),cell,color)
		else:
			tapau_lane(at,Vector2(at.x,low.y-cell*.45),cell,color)
			tapau_lane(at,Vector2(at.x,high.y+cell*.45),cell,color)
	else:
		for p in affected:
			if kind == BoardCell.Special.ORDER:
				_effect("ribbon", at, p, Color("ffb5cd"), cell * .10, .65)
			_effect("tile", p, Vector2.ZERO, color, cell * .88, .55)
			burst(p, color, 3, cell * .45)

## Generated leaf frames are repeated along the actual cleared column.
## Pisang uses the same bounded footprint with three luminous clearing lanes.
func column_sweep(at: Vector2, affected: PackedVector2Array, cell: float, crispy: bool) -> void:
	_effect("crispy_column" if crispy else "selorot_unwrap",at,Vector2.ZERO,Color("ffe6a3"),cell,SELOROT_LIFE)
	effects.back()["points"] = affected
	burst(at,Color("ffe6a3"),10,cell*.65)

func pisang_crispy(at: Vector2, cell: float) -> void:
	_effect("pisang_crispy",at,Vector2.ZERO,Color("ffd95c"),cell,.95)
	var graphic := TextureRect.new()
	graphic.name = "PisangCrispyForeground"
	graphic.texture = BoardArt.PISANG_ART
	graphic.z_index = 60
	graphic.mouse_filter = Control.MOUSE_FILTER_IGNORE
	graphic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	graphic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	graphic.set_meta("pisang_effect",effects.back())
	add_child(graphic)
	_update_karipap_foregrounds()
	_update_pisang_foregrounds()

func _update_pisang_foregrounds() -> void:
	for child in get_children():
		if not child.has_meta("pisang_effect"):
			continue
		var effect: Dictionary = child.get_meta("pisang_effect")
		var age: float = effect.age
		if age >= float(effect.life) or not effects.has(effect):
			child.queue_free()
			continue
		var reveal := lerpf(.35,1.0,smoothstep(0,.16,age))
		var extent := Vector2.ONE*float(effect.width)*2.0*reveal
		child.size = extent
		child.pivot_offset = extent*.5
		child.position = effect.a-extent*.5
		child.rotation = sin(age*16)*.045
		child.modulate.a = 1.0-smoothstep(.52,.95,age)

func ketupat_appear(at: Vector2, cell: float, dramatic: bool = false, board_size: Vector2 = Vector2.ZERO) -> void:
	var hold := KETUPAT_RAYA_HOLD if dramatic else KETUPAT_COMBO_HOLD
	_effect("ketupat_appear",at,Vector2.ZERO,Color("d7f379"),cell,hold+KETUPAT_RELEASE)
	var effect: Dictionary = effects.back()
	effect["dramatic"] = dramatic
	var margin := Vector2.ONE*cell*(1.65 if dramatic else .85)
	effect["display_at"] = at.clamp(margin,board_size-margin) if board_size.x > margin.x*2 and board_size.y > margin.y*2 else at
	var graphic := TextureRect.new()
	graphic.name = "KetupatForeground"
	graphic.z_index = 60
	graphic.mouse_filter = Control.MOUSE_FILTER_IGNORE
	graphic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	graphic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	graphic.set_meta("ketupat_effect",effect)
	graphic.texture = KETUPAT_ART
	var sequence := TextureRect.new()
	sequence.name = "UnwrapSequence"
	sequence.mouse_filter = Control.MOUSE_FILTER_IGNORE
	sequence.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	sequence.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	sequence.modulate.a = 0
	graphic.add_child(sequence)
	add_child(graphic)
	_update_ketupat_foregrounds()
	burst(at,Color("ffec93"),16,cell*.8)

func _update_ketupat_foregrounds() -> void:
	for child in get_children():
		if not child.has_meta("ketupat_effect"):
			continue
		var effect: Dictionary = child.get_meta("ketupat_effect")
		var age: float = effect.age
		if age >= float(effect.life) or not effects.has(effect):
			child.queue_free()
			continue
		var cell: float = effect.width
		var dramatic: bool = effect.dramatic
		var hold := KETUPAT_RAYA_HOLD if dramatic else KETUPAT_COMBO_HOLD
		var center: Vector2 = effect.display_at
		var extent := Vector2.ONE*cell*(3.15 if dramatic else KETUPAT_COMBO_EDGE)
		var sequence: TextureRect = child.get_node("UnwrapSequence")
		if age < hold:
			if dramatic:
				var drop := clampf(age/.22,0,1)
				var landing := maxf(0,age-.22)
				var bounce := sin(landing*32)*exp(-landing*9)*.12 if age >= .22 else 0.0
				extent *= lerpf(1.65,1.0,drop*drop)+bounce
				center.y -= cell*.85*(1-drop)*(1-drop)
				center.x += sin(landing*64)*cell*.11*exp(-landing*2.3) if age >= .22 else 0.0
				child.rotation = sin(landing*48)*.18*exp(-landing*2.0) if age >= .22 else -.13*(1-drop)
			else:
				extent *= lerpf(.70,1.0,smoothstep(0,.10,age))
		else:
			var frame := clampi(int((age-hold)/KETUPAT_RELEASE*8),0,7)
			var atlas := AtlasTexture.new()
			atlas.atlas = KETUPAT_SEQUENCE
			var slot := KETUPAT_SEQUENCE.get_size()/Vector2(4,2)
			atlas.region = Rect2(Vector2(frame%4,frame/4)*slot,slot)
			atlas.filter_clip = true
			sequence.texture = atlas
			child.rotation = 0
		child.size = extent
		child.pivot_offset = extent*.5
		child.position = center-extent*.5
		# Crossfade independent image layers; never swap/collapse the solid body.
		child.self_modulate.a = 1.0-smoothstep(hold,hold+.20,age)
		sequence.size = Vector2(cell*3.4,cell*4.2) if dramatic else Vector2(cell*1.75,cell*2.1)
		sequence.position = (extent-sequence.size)*.5
		sequence.modulate.a = smoothstep(hold,hold+.20,age)*(1.0-smoothstep(hold+.40,hold+KETUPAT_RELEASE,age))

func ketupat_lane(at: Vector2, points: PackedVector2Array, cell: float, vertical: bool) -> void:
	_effect("ketupat_lane",at,Vector2.DOWN if vertical else Vector2.RIGHT,Color("fff1a0"),cell,.40)
	effects.back()["points"] = points

static func ketupat_arrival(at: Vector2, point: Vector2, points: PackedVector2Array) -> float:
	var reach := 1.0
	for target in points:
		reach = maxf(reach,at.distance_to(target))
	return at.distance_to(point)/reach*KETUPAT_TRAVEL

func _draw_ketupat_appear(e: Dictionary) -> void:
	var cell: float = e.width
	var age: float = e.age
	var grow := lerpf(.25,1.0,smoothstep(0,.12,age))
	var hold := KETUPAT_RAYA_HOLD if e.dramatic else KETUPAT_COMBO_HOLD
	var fade := 1.0-smoothstep(hold+.40,hold+KETUPAT_RELEASE,age)
	var at: Vector2 = e.display_at
	_glow(at,cell*(4.4 if e.dramatic else 2.3)*grow,Color(.89,1,.37,fade*.5))
	if e.dramatic and age >= .22:
		for ring in 3:
			var travel := clampf((age-.22-ring*.055)/.42,0,1)
			if travel <= 0 or travel >= 1:
				continue
			var radius := cell*lerpf(.55,2.8,travel)
			draw_arc(at,radius,0,TAU,64,Color(1,.89,.32,(1-travel)*.55),cell*.10*(1-travel),true)
			draw_arc(at,radius,0,TAU,64,Color(1,1,.81,(1-travel)*.9),cell*.025,true)
	for i in 8:
		var axis := Vector2.from_angle(i*TAU/8+age*.8)
		_star(at+axis*cell*1.12,cell*.12,Color(1,1,.68,fade),age*3)

func _draw_ketupat_lane(e: Dictionary) -> void:
	var cell: float = e.width
	var axis: Vector2 = e.b
	var normal := axis.orthogonal()
	var points: PackedVector2Array = e.points
	var fade := 1.0-smoothstep(.20,.40,e.age)
	for side in [-1,1]:
		var reach := 0.0
		for point in points:
			if (point-e.a).dot(axis)*side >= 0:
				reach = maxf(reach,absf((point-e.a).dot(axis)))
		var distance := reach*clampf(e.age/KETUPAT_TRAVEL,0,1)
		var tip: Vector2 = e.a+axis*distance*side
		draw_line(e.a,tip,Color(.85,1,.34,fade*.22),cell*.88,true)
		for strip in 2:
			var ribbon := PackedVector2Array()
			for i in 33:
				var progress := float(i)/32.0
				var curl := sin(progress*distance/cell*TAU-e.age*18+strip*PI)*cell*.17
				ribbon.append(e.a+axis*distance*progress*side+normal*curl)
			draw_polyline(ribbon,Color(.24,.39,.035,fade),cell*.18,true)
			draw_polyline(ribbon,Color("f5df72")*Color(1,1,1,fade) if strip == 0 else Color(.54,.84,.16,fade),cell*.12,true)
			draw_polyline(ribbon,Color(1,1,.76,fade*.9),cell*.024,true)
		_star(tip,cell*.25,Color(1,1,.68,fade),e.age*4)
		_glow(tip,cell*.7,Color(.9,1,.35,fade*.6))

func _draw_pisang_crispy(e: Dictionary) -> void:
	var cell: float = e.width
	var age: float = e.age
	var reveal := lerpf(.35,1.0,smoothstep(0,.16,age))
	var fade := 1.0-smoothstep(.52,.95,age)
	_glow(e.a,cell*3.0*reveal,Color(1,.76,.10,fade*.65))
	for i in 12:
		var axis := Vector2.from_angle(i*TAU/12+age*.6)
		draw_line(e.a+axis*cell*.5,e.a+axis*cell*(1.2+.18*sin(age*15+i)),Color(1,.88,.35,fade*.75),cell*.055,true)
	for i in 6:
		var theta := i*TAU/6-age
		_star(e.a+Vector2.from_angle(theta)*cell*.96,cell*.13,Color(1,1,.76,fade),age*2)

static func column_arrival(origin: Vector2, point: Vector2, points: PackedVector2Array) -> float:
	var reach := 1.0
	for target in points:
		reach = maxf(reach,absf(target.y-origin.y))
	return absf(point.y-origin.y)/reach*SELOROT_TRAVEL

func _draw_column_sweep(e: Dictionary, crispy: bool) -> void:
	var cell: float = e.width
	var points: PackedVector2Array = e.points
	var frame_size := SELOROT_UNWRAP.get_size()/Vector2(4,2)
	for point in points:
		var local_age: float = e.age-column_arrival(e.a,point,points)
		if local_age < 0:
			continue
		var fade := 1.0-smoothstep(.22,.38,local_age)
		if fade <= 0:
			continue
		_glow(point,cell*1.2,Color(1,.80,.23,fade*.35))
		if crispy:
			for crumb in 4:
				var direction := Vector2.from_angle(crumb*TAU/4+local_age*3)
				_star(point+direction*cell*local_age*2,cell*.09,Color(1,.77,.24,fade),local_age*5)
		else:
			var frame := clampi(int(local_age/.38*8),0,7)
			var source := Rect2(Vector2(frame%4,frame/4)*frame_size,frame_size)
			draw_texture_rect_region(SELOROT_UNWRAP,Rect2(point-Vector2(cell*.55,cell*.78),Vector2(cell*1.1,cell*1.56)),source,Color(1,1,1,fade))
	if crispy:
		# Three continuous luminous lanes clear the original kuih; no food replacements.
		for side in [-1,1]:
			var reach := cell*.5
			for point in points:
				if (point.y-e.a.y)*side >= 0:
					reach = maxf(reach,absf(point.y-e.a.y)+cell*.45)
			var tip: Vector2 = e.a+Vector2(0,side*reach*clampf(e.age/SELOROT_TRAVEL,0,1))
			var alpha := 1.0-smoothstep(.39,SELOROT_LIFE,e.age)
			draw_line(e.a,tip,Color(1,.49,.04,alpha*.18),cell*.94,true)
			draw_line(e.a,tip,Color(1,.74,.10,alpha*.44),cell*.55,true)
			draw_line(e.a,tip,Color(1,.92,.52,alpha*.85),cell*.20,true)
			draw_line(e.a,tip,Color(1,1,.93,alpha),cell*.06,true)
			_glow(tip,cell*.85,Color(1,.90,.42,alpha*.75))
			_star(tip,cell*.26,Color(1,1,.87,alpha),e.age*3)
	else:
		# Continuous unfurled leaf stream visibly joins the per-slot frames.
		for side in [-1,1]:
			var reach := 0.0
			for point in points:
				if (point.y-e.a.y)*side >= 0:
					reach = maxf(reach,absf(point.y-e.a.y))
			var distance := reach*clampf(e.age/SELOROT_TRAVEL,0,1)
			var ribbon := PackedVector2Array()
			for i in 25:
				var progress := float(i)/24.0
				ribbon.append(e.a+Vector2(sin(progress*distance/cell*TAU-e.age*14)*cell*.16,side*distance*progress))
			var alpha := 1.0-smoothstep(.40,SELOROT_LIFE,e.age)
			draw_polyline(ribbon,Color(.69,.44,.12,alpha),cell*.16,true)
			draw_polyline(ribbon,Color(1,.88,.58,alpha),cell*.11,true)
			draw_polyline(ribbon,Color(1,.98,.80,alpha),cell*.025,true)

func karipap_appear(at: Vector2, cell: float) -> void:
	_effect("karipap",at,Vector2.ZERO,Color("b9f8ff"),cell,KARIPAP_HOLD+KARIPAP_RELEASE)
	var graphic := TextureRect.new()
	graphic.name = "KaripapForeground"
	graphic.z_index = 70
	graphic.mouse_filter = Control.MOUSE_FILTER_IGNORE
	graphic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	graphic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	graphic.set_meta("karipap_effect",effects.back())
	add_child(graphic)
	_update_karipap_foregrounds()

func _update_karipap_foregrounds() -> void:
	for child in get_children():
		if not child.has_meta("karipap_effect"):
			continue
		var e: Dictionary = child.get_meta("karipap_effect")
		if not effects.has(e):
			child.queue_free()
			continue
		var frame := 0 if e.age < .16 else 1
		if e.age >= KARIPAP_HOLD:
			frame = clampi(2+int((e.age-KARIPAP_HOLD)/KARIPAP_RELEASE*6),2,7)
		var slot := KARIPAP_SEQUENCE.get_size()/Vector2(4,2)
		var atlas := AtlasTexture.new()
		atlas.atlas = KARIPAP_SEQUENCE
		atlas.region = Rect2(Vector2(frame%4,frame/4)*slot,slot)
		atlas.filter_clip = true
		child.texture = atlas
		var edge: float = e.width*1.85*lerpf(.65,1.0,smoothstep(0,.12,e.age))
		child.size = Vector2.ONE*edge
		child.pivot_offset = child.size*.5
		child.position = e.a-child.size*.5
		child.rotation = sin(e.age*64)*.07 if e.age < KARIPAP_HOLD else 0.0
		child.modulate.a = 1.0-smoothstep(KARIPAP_HOLD+.42,KARIPAP_HOLD+KARIPAP_RELEASE,e.age)

func karipap_wind(at: Vector2, affected: PackedVector2Array, cell: float) -> void:
	_effect("karipap_wind",at,Vector2.ZERO,Color("bcfaff"),cell,KARIPAP_RELEASE)
	effects.back()["points"] = affected

func _draw_karipap_wind(e: Dictionary) -> void:
	var progress := clampf(e.age/.18,0,1)
	var fade := 1.0-smoothstep(.22,KARIPAP_RELEASE,e.age)
	for direction in [Vector2.LEFT,Vector2.RIGHT,Vector2.UP,Vector2.DOWN]:
		var reach: float = e.width*.5
		for point in e.points:
			var offset: Vector2 = point-e.a
			if offset.dot(direction) > 0 and absf(offset.cross(direction)) < e.width*.15:
				reach = maxf(reach,offset.length()+e.width*.5)
		var tip: Vector2 = e.a+direction*reach*progress
		var normal: Vector2 = direction.orthogonal()
		for strand in range(-2,3):
			var points := PackedVector2Array()
			for step in 13:
				var t := float(step)/12.0
				points.append(e.a.lerp(tip,t)+normal*(strand*e.width*.11+sin(t*TAU*1.5-e.age*25+strand)*e.width*.09))
			draw_polyline(points,Color(.24,.85,1,.28*fade),e.width*.13,true)
			draw_polyline(points,Color(.88,1,1,.92*fade),e.width*.035,true)

func cross(at: Vector2, affected: PackedVector2Array, cell: float) -> void:
	var row := PackedVector2Array()
	var column := PackedVector2Array()
	for point in affected:
		if absf(point.y-at.y) < cell*.1:
			row.append(point)
		if absf(point.x-at.x) < cell*.1:
			column.append(point)
	ketupat_lane(at,row,cell,false)
	ketupat_lane(at,column,cell,true)
	burst(at,Color("fff0a2"),16,cell*.8)


func order_electric(at: Vector2, affected: PackedVector2Array, cell: float) -> void:
	# One grouped effect covers the full board without exhausting the effect cap.
	var index := _order_chain_index
	_order_chain_index += 1
	var color: Color = ORDER_CHAIN_COLORS[index] if index < ORDER_CHAIN_COLORS.size() else Color.from_hsv(fposmod(.12+index*.61803398875,1),.65,1)
	_order_origin_colors[at] = color
	_effect("order_electric",at,Vector2.ZERO,color,cell,.75)
	effects.back()["points"] = affected
	effects.back()["chain_index"] = index
	burst(at,color.lightened(.35),12,cell*.5)

func dulang_charge(at: Vector2, affected: PackedVector2Array, cell: float, foods: Array[Dictionary] = [], double_blast: bool = false, orbit_direction: Vector2 = Vector2.RIGHT) -> void:
	_effect("charge", at, Vector2.ZERO, Color("fff0a2"), cell, 1.10 if double_blast else .24)
	effects.back()["foods"] = foods
	effects.back()["points"] = affected
	effects.back()["double_blast"] = double_blast
	effects.back()["orbit_direction"] = orbit_direction


func _draw_dulang_charge(effect: Dictionary) -> void:
	if effect.get("double_blast",false):
		COCONUT.orbit(self,effect.a,effect.width,effect.age,effect.get("orbit_direction",Vector2.RIGHT))
		if effect.age >= .78:
			COCONUT.blue_impact(self,effect.a,effect.width,effect.age-.78,BLUE_SPLASH)
			COCONUT.sprite(self,COCONUT.PUTERI,effect.a-Vector2(0,effect.width*.70),effect.width*5.0,smoothstep(.82,.94,effect.age))
		return
	# Reuse the complete gathering motion within the short normal-bomb charge.
	if not effect.get("double_blast",false):
		effect = effect.duplicate()
		effect.age *= .64/.18
	var cell: float = effect.width
	var grow := smoothstep(0, .20, effect.age)
	var edge := cell * lerpf(1.0, 4.5 if effect.get("double_blast",false) else 2.9, grow)
	var toss := smoothstep(.04,.22,effect.age)
	var toward_screen := 1.0+.22*sin(toss*PI)+.12*toss
	edge *= toward_screen
	var tray_at: Vector2 = effect.a-Vector2(0,cell*.35*sin(toss*PI))
	if effect.get("double_blast",false):
		# Keep the princess at the same five-slot size and center as the impact.
		edge = cell*5.0
		tray_at = effect.a-Vector2(0,cell*.70)
	_match_glow(tray_at, edge * 1.05, .65 * grow)
	COCONUT.charge(self,tray_at,edge,effect.age,effect.get("double_blast",false))
	var gather := smoothstep(.20, .53, effect.age)
	for index in effect.foods.size():
		var food: Dictionary = effect.foods[index]
		var destination: Vector2 = effect.a + Vector2((index % 3 - 1) * cell * .38, (index / 3 - 1) * cell * .25)
		if effect.get("double_blast",false):
			destination = effect.a + Vector2.from_angle(index * 2.39996323) * sqrt(float(index)+1) * cell * .22
		var at: Vector2 = food.at.lerp(destination, gather)
		at.y -= sin(gather * PI) * cell * .30
		var food_edge := cell * lerpf(.82, .48, gather)
		BoardArt.draw_item_texture(self, Rect2(at - Vector2.ONE * food_edge * .5, Vector2.ONE * food_edge), food.texture)

func dulang_burst(at: Vector2, affected: PackedVector2Array, cell: float, double_blast: bool = false) -> void:
	# The loaded tray disappears at the blast; no 3x3 slot borders or fill.
	for index in range(effects.size()-1, -1, -1):
		if effects[index].kind == "charge" and effects[index].a.is_equal_approx(at):
			effects.remove_at(index)
	var spread := 1.8 if double_blast else 1.0
	_effect("coconut_burst",at,Vector2.ZERO,Color.WHITE,cell,1.25 if double_blast else 1.15)
	effects.back()["points"] = affected
	effects.back()["double_blast"] = double_blast
	_effect("impact", at, Vector2.ZERO, Color.WHITE, cell * 1.9 * spread, .28)
	_effect("flower_wave", at, Vector2.ZERO, Color.WHITE, cell*1.5*spread, .58)
	_effect("dulang_radial", at, Vector2.ZERO, Color.WHITE, cell*1.5*spread, .52)
	if double_blast:
		# One logical hit; the delayed outer pulse is purely visual.
		_effect("flower_wave", at, Vector2.ZERO, Color("fff2bd"), cell*2.75, .65, .15)
		_effect("dulang_radial", at, Vector2.ZERO, Color("ffd25e"), cell*2.75, .60, .15)
	# The cream artwork carries the impact; a small accent pool preserves the
	# character silhouette instead of burying it under dense gold confetti.
	burst(at, Color("fff7e9"), 24 if double_blast else 16, cell*1.15*spread)
	var fragments: Array[Dictionary] = []
	var fragment_groups := 2
	for index in fragment_groups:
		fragments.append({"at": at + Vector2.from_angle(index * TAU / fragment_groups) * cell * .25*spread, "color": Color("ffe34d")})
	kuih_dissolve(fragments, cell * .35, 0)

func delivery_cross(origin: Vector2, targets: PackedVector2Array, cell: float) -> void:
	_effect("robot_cross",origin,Vector2.ZERO,Color("dce6ed"),cell,.64)
	effects.back()["points"] = targets
	if _gust_frames == null:
		_gust_frames = SpriteFrames.new()
		_gust_frames.set_animation_loop("default",false)
		_gust_frames.set_animation_speed("default",25.0)
		var slot := SEPiT_GUST.get_size()/Vector2(4,4)
		for i in 16:
			var frame := AtlasTexture.new()
			frame.atlas = SEPiT_GUST
			frame.region = Rect2(Vector2(i%4,i/4)*slot,slot)
			_gust_frames.add_frame("default",frame)
	for target in targets:
		var direction := (target-origin).normalized()
		var gust := AnimatedSprite2D.new()
		gust.set_meta("sepit_gust",true)
		gust.sprite_frames = _gust_frames
		gust.speed_scale = ANIMATION_PACE.SPEED
		gust.rotation = direction.angle()
		gust.scale = Vector2.ONE*(cell*1.25/(SEPiT_GUST.get_width()/4.0))
		gust.position = origin+direction*cell*.42
		gust.z_index = 14
		add_child(gust)
		gust.animation_finished.connect(gust.queue_free)
		gust.play()
		var motion := gust.create_tween().set_speed_scale(ANIMATION_PACE.SPEED).set_parallel(true)
		motion.tween_property(gust,"position",origin+direction*cell*.88,.48).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		motion.tween_property(gust,"modulate:a",0.0,.18).set_delay(.46)


func _draw_robot_cross(_effect: Dictionary) -> void:
	# Generated animation frames are rendered by the four AnimatedSprite2D nodes.
	pass


func delivery(origin: Vector2, target: Vector2, cell: float, payload: Texture2D = null, carry_kind: int = BoardCell.Special.NONE) -> void:
	_effect("delivery",origin,target,Color("ffd56b"),cell*1.05,SepitFlight.LIFE)
	effects.back()["payload"] = payload
	var sprite := SepitFlight.new()
	sprite.configure(origin,target,cell*1.05,carry_kind)
	effects.back()["carry_kind"] = carry_kind
	add_child(sprite)
	effects.back()["sprite"] = sprite
	burst(origin,Color("fff0bc"),5,cell*.3)


func _draw_delivery(effect: Dictionary) -> void:
	var sprite = effect.get("sprite")
	if not is_instance_valid(sprite):
		return
	var trail := PackedVector2Array()
	for i in 16:
		trail.append(sprite.flight_position(maxf(0,effect.age-(15-i)*.015)))
	var fade := 1.0-smoothstep(SepitFlight.LAND_TIME,SepitFlight.LIFE,effect.age)
	draw_polyline(trail,Color(1,.86,.40,.28*fade),maxf(2,effect.width*.09),true)
	draw_polyline(trail,Color(1,.98,.88,.7*fade),maxf(1,effect.width*.025),true)
	if effect.age >= SepitFlight.LAND_TIME:
		_glow(effect.b,effect.width*1.5,Color(1,.9,.5,.65*fade))


func celebrate(bounds: Rect2) -> void:
	reset()
	for color in [Color("ff709e"), Color("ffd35b"), Color("8bdb4b"), Color("fff4ce")]:
		burst(bounds.position + Vector2(bounds.size.x * .15, bounds.size.y * .25), color, 20, bounds.size.x * .34, true)
		burst(bounds.position + Vector2(bounds.size.x * .85, bounds.size.y * .25), color, 20, bounds.size.x * .34, true)
	for side in [.18, .82]:
		_effect("flash", bounds.position + Vector2(bounds.size.x * side, bounds.size.y * .38), Vector2.ZERO, Color("ffd35b"), bounds.size.x * .30, .7)

func _process(delta: float) -> void:
	delta *= ANIMATION_PACE.SPEED
	clock += delta
	for i in range(particles.size() - 1, -1, -1):
		var p := particles[i]
		p.age += delta
		if p.age >= p.life:
			particles.remove_at(i)
			continue
		p.at += p.velocity * delta
		p.velocity.y += (330.0 if p.confetti else 85.0) * delta
		p.velocity *= exp(-delta * (1.2 if p.confetti else 2.6))
		p.angle += delta * (1.3 if p.confetti else .6)
	for i in range(effects.size() - 1, -1, -1):
		effects[i].age += delta
		if effects[i].age >= effects[i].life:
			effects.remove_at(i)
	_update_ketupat_foregrounds()
	_update_karipap_foregrounds()
	_update_pisang_foregrounds()
	queue_redraw()
	if particles.is_empty() and effects.is_empty():
		set_process(false)

func _glow(at: Vector2, edge: float, color: Color) -> void:
	draw_texture_rect(GLOW, Rect2(at - Vector2.ONE * edge * .5, Vector2.ONE * edge), false, color)

func _star(at: Vector2, edge: float, color: Color, angle: float = 0.0) -> void:
	draw_set_transform(at, angle)
	draw_texture_rect(SPARKLE, Rect2(-Vector2.ONE * edge * .5, Vector2.ONE * edge), false, color)
	draw_set_transform(Vector2.ZERO)

func _gold_glint(at: Vector2, edge: float, color: Color, angle: float = 0.0) -> void:
	_star(at, edge*1.6, color, angle)
	# A crisp cream core keeps the sparkle readable at phone resolution.
	draw_set_transform(at, angle)
	var points := PackedVector2Array()
	for i in 8:
		points.append(Vector2.from_angle(i*TAU/8.0)*(edge*(.5 if i%2 == 0 else .12)))
	draw_colored_polygon(points, color)
	draw_set_transform(Vector2.ZERO)

func _curve(a: Vector2, b: Vector2, bend: float, t: float) -> Vector2:
	return a.lerp(b, t) + Vector2(0, -sin(t * PI) * bend)

func _draw_tapau_lane(effect: Dictionary, t: float) -> void:
	var origin: Vector2 = effect.a
	var endpoint: Vector2 = effect.b
	var cell: float = effect.cell
	var direction := (endpoint-origin).normalized()
	var travel := smoothstep(0,.48,t)
	var front := origin.lerp(endpoint,travel)
	var flash := .40+.60*pow(sin(effect.age*PI*9),2)
	var fade := (1-smoothstep(.72,1,t))*flash
	var color := Color(effect.color,fade)
	var normal: Vector2 = direction.orthogonal()
	var points := PackedVector2Array()
	var segments := clampi(int(origin.distance_to(front)/(cell*.18)),6,48)
	for index in segments+1:
		var progress := float(index)/segments
		var jitter := sin(index*2.4+clock*65)*cell*.025*sin(progress*PI)
		points.append(origin.lerp(front,progress)+normal*jitter)
	# A full-slot energy band surrounds the electric core, for native and combo lanes.
	draw_line(origin,front,Color(color,fade*.32),cell*.96,true)
	draw_line(origin,front,Color(color,fade*.55),cell*.78,true)
	draw_polyline(points,Color(color,fade*.85),cell*.46,true)
	draw_polyline(points,Color("f4ffff",fade),maxf(2,cell*.10),true)
	_glow(front,cell*.85,Color(color,fade*.45))
	var marker_from := origin+direction*cell*.18
	var marker_to := endpoint-direction*cell*.24
	if not effect.get("hide_utensil",false):
		BoardArt.draw_direction_marker(self,marker_from.lerp(marker_to,travel),cell*1.2,direction.angle(),fade)


func _draw_tapau_slots(effect: Dictionary) -> void:
	var cell: float = effect.width
	var axis := Vector2.UP if effect.get("vertical", false) else Vector2.RIGHT
	var normal := axis.orthogonal()
	for point in effect.points:
		var delay: float = effect.a.distance_to(point)/cell*.018
		var age: float = effect.age-delay
		if age < 0:
			continue
		var pulse := (.3+.7*pow(sin(age*PI*9),2))*(1-smoothstep(effect.life*.67,effect.life,effect.age))
		var rect := Rect2(point-Vector2.ONE*cell*.49,Vector2.ONE*cell*.98)
		var tint := Color(effect.color,pulse*.32)
		draw_rect(rect,tint,true)
		# Four flickering bolts cover the slot interior along the clearing axis.
		# Bounds stay inside this cell, including at the board edges.
		for lane in 4:
			var bolt := PackedVector2Array()
			var offset := (float(lane)-1.5)*cell*.22
			for index in 9:
				var along := lerpf(-.49,.49,float(index)/8.0)*cell
				var jitter := sin(index*2.7+lane*1.9+clock*80+point.x*.03+point.y*.02)*cell*.065
				bolt.append(point+axis*along+normal*(offset+jitter))
			draw_polyline(bolt,Color(effect.color,pulse*.24),cell*.18,true)
			draw_polyline(bolt,Color(effect.color,pulse*.85),maxf(2.0,cell*.075),true)
			draw_polyline(bolt,Color("efffff",pulse*.95),maxf(1.2,cell*.035),true)
			for branch in [2, 5]:
				var sign_value := 1.0 if lane%2 == 0 else -1.0
				var root: Vector2 = bolt[branch]
				var twig := PackedVector2Array([root,root+axis*cell*.065+normal*cell*.045*sign_value,root+axis*cell*.12+normal*cell*.08*sign_value])
				draw_polyline(twig,Color(effect.color,pulse*.75),maxf(1.5,cell*.025),true)


func _draw() -> void:
	for e in effects:
		if e.age < 0.0:
			continue
		var t: float = clampf(e.age / e.life, 0, 1)
		var color: Color = e.color
		color.a *= 1.0 - smoothstep(.18, 1.0, t)
		match e.kind:
			"karipap_wind":
				_draw_karipap_wind(e)
			"ketupat_appear":
				_draw_ketupat_appear(e)
			"ketupat_lane":
				_draw_ketupat_lane(e)
			"pisang_crispy":
				_draw_pisang_crispy(e)
			"selorot_unwrap", "crispy_column":
				_draw_column_sweep(e,e.kind == "crispy_column")
			"pisang_solar":
				_draw_pisang_solar(e)
			"royal_cake_bomb":
				_draw_royal_cake_bomb(e)
			"special_formation":
				_draw_special_formation(e)
			"kuih_dissolve":
				_draw_kuih_dissolve(e)
			"roller_lane":
				var travel := smoothstep(0,.75,t)
				var direction: Vector2 = (e.b-e.a).normalized()
				var roller_at: Vector2 = e.a.lerp(e.b,travel)
				var fade := 1-smoothstep(.8,1,t)
				var tail: Vector2 = roller_at-direction*minf(e.a.distance_to(roller_at),e.width*1.8)
				# Broad gold motion light follows the rolling pin, nearly a slot wide.
				draw_line(tail,roller_at,Color("ffca26",fade*.28),e.width*.96,true)
				draw_line(tail,roller_at,Color("ffe36b",fade*.60),e.width*.65,true)
				draw_line(tail,roller_at,Color("fffbe6",fade*.85),e.width*.18,true)
				var roll_phase: float = e.a.distance_to(roller_at)/e.width*TAU
				BoardArt.draw_roller(self,roller_at,e.width*1.15,direction.angle(),fade,roll_phase)
			"tapau_slots":
				_draw_tapau_slots(e)
			"order_electric":
				_draw_premium_electric(e)
			"gold_slot":
				var travel := clampf(e.age / .22, 0.0, 1.0)
				var front: Vector2 = e.a.lerp(e.b, smoothstep(0.0, 1.0, travel))
				if travel < 1.0 and e.a.distance_to(e.b) > 1.0:
					var tail: Vector2 = e.a.lerp(e.b, maxf(0.0, travel - .32))
					draw_line(tail, front, Color(color, .18), e.width*.12, true)
					draw_line(tail, front, Color("fff5cd", .9), maxf(2.0, e.width*.035), true)
					_glow(front, e.width*.55, Color(color, .45))
					_gold_glint(front, e.width*.30, Color("fff9e0"), travel*.4)
				else:
					var shine := clampf((e.age - .22) / .50, 0.0, 1.0)
					if e.a.is_equal_approx(e.b):
						shine = t
					var alpha := (1.0 - smoothstep(.35, 1.0, shine)) * (.75 + .25*sin(shine*TAU*2.0))
					var rect := Rect2(e.b - Vector2.ONE*e.width*.5, Vector2.ONE*e.width)
					draw_style_box(UIKit.flat_box(Color(color, alpha*.15), Color(color, alpha*.8), 10, 2), rect)
					_glow(e.b, e.width*1.05, Color(color, alpha*.38))
					for i in 4:
						var offset: Vector2 = Vector2.from_angle(PI*.25 + i*PI*.5 + shine*.18)*e.width*.40
						_gold_glint(e.b + offset, e.width*(.24 + .10*sin(shine*PI)), Color("fff8da",alpha), shine*.35)
			"charge":
				_draw_dulang_charge(e)
			"coconut_burst":
				COCONUT.burst(self,e)
			"preview":
				var rect := Rect2(e.a-Vector2.ONE*e.width*.5,Vector2.ONE*e.width)
				draw_style_box(UIKit.flat_box(Color(color,t*.10),Color(color,t*.5),8,2),rect)
			"flower_wave":
				var radius: float = e.width*(1-pow(1-t,3))
				var wave := PackedVector2Array()
				for i in 81:
					var angle := i*TAU/80
					wave.append(e.a+Vector2.from_angle(angle)*radius*(1+.045*cos(angle*5)))
				draw_polyline(wave,Color(color,color.a*.16),e.width*.12*(1-t)+1,true)
				draw_polyline(wave,color,e.width*.025*(1-t)+1,true)
				draw_polyline(wave,Color("fff7dc",color.a*.85),2,true)
				for i in 5:
					_star(e.a+Vector2.from_angle(i*TAU/5)*radius,e.width*.18,color,t*.2)
			"dulang_radial":
				var radius: float = e.width*(1-pow(1-t,3))
				_match_glow(e.a,maxf(1,radius*2), (1-t)*.65)
				draw_arc(e.a,maxf(1,radius),0,TAU,80,Color("fff8dc",(1-t)*.8),maxf(1,e.width*.025*(1-t)),true)
			"impact":
				var fade := 1.0 - smoothstep(.04, .22, e.age)
				_match_glow(e.a, e.width * (1 + t), fade)
				draw_circle(e.a, e.width * (.10 + .20 * t), Color("fffef1", fade * .85))
				for ray in 12:
					var direction := Vector2.from_angle(ray * TAU / 12.0)
					draw_line(e.a + direction * e.width * .15, e.a + direction * e.width * (.28 + .50 * t), Color("fff3ab", fade * .75), maxf(1, e.width * .018 * fade), true)
			"flash":
				_glow(e.a, e.width * (1 + t * .7), Color(color, color.a * .55))
				_star(e.a, e.width * (.65 + t * .3), color, t * .2)
			"delivery":
				_draw_delivery(e)
			"robot_cross":
				_draw_robot_cross(e)
			"arrival":
				if t > .54:
					var hit := (t - .54) / .46
					_glow(e.a, e.width * (1+hit), Color(color, (1-hit)*.65))
					for i in 6:
						_star(e.a + Vector2.from_angle(i*TAU/6) * e.width * hit, e.width * .5, Color(color, 1-hit))
			"beam":
				if e.get("tapau",false):
					_draw_tapau_lane(e,t)
					continue
				var front: Vector2 = e.a.lerp(e.b, smoothstep(0.0, .52, t))
				var thickness: float = maxf(1, e.width * (1-t))
				for layer in range(4, 0, -1):
					draw_line(e.a, front, Color(color, color.a * .07), thickness * (1+layer*.9), true)
				draw_line(e.a, front, color, thickness, true)
				draw_line(e.a, front, Color("fffbe3", color.a), maxf(1.5, thickness*.28), true)
				_glow(front, e.width * 7, Color(color, color.a * .7))
				_star(front, e.width * 6, Color("fffbe3", color.a))
			"ribbon":
				var progress := smoothstep(0.0, .70, t)
				var points := PackedVector2Array()
				for i in 18:
					points.append(_curve(e.a, e.b, e.a.distance_to(e.b) * .18, progress * i / 17))
				draw_polyline(points, Color(color, color.a*.18), e.width*2.4, true)
				draw_polyline(points, color, maxf(1, e.width*.5), true)
				_star(points[-1], e.width * 6, Color("fff7d0", color.a))
			"ring":
				var radius: float = maxf(1, e.width * (1-pow(1-t, 3)))
				draw_arc(e.a, radius, 0, TAU, 64, Color(color, color.a*.17), 12*(1-t)+1, true)
				draw_arc(e.a, radius, 0, TAU, 64, color, 3*(1-t)+1, true)
				for i in 6:
					_star(e.a+Vector2.from_angle(i*TAU/6 + t*.3)*radius, e.width*.3, color)
			"tile":
				_glow(e.a, e.width * 1.2, Color(color, color.a * .35))
				_star(e.a, e.width * .7, color)
			"scoop":
				var at: Vector2 = e.a.lerp(e.b, 1-pow(1-t, 2))
				_star(at, e.width, color, t*.3)
				_glow(at, e.width*1.8, Color(color, color.a*.4))
			"swirl":
				for arm in 2:
					var points := PackedVector2Array()
					for i in 28:
						var angle := arm * PI + t * TAU * 1.2 + i * .055
						points.append(e.a + Vector2.from_angle(angle) * e.width * (.25 + i*.75/27))
					draw_polyline(points, Color(color, color.a*.15), 12, true)
					draw_polyline(points, color, 3, true)
					_star(points[-1], e.width*.18, Color("fff2bc", color.a))
	for p in particles:
		var color: Color = p.color
		var t: float = p.age / p.life
		color.a *= smoothstep(0, .10, t) * (1-smoothstep(.3, 1, t))
		if not p.confetti and p.shape == 0:
			_star(p.at, p.radius * 4 * (1-t*.4), color, p.angle)
			continue
		draw_set_transform(p.at, p.angle, Vector2(1, maxf(.3, absf(cos(p.age * 3)))))
		if p.shape == 1:
			# A small pandan leaf with a warm outline and a pale central vein.
			var leaf := PackedVector2Array([Vector2(-p.radius,0), Vector2(0,-p.radius*.48), Vector2(p.radius,0), Vector2(0,p.radius*.48)])
			draw_colored_polygon(leaf, Color(color, color.a*.9))
			draw_line(Vector2(-p.radius*.65,0), Vector2(p.radius*.65,0), Color("fff2be",color.a*.6), 1, true)
		elif p.confetti:
			for petal in 5:
				var at: Vector2 = Vector2.from_angle(petal * TAU / 5) * p.radius * .45
				draw_circle(at, p.radius * .38, color)
			draw_circle(Vector2.ZERO, p.radius*.24, Color("fff4b5",color.a))
		else:
			draw_circle(Vector2.ZERO, p.radius*.3, Color("fff8d9",color.a))
		draw_set_transform(Vector2.ZERO)


## One lightweight renderer; cycle at most 18 arcs for large target sets.
func _draw_premium_electric(e: Dictionary) -> void:
	var accent: Color = e.color
	var core := accent.lightened(.82)
	var age: float = e.age/.75
	var intensity := smoothstep(.08,.16,age)*(1-smoothstep(.82,1.0,age))
	var pulse := .75+.25*sin(age*45.0)
	_glow(e.a,e.width*1.65,Color(accent,intensity*.55*pulse))
	var count: int = e.points.size()
	var tick := int(age/.035)
	for index in count:
		var endpoint: Vector2 = e.points[index]
		if endpoint.distance_to(e.a)<2:
			continue
		var target_alpha := intensity*(.6+.4*pow(sin(age*26+index),2))
		_glow(endpoint,e.width*1.25,Color(accent.lightened(.25),target_alpha*.45))
		_star(endpoint+Vector2.from_angle(age*8+index)*e.width*.40,e.width*.09,Color(core,target_alpha),age)
		if (index-tick*18+count*100)%count >= mini(18,count):
			continue
		var start: Vector2 = e.a
		var normal := (endpoint-start).normalized().orthogonal()
		var bolt := PackedVector2Array([start])
		for segment in range(1,7):
			var along := segment/7.0
			var jitter: float = sin(tick*7.3+index*3.7+segment*8.2)*e.width*.18
			bolt.append(start.lerp(endpoint,along)+normal*jitter)
		bolt.append(endpoint)
		var thickness := 1.35 if age >= .55 else 1.0
		draw_polyline(bolt,Color(accent,intensity*.16),e.width*.22*thickness,true)
		draw_polyline(bolt,Color(accent,intensity),maxf(1.6,e.width*.085)*thickness,true)
		draw_polyline(bolt,Color(core,intensity),maxf(1.0,e.width*.035)*thickness,true)

		for split in [2,5]:
			var branch := PackedVector2Array([bolt[split],bolt[split]+normal*e.width*.20,bolt[split]+normal*e.width*.32+(endpoint-start).normalized()*e.width*.15])
			draw_polyline(branch,Color("ffdf3b",intensity*.8),e.width*.035,true)
			draw_polyline(branch,Color("fffde4",intensity),e.width*.015,true)
