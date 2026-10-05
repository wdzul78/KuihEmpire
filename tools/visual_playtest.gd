extends LevelController

## F6 entry point for art review, with a separate disposable save.
func _ready() -> void:
	SaveManager.save_path = "user://kuih_visual_playtest.json"
	SaveManager.reset()
	SaveManager.data["tutorial_done"] = true
	SaveManager.data["tutorial_index"] = TutorialLibrary.count()
	GameManager.pending_tutorial_index = 0
	level_id = 18 # All six normal kuih, no blockers obscuring the artwork.
	var preview_level := LevelLibrary.get_level(level_id)
	SaveManager.data["story_seen"] = [String(preview_level.story_before)]
	super._ready()
