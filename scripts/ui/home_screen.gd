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
	MobileLayout.bind(self,["BackgroundLayer"])
	ProgressionManager.stars_changed.connect(func(_a: int, _b: int) -> void: _refresh())
	EconomyManager.coins_changed.connect(func(_a: int) -> void: _refresh())

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
	if id == "play":
		var source: Texture2D = load("res://assets/menu/v3/play_button.png")
		var cutout := AtlasTexture.new()
		cutout.atlas = source
		cutout.region = Rect2(124, 98, 1735, 572)
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

class MenuPlayGlyph extends Control:
	func _init() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		resized.connect(queue_redraw)
	func _draw() -> void:
		var points := PackedVector2Array([Vector2(size.x * .08, size.y * .04), Vector2(size.x * .95, size.y * .5), Vector2(size.x * .08, size.y * .96)])
		draw_colored_polygon(points, Color("fffbea"))
		points.append(points[0])
		draw_polyline(points, Color("285922"), 5, true)

func _build() -> void:
	var backdrop := _art("background", Rect2(0, 0, 1, 1))
	backdrop.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	# Cat is behind the character, logo and all interactive UI.
	_art("cat", Rect2(.76, .42, .22, .08), true)
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
	_place(logo, Rect2(.30, .153, .68, .23))
	_animated.append(logo)
	var banner := _art("tagline", Rect2(.383, .358, .52, .045), false, "v2")
	banner.texture = _framed_texture("tagline")
	banner.stretch_mode = TextureRect.STRETCH_SCALE
	var slogan := TitleArt.create("sweetness_smile", "Sweetness in Every Smile")
	slogan.name = "SloganGraphic"
	_place(slogan, Rect2(.410, .365, .467, .031))
	_art("foreground", Rect2(-.10, .584, .80, .225))
	_play_button = _art_button("play", Rect2(.36, .556, .60, .115), _on_play)
	_play_label = _label(MenuText.text("play"), Rect2(.40, .23, .45, .47), 65, _play_button)
	_play_label.hide()
	_play_button.accessibility_name = "Play"
	_play_button.tooltip_text = "Play"
	_play_button.name = "PlayButton"

	# Header follows the user layout: coins/hearts stacked below the left profile.
	var profile := _panel(Rect2(.025, .028, .43, .085))
	profile.name = "PlayerProfilePanel"
	profile.add_theme_stylebox_override("panel", _header_box("profile"))
	_avatar = AvatarLibrary.icon(str(SaveManager.data.get("profile", {}).get("avatar", "aina")))
	_place(_avatar, Rect2(.060, .155, .24, .67), profile)
	_profile_label = _label("", Rect2(.35, .185, .44, .20), 34, profile)
	_label(MenuText.text("maker"), Rect2(.35, .375, .59, .15), 22, profile)
	_level_label = _label("", Rect2(.80, .195, .14, .18), 25, profile)
	_level_label.add_theme_color_override("font_color", Palette.WOOD)
	_progress = ProgressBar.new()
	_progress.show_percentage = false
	_progress.max_value = 10
	_progress.add_theme_stylebox_override("background", StyleBoxEmpty.new())
	_progress.add_theme_stylebox_override("fill", UIKit.flat_box(Color("71d12b"), Color("4b9b17"), 0, 2, 12))
	_place(_progress, Rect2(.367, .69, .568, .13), profile)
	_progress.hide()
	# The illustration already contains the score track; align text inside it.
	_total_score_label = _label("", Rect2(.367, .568, .566, .175), 28, profile)
	_total_score_label.add_theme_color_override("font_color", Palette.PAPER)
	_total_score_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	# Preserve the painted circular frame and use an actual square for its portrait.
	var layout_profile := func() -> void:
		var texture := profile.get_theme_stylebox("panel").texture as Texture2D
		profile.offset_bottom = profile.offset_top + profile.size.x / texture.get_size().aspect() - size.y * (.085)
		var diameter := profile.size.x * .24
		_avatar.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
		_avatar.size = Vector2(diameter, diameter)
		_avatar.position = profile.size * Vector2(.18, .49) - _avatar.size * .5
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
	_place(_coin_display, Rect2(.075, .132, .31, .038))
	var heart := HeartDisplay.new()
	heart.compact_count = true
	heart.square_plus = false
	heart.pill_shape = true
	_place(heart, Rect2(.075, .174, .31, .038))
	var star := StarMeterFrame.new()
	star.name = "StarCounter"
	star.hide()
	star.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_place(star, Rect2(.675, .130, .29, .045))
	_star_label = _label("", Rect2(.32, .16, .63, .68), ResourceBarArt.FONT_SIZE, star)
	_star_label.add_theme_color_override("font_color", Palette.WOOD_DARK)
	_star_label.add_theme_color_override("font_outline_color", Palette.WOOD_DARK)
	_star_label.add_theme_constant_override("outline_size", 0)
	var settings := _button("", Rect2(.850, .028, .10, .056), func() -> void: SceneManager.goto(SceneManager.SETTINGS))
	for state in ["normal", "hover", "pressed"]:
		settings.add_theme_stylebox_override(state, _header_box("settings"))
	settings.name = "SettingsButton"
	settings.accessibility_name = MenuText.text("settings")
	settings.tooltip_text = MenuText.text("settings")

	var captions := ["recipes", "records", "shop", "achievements"]
	var symbols := ["▤", "★", "⌂", "▥"]
	var actions: Array[Callable] = [func() -> void: SceneManager.goto(SceneManager.RECIPE_BOOK), _show_records, func() -> void: SceneManager.goto(SceneManager.GERAI), _show_achievements]
	for i in range(4):
		var x := .075 + i * .225
		var button := _art_button("nav_story" if i == 0 else "nav_" + captions[i], Rect2(x, .825, .195, .115), actions[i])
		button.name = captions[i].capitalize() + "Button"
		_label(MenuText.text(captions[i]), Rect2(.06, .70, .88, .18), 23, button)
		if i == 0:
			_story_button = button
	var journey := _art_button("tagline", Rect2(.405, .703, .50, .075), func() -> void: SceneManager.goto(SceneManager.JOURNEY))
	journey.name = "JourneyButton"
	var journey_graphic := TitleArt.create("journey", "Journey")
	_place(journey_graphic, Rect2(.105, -.04, .88, 1.10), journey)
	_label(MenuText.text("motto"), Rect2(.13, .955, .74, .025), 26).add_theme_color_override("font_color", Palette.PAPER)
	_label("v" + str(ProjectSettings.get_setting("application/config/version", "0.1.0")), Rect2(.025, .97, .19, .02), 19).add_theme_color_override("font_color", Palette.PAPER)

func _header_box(id: String) -> StyleBoxTexture:
	var box := StyleBoxTexture.new()
	var source: Texture2D = load("res://assets/menu/v3/%s.png" % id)
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
	var stars := ProgressionManager.total_stars()
	var player_name: String = str(SaveManager.data.get("profile", {}).get("name", "Player"))
	_profile_label.text = player_name
	_avatar.texture = AvatarLibrary.portrait(str(SaveManager.data.get("profile", {}).get("avatar", "aina")))
	_level_label.text = "Lv %d" % (1 + stars / 10)
	_profile_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	_progress.value = stars % 10
	_total_score_label.text = "Score %s" % str(ProgressionManager.total_best_score())
	_star_label.text = str(stars)
	_coin_display.amount = EconomyManager.coins()
	_play_label.text = MenuText.text("play")

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
			rows += "%s %d    %s\n" % [MenuText.text("stage"), id, "★".repeat(int(record["stars"]))]
			count += 1
	if count == 0:
		rows += MenuText.text("empty")
	_popup(MenuText.text("records"), rows)

func _show_achievements() -> void:
	SceneManager.goto(SceneManager.ACHIEVEMENTS)
