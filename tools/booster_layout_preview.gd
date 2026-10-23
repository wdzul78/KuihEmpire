extends LevelController

func _pause_after_interruption() -> void:
	pass

func _ready() -> void:
	endless_mode = true
	super._ready()
	await get_tree().create_timer(2.0).timeout
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://.analysis/booster-new-layout.png")
	get_tree().quit()
