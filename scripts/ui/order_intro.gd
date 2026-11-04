class_name OrderIntro
extends Control

## Opening of a campaign stage: the first customer and Aina talk, shown full body,
## then step aside for an order card that flies into the order panel.
##
## The conversation plays on a stage's first visit only; later attempts open on
## the order card. Tap anywhere to advance, or Skip to go straight to the card.

signal finished()

const LISTENER_TINT := Color(.42, .42, .48)
const AINA_ART := "res://assets/characters/fullbody_v2/aina.png"
## Dedicated poses that face left, towards the customer. Until they exist the
## standing art is mirrored so Aina's eyes, not her hand, meet the customer's.
const AINA_TALK := "res://assets/characters/dialogue_v1/aina_talk.png"
const AINA_LISTEN := "res://assets/characters/dialogue_v1/aina_listen.png"
## Customers face right in their art, so they stand on the left and Aina on the right.
const GUEST_RECT := Rect2(-.10, .31, .66, .52)
const AINA_RECT := Rect2(.44, .31, .66, .52)
const ASKS := [
	["Aina, saya nak %s. Sempat siapkan?", "Aina, could I have %s? Can you make them in time?"],
	["Assalamualaikum! Hari ni saya nak %s, ya.", "Hello! Today I would like %s, please."],
	["Aina, tolong sediakan %s untuk saya.", "Aina, please get %s ready for me."],
]
const REPLIES := [
	["Sempat! Tunggu sekejap ya, saya siapkan sekarang.", "Of course! Give me a moment, I will start now."],
	["Baik! Siap sekejap lagi.", "Coming right up!"],
	["Boleh! Saya mulakan sekarang.", "Sure! I will get started."],
]

## Where the card flies to and glows once it leaves.
var order_target: Control

var _dim: ColorRect
var _aina: TextureRect
var _guest: TextureRect
var _bubble: SpeechBubble
var _name_tag: Panel
var _name_label: Label
var _line_label: Label
var _skip: Button
var _card: Control
var _lines: Array = []
var _line := 0
var _done := false

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	z_index = 95
	visible = false
	UIKit.apply_root_theme(self)
	gui_input.connect(_on_input)

## Lines are [speaker_is_customer, text] pairs. With no lines the order card shows at once.
static func conversation(stage: int, customer: CustomerData, remaining: Dictionary) -> Array:
	var wants := PackedStringArray()
	for id in remaining:
		wants.append("%d %s" % [int(remaining[id]), KuihLibrary.get_display_name(id)])
	var joiner := JourneyArt.localized(" dan ", " and ")
	var listed := wants[0] if wants.size() == 1 else ", ".join(wants.slice(0, wants.size() - 1)) + joiner + wants[-1]
	var ask: Array = ASKS[stage % ASKS.size()]
	var reply: Array = REPLIES[stage % REPLIES.size()]
	return [
		[true, JourneyArt.localized(ask[0], ask[1]) % listed],
		[false, JourneyArt.localized(reply[0], reply[1]) if customer != null else ""],
	]

func play(customer: CustomerData, remaining: Dictionary, moves: int, lines: Array) -> void:
	_clear()
	_done = false
	_lines = lines
	_line = 0
	visible = true
	_dim = ColorRect.new()
	_dim.color = Color(.10, .06, .03, .78)
	_dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	JourneyArt.place(self, _dim, Rect2(0, 0, 1, 1))
	_build_card(customer, remaining, moves)
	if lines.is_empty() or customer == null or customer.texture == null:
		_show_card()
		return
	_card.hide()
	_guest = _figure(customer.texture, GUEST_RECT, false)
	_aina = _figure(aina_art(true), AINA_RECT, not has_dialogue_poses())
	_build_bubble()
	# Feet stand behind the bubble; the words always stay on top.
	for node in [_bubble, _line_label, _name_tag, find_child("OrderIntroHint", false, false)]:
		node.z_index = 1
	_skip = GameButton.create(JourneyArt.localized("Langkau  ›", "Skip  ›"), "back", 30)
	_skip.name = "OrderIntroSkip"
	_skip.custom_minimum_size = Vector2.ZERO
	JourneyArt.place(self, _skip, Rect2(.70, .27, .25, .05))
	_skip.pressed.connect(_show_card)
	_customer_name = customer.display_name
	_show_line()
	_guest.position.x -= 120
	_aina.position.x += 120
	modulate.a = 0.0
	var tw := create_tween().set_parallel(true)
	tw.tween_property(self, "modulate:a", 1.0, .22)
	tw.tween_property(_guest, "position:x", _guest.position.x + 120, .32).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(_aina, "position:x", _aina.position.x - 120, .32).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

