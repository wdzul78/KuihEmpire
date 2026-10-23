class_name SepitFlight
extends Sprite2D

## Native sprite animation: launch orbit, banked glide, landing and fade.
## One original texture; transform animation preserves the food illustration.
const PACE = preload("res://scripts/gameplay/animation_pace.gd")
const LAND_TIME := 1.55
const LIFE := 1.72
var origin := Vector2.ZERO
var target := Vector2.ZERO
var edge := 60.0
var age := 0.0
var base_scale := 1.0

func configure(start: Vector2, finish: Vector2, cell: float, _carry_kind: int = BoardCell.Special.NONE) -> void:
	origin = start
	target = finish
	edge = cell
	texture = BoardArt.HANTAR_ART
	region_enabled = true
	region_rect = BoardArt.delivery_region()
	base_scale = cell/maxf(region_rect.size.x,region_rect.size.y)
	scale = Vector2.ONE*base_scale
	position = start
	z_index = 20

func flight_position(time: float) -> Vector2:
	var departure := origin+Vector2(0,-edge*.45)
	if time < .40:
		var u := clampf(time/.40,0,1)
		return origin.lerp(departure,u)+Vector2(sin(u*TAU)*edge*.62,-sin(u*PI)*edge*.55)
	var u := smoothstep(.40,LAND_TIME,time)
	var direction := (target-departure).normalized()
	return departure.lerp(target,u)+direction.orthogonal()*sin(u*TAU)*edge*.65+Vector2(0,-sin(u*PI)*edge*.5)

func _process(delta: float) -> void:
	age += delta*PACE.SPEED
	if age >= LIFE:
		queue_free()
		return
	position = flight_position(minf(age,LAND_TIME))
	var heading := flight_position(minf(age+.015,LAND_TIME))-flight_position(maxf(age-.015,0))
	if heading.length_squared() > .01:
		# The illustration's pointed nose faces lower-left in its neutral pose.
		rotation = lerp_angle(rotation,heading.angle()-2.35,minf(1,delta*22))
	var flutter := .95+.06*cos(age*18)
	var landing := smoothstep(LAND_TIME,LIFE,age)
	scale = Vector2(1,flutter)*base_scale*lerpf(1.05,.70,landing)
	modulate.a = 1.0-landing
