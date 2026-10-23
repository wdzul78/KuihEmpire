class_name HomeScreen
extends Control

# Normalized layer rectangles keep the reference composition at every viewport size.
var _coin_display: CoinDisplay
var _play_button: Button
var _play_label: Label
var _story_button: Button
var _profile_label: Label
var _avatar: TextureRect
var _star_label: Label
var _level_label: Label
var _total_score_label: Label
var _progress: ProgressBar
var _animated: Array[Control] = []
var _clock := 0.0

func _ready() -> void:
	AudioManager.play_music(AudioManager.MENU_MUSIC)
	AudioManager.set_music_ducked(false)
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	UIKit.apply_root_theme(self)
	_build()
	_refresh()
	_fit_menu_text.call_deferred()
	resized.connect(func() -> void: _fit_menu_text.call_deferred())
	MobileLayout.bind(self,["BackgroundLayer"])
	ProgressionManager.stars_changed.connect(func(_a: int, _b: int) -> void: _refresh())
	EconomyManager.stars_changed.connect(func(_a: int) -> void: _refresh())
	EconomyManager.coins_changed.connect(func(_a: int) -> void: _refresh())
	# Resume saved discovery presentations after restart without paying again.
	RecipePresentation.present_pending.call_deferred(self)

func _place(node: Control, rect: Rect2, parent: Control = self) -> Control:
	parent.add_child(node)
	node.anchor_left = rect.position.x
	node.anchor_top = rect.position.y
	node.anchor_right = rect.end.x
	node.anchor_bottom = rect.end.y
	node.offset_left = 0
	node.offset_top = 0
	node.offset_right = 0
	node.offset_bottom = 0
	return node

func _art(id: String, rect: Rect2, animated: bool = false, version: String = "v1") -> TextureRect:
	var node := TextureRect.new()
	node.name = id.capitalize() + "Layer"
	node.texture = load("res://assets/menu/%s/%s.png" % [version, id])
	node.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	node.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_place(node, rect)
	if animated:
		_animated.append(node)
	return node

func _panel(rect: Rect2, cream: bool = true) -> Panel:
	var node := Panel.new()
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	node.add_theme_stylebox_override("panel", UIKit.cream_box() if cream else UIKit.wood_box(Palette.WOOD, Palette.WOOD_DARK))
	_place(node, rect)
	return node

func _label(value: String, rect: Rect2, font_size: int = 28, parent: Control = self) -> Label:
	var node := UIKit.label(value, font_size)
	node.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_place(node, rect, parent)
	return node

func _button(value: String, rect: Rect2, action: Callable, fill: Color = Palette.PAPER, font_size: int = 28) -> Button:
	var node := UIKit.button(value, font_size, fill)
	node.custom_minimum_size = Vector2.ZERO
	for state in ["normal", "hover", "pressed", "disabled"]:
		var style := node.get_theme_stylebox(state).duplicate() as StyleBox
		style.content_margin_left = 0
		style.content_margin_right = 0
		style.content_margin_top = 0
		style.content_margin_bottom = 0
		node.add_theme_stylebox_override(state, style)
	node.add_theme_color_override("font_color", Palette.INK)
	_place(node, rect)
	node.pressed.connect(action)
	return node


# Texture-backed buttons retain native keyboard/touch/focus behavior.
func _art_button(id: String, rect: Rect2, action: Callable) -> Button:
	var button := _button("", rect, action)
	for state in ["normal", "hover", "pressed", "disabled"]:
		var style := StyleBoxTexture.new()
		style.texture = _framed_texture(id)
		style.modulate_color = Color(.87, .87, .87) if state == "pressed" else Color(1.07, 1.07, 1.07) if state == "hover" else Color.WHITE
		button.add_theme_stylebox_override(state, style)
	var focus := UIKit.flat_box(Color.TRANSPARENT, Palette.GOLD, 0, 3, 24)
	button.add_theme_stylebox_override("focus", focus)
	return button

