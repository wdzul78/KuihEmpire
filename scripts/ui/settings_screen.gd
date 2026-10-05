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

	var margin := UIKit.margin(30)
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(margin)

	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	margin.add_child(scroll)
	var column := UIKit.vbox(24)
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(column)

	var top := UIKit.hbox(16)
	column.add_child(top)
	var back := GameButton.create(MenuText.text("back"))
	back.custom_minimum_size.x = 220
	back.pressed.connect(func() -> void:
		AudioManager.play(AudioManager.Sfx.TAP)
		GameManager.go_home()
	)
	top.add_child(back)
	var title := UIKit.title(MenuText.text("settings"), 56)
	title.add_theme_color_override("font_color", Palette.PAPER)
	title.add_theme_color_override("font_outline_color", Palette.WOOD_DARK)
	title.add_theme_constant_override("outline_size", 5)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	top.add_child(title)

	var card := PanelContainer.new()
	card.add_theme_stylebox_override("panel", UIKit.cream_box())
	column.add_child(card)
	var stack := UIKit.vbox(14)
	card.add_child(stack)

	stack.add_child(UIKit.label(MenuText.text("name"), 36))
	var player_name := LineEdit.new()
	player_name.name = "PlayerName"
	player_name.max_length = 24
	player_name.text = str(SaveManager.data.get("profile", {}).get("name", "Player"))
	player_name.custom_minimum_size = Vector2(0, GameButton.HEIGHT)
	player_name.add_theme_font_size_override("font_size", 38)
	player_name.add_theme_color_override("font_color", Palette.WOOD_DARK)
	player_name.add_theme_stylebox_override("normal", UIKit.wood_box(Palette.CREAM_DEEP, Palette.WOOD, 12))
	player_name.text_changed.connect(func(value: String) -> void:
		SaveManager.data["profile"]["name"] = value.strip_edges() if not value.strip_edges().is_empty() else "Player"
		SaveManager.mark_dirty()
	)
	stack.add_child(player_name)
	var avatar_button := GameButton.create(MenuText.text("avatar") + " · " + AvatarLibrary.display_name(str(SaveManager.data["profile"].get("avatar", "aina"))), "secondary")
	avatar_button.name = "AvatarSelector"
	avatar_button.pressed.connect(_show_avatars)
	stack.add_child(avatar_button)
	stack.add_child(UIKit.label(MenuText.text("language"), 36))
	var language := OptionButton.new()
	language.name = "LanguageSelector"
	language.add_item("Bahasa Melayu")
	language.add_item("English")
	language.selected = 1 if SaveManager.get_setting("language", "en") == "en" else 0
	language.custom_minimum_size = Vector2(0, 104)
	language.add_theme_font_size_override("font_size", 36)
	GameButton.apply(language, "back")
	for state in ["normal", "hover", "pressed", "disabled"]:
		var inset := StyleBoxEmpty.new()
		inset.content_margin_left = 36
		inset.content_margin_right = 54
		language.add_theme_stylebox_override(state, inset)
	language.item_selected.connect(func(index: int) -> void:
		SaveManager.set_setting("language", "en" if index == 1 else "ms")
		_rebuild.call_deferred()
	)
	stack.add_child(language)
	stack.add_child(_toggle_row(MenuText.text("music"), "music"))
	stack.add_child(_toggle_row(MenuText.text("sfx"), "sfx"))
	stack.add_child(_toggle_row(MenuText.text("haptics"), "haptics"))
	stack.add_child(_toggle_row(MenuText.text("hints"), "show_hints"))

	var reset := GameButton.create(MenuText.text("reset"), "danger")
	reset.pressed.connect(_on_reset)
	stack.add_child(reset)

	var spacer := UIKit.spacer(Vector2(0, 20))
	column.add_child(spacer)

	var stats := ProgressionManager.stats()
	column.add_child(UIKit.label(
		MenuText.text("stats") % [
			int(stats.get("levels_played", 0)),
			int(stats.get("levels_won", 0)),
			ProgressionManager.total_stars(),
		],
		30, Palette.PAPER
	))

	_toast = UIKit.label("", 26, Palette.PINK_DARK)
	column.add_child(_toast)


func _toggle_row(text: String, key: String) -> Control:
	var row := UIKit.hbox(16)
	var label := UIKit.wrap_label(text, 36, Palette.INK, HORIZONTAL_ALIGNMENT_LEFT)
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(label)

	var button := SettingsToggle.new()
	button.name = "Toggle_" + key
	button.accessibility_name = text
	button.toggled.connect(func(value: bool) -> void:
		AudioManager.play(AudioManager.Sfx.TAP)
		GameManager.set_setting(key, value)
	)
	button.set_pressed_no_signal(bool(GameManager.setting(key, true)))
	row.add_child(button)
	return row


func _select_avatar(id: String) -> void:
	if not AvatarLibrary.valid(id):
		return
	SaveManager.data["profile"]["avatar"] = id
	SaveManager.mark_dirty()
	SaveManager.save_game()
	_rebuild.call_deferred()