static func has_dialogue_poses() -> bool:
	return ResourceLoader.exists(AINA_TALK) and ResourceLoader.exists(AINA_LISTEN)

static func aina_art(talking: bool) -> Texture2D:
	if has_dialogue_poses():
		return load(AINA_TALK if talking else AINA_LISTEN)
	return load(AINA_ART)

var _customer_name := ""

func is_talking() -> bool:
	return visible and _bubble != null and _bubble.visible

func is_showing_card() -> bool:
	return visible and _card != null and _card.visible

## Moves on one line, from the last line to the card, and from the card into play.
func advance() -> void:
	if _done:
		return
	if is_talking():
		AudioManager.play(AudioManager.Sfx.TAP, randf_range(0.95, 1.1), -8.0)
		_line += 1
		if _line >= _lines.size():
			_show_card()
		else:
			_show_line()
	elif is_showing_card():
		start()

## Leaves at once, for retries and harnesses that do not watch the opening.
func finish_now() -> void:
	if _done:
		return
	_done = true
	_clear()
	visible = false
	finished.emit()

## Hides without handing over, when the stage restarts underneath it.
func dismiss() -> void:
	_done = true
	_clear()
	visible = false

## Sends the card into the order panel, then hands the board to the player.
func start() -> void:
	if _done or not is_showing_card():
		return
	_done = true
	AudioManager.play(AudioManager.Sfx.TAP, 1.0, -6.0)
	var tw := create_tween().set_parallel(true)
	tw.tween_property(_dim, "modulate:a", 0.0, .30)
	if is_instance_valid(order_target):
		var from := _card.get_global_rect()
		var to := order_target.get_global_rect()
		_card.pivot_offset = _card.size * .5
		var shrink := minf(to.size.x / from.size.x, to.size.y / from.size.y)
		tw.tween_property(_card, "global_position", to.get_center() - _card.size * .5, .36).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
		tw.tween_property(_card, "scale", Vector2.ONE * shrink, .36).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	tw.tween_property(_card, "modulate:a", 0.0, .36).set_delay(.12)
	await tw.finished
	_clear()
	visible = false
	_glow()
	finished.emit()

func _show_line() -> void:
	var customer_talks: bool = _lines[_line][0]
	_name_label.text = _customer_name if customer_talks else "Aina"
	_line_label.text = _lines[_line][1]
	_bubble.speaker_on_left = customer_talks
	# The name plate sits above whoever is talking.
	_name_tag.anchor_left = .08 if customer_talks else .52
	_name_tag.anchor_right = _name_tag.anchor_left + .40
	_aina.texture = aina_art(not customer_talks)
	_focus(_guest if customer_talks else _aina, _aina if customer_talks else _guest)
	_line_label.modulate.a = 0.0
	create_tween().tween_property(_line_label, "modulate:a", 1.0, .18)

## The speaker stands tall and bright; the listener steps back into the shade.
func _focus(speaker: Control, listener: Control) -> void:
	speaker.modulate = Color.WHITE
	speaker.scale = Vector2.ONE
	listener.modulate = LISTENER_TINT
	listener.pivot_offset = Vector2(listener.size.x * .5, listener.size.y)
	listener.scale = Vector2(.9, .9)
	move_child(speaker, _bubble.get_index())

func _show_card() -> void:
	if _done:
		return
	for node in [_aina, _guest, _bubble, _skip, _name_tag, _line_label, find_child("OrderIntroHint", false, false)]:
		if is_instance_valid(node):
			node.hide()
	_card.show()
	_card.pivot_offset = _card.size * .5
	_card.scale = Vector2(.9, .9)
	_card.modulate.a = 0.0
	var tw := create_tween().set_parallel(true)
	tw.tween_property(_card, "scale", Vector2.ONE, .30).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(_card, "modulate:a", 1.0, .18)

func _figure(texture: Texture2D, rect: Rect2, flip: bool) -> TextureRect:
	var figure := TextureRect.new()
	figure.texture = texture
	figure.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	figure.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	figure.flip_h = flip
	figure.mouse_filter = Control.MOUSE_FILTER_IGNORE
	JourneyArt.place(self, figure, rect)
	return figure

