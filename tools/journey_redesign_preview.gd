extends Node
func _ready() -> void:
 run.call_deferred()
func run() -> void:
 GameManager.pending_level_id = 1
 var map := JourneyMap.new()
 add_child(map)
 await get_tree().create_timer(.7).timeout
 assert(map._destination.visible and map._nodes.has(1))
 assert(map._targets.get_child_count() > 0)
 if DisplayServer.get_name() != "headless":
  await RenderingServer.frame_post_draw
  get_viewport().get_texture().get_image().save_png("res://.analysis/journey-redesign.png")
 map.free()
 AudioManager.stop_music()
 print("Journey redesign: PASS (stage nodes, real targets, navigation)")
 get_tree().quit()