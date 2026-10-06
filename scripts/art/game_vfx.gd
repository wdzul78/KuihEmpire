class_name GameVfx
extends Control

## One bounded, input-transparent canvas. Inherits pause and dies with its owner.
const MAX_PARTICLES := 240
const MAX_EFFECTS := 48
const SPARKLE := preload("res://assets/vfx/kenney/star_04.png")
const GLOW := preload("res://assets/vfx/kenney/light_02.png")
var particles: Array[Dictionary] = []
var effects: Array[Dictionary] = []
var clock := 0.0

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_process(false)

func reset() -> void:
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


## One bounded batch gives every cleared item a gold glow and 48 fragments,
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
	_effect("special_formation", at, Vector2.ZERO, color, cell, .48)
	effects.back()["points"] = points


func _draw_special_formation(effect: Dictionary) -> void:
	var cell: float = effect.width
	var gather := smoothstep(.16, .40, effect.age)
	var fade := 1.0 - smoothstep(.40, .48, effect.age)
	var pulse := sin(clampf(effect.age / .20, 0, 1) * PI * .5)
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
		_match_glow(item.at, cell * 1.15, glow)
		if effect.age < .10:
			continue
		# Staggered directions/speeds fill a cloud rather than a thin ring.
		for spark in 48:
			var tint := Color("ffe34d") if spark % 3 == 0 else Color("ffbd27")
			if spark % 4 == 0:
				tint = Color("fff7ad")
			tint.a = fade
			var angle: float = spark * 2.39996323
			var reach: float = .30 + float(spark % 5) * .17
			var distance := cell * (.08 + reach * (1.0 - pow(1.0-t, 2)))
			var at: Vector2 = item.at + Vector2.from_angle(angle) * distance
			at.y -= cell * .12 * t * t
			var edge := cell * (.14 if spark % 3 == 0 else .10) * (1.0-t*.65)
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
	_effect("beam",a,b,color,cell*.32,.42)
	effects.back()["tapau"] = true
	effects.back()["cell"] = cell
	burst(a,color,5,cell*.35)

func shuffle(bounds: Rect2, cell: float) -> void:
	_effect("swirl", bounds.get_center(), Vector2.ZERO, Color("b7ef77"), bounds.size.x * .43, .75)
	burst(bounds.get_center(), Color("ffe7a0"), 18, cell * 1.4)

func special(at: Vector2, kind: int, affected: PackedVector2Array, cell: float) -> void:
	if kind == BoardCell.Special.DULANG:
		dulang_burst(at, affected, cell)
		return
	if kind == BoardCell.Special.ORDER:
		order_electric(at, affected, cell)
		return
	var color := Color("9df465") if kind == BoardCell.Special.TAPAU or kind == BoardCell.Special.TAPAU_VERTICAL else Color("ffca62")
	if kind == BoardCell.Special.TAPAU_VERTICAL:
		color = Color("55cfff")
	_effect("ring", at, Vector2.ZERO, color, cell * (1.45 if kind == BoardCell.Special.DULANG else .65), .55)
	_effect("flash", at, Vector2.ZERO, color, cell * 1.8, .35)
	burst(at, color, 22, cell * 1.4)
	if kind == BoardCell.Special.TAPAU or kind == BoardCell.Special.TAPAU_VERTICAL:
		_effect("tapau_slots",at,Vector2.ZERO,color,cell,.42)
		effects.back()["points"] = affected
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

func cross(at: Vector2, affected: PackedVector2Array, cell: float) -> void:
	var low := at
	var high := at
	for point in affected:
		low = low.min(point)
		high = high.max(point)
	_effect("flash", at, Vector2.ZERO, Color("fff0a2"), cell * 2.3, .40)
	_effect("ring", at, Vector2.ZERO, Color("fff0a2"), cell * 1.8, .6)
	for endpoint in [Vector2(low.x-cell*.45,at.y),Vector2(high.x+cell*.45,at.y),Vector2(at.x,low.y-cell*.45),Vector2(at.x,high.y+cell*.45)]:
		line_clear(at,endpoint,cell,Color("ffe38a"),true)
	burst(at, Color("fff0a2"), 24, cell*1.5)

func order_electric(at: Vector2, affected: PackedVector2Array, cell: float) -> void:
	# One grouped effect covers the full board without exhausting the effect cap.
	_effect("order_electric",at,Vector2.ZERO,Color("a9f4ff"),cell,.78)
	effects.back()["points"] = affected
	burst(at,Color("fff1aa"),12,cell*.5)

func dulang_charge(at: Vector2, affected: PackedVector2Array, cell: float, foods: Array[Dictionary] = [], double_blast: bool = false) -> void:
	_effect("charge", at, Vector2.ZERO, Color("fff0a2"), cell, .72)
	effects.back()["foods"] = foods
	effects.back()["points"] = affected
	effects.back()["double_blast"] = double_blast


