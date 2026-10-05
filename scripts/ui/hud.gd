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

const TOP_HEIGHT := 600
const BOTTOM_HEIGHT := 190

var board_holder: Control
var order_panel: OrderPanel
var booster_bar: BoosterBar

var _coin_pill: Control
var _title_label: Label
var _queue_row: HBoxContainer
var _moves_label: Label
var _moves_cap: Label
var _moves_card: Panel
var _stage_title: Label
var _booster_row: Control
var _lesson_badge: PanelContainer
var score_progress: ScoreProgress
var _is_tutorial: bool = false
var tutorial_layout: PackedScene = GameUILayout.TUTORIAL
var campaign_layout: PackedScene = GameUILayout.CAMPAIGN
var _hint_button: Button
var _title_plaque: Panel


## Tutorial stages have no move pressure. Booster controls remain in their tray.
func set_tutorial_mode(value: bool) -> void:
	_is_tutorial = value
	if _moves_card != null:
		_moves_card.visible = not value
	if _booster_row != null:
		_booster_row.visible = true
	if _lesson_badge != null:
		_lesson_badge.visible = value
	if _title_plaque != null:
		_title_plaque.visible = value
	if _queue_row != null:
		_queue_row.visible = not value
	if value and _title_label != null:
		_title_label.add_theme_font_size_override("font_size", 36)
		_title_label.anchor_left = .14
		_title_label.anchor_top = .093
		_title_label.anchor_right = .64
		_title_label.anchor_bottom = .127
		_title_label.add_theme_color_override("font_color", Palette.WOOD_DARK)
		_title_label.add_theme_constant_override("outline_size", 0)
		_hint_button.anchor_left = .67
		_hint_button.anchor_right = .77
		_hint_button.anchor_top = .087
		_hint_button.anchor_bottom = .143
	else:
		if _title_label != null:
			_title_label.add_theme_font_size_override("font_size", 24)
			_title_label.add_theme_color_override("font_color", Palette.PAPER)
			_title_label.add_theme_constant_override("outline_size", 5)
			_title_label.anchor_left = .04
			_title_label.anchor_top = .115
			_title_label.anchor_right = .26
			_title_label.anchor_bottom = .143
		if _hint_button != null:
			_hint_button.add_theme_font_size_override("font_size", 26)
			_hint_button.anchor_left = .30
			_hint_button.anchor_right = .355
			_hint_button.anchor_top = .09
			_hint_button.anchor_bottom = .115

	if is_instance_valid(order_panel):
		GameUILayout.apply_hud(self, tutorial_layout if value else campaign_layout)


func _ready() -> void:
	UIKit.apply_root_theme(self)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_build()
	resized.connect(queue_redraw)


