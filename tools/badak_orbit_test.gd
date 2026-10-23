extends Node

const ART = preload("res://scripts/art/coconut_art.gd")

func _ready() -> void:
	var at := Vector2(350,500)
	var cell := 90.0
	for age in [0.0,.08,.18,.35,.60,.78]:
		var a := ART.orbit_position(at,cell,age,0)
		var b := ART.orbit_position(at,cell,age,1)
		assert(a.lerp(b,.5).distance_to(at) < .001)
	assert(ART.orbit_position(at,cell,.195,0).x < at.x)
	assert(ART.orbit_position(at,cell,.0975,0).y > at.y)
	assert(ART.orbit_position(at,cell,.78,0).is_equal_approx(at))
	for direction in [Vector2.RIGHT,Vector2.LEFT,Vector2.UP,Vector2.DOWN]:
		assert(ART.orbit_position(at,cell,0,0,direction).is_equal_approx(at+direction*cell*.5))
		assert(ART.orbit_position(at,cell,.78,0,direction).is_equal_approx(at))
		var first := ART.orbit_position(at,cell,.12,0,direction)
		var second := ART.orbit_position(at,cell,.12,1,direction)
		assert(first.lerp(second,.5).distance_to(at) < .001)
	assert(ART.orbit_position(at,cell,.001,0).distance_to(ART.orbit_position(at,cell,0,0)) < .03)
	var vfx := GameVfx.new()
	add_child(vfx)
	vfx.dulang_charge(at,PackedVector2Array(),cell,[],true)
	assert(vfx.effects.size() == 1 and vfx.effects[0].double_blast)
	for age in [.18,.45,.80,.96]:
		vfx.effects[0].age = age
		vfx.queue_redraw()
		await get_tree().process_frame
		if DisplayServer.get_name() != "headless":
			await RenderingServer.frame_post_draw
			get_viewport().get_texture().get_image().save_png("res://.shots/badak_orbit_%d.png" % int(age*100))
	vfx.dulang_burst(at,PackedVector2Array(),cell,true)
	assert(not vfx.effects.any(func(e): return e.kind == "charge"))
	await get_tree().create_timer(1.5).timeout
	assert(vfx.effects.is_empty())
	vfx.free()
	print("Badak orbit: PASS (shared centre, position exchange, contraction, splash/reveal, cleanup)")
	get_tree().quit()
