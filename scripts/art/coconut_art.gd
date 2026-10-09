extends RefCounted

const SPLASH = preload("res://assets/vfx/coconut_v1/splash.png")
const BALLS = preload("res://assets/vfx/coconut_v1/balls.png")
const PUTERI = preload("res://assets/vfx/coconut_v1/puteri.png")
const RHINO = preload("res://assets/vfx/coconut_v1/rhino.png")

static func sprite(canvas: CanvasItem, texture: Texture2D, at: Vector2, edge: float, alpha: float = 1.0, angle: float = 0.0) -> void:
	var extent := texture.get_size() * (edge / maxf(texture.get_width(), texture.get_height()))
	canvas.draw_set_transform(at, angle)
	canvas.draw_texture_rect(texture, Rect2(-extent*.5, extent), false, Color(1,1,1,alpha))
	canvas.draw_set_transform(Vector2.ZERO)

static func charge(canvas: CanvasItem, at: Vector2, edge: float, age: float, double_blast: bool) -> void:
	if double_blast:
		var reveal := smoothstep(.10,.45,age)
		sprite(canvas, PUTERI, at, edge*lerpf(.65,1.0,reveal), reveal)
	else:
		BoardArt.draw_dulang_animated(canvas,Rect2(at-Vector2.ONE*edge*.5,Vector2.ONE*edge),age*3.0,true)
	# Cream swirls grow behind the later impact without obscuring the food.
	sprite(canvas,SPLASH,at,edge*1.08,smoothstep(.20,.55,age)*.22,age*.35)

static func burst(canvas: CanvasItem, effect: Dictionary) -> void:
	var cell: float = effect.width
	var age: float = effect.age
	var double_blast: bool = effect.double_blast
	if not double_blast:
		age *= .90/.55
	var spread := 1.6 if double_blast else 1.0
	var travel := 1.0-pow(1.0-clampf(age/.55,0,1),3)
	var fade := 1.0-smoothstep(.40,.90,age)
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
		var edge := cell*(.38 if double_blast else .42)*(1.0-.25*travel)
		var color_index := index%7
		var source := Rect2(Vector2(color_index%4,color_index/4)*slot,slot)
		canvas.draw_set_transform(at,age*(2.0 if index%2==0 else -2.0))
		canvas.draw_texture_rect_region(BALLS,Rect2(Vector2.ONE*-edge*.5,Vector2.ONE*edge),source,Color(1,1,1,opacity))
		canvas.draw_set_transform(Vector2.ZERO)
	if double_blast:
		sprite(canvas,PUTERI,effect.a-Vector2(0,cell*.70),cell*2.7,opacity)
	else:
		# The rhino is an impact identity, never an idle board piece.
		var spirit_alpha := smoothstep(.07,.18,age)*fade*.68
		sprite(canvas,RHINO,effect.a-Vector2(0,cell*(1.05+age*.3)),cell*1.8,spirit_alpha)
