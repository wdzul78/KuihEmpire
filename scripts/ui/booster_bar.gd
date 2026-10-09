class_name BoosterBar
extends Control

## Booster tray (Master Plan section 38).
##
## Tangan, Dulang, Shuffle and Tapau need the player to tap the board afterwards,
## so this bar only reports the request; the level screen drives the targeting.

signal booster_requested(booster: int)

const BUTTONS := [
	{"booster": EconomyManager.Booster.SPATULA, "name": "Tangan", "color": Color("63a7e0")},
	{"booster": EconomyManager.Booster.TRAY, "name": "Dulang", "color": Palette.GOLD},
	{"booster": EconomyManager.Booster.SHUFFLE, "name": "Shuffle", "color": Color("9bdc43")},
	{"booster": EconomyManager.Booster.GIFT, "name": "Tapau", "color": Color("bc72df")},
]

var _buttons: Dictionary = {}   # booster -> Button
var _selected: int = -1
var _available := true
var practice_mode := false
var _locked_material: ShaderMaterial
const SURFACES := ["booster_blue", "booster_gold", "booster_green", "booster_purple"]
const ICONS := {
	EconomyManager.Booster.SPATULA: preload("res://assets/ui/booster_tray_v1/hand.png"),
	EconomyManager.Booster.TRAY: preload("res://assets/specials/badak_berendam_v1/badak_berendam.png"),
	EconomyManager.Booster.SHUFFLE: preload("res://assets/boosters/shuffle.png"),
	EconomyManager.Booster.GIFT: preload("res://assets/boosters/tapau.png"),
}


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_build()
	EconomyManager.boosters_changed.connect(refresh)
	resized.connect(_recenter)


func _build() -> void:
	_locked_material = ShaderMaterial.new()
	_locked_material.shader = preload("res://scripts/art/shaders/locked_booster.gdshader")
	var row := UIKit.hbox(18)
	row.name = "SpecialItemsRow"
	row.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	add_child(row)

	for index in range(BUTTONS.size()):
		var entry: Dictionary = BUTTONS[index]
		var booster: int = entry["booster"]
		var holder := Control.new()
		holder.name = ["SpatulaSlot", "TraySlot", "ShuffleSlot", "TapauSlot"][index]
		holder.custom_minimum_size = Vector2(164, 164)
		holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
		holder.size_flags_vertical = Control.SIZE_SHRINK_CENTER

		var button := Button.new()
		button.name = ["SpatulaButton", "TrayButton", "ShuffleButton", "TapauButton"][index]
		button.custom_minimum_size = Vector2(164, 164)
		button.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
		button.offset_bottom = 164
		button.focus_mode = Control.FOCUS_NONE
		for state in ["normal", "hover", "pressed", "disabled", "focus"]:
			button.add_theme_stylebox_override(state, StyleBoxEmpty.new())
		GameplaySkin.button(button, SURFACES[index])
		var booster_name := JourneyArt.localized(entry["name"], ["Hand", "Tray", "Shuffle", "Tapau"][index])
		button.text = ""
		button.tooltip_text = booster_name
		if ICONS.has(booster):
			button.text = ""
			var art := TextureRect.new()
			art.name = "BoosterArt"
			art.texture = GameplaySkin.texture("booster_hand") if booster == EconomyManager.Booster.SPATULA else ICONS[booster]
			art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			art.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
			art.offset_left = 12
			art.offset_top = 8
			art.offset_right = -12
			art.offset_bottom = -8
			art.mouse_filter = Control.MOUSE_FILTER_IGNORE
			button.add_child(art)
			var lock := BoosterLockIcon.new()
			lock.name = "LockIcon"
			lock.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
			lock.offset_left = 12
			lock.offset_top = 8
			lock.offset_right = -12
			lock.offset_bottom = -8
			lock.visible = false
			button.add_child(lock)
		button.add_theme_font_size_override("font_size", 26)
		button.add_theme_color_override("font_color", Palette.WHITE)
		button.add_theme_font_override("font", UIKit.bold_font())
		button.pressed.connect(_on_pressed.bind(booster))
		holder.add_child(button)

		var badge_style := GameplaySkin.box("booster_count")
		var badge := PanelContainer.new()
		badge.name = "Badge"
		badge.add_theme_stylebox_override("panel", badge_style)
		badge.custom_minimum_size = Vector2(56, 56)
		badge.size = Vector2(56, 56)
		badge.position = Vector2(112, -6)
		badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var badge_label := UIKit.label("0", 34, Palette.WHITE)
		badge_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		badge_label.add_theme_color_override("font_outline_color", Color("8b190b"))
		badge_label.add_theme_constant_override("outline_size", 5)
		badge_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		badge.add_child(badge_label)
		holder.add_child(badge)

		row.add_child(holder)
		_buttons[booster] = button
	refresh()


func _recenter() -> void:
	var side := clampf(minf(size.y,(size.x-54)/4.0),80,136)
	for button in _buttons.values():
		var holder := button.get_parent() as Control
		holder.custom_minimum_size = Vector2.ONE*side
		button.custom_minimum_size = Vector2.ONE*side
		button.offset_bottom = side
		var badge := holder.get_node_or_null("Badge") as Control
		if badge != null:
			badge.position = Vector2(side-50,side-48)
			badge.custom_minimum_size = Vector2(52,52)
			badge.size = Vector2(52,52)
	queue_redraw()


func _on_pressed(booster: int) -> void:
	if not _available:
		return
	if _buttons.get(booster, null) == null:
		return
	if not practice_mode and not EconomyManager.has_booster(booster):
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
		if booster == _selected:
			button.modulate = Color(1.18,1.18,1.18)
			button.scale = Vector2(1.10, 1.10)
			button.pivot_offset = button.size * 0.5
		else:
			button.modulate = Color.WHITE
			button.scale = Vector2.ONE


func refresh() -> void:
	for booster in _buttons:
		var button: Button = _buttons[booster]
		button.disabled = not _available or (not practice_mode and EconomyManager.booster_count(booster) <= 0)
		button.material = null if _available else _locked_material
		button.tooltip_text = JourneyArt.localized("Bekalan latihan percuma", "Free practice supplies") if practice_mode else "" if _available else JourneyArt.localized("Dibuka selepas tutorial", "Unlocks after tutorials")
		var art := button.get_node_or_null("BoosterArt") as Control
		var lock := button.get_node_or_null("LockIcon") as Control
		if art != null:
			art.visible = _available
		if lock != null:
			lock.visible = not _available
		var holder := button.get_parent() as Control
		if holder == null:
			continue
		var badge := holder.get_node_or_null("Badge") as Control
		if badge != null:
			badge.visible = _available
			var badge_label := badge.get_child(0) as Label
			if badge_label != null:
				badge_label.text = "∞" if practice_mode else str(EconomyManager.booster_count(booster))
			badge.modulate.a = 0.6 if button.disabled else 1.0
	_highlight()

func set_available(value: bool) -> void:
	_available = value
	if not value:
		_selected = -1
	refresh()