func _build_bubble() -> void:
	_bubble = SpeechBubble.new()
	_bubble.name = "OrderIntroBubble"
	_bubble.tail_on_top = true
	_bubble.mouse_filter = Control.MOUSE_FILTER_IGNORE
	JourneyArt.place(self, _bubble, Rect2(.04, .79, .92, .17))
	# The bubble is a container that would stretch its children over each other,
	# so the text sits beside it on the same rect instead.
	_line_label = UIKit.label("", 40, Palette.WOOD_DARK)
	_line_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	JourneyArt.place(self, _line_label, Rect2(.10, .825, .80, .095))
	_bubble.configure_text_fit(_line_label, 40)
	var hint := UIKit.label(JourneyArt.localized("Ketik untuk teruskan ›", "Tap to continue ›"), 26, Palette.WOOD_LIGHT)
	hint.name = "OrderIntroHint"
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	JourneyArt.place(self, hint, Rect2(.48, .918, .42, .03))
	_name_tag = Panel.new()
	_name_tag.add_theme_stylebox_override("panel", GeraiSkin.box("name_plate", .45))
	_name_tag.mouse_filter = Control.MOUSE_FILTER_IGNORE
	JourneyArt.place(self, _name_tag, Rect2(.08, .755, .40, .055))
	_name_label = UIKit.label("", 36, Palette.PAPER)
	_name_label.add_theme_color_override("font_outline_color", Palette.WOOD_DARK)
	_name_label.add_theme_constant_override("outline_size", 6)
	JourneyArt.place(_name_tag, _name_label, Rect2(0, 0, 1, 1))

func _build_card(customer: CustomerData, remaining: Dictionary, moves: int) -> void:
	_card = Control.new()
	_card.name = "OrderIntroCard"
	_card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	JourneyArt.place(self, _card, Rect2(.08, .29, .84, .40))
	var panel := TextureRect.new()
	panel.texture = ResultOverlay.artwork("panel")
	panel.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	panel.stretch_mode = TextureRect.STRETCH_SCALE
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	JourneyArt.place(_card, panel, Rect2(0, 0, 1, 1))
	# The panel art carries a small plaque at the top, as on the result card.
	var who := customer.display_name if customer != null else ""
	var title := UIKit.label(JourneyArt.localized("Pesanan %s", "%s's order") % who, 34, Palette.WOOD_DARK)
	title.clip_text = true
	JourneyArt.place(_card, title, Rect2(.23, .118, .54, .075))
	if customer != null:
		var portrait := CharacterIcon.new()
		portrait.customer = customer
		portrait.cast = CharacterIcon.Cast.CUSTOMER
		portrait.compact_portrait = true
		portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
		JourneyArt.place(_card, portrait, Rect2(.39, .20, .22, .19))
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 36)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	JourneyArt.place(_card, row, Rect2(.08, .40, .84, .23))
	for id in remaining:
		var cell := VBoxContainer.new()
		cell.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var icon := TextureRect.new()
		var kuih := KuihLibrary.get_kuih(id)
		icon.texture = kuih.texture if kuih != null else null
		icon.custom_minimum_size = Vector2(130, 100)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		cell.add_child(icon)
		cell.add_child(UIKit.label("× %d" % int(remaining[id]), 44, Palette.WOOD_DARK))
		row.add_child(cell)
	var moves_label := UIKit.label(JourneyArt.localized("Siapkan dalam %d langkah", "Serve it within %d moves") % moves, 34, Palette.WOOD)
	JourneyArt.place(_card, moves_label, Rect2(.08, .64, .84, .08))
	var go := GameButton.create(JourneyArt.localized("Mula!", "Start!"), "primary", 46)
	go.name = "OrderIntroStart"
	go.custom_minimum_size = Vector2.ZERO
	JourneyArt.place(_card, go, Rect2(.20, .76, .60, .16))
	go.pressed.connect(start)

func _glow() -> void:
	if not is_instance_valid(order_target):
		return
	var ring := Panel.new()
	var box := StyleBoxFlat.new()
	box.bg_color = Color(1, .9, .4, .14)
	box.border_color = Color("ffd54f")
	box.set_border_width_all(8)
	box.set_corner_radius_all(30)
	box.shadow_color = Color(1, .85, .3, .6)
	box.shadow_size = 24
	ring.add_theme_stylebox_override("panel", box)
	ring.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ring.z_index = 95
	get_parent().add_child(ring)
	var rect := order_target.get_global_rect().grow(10)
	ring.global_position = rect.position
	ring.size = rect.size
	var tw := ring.create_tween()
	tw.tween_property(ring, "modulate:a", 0.0, .9).set_delay(.35)
	tw.tween_callback(ring.queue_free)

func _clear() -> void:
	for child in get_children():
		child.queue_free()
	_bubble = null
	_card = null
	_aina = null
	_guest = null
	_skip = null

func _on_input(event: InputEvent) -> void:
	var pressed := false
	if event is InputEventScreenTouch:
		pressed = (event as InputEventScreenTouch).pressed
	elif event is InputEventMouseButton:
		pressed = (event as InputEventMouseButton).pressed
	if not pressed:
		return
	# A tap moves the talk on; only Start leaves the card, so a quick double tap
	# cannot skip the order before it is read.
	if is_talking():
		advance()
	accept_event()
