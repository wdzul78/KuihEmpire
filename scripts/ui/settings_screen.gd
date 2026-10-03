class_name SettingsScreen
extends Control

## Settings (Master Plan section 49) - audio, haptics, hints and a reset.

var _toast: Label


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	UIKit.apply_root_theme(self)
	_build()


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

	var top := UIKit.hbox(16)
	column.add_child(top)
	var back := UIKit.button("Back", 28, Palette.WOOD_LIGHT)
	back.custom_minimum_size = Vector2(200, 88)
	back.pressed.connect(func() -> void:
		AudioManager.play(AudioManager.Sfx.TAP)
		GameManager.go_home()
	)
	top.add_child(back)
	var title := UIKit.title("Settings", 56)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	top.add_child(title)

	var card := PanelContainer.new()
	card.add_theme_stylebox_override("panel", UIKit.cream_box())
	column.add_child(card)
	var stack := UIKit.vbox(14)
	card.add_child(stack)

	stack.add_child(_toggle_row("Music", "music"))
	stack.add_child(_toggle_row("Sound Effects", "sfx"))
	stack.add_child(_toggle_row("Haptics", "haptics"))
	stack.add_child(_toggle_row("Show Move Hints", "show_hints"))

	var reset := UIKit.button("Reset Progress", 30, Palette.PINK_DARK)
	reset.pressed.connect(_on_reset)
	stack.add_child(reset)

	var spacer := UIKit.spacer(Vector2(0, 20))
	column.add_child(spacer)

	var stats := ProgressionManager.stats()
	column.add_child(UIKit.label(
		"Stages played %d   ·   Stages cleared %d   ·   Stars %d" % [
			int(stats.get("levels_played", 0)),
			int(stats.get("levels_won", 0)),
			ProgressionManager.total_stars(),
		],
		24, Palette.INK_SOFT
	))

	_toast = UIKit.label("", 26, Palette.PINK_DARK)
	column.add_child(_toast)


func _toggle_row(text: String, key: String) -> Control:
	var row := UIKit.hbox(16)
	var label := UIKit.label(text, 30, Palette.INK, HORIZONTAL_ALIGNMENT_LEFT)
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(label)

	var button := Button.new()
	button.custom_minimum_size = Vector2(180, 76)
	button.focus_mode = Control.FOCUS_NONE
	button.add_theme_font_size_override("font_size", 26)
	button.add_theme_font_override("font", UIKit.bold_font())
	button.add_theme_color_override("font_color", Palette.PAPER)
	button.pressed.connect(func() -> void:
		AudioManager.play(AudioManager.Sfx.TAP)
		var value := not bool(GameManager.setting(key, true))
		GameManager.set_setting(key, value)
		_paint_toggle(button, value)
	)
	_paint_toggle(button, bool(GameManager.setting(key, true)))
	row.add_child(button)
	return row


func _paint_toggle(button: Button, value: bool) -> void:
	button.text = "ON" if value else "OFF"
	var fill := Palette.LEAF if value else Color("b9a891")
	button.add_theme_stylebox_override("normal", UIKit.wood_box(fill, Palette.WOOD_DARK, 10))
	button.add_theme_stylebox_override("hover", UIKit.wood_box(Palette.jitter(fill, 4, 0.06), Palette.WOOD_DARK, 10))
	button.add_theme_stylebox_override("pressed", UIKit.wood_box(Palette.darken(fill, 0.1), Palette.WOOD_DARK, 10))
	button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())


func _on_reset() -> void:
	ProgressionManager.reset_all()
	AudioManager.apply_settings(SaveManager.data.get("settings", {}))
	_toast.text = "Progress reset. Aina is back at the small stall."
	AudioManager.play(AudioManager.Sfx.TAP, 0.8)
