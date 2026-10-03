class_name HUD
extends Control

## Gameplay HUD: coins, stage title, the live customer order, the move counter,
## the waiting queue and the booster tray (Master Plan section 50).
##
## The board lives in [member board_holder] so this node owns the whole vertical
## layout: order on top, board in the middle, boosters at the bottom.

signal settings_pressed()
signal restart_pressed()
signal hint_pressed()
signal booster_requested(booster: int)

const TOP_HEIGHT := 470
const BOTTOM_HEIGHT := 190

var board_holder: Control
var order_panel: OrderPanel
var booster_bar: BoosterBar

var _coin_pill: Control
var _title_label: Label
var _queue_row: HBoxContainer
var _moves_label: Label
var _moves_cap: Label
var _moves_card: PanelContainer
var _stage_title: Label
var _booster_row: Control
var _lesson_badge: PanelContainer
var _is_tutorial: bool = false


## Tutorial stages have no move pressure, so the counter and the booster tray
## step aside and the title reads as a lesson instead of a stage number.
func set_tutorial_mode(value: bool) -> void:
	_is_tutorial = value
	if _moves_card != null:
		_moves_card.visible = not value
	if _booster_row != null:
		_booster_row.visible = not value
	if _lesson_badge != null:
		_lesson_badge.visible = value


func _ready() -> void:
	UIKit.apply_root_theme(self)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_build()


func _build() -> void:
	var column := UIKit.vbox(0)
	column.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(column)

	# --- top: coins / stage / settings
	var top := UIKit.vbox(6)
	top.custom_minimum_size = Vector2(0, TOP_HEIGHT)
	top.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_child(top)

	var top_row := UIKit.hbox(14)
	top_row.custom_minimum_size = Vector2(0, 108)
	var fascia := PanelContainer.new()
	fascia.add_theme_stylebox_override("panel", UIKit.wood_box(Palette.WOOD, Palette.WOOD_DARK, 10))
	fascia.custom_minimum_size = Vector2(0, 108)
	top.add_child(fascia)
	fascia.add_child(top_row)

	_coin_pill = CoinDisplay.new()
	_coin_pill.icon_size = 74.0
	top_row.add_child(_coin_pill)

	_title_label = UIKit.label("", 34, Palette.CREAM, HORIZONTAL_ALIGNMENT_LEFT)
	_title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_title_label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_stage_title = _title_label
	top_row.add_child(_title_label)

	var hint_btn := _round_button("?", Color("7b9ec9"))
	hint_btn.pressed.connect(func() -> void: hint_pressed.emit())
	top_row.add_child(hint_btn)

	var restart_btn := _round_button("↺", Palette.WOOD)
	restart_btn.pressed.connect(func() -> void: restart_pressed.emit())
	top_row.add_child(restart_btn)

	var settings_btn := _round_button("⚙", Palette.PINK_DARK)
	settings_btn.pressed.connect(func() -> void: settings_pressed.emit())
	top_row.add_child(settings_btn)

	# --- middle: active order + moves + queue
	var middle := UIKit.hbox(14)
	middle.custom_minimum_size = Vector2(0, 240)
	top.add_child(middle)

	order_panel = OrderPanel.new()
	order_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	order_panel.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	middle.add_child(order_panel)

	_moves_card = PanelContainer.new()
	_moves_card.add_theme_stylebox_override("panel", UIKit.wood_box(Palette.CREAM_DEEP, Palette.WOOD_DARK, 10, 1.0))
	_moves_card.custom_minimum_size = Vector2(190, 190)
	_moves_card.size_flags_horizontal = Control.SIZE_SHRINK_END
	_moves_card.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	middle.add_child(_moves_card)

	_lesson_badge = PanelContainer.new()
	_lesson_badge.add_theme_stylebox_override("panel", UIKit.wood_box(Palette.LEAF, Palette.LEAF_DEEP, 12))
	_lesson_badge.custom_minimum_size = Vector2(220, 0)
	_lesson_badge.size_flags_horizontal = Control.SIZE_SHRINK_END
	_lesson_badge.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	_lesson_badge.visible = false
	var badge_stack := UIKit.vbox(0)
	badge_stack.alignment = BoxContainer.ALIGNMENT_CENTER
	_lesson_badge.add_child(badge_stack)
	badge_stack.add_child(UIKit.label("LESSON", 24, Palette.PAPER))
	badge_stack.add_child(UIKit.label("Nothing to lose", 22, Palette.LEAF_LIGHT))
	middle.add_child(_lesson_badge)
	if _is_tutorial:
		_lesson_badge.visible = true

	var moves_stack := UIKit.vbox(0)
	moves_stack.alignment = BoxContainer.ALIGNMENT_CENTER
	_moves_card.add_child(moves_stack)
	_moves_cap = UIKit.label("MOVES", 24, Palette.WOOD_DARK)
	moves_stack.add_child(_moves_cap)
	_moves_label = UIKit.label("0", 68, Palette.PINK_DARK)
	moves_stack.add_child(_moves_label)

	_queue_row = UIKit.hbox(10)
	_queue_row.custom_minimum_size = Vector2(0, 88)
	_queue_row.alignment = BoxContainer.ALIGNMENT_BEGIN
	top.add_child(_queue_row)

	# --- middle board slot
	board_holder = Control.new()
	board_holder.size_flags_vertical = Control.SIZE_EXPAND_FILL
	board_holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_child(board_holder)

	# --- bottom: boosters
	var bottom := UIKit.hbox(0)
	bottom.custom_minimum_size = Vector2(0, BOTTOM_HEIGHT)
	bottom.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_child(bottom)
	_booster_row = bottom

	booster_bar = BoosterBar.new()
	booster_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	booster_bar.size_flags_vertical = Control.SIZE_EXPAND_FILL
	bottom.add_child(booster_bar)
	booster_bar.booster_requested.connect(func(booster: int) -> void: booster_requested.emit(booster))
	if _is_tutorial:
		bottom.visible = false


