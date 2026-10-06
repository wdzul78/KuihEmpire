class_name OrderPanel
extends Control

## Customer order display - the heart of the game's identity
## (Master Plan sections 19, 20 and 50).
##
## Shows who is at the counter, what they asked for, and how far along the order
## already is. Chips pop when kuih land and turn gold the moment a line is done.

signal line_completed(kuih_id: StringName)

const CHIP_WIDTH := 112.0
const CHIP_HEIGHT := 182.0

class OrderTick extends Control:
	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		resized.connect(queue_redraw)

	func _stroke(points: PackedVector2Array, color: Color, width: float) -> void:
		draw_polyline(points, color, width, true)
		for point in points:
			draw_circle(point, width * .5, color, true, -1, true)

	func _draw() -> void:
		var edge := minf(size.x, size.y)
		var origin := (size - Vector2.ONE * edge) * .5
		var points := PackedVector2Array([
			origin + Vector2(.17, .52) * edge,
			origin + Vector2(.40, .76) * edge,
			origin + Vector2(.82, .20) * edge,
		])
		_stroke(PackedVector2Array([points[0] + Vector2(0, edge * .045), points[1] + Vector2(0, edge * .045), points[2] + Vector2(0, edge * .045)]), Color(.18, .28, .04, .24), edge * .24)
		_stroke(points, Color("277a12"), edge * .23)
		_stroke(points, Color("61e526"), edge * .17)
		_stroke(PackedVector2Array([points[0] + Vector2(0, -edge * .035), points[1] + Vector2(0, -edge * .035), points[2] + Vector2(0, -edge * .035)]), Color("b7fa66"), edge * .045)

var _portrait: CharacterIcon
var _aina: CharacterIcon
var _name_label: Label
var _line_label: Label
var _chips_row: Control
var _card: Panel
var _bubble: PanelContainer
var _coaching := false
var compact_mode := true
var tutorial_layout: PackedScene = GameUILayout.TUTORIAL
var campaign_layout: PackedScene = GameUILayout.CAMPAIGN
var _order: CustomerOrder = null
var _chips: Dictionary = {}   # kuih id -> {icon, count, label, root}


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	custom_minimum_size = Vector2.ZERO
	_build()


func _place(node: Control, rect: Rect2) -> void:
	add_child(node)
	node.anchor_left = rect.position.x
	node.anchor_top = rect.position.y
	node.anchor_right = rect.end.x
	node.anchor_bottom = rect.end.y
	node.offset_left = 0
	node.offset_top = 0
	node.offset_right = 0
	node.offset_bottom = 0


func _build() -> void:
	_portrait = CharacterIcon.new()
	_portrait.name = "CustomerCharacter"
	_portrait.cast = CharacterIcon.Cast.CUSTOMER
	_portrait.framing = 1
	# Full sprites continue below the counter; the later board layer hides their
	# lower bodies, so faces can be larger without cropping the source artwork.
	_place(_portrait, Rect2(-0.015, 0.10, 0.34, 1.60))
	var aina := CharacterIcon.new()
	aina.name = "AinaCharacter"
	_aina = aina
	aina.framing = 1
	_place(aina, Rect2(0.675, 0.10, 0.34, 1.60))
	var bubble := SpeechBubble.new()
	bubble.name = "DialogueBubble"
	bubble.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	_bubble = bubble
	_portrait.dialogue_clearance = bubble
	_aina.dialogue_clearance = bubble
	bubble.resized.connect(_redraw_characters)
	_place(bubble, Rect2(0.22, 0.12, 0.56, 0.36))
	var dialogue := Control.new()
	dialogue.name = "DialogueContents"
	bubble.add_child(dialogue)
	dialogue.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_name_label = UIKit.label("", 24, Palette.WOOD_DARK)
	_name_label.name = "SpeakerName"
	_name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	dialogue.add_child(_name_label)
	_line_label = UIKit.wrap_label("", 22, Palette.INK)
	_line_label.name = "InstructionText"
	_line_label.custom_minimum_size = Vector2.ZERO
	dialogue.add_child(_line_label)

	_card = Panel.new()
	_card.name = "OrderBoard"
	_card.add_theme_stylebox_override("panel", GameplaySkin.box("order_board"))
	_place(_card, Rect2(0.21, 0.78, 0.58, 0.50))
	var order_title := UIKit.label("Order", 32, Palette.WOOD_DARK)
	order_title.name = "OrderTitle"
	_child_place(_card, order_title, Rect2(.25, .015, .5, .17))
	order_title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_chips_row = Control.new()
	_chips_row.name = "KuihItems"
	_child_place(_card, _chips_row, Rect2(.08, .24, .84, .69))
	_chips_row.resized.connect(_layout_chips)
	resized.connect(_rebuild_chips)
	GameUILayout.apply_order(self, campaign_layout)


