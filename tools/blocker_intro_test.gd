extends Node
func _ready() -> void:
 run.call_deferred()
func run() -> void:
 var controller := LevelController.new()
 controller.endless_mode = true
 add_child(controller)
 await get_tree().create_timer(.4).timeout
 controller.endless_mode = false
 controller.level.story_before = &""
 controller.level.blockers.clear()
 for kind in 6:
  controller.level.blockers.append(BlockerSpec.make(kind,[Vector2i(0,0)]))
  SaveManager.data["story_seen"].erase("blocker_intro_%d" % kind)
 controller._blocker_intro_prepared = false
 controller._begin_presentation()
 for kind in 6:
  assert(controller._active_blocker_intro == kind)
  assert(controller.story.visible and not controller.board.enabled)
  controller.story.close()
 assert(controller._active_blocker_intro == -1 and controller.board.enabled)
 for kind in 6:
  assert(ProgressionManager.story_seen(StringName("blocker_intro_%d" % kind)))
 controller.free()
 AudioManager.stop_music()
 print("Blocker introductions: PASS (six types, queued dialogue, input lock, once-only records)")
 get_tree().quit()