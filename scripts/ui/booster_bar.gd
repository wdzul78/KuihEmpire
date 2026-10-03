class_name BoosterBar
extends Control

## Booster tray (Master Plan section 38).
##
## Sudip, Dulang, Shuffle and Tapau need the player to tap the board afterwards,
## so this bar only reports the request; the level screen drives the targeting.

signal booster_requested(booster: int)

const BUTTONS := [
	{"booster": EconomyManager.Booster.SPATULA, "name": "Sudip", "color": Color("63a7e0")},
	{"booster": EconomyManager.Booster.TRAY, "name": "Dulang", "color": Palette.GOLD},
	{"booster": EconomyManager.Booster.SHUFFLE, "name": "Shuffle", "color": Color("9b7fd4")},
	{"booster": EconomyManager.Booster.GIFT, "name": "Tapau", "color": Palette.PINK},
	{"booster": EconomyManager.Booster.EXTRA_MOVES, "name": "+5", "color": Palette.LEAF},
]

var _buttons: Dictionary = {}   # booster -> Button
var _selected: int = -1


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_build()
	EconomyManager.boosters_changed.connect(refresh)
	resized.connect(_recenter)


func _build() -> void:
	var row := UIKit.hbox(18)
	row.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	add_child(row)

	for entry in BUTTONS:
		var booster: int = entry["booster"]
		var holder := Control.new()
		holder.custom_minimum_size = Vector2(150, 156)
		holder.mouse_filter = Control.MOUSE_FILTER_IGNORE

		var button := Button.new()
		button.custom_minimum_size = Vector2(150, 150)
		button.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		button.focus_mode = Control.FOCUS_NONE
		button.add_theme_stylebox_override("normal", UIKit.wood_box(entry["color"], Palette.WOOD_DARK, 12))
		button.add_theme_stylebox_override("hover", UIKit.wood_box(Palette.jitter(entry["color"], 5, 0.08), Palette.WOOD_DARK, 12))
		button.add_theme_stylebox_override("pressed", UIKit.wood_box(Palette.darken(entry["color"], 0.12), Palette.WOOD_DARK, 12))
		button.add_theme_stylebox_override("disabled", UIKit.wood_box(Color("b9a891"), Color("8d8271"), 12))
		button.text = entry["name"]
		button.add_theme_font_size_override("font_size", 26)
		button.add_theme_color_override("font_color", Palette.WHITE)
		button.add_theme_font_override("font", UIKit.bold_font())
		button.pressed.connect(_on_pressed.bind(booster))
		holder.add_child(button)

		var badge_style := StyleBoxFlat.new()
		badge_style.bg_color = Palette.PINK_DARK
		badge_style.set_corner_radius_all(26)
		badge_style.border_color = Palette.WOOD_DARK
		badge_style.set_border_width_all(3)
		var badge := PanelContainer.new()
		badge.name = "Badge"
		badge.add_theme_stylebox_override("panel", badge_style)
		badge.custom_minimum_size = Vector2(56, 56)
		badge.size = Vector2(56, 56)
		badge.position = Vector2(94, -6)
		badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var badge_label := UIKit.label("0", 26, Palette.WHITE)
		badge_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		badge.add_child(badge_label)
		holder.add_child(badge)

		row.add_child(holder)
		_buttons[booster] = button
	refresh()


func _recenter() -> void:
	queue_redraw()


func _on_pressed(booster: int) -> void:
	if _buttons.get(booster, null) == null:
		return
	if not EconomyManager.has_booster(booster):
		AudioManager.play(AudioManager.Sfx.INVALID, 0.9, -6.0)
		return
	AudioManager.play(AudioManager.Sfx.TAP)
	_selected = booster if _selected != booster else -1
	_highlight()
	booster_requested.emit(booster)


func cancel_selection() -> void:
	_selected = -1
	_highlight()


func selected() -> int:
	return _selected


func _highlight() -> void:
	for booster in _buttons:
		var button: Button = _buttons[booster]
		var entry: Dictionary = BUTTONS[0]
		for candidate in BUTTONS:
			if candidate["booster"] == booster:
				entry = candidate
				break
		var base: Color = entry["color"]
		if booster == _selected:
			button.modulate = Palette.lighten(base, 0.35)
			button.scale = Vector2(1.10, 1.10)
			button.pivot_offset = button.size * 0.5
		else:
			button.modulate = Color.WHITE
			button.scale = Vector2.ONE


func refresh() -> void:
	for booster in _buttons:
		var button: Button = _buttons[booster]
		button.disabled = EconomyManager.booster_count(booster) <= 0
		var holder := button.get_parent() as Control
		if holder == null:
			continue
		var badge := holder.get_node_or_null("Badge") as Control
		if badge != null:
			var badge_label := badge.get_child(0) as Label
			if badge_label != null:
				badge_label.text = str(EconomyManager.booster_count(booster))
			badge.modulate.a = 0.6 if button.disabled else 1.0
	_highlight()