func _framed_texture(id: String) -> Texture2D:
	if id in ["nav_story", "nav_records", "nav_shop", "nav_achievements"]:
		var artwork_id := "recipes" if id == "nav_story" else id.trim_prefix("nav_")
		var artwork: Texture2D = load("res://assets/menu/nav_v4/%s.png" % artwork_id)
		var framed := AtlasTexture.new()
		framed.atlas = artwork
		framed.region = artwork.get_image().get_used_rect()
		return framed
	if id == "play":
		var source: Texture2D = load("res://assets/menu/play_v5/play_button.png")
		var cutout := AtlasTexture.new()
		cutout.atlas = source
		cutout.region = Rect2(45, 64, 1978, 729)
		return cutout
	var texture: Texture2D = load("res://assets/menu/v2/%s.png" % id)
	# Trim transparent export margins in Godot; retain the untouched PNG sources.
	var bounds := {
		"nav_story": Rect2(40, 47, 1172, 1161),
		"nav_records": Rect2(41, 48, 1172, 1167),
		"nav_shop": Rect2(71, 88, 1112, 1077),
		"nav_achievements": Rect2(45, 50, 1163, 1158),
		"tagline": Rect2(40, 121, 2092, 449),
	}
	if not bounds.has(id):
		return texture
	var atlas := AtlasTexture.new()
	atlas.atlas = texture
	atlas.region = bounds[id]
	return atlas

