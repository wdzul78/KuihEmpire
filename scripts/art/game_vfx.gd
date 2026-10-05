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

func scoop(at: Vector2, cell: float) -> void:
	_effect("scoop", at, at - Vector2(0, cell * 1.3), Color("fff1ad"), cell * .55, .55)
	burst(at, Color("fff0bd"), 10, cell * .6)

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
		var low := at
		var high := at
		for p in affected:
			low = low.min(p)
			high = high.max(p)
		if kind == BoardCell.Special.TAPAU:
			line_clear(at,Vector2(low.x-cell*.45,at.y),cell,color,true)
			line_clear(at,Vector2(high.x+cell*.45,at.y),cell,color,true)
		else:
			line_clear(at,Vector2(at.x,low.y-cell*.45),cell,color,true)
			line_clear(at,Vector2(at.x,high.y+cell*.45),cell,color,true)
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

func dulang_charge(at: Vector2, affected: PackedVector2Array, cell: float) -> void:
	_effect("charge", at, Vector2.ZERO, Color("fff0a2"), cell, .18)
	for point in affected:
		_effect("preview", point, Vector2.ZERO, Color("ffd768"), cell*.92, .18)

func dulang_burst(at: Vector2, affected: PackedVector2Array, cell: float) -> void:
	_effect("flower_wave", at, Vector2.ZERO, Color("ffd25e"), cell*1.38, .58)
	_effect("flash", at, Vector2.ZERO, Color("fff4ce"), cell*1.65, .24)
	burst(at, Color("ffe79a"), 16, cell*.85)
	burst(at, Color("ffce50"), 12, cell*.65)
	for point in affected:
		# The centre lights first; travelling glints reach the outer slots next.
		_effect("gold_slot", at, point, Color("ffd768"), cell*.88, .72,
			at.distance_to(point) / cell * .045)

func delivery(origin: Vector2, target: Vector2, cell: float) -> void:
	_effect("delivery", origin, target, Color("a6e864"), cell * .75, .60)
	_effect("arrival", target, Vector2.ZERO, Color("fff0b7"), cell * .8, .80)
	burst(origin, Color("fff0b7"), 5, cell * .3)

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

func _draw() -> void:
	for e in effects:
		if e.age < 0.0:
			continue
		var t: float = clampf(e.age / e.life, 0, 1)
		var color: Color = e.color
		color.a *= 1.0 - smoothstep(.18, 1.0, t)
		match e.kind:
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
				_glow(e.a,e.width*(.5+t*.9),Color(color,t*.6))
				for i in 5:
					var point: Vector2 = e.a+Vector2.from_angle(i*TAU/5+t)*e.width*(.5-t*.3)
					_star(point,e.width*.13,Color(color,t))
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
			"flash":
				_glow(e.a, e.width * (1 + t * .7), Color(color, color.a * .55))
				_star(e.a, e.width * (.65 + t * .3), color, t * .2)
			"delivery":
				# Flight duration still agrees with the board's .45-second hit cue.
				var progress := smoothstep(0.0, .75, t)
				var at := _curve(e.a, e.b, e.width * .80, progress)
				var trail := PackedVector2Array()
				for i in 14:
					trail.append(_curve(e.a, e.b, e.width * .80, maxf(0, progress - .30 + i * .30 / 13)))
				draw_polyline(trail, Color("85b850", color.a * .2), 10, true)
				draw_polyline(trail, Color("fff3af", color.a * .8), 3, true)
				for i in 4:
					var behind := maxf(0, progress - i * .08)
					_star(_curve(e.a, e.b, e.width * .80, behind), e.width * .3, Color("fff4b2", color.a * (1-i*.18)))
				_glow(at, e.width * 1.7, Color("caff9e", color.a * .4))
				BoardArt.draw_delivery(self, Rect2(at - Vector2.ONE * e.width * .5, Vector2.ONE * e.width))
			"arrival":
				if t > .54:
					var hit := (t - .54) / .46
					_glow(e.a, e.width * (1+hit), Color(color, (1-hit)*.65))
					for i in 6:
						_star(e.a + Vector2.from_angle(i*TAU/6) * e.width * hit, e.width * .5, Color(color, 1-hit))
			"beam":
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
