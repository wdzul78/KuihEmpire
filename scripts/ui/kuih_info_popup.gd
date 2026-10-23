class_name KuihInfoPopup
extends Control

var kuih: KuihData
var special_kind := -1
var special_name := ""
var special_note := ""

func _ready() -> void:
	name = "KuihInfoPopup"
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	z_index = 400
	mouse_filter = Control.MOUSE_FILTER_STOP
	var shade := ColorRect.new()
	shade.color = Color(0,0,0,.90)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(shade)
	var panel := PanelContainer.new()
	panel.name = "InfoPanel"
	var frame := StyleBoxTexture.new()
	frame.texture = preload("res://assets/ui/introduction_v2/window.png")
	panel.add_theme_stylebox_override("panel",frame)
	JourneyArt.place(self,panel,Rect2(.035,.12,.93,.78))
	var update_margins := func() -> void:
		frame.content_margin_top = panel.size.y*.18
		frame.content_margin_bottom = panel.size.y*.065
		frame.content_margin_left = panel.size.x*.08
		frame.content_margin_right = panel.size.x*.08
	panel.resized.connect(update_margins)
	update_margins.call()
	var heading := JourneyArt.label(self,JourneyArt.localized("Kenali kuih kita","Meet our kuih"),Rect2(.17,.16,.66,.066),54,Color("fffbe9"))
	heading.add_theme_color_override("font_outline_color",Color("54250f"))
	heading.add_theme_constant_override("outline_size",3)
	var margin := UIKit.margin(30)
	panel.add_child(margin)
	var column := UIKit.vbox(14)
	margin.add_child(column)
	var icon := KuihIcon.new()
	icon.kuih = kuih
	if special_kind >= 0:
		icon.special_kind = special_kind
	icon.custom_minimum_size = Vector2(310,310)
	icon.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	column.add_child(icon)
	column.add_child(UIKit.wrap_label(special_name if special_kind >= 0 else KuihLibrary.get_display_name(kuih.id),54,Palette.WOOD_DARK))
	column.add_child(UIKit.label("Special" if special_kind >= 0 else JourneyArt.localized("Kuih tradisional","Traditional kuih"),26,Palette.WOOD_DARK))
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	column.add_child(scroll)
	var content := UIKit.vbox(20)
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(content)
	var note := special_note if special_kind >= 0 else kuih.note
	if special_kind == BoardCell.Special.TAPAU_VERTICAL:
		note = JourneyArt.localized("Daun Selorot terlerai untuk membersihkan satu lajur penuh.","Selorot unwraps its leaf to clear one full column.")
	elif special_kind == PowerupRecipes.PISANG_COMBO:
		note = JourneyArt.localized("Gabungkan Badak Berendam + Kuih Selorot. Pisang Goreng rangup membersihkan tiga lajur bersebelahan.","Combine Badak Berendam + Kuih Selorot. Crispy banana fritters clear three neighbouring columns.")
	if special_kind < 0 and kuih.id == &"onde_onde" and SaveManager.get_setting("language","en") == "ms":
		note = "Bebola pulut pandan berinti gula Melaka, disalut kelapa parut."
	content.add_child(UIKit.wrap_label(note,36,Palette.WOOD_DARK))
	if special_kind < 0 and kuih.id == &"onde_onde":
		content.add_child(UIKit.label(JourneyArt.localized("Bahan utama","Main ingredients"),32,Palette.WOOD_DARK))
		content.add_child(UIKit.wrap_label(JourneyArt.localized("Tepung pulut · Pandan · Gula Melaka · Kelapa","Glutinous rice flour · Pandan · Palm sugar · Coconut"),28,Palette.WOOD_DARK))
	content.add_child(UIKit.label(JourneyArt.localized("Dalam permainan","In the game"),32,Palette.WOOD_DARK))
	content.add_child(UIKit.wrap_label(JourneyArt.localized("Swap atau double tap untuk aktifkan. Gabungkan dengan special lain untuk kesan lebih besar.","Swap or double tap to activate. Combine with other specials for stronger effects.") if special_kind >= 0 else JourneyArt.localized("Padankan 3 atau lebih untuk mengumpul kuih ini.","Match 3 or more to collect this kuih."),28,Palette.WOOD_DARK))
	var close := GameButton.create(JourneyArt.localized("Tutup","Close"),"primary",44)
	close.custom_minimum_size = Vector2(0,100)
	column.add_child(close)
	close.pressed.connect(_close)
	var cross := GameButton.create("×","back",38)
	cross.custom_minimum_size = Vector2.ZERO
	JourneyArt.place(self,cross,Rect2(.855,.137,.09,.05))
	cross.pressed.connect(_close)
	close.focus_mode = Control.FOCUS_ALL
	close.grab_focus()

func _close() -> void:
	AudioManager.play(AudioManager.Sfx.TAP)
	get_parent().remove_child(self)
	queue_free()

func _unhandled_key_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		_close()