func _build() -> void:
	var backdrop := GeraiBackdrop.new()
	backdrop.name = "BackgroundLayer"
	backdrop.background_context = "menu"
	backdrop.follow_active_stall = true
	_place(backdrop, Rect2(0, 0, 1, 1))
	# Cat is behind the character, logo and all interactive UI.
	var cat := _art("cat", Rect2(.727, .400, .36, .087))
	var cat_crop := AtlasTexture.new()
	cat_crop.atlas = cat.texture
	cat_crop.region = Rect2(12, 140, 1512, 744)
	cat.texture = cat_crop
	cat.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	var character_clip := Control.new()
	character_clip.name = "AinaCrop"
	character_clip.clip_contents = true
	character_clip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_place(character_clip, Rect2(-.19, .24, .96, .46))
	var aina := _art("aina", Rect2(0, 0, 1, 1), true)
	remove_child(aina)
	_place(aina, Rect2(0, 0, 1, 1.70), character_clip)
	aina.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT
	var logo := UIKit.brand_logo(Vector2.ZERO)
	_place(logo, Rect2(.405, .120, .565, .200))
	_animated.append(logo)
	var banner := _art("tagline", Rect2(.49, .307, .40, .045), false, "v2")
	banner.texture = _framed_texture("tagline")
	banner.stretch_mode = TextureRect.STRETCH_SCALE
	var slogan := TitleArt.create("sweetness_smile", "Sweetness in Every Smile")
	slogan.name = "SloganGraphic"
	_place(slogan, Rect2(.535, .315, .310, .025))
	_art("foreground", Rect2(-.10, .570, .80, .230))
	_play_button = _art_button("play", Rect2(.44, .556, .56, .115), _on_play)
	# The supplied artwork contains the triangle; keep the live level on its left.
	_play_label = _label("Lvl.", Rect2(.115, .29, .17, .43), 56, _play_button)
	UIKit.set_text_color(_play_label, Color.WHITE)
	_play_label.add_theme_color_override("font_outline_color", Color("064509"))
	_play_label.add_theme_constant_override("outline_size", 18)
	_play_button.accessibility_name = "Play"
	_play_button.tooltip_text = "Play"
	_play_button.name = "PlayButton"
	var endless := _button("Endless Test", Rect2(.625,.695,.32,.033), func() -> void: SceneManager.goto("res://scenes/game/endless_screen.tscn"))
	endless.name = "EndlessTestLink"
	endless.visible = OS.has_feature("debug")
	endless.flat = true
	endless.add_theme_font_size_override("font_size",32)


	# Header follows the user layout: coins/hearts stacked below the left profile.
	var profile := _panel(Rect2(.505, .014, .46, .088))
	profile.name = "PlayerProfilePanel"
	profile.add_theme_stylebox_override("panel", _header_box("profile"))
	_avatar = AvatarLibrary.icon(str(SaveManager.data.get("profile", {}).get("avatar", "aina")))
	_place(_avatar, Rect2(.060, .155, .24, .67), profile)
	_profile_label = _label("", Rect2(.35, .15, .59, .30), 38, profile)

	_level_label = _label("", Rect2(.29, .13, .36, .72), 96, _play_button)
	UIKit.set_text_color(_level_label, Color("fffbea"))
	_level_label.add_theme_color_override("font_outline_color", Color("064509"))
	_level_label.add_theme_constant_override("outline_size", 18)
	_progress = ProgressBar.new()
	_progress.show_percentage = false
	_progress.max_value = 10
	_progress.add_theme_stylebox_override("background", StyleBoxEmpty.new())
	_progress.add_theme_stylebox_override("fill", UIKit.flat_box(Color("71d12b"), Color("4b9b17"), 0, 2, 12))
	_place(_progress, Rect2(.367, .69, .568, .13), profile)
	_progress.hide()
	_label("Score", Rect2(.365, .53, .10, .19), 18, profile).add_theme_color_override("font_color", Color.WHITE)
	# The illustration already contains the score track; align text inside it.
	_total_score_label = _label("", Rect2(.465, .505, .46, .245), 34, profile)
	UIKit.set_text_color(_total_score_label, Color("fffdf2"))
	_total_score_label.clip_text = true
	_total_score_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	# Preserve the painted circular frame and use an actual square for its portrait.
	var layout_profile := func() -> void:
		var texture := profile.get_theme_stylebox("panel").texture as Texture2D
		profile.offset_bottom = profile.offset_top + profile.size.x / texture.get_size().aspect() - size.y * (.088)
		var diameter := profile.size.x * .245
		_avatar.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
		_avatar.size = Vector2(diameter, diameter)
		_avatar.position = profile.size * Vector2(.176, .49) - _avatar.size * .5
	profile.resized.connect(layout_profile)
	layout_profile.call_deferred()
	_coin_display = CoinDisplay.new()
	_coin_display.icon_size = 76
	_coin_display.dark_style = true
	_coin_display.illustrated_style = true
	_coin_display.uniform_bar_height = true
	_coin_display.square_plus = false
	_coin_display.pill_shape = true
	_coin_display.name = "MainMenuCoinMeter"
	_place(_coin_display, Rect2(.055, .083, .375, .061))
	var heart := HeartDisplay.new()
	heart.compact_count = true
	heart.square_plus = false
	heart.pill_shape = true
	_place(heart, Rect2(.055, .020, .375, .061))
	var star := StarMeterFrame.new()
	star.name = "StarCounter"
	star.show()
	star.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_place(star, Rect2(.055, .147, .375, .064))
	_star_label = _label("", Rect2(.30, .08, .49, .84), 46, star)
	_star_label.add_theme_color_override("font_color", Palette.WOOD_DARK)
	_star_label.add_theme_color_override("font_outline_color", Palette.WOOD_DARK)
	_star_label.add_theme_color_override("font_outline_color", Color("fffdf2"))
	_star_label.add_theme_constant_override("outline_size", 3)
	var settings := _button("", Rect2(.060, .884, .11, .062), func() -> void: SceneManager.goto(SceneManager.SETTINGS))
	GameplaySkin.button(settings, "settings")
	settings.name = "SettingsButton"
	settings.accessibility_name = MenuText.text("settings")
	settings.tooltip_text = MenuText.text("settings")

	var captions := ["recipes", "records", "shop", "achievements"]
	var symbols := ["â–¤", "â˜…", "âŒ‚", "â–¥"]
	var actions: Array[Callable] = [func() -> void: SceneManager.goto(SceneManager.RECIPE_BOOK), _show_records, func() -> void: SceneManager.goto(SceneManager.GERAI), _show_achievements]
	for i in range(4):
		var x := .22 + i * .18
		var button := _art_button("nav_story" if i == 0 else "nav_" + captions[i], Rect2(x, .870, .17, .095), actions[i])
		button.name = captions[i].capitalize() + "Button"
		button.accessibility_name = MenuText.text(captions[i])
		button.tooltip_text = MenuText.text(captions[i])
		if i == 0:
			_story_button = button
	var journey := _button("", Rect2(.635, .741, .29, .096), func() -> void: SceneManager.goto(SceneManager.JOURNEY))
	journey.name = "JourneyButton"
	journey.accessibility_name = "Journey"
	journey.tooltip_text = "Journey"
	var map_texture := AtlasTexture.new()
	map_texture.atlas = load("res://assets/ui/titles_v1/journey.png")
	map_texture.region = Rect2(30, 141, 946, 612)
	ButtonArt.apply(journey, map_texture)

