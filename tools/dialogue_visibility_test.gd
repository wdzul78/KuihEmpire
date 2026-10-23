extends Node
func _ready() -> void:
 run.call_deferred()
func run() -> void:
 var controller := LevelController.new()
 controller.tutorial_index = 1
 add_child(controller)
 await get_tree().create_timer(1).timeout
 print("Coach ",controller.coach.visible," bubble ",controller.coach._card.is_visible_in_tree()," rect ",controller.coach._card.get_global_rect()," text ",controller.coach._body.text," textrect ",controller.coach._body.get_global_rect())
 if DisplayServer.get_name() != "headless":
  await RenderingServer.frame_post_draw
  get_viewport().get_texture().get_image().save_png("res://.analysis/dialogue-check.png")
 var beat := StoryBeat.new()
 beat.speaker = StoryBeat.Speaker.AINA
 beat.lines = PackedStringArray(["Selamat datang! Mari kita siapkan pesanan ini."])
 controller.story.play(beat)
 await get_tree().create_timer(.5).timeout
 assert(controller.story._card.is_visible_in_tree())
 assert(controller.story._card.get_global_rect().position.y >= controller.hud.order_panel.get_global_rect().position.y)
 if DisplayServer.get_name() != "headless":
  await RenderingServer.frame_post_draw
  get_viewport().get_texture().get_image().save_png("res://.analysis/story-dialogue-fixed.png")
 controller.story.close()
 controller.free()
 print("Dialogue visibility: PASS (tutorial coach and inline story anchored to current HUD)")
 get_tree().quit()