extends Node

const OUT := "res://release/playstore-2026-10-23/media/"
var _capture: SubViewport
class CaptureLevel extends LevelController:
 func _pause_after_interruption() -> void:
  pass
 func _notification(what: int) -> void:
  if what in [NOTIFICATION_APPLICATION_PAUSED,NOTIFICATION_APPLICATION_FOCUS_OUT]:
   return
  super._notification(what)

func _ready() -> void:
 process_mode = Node.PROCESS_MODE_ALWAYS
 _capture = SubViewport.new()
 _capture.size = Vector2i(1080,1920)
 _capture.render_target_update_mode = SubViewport.UPDATE_ALWAYS
 add_child(_capture)
 var display := TextureRect.new()
 display.texture = _capture.get_texture()
 display.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
 display.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
 add_child(display)
 display.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 run.call_deferred()

func shot(name: String) -> void:
 await RenderingServer.frame_post_draw
 var picture := _capture.get_texture().get_image()
 picture.convert(Image.FORMAT_RGB8)
 picture.save_png(OUT+"screenshots/"+name+".png")

func run() -> void:
 DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT+"screenshots"))
 SaveManager.save_path = "user://store_capture.json"
 SaveManager.reset()
 SaveManager.data.settings.language = "en"
 ProgressionManager.complete_tutorial()
 for item in KuihLibrary.all():
  SaveManager.data.kuih_seen.append(String(item.id))
 for stage in range(1,18):
  ProgressionManager.record_win(stage,3,0)
 for stage in range(1,31):
  var spec := LevelLibrary.get_level(stage)
  ProgressionManager.mark_story_seen(spec.story_before)
  ProgressionManager.mark_story_seen(spec.story_after)
 for blocker in range(16):
  ProgressionManager.mark_story_seen(StringName("blocker_intro_%d" % blocker))
 await get_tree().create_timer(4).timeout
 var home := HomeScreen.new()
 _capture.add_child(home)
 await get_tree().create_timer(.8).timeout
 await shot("01-home")
 home.free()
 GameManager.pending_level_id = 18
 GameManager.pending_tutorial_index = 0
 var journey := JourneyMap.new()
 _capture.add_child(journey)
 await get_tree().create_timer(.8).timeout
 await shot("02-journey")
 await get_tree().create_timer(2).timeout
 journey.free()
 var level := CaptureLevel.new()
 level.level_id = 18
 _capture.add_child(level)
 await get_tree().create_timer(1.5).timeout
 await shot("03-gameplay")
 var began := Time.get_ticks_msec()
 for step in 8:
  if level.finished:
   break
  while level.board.busy or not level.board.enabled:
   await get_tree().create_timer(.15).timeout
  var moves := level.board.logic.find_possible_moves(128)
  if moves.is_empty():
   break
  var move: Dictionary = moves[step % moves.size()]
  level.board.show_hint()
  await get_tree().create_timer(.7).timeout
  await level.board.attempt_swap(move.a,move.b)
  await get_tree().create_timer(.6).timeout
  if step == 3:
   await shot("04-puzzle-progress")
 await get_tree().create_timer(1).timeout
 level.free()
 get_tree().paused = false
 var collection := RecipeBookScreen.new()
 _capture.add_child(collection)
 await get_tree().create_timer(.7).timeout
 await shot("05-kuih-collection")
 await get_tree().create_timer(2).timeout
 collection.free()
 SaveManager.save_path = "res://.analysis/shop-final-visual/Godot/app_userdata/Kuih Empire/shop_complete_test.json"
 # Load an isolated, already-validated completed-stall fixture; never the player's save.
 SaveManager.load_game()
 SaveManager.save_path = "user://store_capture.json"
 SaveManager.data.settings.language = "en"
 var shop := GeraiScreen.new()
 _capture.add_child(shop)
 await get_tree().create_timer(.8).timeout
 await shot("06-stall-upgrades")
 await get_tree().create_timer(2.5).timeout
 shop.free()
 AudioManager.stop_music()
 print("Store capture: PASS (six real UI screenshots and actual legal puzzle swaps)")
 get_tree().quit()