func _show_avatars() -> void:
	if has_node("AvatarPicker"):
		return
	var overlay := Control.new()
	overlay.name = "AvatarPicker"
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(overlay)
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, .65)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(dim)
	var card := PanelContainer.new()
	card.add_theme_stylebox_override("panel", UIKit.cream_box())
	card.anchor_left = .08
	card.anchor_right = .92
	card.anchor_top = .17
	card.anchor_bottom = .83
	overlay.add_child(card)
	var stack := UIKit.vbox(20)
	card.add_child(stack)
	stack.add_child(UIKit.title(MenuText.text("avatar"), 40))
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	stack.add_child(scroll)
	var grid := GridContainer.new()
	grid.columns = 4
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation", 12)
	grid.add_theme_constant_override("v_separation", 12)
	scroll.add_child(grid)
	for avatar_id in AvatarLibrary.ids():
		var id := String(avatar_id)
		var selected := id == str(SaveManager.data["profile"].get("avatar", "aina"))
		var button := UIKit.button("", 22, Palette.GOLD_PALE if selected else Palette.CREAM_DEEP)
		button.name = "Avatar_" + id
		button.custom_minimum_size = Vector2(180, 210)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.tooltip_text = AvatarLibrary.display_name(id)
		grid.add_child(button)
		var image := AvatarLibrary.icon(id)
		image.anchor_left = .12
		image.anchor_right = .88
		image.anchor_top = .04
		image.anchor_bottom = .75
		button.add_child(image)
		var caption := UIKit.label(AvatarLibrary.display_name(id), 22, Palette.WOOD_DARK)
		caption.mouse_filter = Control.MOUSE_FILTER_IGNORE
		caption.clip_text = true
		caption.anchor_left = .04
		caption.anchor_right = .96
		caption.anchor_top = .76
		caption.anchor_bottom = .98
		button.add_child(caption)
		button.pressed.connect(func() -> void: _select_avatar(id))
	var close := GameButton.create(MenuText.text("close"), "back")
	close.pressed.connect(func() -> void: overlay.queue_free())
	stack.add_child(close)


func _paint_toggle(button: Button, value: bool) -> void:
	button.text = MenuText.text("on") if value else MenuText.text("off")
	var fill := Palette.LEAF if value else Color("b9a891")
	button.add_theme_stylebox_override("normal", UIKit.wood_box(fill, Palette.WOOD_DARK, 10))
	button.add_theme_stylebox_override("hover", UIKit.wood_box(Palette.jitter(fill, 4, 0.06), Palette.WOOD_DARK, 10))
	button.add_theme_stylebox_override("pressed", UIKit.wood_box(Palette.darken(fill, 0.1), Palette.WOOD_DARK, 10))
	button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())


func _on_reset() -> void:
	if has_node("ResetConfirmation"):
		return
	var overlay := Control.new()
	overlay.name = "ResetConfirmation"
	overlay.z_index = 100
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(overlay)
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, .65)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(dim)
	var card := PanelContainer.new()
	card.add_theme_stylebox_override("panel", UIKit.cream_box())
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(center)
	card.custom_minimum_size.x = get_viewport_rect().size.x * .88
	center.add_child(card)
	overlay.resized.connect(func() -> void: card.custom_minimum_size.x = overlay.size.x * .88)
	var stack := UIKit.vbox(22)
	card.add_child(stack)
	stack.add_child(UIKit.title(MenuText.text("reset"), 48))
	stack.add_child(UIKit.wrap_label(JourneyArt.localized(
		"Reset semua kemajuan? Permainan akan kembali ke keadaan awal. Tindakan ini tidak boleh dibatalkan.",
		"Reset all progress? The game will return to its initial state. This cannot be undone."
	), 38))
	var buttons := UIKit.hbox(18)
	stack.add_child(buttons)
	var cancel := GameButton.create("Cancel", "back")
	cancel.name = "CancelReset"
	cancel.focus_mode = Control.FOCUS_ALL
	cancel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	buttons.add_child(cancel)
	cancel.pressed.connect(overlay.queue_free)
	var confirm := GameButton.create("OK", "danger")
	confirm.name = "ConfirmReset"
	confirm.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	buttons.add_child(confirm)
	confirm.pressed.connect(_confirm_reset, CONNECT_DEFERRED)
	cancel.grab_focus()


func _confirm_reset() -> void:
	if not has_node("ResetConfirmation"):
		return
	get_node("ResetConfirmation").free()
	ProgressionManager.reset_all()
	AudioManager.apply_settings(SaveManager.data.get("settings", {}))
	_rebuild()
	_toast.text = MenuText.text("reset_done")
	AudioManager.play(AudioManager.Sfx.TAP, 0.8)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("go_back") and has_node("ResetConfirmation"):
		get_node("ResetConfirmation").queue_free()
		get_viewport().set_input_as_handled()


func _rebuild() -> void:
	for child in get_children():
		remove_child(child)
		child.queue_free()
	_build()