func bind(order: CustomerOrder) -> void:
	_order = order
	(_bubble as SpeechBubble).speaker_on_left = order != null and not _coaching
	# A stage with no customer (the gesture lessons) shows nothing at all rather
	# than an empty card.
	visible = true
	_portrait.visible = order != null
	_card.visible = order != null
	if order == null or order.customer == null:
		_portrait.cast = CharacterIcon.Cast.CUSTOMER
		_portrait.customer = null
		if not _coaching:
			_name_label.text = ""
			_line_label.text = "Let's make these kuih together!"
		_clear_chips()
		return
	_portrait.cast = CharacterIcon.Cast.CUSTOMER
	_portrait.customer = order.customer
	_portrait.queue_redraw()
	if not _coaching:
		_name_label.text = order.customer.display_name
		_line_label.text = order.customer.line
	_clear_chips()
	for id in order.item_ids():
		_add_chip(id)
	_refresh_chips()

func set_coaching(value: bool, preserve_tutorial_layout: bool = false) -> void:
	# Ending the instruction gate must not resize the characters mid-lesson.
	# Explicit mode changes still restore the campaign layout by default.
	var tutorial_presentation := value or preserve_tutorial_layout
	_coaching = value
	if tutorial_presentation:
		_portrait.anchor_left = -.125
		_portrait.anchor_right = .305
		_portrait.anchor_top = .08
		_portrait.anchor_bottom = 1.98
		_aina.anchor_left = .645
		_aina.anchor_right = 1.105
		_aina.anchor_top = .08
		_aina.anchor_bottom = 1.98
		_bubble.anchor_left = .06
		_bubble.anchor_right = .73
		_bubble.anchor_top = .12
		_bubble.anchor_bottom = .64
		_name_label.add_theme_font_size_override("font_size", 36)
		_line_label.add_theme_font_size_override("font_size", 34)
		_card.anchor_top = .78
		_card.anchor_bottom = 1.28
		_chips_row.anchor_top = .20
		_chips_row.anchor_bottom = .97
	(_bubble as SpeechBubble).speaker_on_left = not value and _order != null
	if not tutorial_presentation:
		_portrait.anchor_left = -.015
		_portrait.anchor_right = .325
		_portrait.anchor_top = .10
		_portrait.anchor_bottom = 1.70
		_aina.anchor_left = .675
		_aina.anchor_right = 1.015
		_aina.anchor_top = .10
		_aina.anchor_bottom = 1.70
		_bubble.anchor_left = .22
		_bubble.anchor_right = .78
		_bubble.anchor_top = .12
		_bubble.anchor_bottom = .48
		_name_label.add_theme_font_size_override("font_size", 24)
		_line_label.add_theme_font_size_override("font_size", 22)
		_card.anchor_top = .78
		_card.anchor_bottom = 1.28
		_chips_row.anchor_top = .24
		_chips_row.anchor_bottom = .93
	if not value:
		bind(_order)
	GameUILayout.apply_order(self, tutorial_layout if tutorial_presentation else campaign_layout)
	set_compact(not tutorial_presentation)
	_layout_chips()
	_redraw_characters()


func set_compact(value: bool) -> void:
	compact_mode = value
	_portrait.framing = 0 if value else 1
	_aina.framing = 0 if value else 1
	_portrait.compact_portrait = value
	_aina.compact_portrait = value
	_bubble.visible = not value
	_redraw_characters()


func set_story_speaker(speaker: int) -> void:
	_bubble.visible = speaker < 0 and not compact_mode
	_portrait.modulate = Color.WHITE
	_aina.modulate = Color.WHITE
	if speaker < 0:
		_portrait.cast = CharacterIcon.Cast.CUSTOMER
		_portrait.visible = _order != null
		_redraw_characters()
		return
	var aina_talking := speaker == StoryBeat.Speaker.AINA or speaker == StoryBeat.Speaker.NARRATOR
	(_bubble as SpeechBubble).speaker_on_left = not aina_talking
	_aina.modulate = Color.WHITE if aina_talking else Color(0.7, 0.7, 0.7)
	_portrait.modulate = Color(0.7, 0.7, 0.7) if aina_talking else Color.WHITE
	if not aina_talking:
		_portrait.cast = StoryPopup.SPEAKER_CAST.get(speaker, CharacterIcon.Cast.CUSTOMER)
		_portrait.visible = true


func _clear_chips() -> void:
	for child in _chips_row.get_children():
		child.queue_free()
	_chips.clear()


func _add_chip(id: StringName) -> void:
	var data := KuihLibrary.get_kuih(id)
	if data == null:
		return
	var root := Control.new()
	root.name = "Kuih_" + String(id)
	root.clip_contents = true
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_chips_row.add_child(root)
	var icon := KuihIcon.new()
	icon.name = "KuihIcon"
	icon.kuih = data
	icon.custom_minimum_size = Vector2(1, 1)
	root.add_child(icon)
	var badge := Control.new()
	badge.name = "RemainingCountBadge"
	badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(badge)
	var label := UIKit.graphic_label("", 36, UIKit.GraphicText.WHITE)
	label.name = "OrderCount"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_child_place(badge, label, Rect2(0, 0, 1, 1))
	var tick := OrderTick.new()
	tick.name = "OrderCompletedTick"
	root.add_child(tick)
	_chips[id] = {"root": root, "icon": icon, "label": label, "badge": badge, "tick": tick, "done": false, "remaining": -1}
	_layout_chips()


