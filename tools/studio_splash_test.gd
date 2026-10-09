extends Node

func _ready() -> void:
	var boot := preload("res://scenes/boot/boot.tscn").instantiate()
	add_child(boot)
	await get_tree().create_timer(1.1).timeout
	var splash := boot.get_node("StudioSplash") as Control
	assert(splash.visible and splash.modulate.a == 1.0)
	assert(splash.size == boot.size)
	var logo := splash.get_child(1) as TextureRect
	assert(logo.texture != null and logo.size.x > 0)
	assert(logo.material is ShaderMaterial and is_equal_approx(logo.modulate.a, 1.0))
	assert(logo.scale.is_equal_approx(Vector2.ONE))
	assert(logo.position.x >= 0 and logo.position.y >= 0)
	if DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
		DirAccess.make_dir_recursive_absolute("res://.shots")
		get_viewport().get_texture().get_image().save_png("res://.shots/studio_splash.png")
	await get_tree().create_timer(2.1).timeout
	assert(not boot.has_node("StudioSplash"))
	print("Studio splash: PASS (logo, sizing and title transition)")
	boot.queue_free()
	await get_tree().process_frame
	get_tree().quit()
