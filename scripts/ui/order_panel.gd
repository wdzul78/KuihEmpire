class_name OrderPanel
extends Control

## Customer order display - the heart of the game's identity
## (Master Plan sections 19, 20 and 50).
##
## Shows who is at the counter, what they asked for, and how far along the order
## already is. Chips pop when kuih land and turn gold the moment a line is done.

signal line_completed(kuih_id: StringName)

const CHIP_WIDTH := 136.0
const CHIP_HEIGHT := 158.0

var _portrait: CharacterIcon
var _name_label: Label
var _line_label: Label
var _chips_row: HBoxContainer
var _card: PanelContainer
var _order: CustomerOrder = null
var _chips: Dictionary = {}   # kuih id -> {icon, count, label, root}


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	custom_minimum_size = Vector2(0, 228)
	_build()


func _build() -> void:
	var root := UIKit.hbox(14)
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)

	var frame := PanelContainer.new()
	frame.add_theme_stylebox_override("panel", UIKit.cream_box())
	frame.custom_minimum_size = Vector2(168, 0)
	frame.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	root.add_child(frame)
	_portrait = CharacterIcon.new()
	_portrait.framing = 1
	_portrait.custom_minimum_size = Vector2(148, 148)
	frame.add_child(_portrait)

	_card = PanelContainer.new()
	_card.add_theme_stylebox_override("panel", UIKit.cream_box())
	_card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_card.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	root.add_child(_card)

	var stack := UIKit.vbox(6)
	_card.add_child(stack)

	_name_label = UIKit.label("", 32, Palette.WOOD_DARK, HORIZONTAL_ALIGNMENT_LEFT)
	stack.add_child(_name_label)

	_line_label = UIKit.label("", 24, Palette.INK_SOFT, HORIZONTAL_ALIGNMENT_LEFT)
	_line_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_line_label.custom_minimum_size = Vector2(0, 62)
	_line_label.clip_text = true
	stack.add_child(_line_label)

	_chips_row = UIKit.hbox(10)
	stack.add_child(_chips_row)
	resized.connect(_rebuild_chips)


func bind(order: CustomerOrder) -> void:
	_order = order
	# A stage with no customer (the gesture lessons) shows nothing at all rather
	# than an empty card.
	visible = order != null
	if order == null or order.customer == null:
		_portrait.cast = CharacterIcon.Cast.CUSTOMER
		_portrait.customer = null
		_name_label.text = ""
		_line_label.text = ""
		_clear_chips()
		return
	_portrait.cast = CharacterIcon.Cast.CUSTOMER
	_portrait.customer = order.customer
	_portrait.queue_redraw()
	_name_label.text = order.customer.display_name
	_line_label.text = order.customer.line
	_clear_chips()
	for id in order.item_ids():
		_add_chip(id)
	_refresh_chips()


func _clear_chips() -> void:
	for child in _chips_row.get_children():
		child.queue_free()
	_chips.clear()


func _add_chip(id: StringName) -> void:
	var data := KuihLibrary.get_kuih(id)
	if data == null:
		return
	var root := PanelContainer.new()
	root.add_theme_stylebox_override("panel", UIKit.flat_box(Palette.CREAM_DEEP, Palette.WOOD_LIGHT, 4, 3, 14))
	root.custom_minimum_size = Vector2(CHIP_WIDTH, CHIP_HEIGHT)
	root.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	root.size_flags_vertical = Control.SIZE_SHRINK_BEGIN

	var col := UIKit.vbox(0)
	root.add_child(col)

	var icon := KuihIcon.new()
	icon.kuih = data
	icon.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	icon.custom_minimum_size = Vector2(CHIP_WIDTH - 12.0, 112.0)
	icon.cell_ratio = 1.0
	col.add_child(icon)

	var label := UIKit.label("", 28, Palette.INK)
	col.add_child(label)

	_chips_row.add_child(root)
	_chips[id] = {"root": root, "icon": icon, "label": label}
	_pop(root)


func _refresh_chips() -> void:
	if _order == null:
		return
	for id in _chips:
		var entry: Dictionary = _chips[id]
		var need := _order.wanted_for(id)
		var got := _order.collected_for(id)
		entry["label"].text = "%d / %d" % [got, need]
		var done := need > 0 and got >= need
		var chip: PanelContainer = entry["root"]
		chip.add_theme_stylebox_override(
			"panel",
			UIKit.flat_box(
				Palette.GOLD_PALE if done else Palette.CREAM_DEEP,
				Palette.GOLD_DARK if done else Palette.WOOD_LIGHT,
				0, 3, 14
			)
		)
		entry["label"].add_theme_color_override("font_color", Palette.GOLD_DARK if done else Palette.INK)


## Called after a collection pass so only the chips that changed pop.
func animate_progress() -> void:
	if _order == null:
		return
	for id in _chips:
		var entry: Dictionary = _chips[id]
		var need := _order.wanted_for(id)
		var got := _order.collected_for(id)
		entry["label"].text = "%d / %d" % [got, need]
		var done := need > 0 and got >= need
		if not done:
			_pop(entry["root"])
		else:
			var chip: PanelContainer = entry["root"]
			chip.add_theme_stylebox_override("panel", UIKit.flat_box(Palette.GOLD_PALE, Palette.GOLD_DARK, 0, 3, 14))
			entry["label"].add_theme_color_override("font_color", Palette.GOLD_DARK)
			line_completed.emit(id)


func cheer() -> void:
	if _portrait == null:
		return
	_portrait.expression = CharacterIcon.Mood.EXCITED
	_pop(_card, 1.10)
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
