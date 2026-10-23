extends SceneTree

func _initialize() -> void:
 run.call_deferred()

func run() -> void:
 SaveManager.save_path = "user://release_smoke.json"
 SaveManager.reset()
 var screens := [HomeScreen.new(),JourneyMap.new(),GeraiScreen.new(),RecipeBookScreen.new()]
 for screen in screens:
  root.add_child(screen)
  await create_timer(.2).timeout
  screen.free()
 var art: Texture2D = load("res://assets/ui/journey_world_v2/village.png")
 assert(art != null)
 assert(FileAccess.file_exists("res://assets/ui/journey_world_v2/centers.json"))
 assert(ResourceLoader.exists(AudioManager.GAMEPLAY_PLAYLIST[0]))
 assert(not FileAccess.file_exists("res://assets/ui/journey_world_v1/world.png"))
 AudioManager.stop_music()
 print("PACKAGED runtime smoke: PASS (home, Journey, stall, collection, map JSON, new BGM; superseded map excluded)")
 quit()
