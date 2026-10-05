class_name StoryScreen
extends Control

signal finished()

class QuotePanel extends Panel:
	var tail_left := false
	func _draw() -> void:
		var x := size.x * (.17 if tail_left else .83)
		var tip := Vector2(x - 24 if tail_left else x + 24, size.y + 24)
		var points := PackedVector2Array([Vector2(x - 18, size.y - 3), tip, Vector2(x + 18, size.y - 3)])
		draw_colored_polygon(points, Palette.PAPER)
		draw_polyline(PackedVector2Array([points[0], points[1], points[2]]), Palette.WOOD_LIGHT, 4, true)

var pages: Array[StoryPage] = []
var index := 0
var _finished := false
var _last_touch := -1000
var _backdrop: GeraiBackdrop
var _card: Panel
var _speaker: CharacterIcon
var _heading: Label
var _body: Label
var _art: TextureRect
var _quote: Panel
var _quote_text: Label
var _dots: HBoxContainer
var _counter: Label
var _next_button: Button
var _skip_button: Button
var _previous_button: Button
var _prev_hint: Label
var _tap_indicator: TapIndicator
var _welcome: Control
var _rounded_art: ShaderMaterial

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	UIKit.apply_root_theme(self)
	_build()
	finished.connect(SceneManager.finish_story)
	_start_deck()

func _start_deck() -> void:
	await get_tree().process_frame
	if StoryLibrary.has_pages(SceneManager.story_group):
		play(StoryLibrary.pages_for(SceneManager.story_group), SceneManager.story_allow_skip)
	else:
		visible = false

func _build() -> void:
	_backdrop = GeraiBackdrop.new()
	_backdrop.show_counter = false
	_backdrop.simple = false
	JourneyArt.place(self, _backdrop, Rect2(0, 0, 1, 1))
	_card = Panel.new()
	var cream := UIKit.cream_box()
	cream.set_corner_radius_all(48)
	_card.add_theme_stylebox_override("panel", cream)
	JourneyArt.place(self, _card, Rect2(.045, .085, .91, .855))
	_heading = JourneyArt.label(_card, "", Rect2(.045, .025, .91, .11), 58)
	_heading.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_art = TextureRect.new()
	_art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_rounded_art = ShaderMaterial.new()
	_rounded_art.shader = load("res://scripts/art/shaders/story_rounded.gdshader")
	_art.material = _rounded_art
	JourneyArt.place(_card, _art, Rect2(.045, .145, .91, .42))
	_art.resized.connect(_layout_quote)
	_welcome = Control.new()
	_art.add_child(_welcome)
	var welcome_aina := TextureRect.new()
	welcome_aina.texture = load("res://assets/story/prologue_v1/aina_wave_v1.png")
	welcome_aina.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	welcome_aina.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	JourneyArt.place(_welcome, welcome_aina, Rect2(.41, .035, .58, .965))
	var hello := QuotePanel.new()
	var hello_style := UIKit.cream_box()
	hello_style.set_corner_radius_all(36)
	hello.add_theme_stylebox_override("panel", hello_style)
	JourneyArt.place(_welcome, hello, Rect2(.055, .18, .32, .18))
	JourneyArt.label(hello, "Hi!", Rect2(.05, .02, .9, .9), 48, Palette.PINK_DARK)
	_speaker = CharacterIcon.new()
	JourneyArt.place(_card, _speaker, Rect2(.28, .145, .44, .42))
	_quote = QuotePanel.new()
	var quote_style := UIKit.cream_box()
	quote_style.set_corner_radius_all(46)
	_quote.add_theme_stylebox_override("panel", quote_style)
	_art.add_child(_quote)
	_quote_text = JourneyArt.label(_quote, "", Rect2(.065, .05, .87, .9), 32)
	_quote_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_body = JourneyArt.label(_card, "", Rect2(.055, .595, .89, .185), 44)
	_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_dots = HBoxContainer.new()
	_dots.alignment = BoxContainer.ALIGNMENT_CENTER
	_dots.add_theme_constant_override("separation", 18)
	JourneyArt.place(_card, _dots, Rect2(.2, .795, .6, .022))
	_counter = JourneyArt.label(_card, "", Rect2(.3, .819, .4, .033), 32, Palette.INK_SOFT)
	var source: Texture2D = load("res://assets/ui/results_v1/button_pink.png")
	var button_art := AtlasTexture.new()
	button_art.atlas = source
	button_art.region = Rect2(34, 183, 2105, 340)
	_next_button = JourneyArt.painted_button(button_art, "", 48)
	JourneyArt.place(_card, _next_button, Rect2(.085, .857, .83, .085))
	_next_button.pressed.connect(_on_next_pressed)
	_prev_hint = JourneyArt.label(_card, "", Rect2(.04, .952, .92, .034), 30, Palette.INK_SOFT)
	_previous_button = UIKit.button("", 36, Palette.CREAM_DEEP)
	_previous_button.custom_minimum_size = Vector2.ZERO
	_previous_button.add_theme_color_override("font_color", Palette.WOOD_DARK)
	JourneyArt.place(self, _previous_button, Rect2(.045, .0125, .30, .06875))
	_previous_button.pressed.connect(func(): show_page(index - 1))
	_skip_button = UIKit.button("", 36, Palette.CREAM_DEEP)
	_skip_button.custom_minimum_size = Vector2.ZERO
	_skip_button.add_theme_color_override("font_color", Palette.WOOD_DARK)
	JourneyArt.place(self, _skip_button, Rect2(.655, .0125, .30, .06875))
	_skip_button.pressed.connect(finish)
	_tap_indicator = TapIndicator.new()
	_tap_indicator.target = _next_button
	_tap_indicator.anchor_ratio = Vector2(.90, -.45)
	_tap_indicator.anchor_offset = Vector2.ZERO
	add_child(_tap_indicator)
	_ignore_decorations(self)