func _draw_dulang_charge(effect: Dictionary) -> void:
	var cell: float = effect.width
	var grow := smoothstep(0, .20, effect.age)
	var edge := cell * lerpf(1.0, 4.5 if effect.get("double_blast",false) else 2.9, grow)
	_match_glow(effect.a, edge * 1.05, .65 * grow)
	BoardArt.draw_item_texture(self, Rect2(effect.a - Vector2.ONE * edge * .5, Vector2.ONE * edge), BoardArt.DULANG_ART)
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
	_effect("flower_wave", at, Vector2.ZERO, Color("ffd25e"), cell*1.5*spread, .58)
	_effect("dulang_radial", at, Vector2.ZERO, Color("ffe79a"), cell*1.5*spread, .52)
	if double_blast:
		# One logical hit; the delayed outer pulse is purely visual.
		_effect("flower_wave", at, Vector2.ZERO, Color("fff2bd"), cell*2.75, .65, .15)
		_effect("dulang_radial", at, Vector2.ZERO, Color("ffd25e"), cell*2.75, .60, .15)
	burst(at, Color("ffe79a"), 144 if double_blast else 96, cell*1.15*spread)
	burst(at, Color("ffce50"), 96 if double_blast else 64, cell*.85*spread)
	var fragments: Array[Dictionary] = []
	var fragment_groups := 9 if double_blast else 6
	for index in fragment_groups:
		fragments.append({"at": at + Vector2.from_angle(index * TAU / fragment_groups) * cell * .25*spread, "color": Color("ffe34d")})
	kuih_dissolve(fragments, cell * 1.15*spread, 0)

func delivery_cross(origin: Vector2, targets: PackedVector2Array, cell: float) -> void:
	_effect("robot_cross",origin,Vector2.ZERO,Color("dce6ed"),cell,.58)
	effects.back()["points"] = targets


func _draw_robot_cross(effect: Dictionary) -> void:
	var age: float = effect.age
	var reach := smoothstep(0,.18,age)*(1-smoothstep(.25,.50,age))
	var grip := smoothstep(.18,.25,age)
	var edge: float = effect.width
	for target in effect.points:
		var direction: Vector2 = (target-effect.a).normalized()
		var side := direction.orthogonal()
		var start: Vector2 = effect.a+direction*edge*.16
		var end: Vector2 = effect.a.lerp(target,reach)
		var joint := start.lerp(end,.5)+side*edge*.09*reach
		var arm := PackedVector2Array([start,joint,end])
		draw_polyline(arm,Color("242c36"),edge*.14,true)
		draw_polyline(arm,Color("a4b3c2"),edge*.085,true)
		draw_polyline(arm,Color("f1f6f9"),edge*.025,true)
		for point in [start,joint,end]:
			draw_circle(point,edge*.075,Color("242c36"))
			draw_circle(point,edge*.045,Color("ced9e1"))
		var opening := lerpf(.23,.12,grip)
		for sign_value in [-1,1]:
			var finger := PackedVector2Array([end,end+side*sign_value*edge*opening-direction*edge*.08,end+side*sign_value*edge*opening+direction*edge*.12,end+side*sign_value*edge*opening*.6+direction*edge*.18])
			draw_polyline(finger,Color("252e38"),edge*.09,true)
			draw_polyline(finger,Color("d4dfe8"),edge*.035,true)


func delivery(origin: Vector2, target: Vector2, cell: float, payload: Texture2D = null) -> void:
	_effect("delivery", origin, target, Color("ff6155"), cell * 1.05, 1.10)
	effects.back()["payload"] = payload
	_effect("arrival", target, Vector2.ZERO, Color("fff0df"), cell * .8, .80)
	burst(origin, Color("ffaaa0"), 5, cell * .3)


func _draw_delivery(effect: Dictionary) -> void:
	var age: float = effect.age
	var edge: float = effect.width
	var pickup: Vector2 = effect.b-Vector2(0,edge*.39)
	var outbound := smoothstep(.05,.45,age)
	var leaving := smoothstep(.60,1.10,age)
	var at := _curve(effect.a,pickup,edge*.65,outbound)
	if age >= .60:
		at = _curve(pickup,Vector2(effect.b.x,-edge*2),edge*.6,leaving)
	var trail := PackedVector2Array()
	for i in 12:
		var earlier := maxf(0,age-(11-i)*.012)
		if age >= .60:
			trail.append(_curve(pickup,Vector2(effect.b.x,-edge*2),edge*.6,smoothstep(.60,1.10,earlier)))
		else:
			trail.append(_curve(effect.a,pickup,edge*.65,smoothstep(.05,.45,earlier)))
	draw_polyline(trail,Color(1,.3,.25,.20),maxf(2,edge*.12),true)
	draw_polyline(trail,Color(1,.93,.85,.65),maxf(1,edge*.035),true)
	_glow(at,edge*.8,Color(1,.4,.3,.2))
	var food: Texture2D = effect.get("payload",null) if age >= .45 else null
	BoardArt.draw_delivery(self,Rect2(at-Vector2.ONE*edge*.5,Vector2.ONE*edge),age*36,true,food)

