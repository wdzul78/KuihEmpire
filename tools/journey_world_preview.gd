extends Node

func _ready() -> void:
 SaveManager.save_path = "user://journey_world_preview.json"
 SaveManager.reset()
 ProgressionManager.complete_tutorial()
 for id in range(1,18):
  ProgressionManager.record_win(id,3,0)
 await get_tree().create_timer(4).timeout
 for language in ["en","ms"]:
  SaveManager.data.settings.language = language
  GameManager.pending_level_id = 18
  var map := JourneyMap.new()
  add_child(map)
  await get_tree().create_timer(.6).timeout
  assert(map._destination.visible and not map._nodes.has(31))
  assert(map._nodes[18].size.x > map._nodes[19].size.x)
  assert(map._scroll.get_global_rect().position.y > map._chapters[0].get_global_rect().end.y)
  for stage in [1,18,30]:
   map._select_stage(stage if stage < 19 else 18)
   if stage == 30:
    map._scroll.scroll_vertical = int(map._point(29).y-map._scroll.size.y*.5)
   await get_tree().create_timer(.3).timeout
   await RenderingServer.frame_post_draw
   get_viewport().get_texture().get_image().save_png("res://.analysis/journey-world-%s-%d.png" % [language,stage])
  map.free()
 print("Journey world: PASS (30 nodes, larger active node, clipped route below tabs, bilingual views and scrolling)")
 get_tree().quit()