func _round_button(text: String, color: Color) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(92, 92)
	b.focus_mode = Control.FOCUS_NONE
	b.add_theme_font_size_override("font_size", 40)
	b.add_theme_font_override("font", UIKit.bold_font())
	b.add_theme_color_override("font_color", Palette.PAPER)
	b.add_theme_color_override("font_hover_color", Palette.WHITE)
	b.add_theme_stylebox_override("normal", UIKit.wood_box(color, Palette.WOOD_DARK, 10))
	b.add_theme_stylebox_override("hover", UIKit.wood_box(Palette.jitter(color, 9, 0.08), Palette.WOOD_DARK, 10))
	b.add_theme_stylebox_override("pressed", UIKit.wood_box(Palette.darken(color, 0.12), Palette.WOOD_DARK, 10))
	b.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	return b


# --- updates ---------------------------------------------------------------

func set_stage(stage_id: int, title: String) -> void:
	_stage_title.text = "%s" % title


func set_coins(amount: int) -> void:
	var coin := _coin_pill as CoinDisplay
	if coin != null:
		coin.amount = amount


func set_moves(left: int, total: int) -> void:
	_moves_label.text = str(maxi(0, left))
	_moves_cap.text = "MOVES" if left > 3 else "HURRY!"
	var style := UIKit.wood_box(Palette.CREAM_DEEP, Palette.WOOD_DARK, 10, 1.0)
	if left <= 3:
		style = UIKit.wood_box(Palette.PINK_PALE, Palette.PINK_DARK, 10, 1.0)
	_moves_card.add_theme_stylebox_override("panel", style)
	if left <= 3 and left > 0:
		var tw := _moves_label.create_tween()
		tw.set_loops()
		tw.tween_property(_moves_label, "scale", Vector2(1.15, 1.15), 0.42)
		tw.tween_property(_moves_label, "scale", Vector2.ONE, 0.42)
	elif _moves_label.scale != Vector2.ONE:
		_moves_label.scale = Vector2.ONE


func set_queue(customers: Array) -> void:
	for child in _queue_row.get_children():
		child.queue_free()
	var shown := 0
	for entry in customers:
		if shown >= 4:
			break
		var customer: CustomerData = entry
		if customer == null:
			continue
		var chip := PanelContainer.new()
		chip.add_theme_stylebox_override("panel", UIKit.cream_box())
		chip.custom_minimum_size = Vector2(84, 84)
		var portrait := CharacterIcon.new()
		portrait.cast = CharacterIcon.Cast.CUSTOMER
		portrait.customer = customer
		portrait.framing = 0
		portrait.custom_minimum_size = Vector2(72, 72)
		chip.add_child(portrait)
		_queue_row.add_child(chip)
		shown += 1
	if customers.size() > shown:
		var more := UIKit.label("+%d" % (customers.size() - shown), 30, Palette.WOOD_DARK)
		more.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		_queue_row.add_child(more)