## Proportions follow Sweet Match Adventure; board rules still use an 8x8 grid.
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
	var logo := UIKit.brand_logo(Vector2.ZERO)
	_place(logo, Rect2(0.025, 0.012, 0.24, 0.095))
	var heart := HeartDisplay.new()
	heart.refill_enabled = false
	_place(heart, Rect2(.265, .037, .20, .044))
	_coin_pill = CoinDisplay.new()
	_coin_pill.icon_size = 92
	_coin_pill.dark_style = true
	_coin_pill.illustrated_style = true
	_coin_pill.uniform_bar_height = true
	_coin_pill.show_plus = false
	_place(_coin_pill, Rect2(.480, .037, .20, .044))
	_coin_pill.hide()

	score_progress = ScoreProgress.new()
	_place(score_progress, Rect2(.485, .043, .405, .052))
	var settings := _round_button("⚙", Palette.WOOD)
	settings.text = ""
	GameplaySkin.button(settings, "settings")
	settings.pressed.connect(func() -> void: settings_pressed.emit())
	_place(settings, Rect2(0.905, 0.0389, 0.075, 0.0422))

	_title_plaque = Panel.new()
	_title_plaque.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_title_plaque.add_theme_stylebox_override("panel", UIKit.cream_box())
	_place(_title_plaque, Rect2(.12, .09, .54, .04))
	_title_plaque.visible = false
	_title_label = UIKit.label("", 24, Palette.PAPER)
	_title_label.clip_text = true
	_title_label.add_theme_color_override("font_outline_color", Palette.WOOD_DARK)
	_title_label.add_theme_constant_override("outline_size", 5)
	_stage_title = _title_label
	_place(_title_label, Rect2(0.04, 0.115, 0.22, 0.028))
	if _is_tutorial:
		_title_label.add_theme_font_size_override("font_size", 36)
		_title_label.anchor_left = .025
		_title_label.anchor_top = .093
		_title_label.anchor_right = .75
		_title_label.anchor_bottom = .133

	_moves_card = Panel.new()
	_moves_card.add_theme_stylebox_override("panel", GameplaySkin.box("moves_board"))
	_place(_moves_card, Rect2(0.815, 0.102, 0.15, 0.078))
	_moves_label = UIKit.label("0", 46, Palette.GOLD_PALE)
	_moves_label.add_theme_color_override("font_outline_color", Palette.WOOD_DARK)
	_moves_label.add_theme_constant_override("outline_size", 4)
	_moves_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	order_place(_moves_card, _moves_label, Rect2(.12, .30, .76, .40))
	_moves_cap = UIKit.label("MOVES", 21, Palette.PAPER)
	_moves_cap.add_theme_color_override("font_outline_color", Palette.WOOD_DARK)
	_moves_cap.add_theme_constant_override("outline_size", 3)
	_moves_cap.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	order_place(_moves_card, _moves_cap, Rect2(.10, .70, .80, .23))

	_lesson_badge = PanelContainer.new()
	_lesson_badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_lesson_badge.add_theme_stylebox_override("panel", GameplaySkin.box("moves_board", Vector4(16, 38, 16, 16)))
	_place(_lesson_badge, Rect2(.79, .091, .18, .080))
	var practice := UIKit.vbox(4)
	practice.alignment = BoxContainer.ALIGNMENT_CENTER
	_lesson_badge.add_child(practice)
	practice.add_child(UIKit.label(JourneyArt.localized("LATIHAN", "LESSON"), 29, Palette.GOLD_PALE))
	practice.add_child(UIKit.label(JourneyArt.localized("Santai", "Practice"), 26, Palette.PAPER))
	_lesson_badge.visible = _is_tutorial
	var hint := _round_button("", Palette.LEAF)
	_hint_button = hint
	hint.custom_minimum_size = Vector2(54, 54)
	hint.add_theme_font_size_override("font_size", 44)
	hint.tooltip_text = JourneyArt.localized("Tunjukkan langkah", "Show a hint")
	for state in ["normal", "hover", "pressed"]:
		var color := Palette.LEAF if state == "normal" else Palette.LEAF_LIGHT if state == "hover" else Palette.LEAF_DEEP
		hint.add_theme_stylebox_override(state, UIKit.flat_box(color, Palette.WOOD_DARK, 0, 5, 54))
	hint.pressed.connect(func() -> void: hint_pressed.emit())
	_place(hint, Rect2(0.30, 0.09, 0.055, 0.025))
	var hint_icon := TextureRect.new()
	hint_icon.texture = TutorialArt.texture("hint_bulb")
	hint_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	hint_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	hint_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	order_place(hint, hint_icon, Rect2(.12, .10, .76, .80))
	if _is_tutorial:
		hint.anchor_left = .755
		hint.anchor_right = .80
		hint.anchor_top = .095
		hint.anchor_bottom = .12

	order_panel = OrderPanel.new()
	_place(order_panel, Rect2(0.045, 0.115, 0.91, 0.225))
	_queue_row = UIKit.hbox(6)
	_queue_row.alignment = BoxContainer.ALIGNMENT_BEGIN
	_place(_queue_row, Rect2(0.04, 0.15, 0.21, 0.03))

	board_holder = Control.new()
	board_holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_place(board_holder, Rect2(0.07, 0.405, 0.86, 0.433))
	order_panel._portrait.occluding_board = board_holder
	order_panel._aina.occluding_board = board_holder

	var tray := PanelContainer.new()
	tray.add_theme_stylebox_override("panel", GameplaySkin.box("booster_tray", Vector4(30, 20, 30, 20)))
	_place(tray, Rect2(0.12, 0.845, 0.76, 0.125))
	_booster_row = tray
	booster_bar = BoosterBar.new()
	tray.add_child(booster_bar)
	booster_bar.booster_requested.connect(func(booster: int) -> void: booster_requested.emit(booster))
	tray.visible = true
	var named_nodes := {
		"Logo": logo, "HeartMeter": heart, "HiddenCoinMeter": _coin_pill,
		"ScoreMeter": score_progress, "PauseButton": settings,
		"StageTitleFrame": _title_plaque, "StageTitle": _title_label,
		"MovesPanel": _moves_card, "MovesValue": _moves_label, "MovesCaption": _moves_cap,
		"LessonBadge": _lesson_badge, "HintButton": hint, "HintIcon": hint_icon,
		"OrderArea": order_panel, "CustomerQueue": _queue_row,
		"PuzzleBoard": board_holder, "SpecialItemsTray": tray, "SpecialItems": booster_bar,
	}
	for node_name in named_nodes:
		named_nodes[node_name].name = node_name
	order_panel.tutorial_layout = tutorial_layout
	order_panel.campaign_layout = campaign_layout
	set_tutorial_mode(_is_tutorial)


func configure_score(level: LevelDefinition) -> void:
	score_progress.configure(level)

func set_score(value: int) -> void:
	score_progress.set_score(value)


func order_place(parent: Control, node: Control, rect: Rect2) -> void:
	parent.add_child(node)
	node.anchor_left = rect.position.x
	node.anchor_top = rect.position.y
	node.anchor_right = rect.end.x
	node.anchor_bottom = rect.end.y

func _round_button(text: String, color: Color) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(46, 46)
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
	var style := GameplaySkin.box("moves_board")
	if left <= 3:
		style.modulate_color = Color(1, .7, .7)
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
		chip.custom_minimum_size = Vector2(54, 54)
		var portrait := CharacterIcon.new()
		portrait.cast = CharacterIcon.Cast.CUSTOMER
		portrait.customer = customer
		portrait.framing = 0
		portrait.custom_minimum_size = Vector2(46, 46)
		chip.add_child(portrait)
		_queue_row.add_child(chip)
		shown += 1
	if customers.size() > shown:
		var more := UIKit.label("+%d" % (customers.size() - shown), 30, Palette.WOOD_DARK)
		more.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		_queue_row.add_child(more)