func _ignore_decorations(node: Node) -> void:
	for child in node.get_children():
		if child is Control and not child is Button:
			child.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_ignore_decorations(child)

func play(deck: Array[StoryPage], allow_skip: bool) -> void:
	pages = deck
	visible = true
	_finished = false
	_skip_button.visible = allow_skip
	if pages.is_empty():
		finish()
		return
	show_page(0, false)

func show_page(to_index: int, animate: bool = true) -> void:
	if pages.is_empty():
		return
	index = clampi(to_index, 0, pages.size() - 1)
	var page := pages[index]
	_backdrop.background_id = page.mood
	_heading.text = page.localized_heading()
	_body.text = page.localized_body()
	_speaker.visible = page.illustration == null
	_speaker.cast = _cast_for(page.speaker)
	_art.visible = page.illustration != null
	_welcome.visible = page.greeting
	if page.illustration:
		var atlas := AtlasTexture.new()
		atlas.atlas = page.illustration
		atlas.region = page.illustration_region
		_art.texture = atlas
	_quote.visible = not page.quote.is_empty()
	_quote_text.text = JourneyArt.localized(page.quote_ms, page.quote)
	(_quote as QuotePanel).tail_left = page.quote_rect.position.x > .5
	_quote.queue_redraw()
	_layout_quote()
	for child in _dots.get_children():
		_dots.remove_child(child)
		child.queue_free()
	for i in pages.size():
		var dot := Panel.new()
		dot.custom_minimum_size = Vector2(24, 24)
		dot.add_theme_stylebox_override("panel", UIKit.flat_box(Palette.PINK_DARK if i == index else Palette.CREAM_DEEP))
		dot.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_dots.add_child(dot)
	_counter.text = "%d / %d" % [index + 1, pages.size()]
	_next_button.text = JourneyArt.localized("Jom Mula", "Let’s Begin") if index == pages.size() - 1 else JourneyArt.localized("Teruskan", "Continue")
	if index == pages.size() - 1 and SceneManager.story_next == SceneManager.JOURNEY:
		_next_button.text = JourneyArt.localized("Kembali ke Peta", "Back to Map")
	_previous_button.text = JourneyArt.localized("‹ Sebelum", "‹ Previous")
	_previous_button.visible = index > 0
	_skip_button.text = JourneyArt.localized("Langkau", "Skip")
	_prev_hint.text = JourneyArt.localized("Sentuh di mana-mana untuk teruskan", "Tap anywhere to continue")
	if animate:
		AudioManager.play(AudioManager.Sfx.TAP, 1.05, -10.0)

func _layout_quote() -> void:
	if pages.is_empty() or not _art.texture or pages[index].illustration == null:
		return
	var source_size := _art.texture.get_size()
	var fitted := source_size * minf(_art.size.x / source_size.x, _art.size.y / source_size.y)
	var page := pages[index]
	_rounded_art.set_shader_parameter("display_size", fitted)
	_rounded_art.set_shader_parameter("region_origin", page.illustration_region.position / page.illustration.get_size())
	_rounded_art.set_shader_parameter("region_size", page.illustration_region.size / page.illustration.get_size())
	_welcome.position = (_art.size - fitted) * .5
	_welcome.size = fitted
	var rect := pages[index].quote_rect
	_quote.position = (_art.size - fitted) * .5 + rect.position * fitted
	_quote.size = rect.size * fitted

static func _cast_for(speaker: int) -> int:
	match speaker:
		StoryBeat.Speaker.IBU: return CharacterIcon.Cast.IBU
		StoryBeat.Speaker.FRIEND: return CharacterIcon.Cast.FRIEND
		StoryBeat.Speaker.RIVAL: return CharacterIcon.Cast.RIVAL
	return CharacterIcon.Cast.AINA

func _input(event: InputEvent) -> void:
	if pages.is_empty() or _finished or not is_visible_in_tree():
		return
	var at := Vector2.ZERO
	if event is InputEventScreenTouch and not event.pressed:
		at = event.position
		_last_touch = Time.get_ticks_msec()
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
		if Time.get_ticks_msec() - _last_touch < 250:
			return
		at = event.position
	else:
		return
	for button in [_next_button, _skip_button, _previous_button]:
		if button.visible and button.get_global_rect().has_point(at):
			return
	get_viewport().set_input_as_handled()
	_turn()

func _turn() -> void:
	if _finished:
		return
	if index < pages.size() - 1:
		show_page(index + 1)
	else:
		finish()

func _on_next_pressed() -> void:
	_turn()

func finish() -> void:
	if _finished:
		return
	_finished = true
	finished.emit()