func celebrate(bounds: Rect2) -> void:
	reset()
	for color in [Color("ff709e"), Color("ffd35b"), Color("8bdb4b"), Color("fff4ce")]:
		burst(bounds.position + Vector2(bounds.size.x * .15, bounds.size.y * .25), color, 20, bounds.size.x * .34, true)
		burst(bounds.position + Vector2(bounds.size.x * .85, bounds.size.y * .25), color, 20, bounds.size.x * .34, true)
	for side in [.18, .82]:
		_effect("flash", bounds.position + Vector2(bounds.size.x * side, bounds.size.y * .38), Vector2.ZERO, Color("ffd35b"), bounds.size.x * .30, .7)

func _process(delta: float) -> void:
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
	var normal := direction.orthogonal()
	var points := PackedVector2Array()
	var segments := clampi(int(origin.distance_to(front)/(cell*.18)),6,48)
	for index in segments+1:
		var progress := float(index)/segments
		var jitter := sin(index*2.4+clock*65)*cell*.055*sin(progress*PI)
		points.append(origin.lerp(front,progress)+normal*jitter)
	draw_line(origin,front,Color(color,fade*.13),cell*.52,true)
	draw_line(origin,front,Color(color,fade*.27),cell*.30,true)
	draw_polyline(points,color,cell*.14,true)
	draw_polyline(points,Color("f4ffff",fade),maxf(2,cell*.045),true)
	_glow(front,cell*.85,Color(color,fade*.45))
	var marker_from := origin+direction*cell*.18
	var marker_to := endpoint-direction*cell*.24
	BoardArt.draw_direction_marker(self,marker_from.lerp(marker_to,travel),cell*1.2,direction.angle(),fade)


func _draw_tapau_slots(effect: Dictionary) -> void:
	var cell: float = effect.width
	for point in effect.points:
		var delay: float = effect.a.distance_to(point)/cell*.018
		var age: float = effect.age-delay
		if age < 0:
			continue
		var pulse := (.3+.7*pow(sin(age*PI*9),2))*(1-smoothstep(.28,.42,effect.age))
		var rect := Rect2(point-Vector2.ONE*cell*.44,Vector2.ONE*cell*.88)
		var tint := Color(effect.color,pulse*.26)
		draw_rect(rect,tint,true)
		draw_rect(rect,Color(effect.color,pulse*.65),false,maxf(2,cell*.065))
		var perimeter := PackedVector2Array()
		for side in 4:
			var corners := [rect.position,rect.position+Vector2(rect.size.x,0),rect.end,rect.position+Vector2(0,rect.size.y)]
			var start: Vector2 = corners[side]
			var finish: Vector2 = corners[(side+1)%4]
			var normal := (finish-start).normalized().orthogonal()
			for index in 4:
				perimeter.append(start.lerp(finish,float(index)/4)+normal*sin(index*2.7+clock*80)*cell*.018)
		perimeter.append(perimeter[0])
		draw_polyline(perimeter,Color("efffff",pulse*.9),maxf(1.2,cell*.025),true)


func _draw() -> void:
	for e in effects:
		if e.age < 0.0:
			continue
		var t: float = clampf(e.age / e.life, 0, 1)
		var color: Color = e.color
		color.a *= 1.0 - smoothstep(.18, 1.0, t)
		match e.kind:
			"special_formation":
				_draw_special_formation(e)
			"kuih_dissolve":
				_draw_kuih_dissolve(e)
			"tapau_slots":
				_draw_tapau_slots(e)
			"order_electric":
				var pull := clampf((e.age-.32)/.42,0,1)
				pull *= pull
				var intensity := minf(1,e.age/.10)*(1-smoothstep(.62,.78,e.age))
				_glow(e.a,e.width*(1.4+.12*sin(clock*18)),Color("bceeff",intensity*.45))
				for index in e.points.size():
					var endpoint: Vector2 = e.points[index].lerp(e.a,pull)
					if endpoint.distance_to(e.a)<2:
						continue
					var normal: Vector2 = (endpoint-e.a).normalized().orthogonal()
					var bolt := PackedVector2Array()
					for segment in 13:
						var along := float(segment)/12
						var jitter: float = sin(clock*48+segment*2.7+index*1.9)*e.width*.055*sin(along*PI)*(1-pull)
						bolt.append(e.a.lerp(endpoint,along)+normal*jitter)
					draw_polyline(bolt,Color("68cfff",intensity*.24),e.width*.14,true)
					draw_polyline(bolt,Color("b7f2ff",intensity*.9),maxf(2.5,e.width*.045),true)
					draw_polyline(bolt,Color("ffffff",intensity*.95),maxf(1.8,e.width*.024),true)
					_star(endpoint,e.width*.17,Color("fff4b5",intensity),clock*.7)
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
