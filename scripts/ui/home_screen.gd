class_name HomeScreen
extends Control

## Home screen - intentionally simple (Master Plan section 49).

var _stage_label: Label
var _coin_display: CoinDisplay
var _play_button: Button
var _story_button: Button


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	UIKit.apply_root_theme(self)
	_build()
	_refresh()
	ProgressionManager.stars_changed.connect(func(_a: int, _b: int) -> void: _refresh())
	EconomyManager.coins_changed.connect(func(_a: int) -> void: _refresh())
	ProgressionManager.recipe_unlocked.connect(func(_a: StringName) -> void: _refresh())


func _build() -> void:
	var backdrop := GeraiBackdrop.new()
	backdrop.background_id = &"stall_dawn"
	backdrop.show_counter = false
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(backdrop)

	var margin := UIKit.margin(40)
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(margin)

	var column := UIKit.vbox(18)
	margin.add_child(column)

	var top_row := UIKit.hbox(14)
	column.add_child(top_row)
	_coin_display = CoinDisplay.new()
	_coin_display.icon_size = 76.0
	top_row.add_child(_coin_display)
	var grow := Control.new()
	grow.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	top_row.add_child(grow)
	var settings := UIKit.button("Settings", 28, Palette.WOOD_LIGHT)
	settings.custom_minimum_size = Vector2(220, 84)
	settings.pressed.connect(func() -> void:
		AudioManager.play(AudioManager.Sfx.TAP)
		SceneManager.goto(SceneManager.SETTINGS)
	)
	top_row.add_child(settings)

	var brand := PanelContainer.new()
	brand.add_theme_stylebox_override("panel", UIKit.wood_box(Palette.WOOD, Palette.WOOD_DARK, 14))
	column.add_child(brand)
	var brand_stack := UIKit.vbox(4)
	brand.add_child(brand_stack)
	brand_stack.add_child(UIKit.brand_logo(Vector2(0, 340)))
	brand_stack.add_child(UIKit.label("Match. Serve. Grow.", 34, Palette.PINK_PALE))

	var aina_row := UIKit.hbox(18)
	column.add_child(aina_row)
	var portrait := CharacterIcon.new()
	portrait.cast = CharacterIcon.Cast.AINA
	portrait.expression = CharacterIcon.Mood.CHEEKY
	portrait.custom_minimum_size = Vector2(190, 190)
	portrait.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	aina_row.add_child(portrait)
	var speech := PanelContainer.new()
	speech.add_theme_stylebox_override("panel", UIKit.cream_box())
	speech.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var speech_text := UIKit.wrap_label(
		"Good kuih, brighter days! Ready to open the stall?",
		28, Palette.INK, HORIZONTAL_ALIGNMENT_LEFT
	)
	speech_text.custom_minimum_size = Vector2(0, 120)
	speech_text.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	speech.add_child(speech_text)
	aina_row.add_child(speech)

	var teaser := PanelContainer.new()
	teaser.add_theme_stylebox_override("panel", UIKit.cream_box())
	column.add_child(teaser)
	var teaser_stack := UIKit.vbox(8)
	teaser.add_child(teaser_stack)
	teaser_stack.add_child(UIKit.label("ON THE TRAY TODAY", 26, Palette.WOOD_DARK))
	var tray := UIKit.hbox(8)
	tray.alignment = BoxContainer.ALIGNMENT_CENTER
	teaser_stack.add_child(tray)
	for id in [&"onde_onde", &"kuih_lapis", &"seri_muka", &"kuih_ketayap", &"ang_ku_kueh", &"vadai"]:
		var dish := KuihIcon.new()
		dish.kuih = KuihLibrary.get_kuih(id)
		dish.custom_minimum_size = Vector2(140, 150)
		tray.add_child(dish)
	teaser_stack.add_child(UIKit.label("Collect them all in the Recipe Book", 22, Palette.INK_SOFT))

	var grow2 := Control.new()
	grow2.size_flags_vertical = Control.SIZE_EXPAND_FILL
	grow2.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_child(grow2)

	var play_card := PanelContainer.new()
	play_card.add_theme_stylebox_override("panel", UIKit.cream_box())
	column.add_child(play_card)
	var play_stack := UIKit.vbox(10)
	play_card.add_child(play_stack)
	_stage_label = UIKit.label("", 30, Palette.WOOD_DARK)
	play_stack.add_child(_stage_label)
	_play_button = UIKit.primary_button("PLAY")
	_play_button.pressed.connect(_on_play)
	play_stack.add_child(_play_button)

	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 16)
	grid.add_theme_constant_override("v_separation", 16)
	column.add_child(grid)

	var journey := UIKit.button("Journey Map", 30, Palette.LEAF)
	journey.custom_minimum_size = Vector2(0, 104)
	journey.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	journey.pressed.connect(func() -> void:
		AudioManager.play(AudioManager.Sfx.TAP)
		SceneManager.goto(SceneManager.JOURNEY)
	)
	grid.add_child(journey)

	var recipes := UIKit.button("Recipe Book", 30, Palette.PINK)
	recipes.custom_minimum_size = Vector2(0, 104)
	recipes.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	recipes.pressed.connect(func() -> void:
		AudioManager.play(AudioManager.Sfx.TAP)
		SceneManager.goto(SceneManager.RECIPE_BOOK)
	)
	grid.add_child(recipes)

	var gerai := UIKit.button("My Gerai", 30, Palette.GOLD)
	gerai.custom_minimum_size = Vector2(0, 104)
	gerai.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	gerai.pressed.connect(func() -> void:
		AudioManager.play(AudioManager.Sfx.TAP)
		SceneManager.goto(SceneManager.GERAI)
	)
	grid.add_child(gerai)

	var play_again := UIKit.button("Play Stage", 30, Palette.WOOD_LIGHT)
	play_again.custom_minimum_size = Vector2(0, 104)
	play_again.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	play_again.pressed.connect(_on_play)
	grid.add_child(play_again)

	_story_button = UIKit.button("Story", 30, Palette.PINK_DARK)
	_story_button.custom_minimum_size = Vector2(0, 104)
	_story_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_story_button.pressed.connect(_on_story)
	grid.add_child(_story_button)


## The storyline stays readable forever - a cozy game should let you re-read it.
func _on_story() -> void:
	AudioManager.play(AudioManager.Sfx.TAP)
	SceneManager.goto_story(StoryLibrary.PROLOGUE, true, SceneManager.HOME)


func _on_play() -> void:
	AudioManager.play(AudioManager.Sfx.TAP)
	GameManager.play_next()


func _refresh() -> void:
	if not is_instance_valid(_stage_label):
		return
	if ProgressionManager.needs_tutorial():
		var next_tutorial := maxi(1, ProgressionManager.tutorial_index())
		var stage := TutorialLibrary.get_stage(next_tutorial)
		_stage_label.text = "Next: Tutorial  ·  %s" % stage.title
		if is_instance_valid(_play_button):
			_play_button.text = "START TUTORIAL"
	else:
		var next_level := ProgressionManager.current_level()
		var stars := ProgressionManager.total_stars()
		var recipes := ProgressionManager.unlocked_recipes().size()
		_stage_label.text = "Next: Stage %d   ·   %d ★   ·   %d / %d recipes" % [
			next_level, stars, recipes, KuihLibrary.count()
		]
		if is_instance_valid(_play_button):
			_play_button.text = "PLAY"
	if is_instance_valid(_story_button):
		_story_button.visible = ProgressionManager.tutorial_done()
	if is_instance_valid(_coin_display):
		_coin_display.amount = EconomyManager.coins()
