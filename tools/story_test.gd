extends Node

func _ready() -> void:
	run.call_deferred()

func run() -> void:
	SaveManager.save_path = "user://kuih_story_test.json"
	SaveManager.reset()
	SceneManager.manual = true
	SceneManager.story_group = StoryLibrary.PROLOGUE
	SceneManager.story_allow_skip = false
	var screen := StoryScreen.new()
	add_child(screen)
	await get_tree().process_frame
	await get_tree().process_frame
	assert(screen.pages.size() == 5)
	assert(not screen._skip_button.visible)
	assert(screen._tap_indicator.visible and screen._tap_indicator.target == screen._next_button)
	var original_size := screen._next_button.size
	assert(original_size.y >= 132)
	var screenshots := "--capture" in OS.get_cmdline_user_args()
	DirAccess.make_dir_recursive_absolute("res://.shots")
	for language in ["ms", "en"]:
		SaveManager.set_setting("language", language)
		for i in 5:
			screen.show_page(i, false)
			await get_tree().process_frame
			assert(screen._welcome.visible == (i == 1))
			assert(screen._art.texture != null)
			assert(screen._next_button.size.is_equal_approx(original_size))
			assert(screen._body.get_minimum_size().y <= screen._body.size.y)
			assert(screen._heading.get_minimum_size().y <= screen._heading.size.y)
			if screen._quote.visible:
				assert(screen._quote_text.get_minimum_size().y <= screen._quote_text.size.y)
			assert(screen._counter.text == "%d / 5" % (i + 1))
			assert(screen._tap_indicator.mouse_filter == Control.MOUSE_FILTER_IGNORE)
			if screenshots:
				await RenderingServer.frame_post_draw
				get_viewport().get_texture().get_image().save_png("res://.shots/story_%s_%02d_%d.png" % [language, i + 1, get_window().size.x])
	screen.show_page(0, false)
	var touch := InputEventScreenTouch.new()
	touch.position = Vector2(4, 700)
	touch.pressed = false
	screen._input(touch)
	assert(screen.index == 1)
	screen._on_next_pressed()
	assert(screen.index == 2)
	var endings := [0]
	screen.finished.connect(func(): endings[0] += 1)
	screen.show_page(4, false)
	screen._on_next_pressed()
	screen.finish()
	assert(endings[0] == 1)
	assert(ProgressionManager.story_read(StoryLibrary.PROLOGUE))
	screen.play(StoryLibrary.pages_for(StoryLibrary.PROLOGUE), true)
	assert(screen._skip_button.visible)
	SceneManager.story_next = SceneManager.JOURNEY
	screen.show_page(4, false)
	assert(screen._next_button.text == "Back to Map")
	screen.queue_free()
	await get_tree().process_frame
	print("STORY PASS: five pages, two languages, consistent controls, tap anywhere, finish once, replay")
	get_tree().quit()