func _child_place(parent: Control, node: Control, rect: Rect2) -> void:
	parent.add_child(node)
	node.anchor_left = rect.position.x
	node.anchor_top = rect.position.y
	node.anchor_right = rect.end.x
	node.anchor_bottom = rect.end.y
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE


func _layout_chips() -> void:
	var count := _chips.size()
	if count == 0 or _chips_row.size.y <= 0:
		return
	var width := minf(230, _chips_row.size.x / count)
	var left := (_chips_row.size.x - width * count) * .5
	var index := 0
	for entry in _chips.values():
		entry["root"].position = Vector2(left + index * width, 0)
		entry["root"].size = Vector2(width, _chips_row.size.y)
		var height := _chips_row.size.y * .78
		var backing_width := minf(width * .84, height * 1.18)
		var backing_left := (width - backing_width) * .5
		var top := (_chips_row.size.y - height) * .5
		entry["icon"].position = Vector2(backing_left + backing_width * .06, top + height * .04)
		entry["icon"].size = Vector2(backing_width * .88, height * .88)
		var badge_edge := clampf(height * .40, 28, 64)
		var badge_position := Vector2(backing_left + backing_width * .82 - badge_edge, top + height * .88 - badge_edge)
		entry["badge"].position = badge_position
		entry["badge"].size = Vector2.ONE * badge_edge
		entry["tick"].position = badge_position - Vector2.ONE * badge_edge * .10
		entry["tick"].size = Vector2.ONE * badge_edge * 1.15
		var number_size := int(badge_edge * .95)
		entry["label"].add_theme_font_size_override("font_size", number_size)
		entry["label"].add_theme_constant_override("outline_size", maxi(3, roundi(number_size*.15)))
		entry["label"].add_theme_color_override("font_outline_color", Color("674229"))
		entry["label"].add_theme_color_override("font_shadow_color", Color(.20, .10, .04, .85))
		entry["label"].add_theme_constant_override("shadow_offset_x", maxi(1, roundi(number_size*.04)))
		entry["label"].add_theme_constant_override("shadow_offset_y", maxi(2, roundi(number_size*.07)))
		index += 1


func _update_chip(id: StringName, animate: bool = false) -> void:
	var entry: Dictionary = _chips[id]
	var remaining := maxi(0, int(_order.remaining.get(id, 0)))
	var done := _order.wanted_for(id) > 0 and remaining == 0
	var was_done: bool = entry["done"]
	var changed: bool = entry["remaining"] != remaining
	entry["label"].text = str(remaining)
	entry["badge"].visible = not done
	entry["tick"].visible = done
	entry["tick"].accessibility_name = "Order complete" if SaveManager.get_setting("language", "en") == "en" else "Pesanan lengkap"
	entry["root"].tooltip_text = "%s: %s" % [KuihLibrary.get_display_name(id), entry["tick"].accessibility_name if done else str(remaining)]
	entry["done"] = done
	entry["remaining"] = remaining
	if animate and changed:
		if done and not was_done:
			_pop(entry["tick"], 1.22)
			line_completed.emit(id)
		elif not done:
			_pop(entry["badge"], 1.12)
			_pop(entry["icon"], 1.08)

func _refresh_chips() -> void:
	if _order == null:
		return
	for id in _chips:
		_update_chip(id)

## Changed counts pop; completed items get one green tick instead of a fraction.
func animate_progress() -> void:
	if _order == null:
		return
	for id in _chips:
		_update_chip(id, true)


func cheer() -> void:
	if _portrait == null:
		return
	_portrait.expression = CharacterIcon.Mood.EXCITED
	_pop(_portrait, 1.04)
	await get_tree().create_timer(0.8).timeout
	if is_instance_valid(_portrait) and _order != null and _order.customer != null:
		_portrait.expression = CharacterIcon.Mood.HAPPY


func _pop(node: Control, amount: float = 1.14) -> void:
	node.pivot_offset = node.size * 0.5
	node.scale = Vector2(amount, amount)
	var tw := node.create_tween()
	tw.tween_property(node, "scale", Vector2.ONE, 0.26).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)


func _rebuild_chips() -> void:
	if _order == null or _chips_row == null:
		return
	if _chips.size() == _order.item_ids().size():
		_refresh_chips()
		return
	_clear_chips()
	for id in _order.item_ids():
		_add_chip(id)

func _redraw_characters() -> void:
	if is_instance_valid(_portrait):
		_portrait.queue_redraw()
	if is_instance_valid(_aina):
		_aina.queue_redraw()

func set_story_clearance(bubble: Control) -> void:
	_portrait.story_clearance = bubble
	_aina.story_clearance = bubble
	if not bubble.resized.is_connected(_redraw_characters):
		bubble.resized.connect(_redraw_characters)
		bubble.visibility_changed.connect(_redraw_characters)
	_redraw_characters()
