class_name ResultOverlay
extends Control

## Win / lose panel shown on top of the board.
##
## Losing is never a dead end: +5 moves can be taken free, and a rewarded video is
## only ever offered as an option, never forced (Master Plan sections 44 and 45).

signal continue_pressed()      ## next stage
signal retry_pressed()
signal home_pressed()
signal watch_ad_for_moves()

const OFFER_COST := 900

var _title: Label
var _subtitle: Label
var _stars: StarDisplay
var _coin_display: CoinDisplay
var _coins_label: Label
var _card: PanelContainer
var _buttons: VBoxContainer
var _unlock_row: HBoxContainer
var is_win: bool = false


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	UIKit.apply_root_theme(self)
	_build()


func _build() -> void:
	var dim := ColorRect.new()
	dim.color = Color(0.20, 0.12, 0.06, 0.62)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(dim)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	_card = PanelContainer.new()
	_card.add_theme_stylebox_override("panel", UIKit.cream_box())
	_card.custom_minimum_size = Vector2(880, 0)
	center.add_child(_card)

	var stack := UIKit.vbox(14)
	_card.add_child(stack)

	_title = UIKit.title("", 76, Palette.WOOD_DARK)
	stack.add_child(_title)

	_subtitle = UIKit.wrap_label("", 30, Palette.INK_SOFT)
	_subtitle.custom_minimum_size = Vector2(780, 60)
	stack.add_child(_subtitle)

	_stars = StarDisplay.new()
	_stars.star_size = 66.0
	_stars.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	stack.add_child(_stars)

	var coin_row := UIKit.hbox(10)
	coin_row.alignment = BoxContainer.ALIGNMENT_CENTER
	_coin_display = CoinDisplay.new()
	_coin_display.icon_size = 88.0
	coin_row.add_child(_coin_display)
	_coins_label = UIKit.label("+0", 52, Palette.WOOD_DARK)
	_coins_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	coin_row.add_child(_coins_label)
	stack.add_child(coin_row)

	_unlock_row = UIKit.hbox(14)
	_unlock_row.alignment = BoxContainer.ALIGNMENT_CENTER
	stack.add_child(_unlock_row)

	_buttons = UIKit.vbox(12)
	stack.add_child(_buttons)


func show_win(title_text: String, stars: int, coins: int, unlocks: Array, is_new_best: bool) -> void:
	visible = true
	is_win = true
	_title.text = "SERVE!"
	_subtitle.text = "%s cleared. The stall smells wonderful." % title_text
	_set_stars(stars)
	_coins_label.text = "+%d" % coins
	_coin_display.amount = coins
	_populate_unlocks(unlocks)
	_clear_buttons()

	var again := UIKit.primary_button("Play Again")
	again.pressed.connect(func() -> void:
		AudioManager.play(AudioManager.Sfx.TAP)
		retry_pressed.emit()
	)
	_buttons.add_child(again)

	var next_stage := UIKit.button("Next Stage", 38, Palette.LEAF)
	next_stage.pressed.connect(func() -> void:
		AudioManager.play(AudioManager.Sfx.TAP)
		continue_pressed.emit()
	)
	_buttons.add_child(next_stage)

	if is_new_best:
		_add_badge("New Best!", Palette.GOLD)

	var home := UIKit.button("Back to Stall", 32, Palette.WOOD_LIGHT)
	home.pressed.connect(func() -> void:
		AudioManager.play(AudioManager.Sfx.TAP)
		home_pressed.emit()
	)
	_buttons.add_child(home)

	AudioManager.play(AudioManager.Sfx.REWARD)
	_animate_in()


func show_fail(missing: String, can_afford_offer: bool) -> void:
	visible = true
	is_win = false
	_title.text = "SO CLOSE!"
	_subtitle.text = missing
	_set_stars(0)
	_coins_label.text = "+0"
	_coin_display.amount = 0
	_populate_unlocks([])
	_clear_buttons()

	var free_moves := UIKit.primary_button("+5 Moves  ·  Free")
	free_moves.pressed.connect(func() -> void:
		AudioManager.play(AudioManager.Sfx.TAP)
		continue_pressed.emit()
	)
	_buttons.add_child(free_moves)

	var retry := UIKit.button("Try Again", 36, Palette.WOOD_LIGHT)
	retry.pressed.connect(func() -> void:
		AudioManager.play(AudioManager.Sfx.TAP)
		retry_pressed.emit()
	)
	_buttons.add_child(retry)

	if can_afford_offer and EconomyManager.can_afford(OFFER_COST):
		var buy := UIKit.button("+5 Moves  ·  %d Coins" % OFFER_COST, 30, Palette.GOLD)
		buy.pressed.connect(func() -> void:
			if EconomyManager.spend_coins(OFFER_COST):
				AudioManager.play(AudioManager.Sfx.REWARD)
			continue_pressed.emit()
		)
		_buttons.add_child(buy)

	# Rewarded video stays optional and is the least prominent option.
	if GameManager.setting("rewarded_ads", false):
		var ad := UIKit.button("Watch Ad  ·  +5 Moves", 28, Palette.LEAF_LIGHT)
		ad.pressed.connect(func() -> void:
			AudioManager.play(AudioManager.Sfx.TAP)
			watch_ad_for_moves.emit()
		)
		_buttons.add_child(ad)

	var home := UIKit.button("Back to Stall", 28, Palette.WOOD_PALE)
	home.pressed.connect(func() -> void:
		AudioManager.play(AudioManager.Sfx.TAP)
		home_pressed.emit()
	)
	_buttons.add_child(home)

	AudioManager.play(AudioManager.Sfx.FAIL, 1.0, -4.0)
	_animate_in()


func _clear_buttons() -> void:
	for child in _buttons.get_children():
		child.queue_free()


func _add_badge(text: String, color: Color) -> void:
	var badge := PanelContainer.new()
	badge.add_theme_stylebox_override("panel", UIKit.flat_box(color, Palette.WOOD_DARK, 8, 3, 16))
	var label := UIKit.label(text, 30, Palette.WOOD_DARK)
	badge.add_child(label)
	badge.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_buttons.add_child(badge)


func _set_stars(stars: int) -> void:
	if _stars != null:
		_stars.filled = stars


func _populate_unlocks(unlocks: Array) -> void:
	for child in _unlock_row.get_children():
		child.queue_free()
	for id in unlocks:
		var data := KuihLibrary.get_kuih(id)
		if data == null:
			continue
		var holder := PanelContainer.new()
		holder.add_theme_stylebox_override("panel", UIKit.flat_box(Palette.CREAM_DEEP, Palette.GOLD_DARK, 6, 3, 16))
		var col := UIKit.vbox(2)
		holder.add_child(col)
		var icon := KuihIcon.new()
		icon.kuih = data
		icon.custom_minimum_size = Vector2(120, 120)
		col.add_child(icon)
		col.add_child(UIKit.label(data.display_name, 22, Palette.WOOD_DARK))
		_unlock_row.add_child(holder)


func _animate_in() -> void:
	modulate.a = 0.0
	_card.pivot_offset = _card.size * 0.5
	_card.scale = Vector2(0.86, 0.86)
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(self, "modulate:a", 1.0, 0.24)
	tw.tween_property(_card, "scale", Vector2.ONE, 0.42).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
