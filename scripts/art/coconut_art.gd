extends RefCounted

const SPLASH = preload("res://assets/vfx/coconut_v1/splash.png")
const BALLS = preload("res://assets/vfx/coconut_v1/balls.png")
const PUTERI = preload("res://assets/vfx/coconut_v1/puteri.png")
const RHINO = preload("res://assets/vfx/badak_bath_v1/badak.png")

# Camera-facing artwork travels around a shared centre, never self-rotates.
static func orbit_position(at: Vector2, cell: float, age: float, index: int, direction: Vector2 = Vector2.RIGHT) -> Vector2:
	var progress := clampf(age / .78, 0.0, 1.0)
	var axis := direction.normalized() if not direction.is_zero_approx() else Vector2.RIGHT
	var sense := 1.0 if axis.x + axis.y >= 0.0 else -1.0
	var angle := TAU * 2.0 * smoothstep(0,1,progress) * sense + PI * index
	var radius := cell * lerpf(.5,.80,smoothstep(0,.22,progress)) * (1.0 - smoothstep(.45, 1.0, progress))
	return at + (axis*cos(angle) + Vector2(-axis.y,axis.x)*sin(angle)*.42)*radius

static func orbit(canvas: CanvasItem, at: Vector2, cell: float, age: float, direction: Vector2 = Vector2.RIGHT) -> void:
	for index in 2:
		for segment in 18:
			var delay := float(segment) * .007
			var a := orbit_position(at, cell, maxf(0, age-delay), index,direction)
			var b := orbit_position(at, cell, maxf(0, age-delay-.007), index,direction)
			var alpha := (1.0-float(segment)/18.0) * (1.0-smoothstep(.70,.80,age))
			canvas.draw_line(a,b,Color(.1,.75,1,alpha*.25),cell*.19,true)
			canvas.draw_line(a,b,Color(.35,.95,1,alpha),cell*.055,true)
			canvas.draw_line(a,b,Color(.9,1,1,alpha),cell*.017,true)
	var front := 0 if orbit_position(at,cell,age,0,direction).y >= at.y else 1
	for index in [1-front, front]:
		var position := orbit_position(at,cell,age,index,direction)
		var depth := clampf((position.y-at.y)/(cell*.34),-1,1)
		var edge := cell*lerpf(1.0,1.55,smoothstep(0,.15,age))*(1.0+depth*.10)
		sprite(canvas,RHINO,position,edge,1.0-smoothstep(.75,.82,age))

static func blue_impact(canvas: CanvasItem, at: Vector2, cell: float, age: float, texture: Texture2D) -> void:
	var t := maxf(0,age)
	var fade := 1.0-smoothstep(.18,.52,t)
	sprite(canvas,texture,at,cell*lerpf(1.2,4.7,smoothstep(0,.32,t)),fade,t*.22)
	canvas.draw_arc(at,cell*(.25+t*5.0),0,TAU,64,Color(.3,.9,1,fade*.8),cell*.045,true)
	for index in 18:
		var angle := float(index)*TAU/18.0
		var point := at+Vector2.from_angle(angle)*cell*(.45+t*(3.0+float(index%3)))
		canvas.draw_circle(point,cell*.035*fade,Color(.25,.85,1,fade))
		canvas.draw_circle(point-Vector2.ONE*cell*.009,cell*.012*fade,Color(1,1,1,fade))
	canvas.draw_circle(at,cell*1.3,Color(.8,1,1,(1.0-smoothstep(0,.12,t))*.8))

static func sprite(canvas: CanvasItem, texture: Texture2D, at: Vector2, edge: float, alpha: float = 1.0, angle: float = 0.0) -> void:
	var extent := texture.get_size() * (edge / maxf(texture.get_width(), texture.get_height()))
	canvas.draw_set_transform(at, angle)
	canvas.draw_texture_rect(texture, Rect2(-extent*.5, extent), false, Color(1,1,1,alpha))
	canvas.draw_set_transform(Vector2.ZERO)

static func charge(canvas: CanvasItem, at: Vector2, edge: float, age: float, double_blast: bool) -> void:
	if double_blast:
		var reveal := smoothstep(.10,.45,age)
		sprite(canvas, PUTERI, at, edge, reveal)
	else:
		BoardArt.draw_dulang_animated(canvas,Rect2(at-Vector2.ONE*edge*.5,Vector2.ONE*edge),age*3.0,true)
		sprite(canvas,RHINO,at-Vector2(0,edge*.06),edge*.48,smoothstep(.02,.10,age))
	# Cream swirls grow behind the later impact without obscuring the food.
	sprite(canvas,SPLASH,at,edge*1.08,smoothstep(.20,.55,age)*.22,age*.35)

static func burst(canvas: CanvasItem, effect: Dictionary) -> void:
	var cell: float = effect.width
	var age: float = effect.age
	var double_blast: bool = effect.double_blast
	var spread := 1.6 if double_blast else 1.0
	var travel := 1.0-pow(1.0-clampf(age/.55,0,1),3)
	var fade := 1.0-smoothstep(.65,effect.life,age)
	var opacity := smoothstep(0,.06,age)*fade
	# Coverage follows the exact logical footprint; no square slot overlays.
	for index in effect.points.size():
		var point: Vector2 = effect.points[index]
		var arrival := smoothstep(.04,.25,age)
		var at: Vector2 = effect.a.lerp(point,arrival)
		sprite(canvas,SPLASH,at,cell*.90,opacity*.45,float(index)*.71)
	sprite(canvas,SPLASH,effect.a,cell*lerpf(1.1,3.6*spread,travel),opacity,age*.28)
	# Atlas cells retain their original transparency; balls travel independently.
	var slot := BALLS.get_size()/Vector2(4,2)
	for index in (14 if double_blast else 7):
		var angle := index*TAU/(14.0 if double_blast else 7.0)-PI*.5
		var radius := cell*(.3+travel*1.5*spread)
		var at: Vector2 = effect.a+Vector2.from_angle(angle)*radius
		at.y -= sin(travel*PI)*cell*.3
		var edge := cell*(.62 if double_blast else .72)*(1.0-.15*travel)
		var color_index := index%7
		var source := Rect2(Vector2(color_index%4,color_index/4)*slot,slot)
		canvas.draw_set_transform(at,age*(2.0 if index%2==0 else -2.0))
		canvas.draw_texture_rect_region(BALLS,Rect2(Vector2.ONE*-edge*.5,Vector2.ONE*edge),source,Color(1,1,1,opacity))
		canvas.draw_set_transform(Vector2.ZERO)
	if double_blast:
		sprite(canvas,PUTERI,effect.a-Vector2(0,cell*.70),cell*5.0,fade)
	else:
		# The rhino is an impact identity, never an idle board piece.
		sprite(canvas,BoardArt.BADAK_IDLE_BOWL,effect.a,cell*1.35,opacity)
		var spirit_alpha := smoothstep(.03,.12,age)*fade
		sprite(canvas,RHINO,effect.a-Vector2(0,cell*.08),cell*3.0,spirit_alpha)
