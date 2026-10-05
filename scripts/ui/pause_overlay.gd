class_name PauseOverlay
extends Control

signal resume_pressed()
signal restart_pressed()
signal extra_moves_pressed()
signal quit_pressed()

var stage_title := ""
var tutorial := false
var restart_available := true
var extra_available := false
var extra_count := 0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	# Above board guidance and the tutorial dialogue spotlight.
	z_index = 200
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	UIKit.apply_root_theme(self)
	var dim := ColorRect.new()
	dim.color = Color(.12, .07, .03, .72)
	JourneyArt.place(self, dim, Rect2(0, 0, 1, 1))
	var frame := Panel.new()
	frame.add_theme_stylebox_override("panel", UIKit.flat_box(Palette.WOOD, Palette.WOOD_DARK, 0, 7, 48))
	JourneyArt.place(self, frame, Rect2(.065, .28 if tutorial else .24, .87, .44 if tutorial else .52))
	var paper := Panel.new()
	paper.add_theme_stylebox_override("panel", UIKit.flat_box(Palette.CREAM, Palette.WOOD_LIGHT, 0, 4, 38))
	JourneyArt.place(frame, paper, Rect2(.018, .015, .964, .97))
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 36)
	paper.add_child(margin)
	var stack := UIKit.vbox(22)
	stack.alignment = BoxContainer.ALIGNMENT_CENTER
	margin.add_child(stack)
	if SaveManager.get_setting("language", "en") == "en":
		var heading := TitleArt.create("paused", "Paused")
		heading.custom_minimum_size.y = 132
		heading.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		stack.add_child(heading)
	else:
		stack.add_child(UIKit.title("Rehat Sebentar", 68))
	var subtitle := UIKit.label(stage_title, 34, Palette.WOOD_DARK)
	subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	subtitle.custom_minimum_size.y = 72
	subtitle.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	stack.add_child(subtitle)
	_button(stack, JourneyArt.localized("Teruskan", "Resume"), "button_green", resume_pressed)
	var restart := _button(stack, JourneyArt.localized("Mula Semula", "Restart"), "button_pink", restart_pressed)
	restart.disabled = not restart_available
	if not tutorial:
		var extra := _button(stack, JourneyArt.localized("+5 Langkah (%d)", "+5 Moves (%d)") % extra_count, "button_green", extra_moves_pressed)
		extra.disabled = not extra_available
	_button(stack, JourneyArt.localized("Kembali ke Gerai", "Back to Stall"), "button_orange", quit_pressed)

func _button(stack: VBoxContainer, caption: String, art: String, action: Signal) -> Button:
	var button := GameButton.create(caption, "back" if art == "button_orange" else "primary" if art == "button_green" else "secondary", 44)
	button.custom_minimum_size = Vector2(0, 132)
	button.add_theme_color_override("font_color", Palette.PAPER)
	button.add_theme_color_override("font_outline_color", Palette.LEAF_DEEP if art == "button_green" else Palette.PINK_DARK)
	button.add_theme_constant_override("outline_size", 3)
	button.add_theme_stylebox_override("focus", UIKit.flat_box(Color.TRANSPARENT, Palette.GOLD, 0, 4, 36))
	button.pressed.connect(func() -> void: action.emit())
	stack.add_child(button)
	return button
