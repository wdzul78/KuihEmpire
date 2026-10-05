class_name SettingsToggle
extends Button

const SHEET := preload("res://assets/ui/settings_v1/toggle_sheet.png")
const REGIONS := [Rect2(136, 176, 980, 432), Rect2(136, 648, 980, 432)]

func _init() -> void:
	toggle_mode = true
	focus_mode = Control.FOCUS_ALL
	custom_minimum_size = Vector2(240, 112)
	for state in ["normal", "hover", "pressed", "disabled"]:
		add_theme_stylebox_override(state, StyleBoxEmpty.new())
	add_theme_stylebox_override("focus", UIKit.flat_box(Color.TRANSPARENT, Palette.GOLD, 0, 3, 20))

func _ready() -> void:
	toggled.connect(func(_value: bool) -> void: queue_redraw())
	resized.connect(queue_redraw)

func _draw() -> void:
	var region: Rect2 = REGIONS[0 if button_pressed else 1]
	var fit := minf(size.x / region.size.x, size.y / region.size.y)
	var art_size := region.size * fit
	draw_texture_rect_region(SHEET, Rect2((size - art_size) / 2, art_size), region)