func _header_box(id: String) -> StyleBoxTexture:
	var box := StyleBoxTexture.new()
	var source: Texture2D = load("res://assets/menu/profile_v4/profile.png" if id == "profile" else "res://assets/menu/v3/%s.png" % id)
	var atlas := AtlasTexture.new()
	atlas.atlas = source
	atlas.region = source.get_image().get_used_rect()
	box.texture = atlas
	return box

func _process(delta: float) -> void:
	_clock += delta
	for i in range(_animated.size()):
		var node := _animated[i]
		node.pivot_offset = node.size * Vector2(.5, .8)
		var wave := sin(_clock * (1.4 if i == 0 else .9) + i)
		node.scale = Vector2(1.0 + wave * .003, 1.0 + wave * .007)
		node.rotation = wave * (.003 if i == 1 else .001)

func _on_story() -> void:
	AudioManager.play(AudioManager.Sfx.TAP)
	SceneManager.goto(SceneManager.RECIPE_BOOK)

func _on_play() -> void:
	AudioManager.play(AudioManager.Sfx.TAP)
	GameManager.play_next()

func _refresh() -> void:
	if not is_instance_valid(_play_label):
		return
	var stars := EconomyManager.stars()
	var player_name: String = str(SaveManager.data.get("profile", {}).get("name", "Player"))
	_profile_label.text = player_name
	_avatar.texture = AvatarLibrary.portrait(str(SaveManager.data.get("profile", {}).get("avatar", "aina")))
	_level_label.text = str(ProgressionManager.current_level())
	_profile_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	_progress.value = stars % 10
	_total_score_label.text = str(ProgressionManager.total_best_score())
	_star_label.text = str(stars)
	_coin_display.amount = EconomyManager.coins()
	_play_label.text = "Lvl."
	_fit_menu_text.call_deferred()

func _fit_menu_text() -> void:
	if not is_instance_valid(_level_label):
		return
	for label_node in [_level_label, _total_score_label, _play_label]:
		var maximum := 96 if label_node == _level_label else 56 if label_node == _play_label else 34
		var available := _play_button.size * Vector2(.36, .72) if label_node == _level_label else _play_button.size * Vector2(.17, .43) if label_node == _play_label else Vector2(_total_score_label.get_parent().size.x * .46, _total_score_label.get_parent().size.y * .245)
		var font: Font = label_node.get_theme_font("font")
		var fitted := maximum
		while fitted > 14 and (font.get_string_size(label_node.text, HORIZONTAL_ALIGNMENT_LEFT, -1, fitted).x > available.x - 10 or font.get_height(fitted) > available.y):
			fitted -= 1
		label_node.add_theme_font_size_override("font_size", fitted)

func _popup(title: String, body: String) -> void:
	var overlay := Control.new()
	overlay.name = "MenuPopup"
	_place(overlay, Rect2(0, 0, 1, 1))
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, .65)
	_place(dim, Rect2(0, 0, 1, 1), overlay)
	var card := Panel.new()
	card.add_theme_stylebox_override("panel", UIKit.cream_box())
	_place(card, Rect2(.12, .24, .76, .50), overlay)
	_label(title, Rect2(.04, .03, .92, .12), 38, card)
	var scroll := ScrollContainer.new()
	_place(scroll, Rect2(.05, .18, .9, .62), card)
	var content := UIKit.wrap_label(body, 27)
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(content)
	var close := UIKit.button(MenuText.text("close"), 28)
	_place(close, Rect2(.20, .84, .60, .12), card)
	close.pressed.connect(overlay.queue_free)

func _show_records() -> void:
	var rows := MenuText.text("local") + "\n\n"
	var count := 0
	for id in range(1, LevelLibrary.count() + 1):
		var record := ProgressionManager.level_record(id)
		if int(record.get("stars", 0)) > 0:
			rows += "%s %d    %s\n" % [MenuText.text("stage"), id, "â˜…".repeat(int(record["stars"]))]
			count += 1
	if count == 0:
		rows += MenuText.text("empty")
	_popup(MenuText.text("records"), rows)

func _show_achievements() -> void:
	SceneManager.goto(SceneManager.ACHIEVEMENTS)
