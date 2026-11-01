class_name OnboardingFinish
extends Control

var _page := 0
var _chest: WelcomeChest

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	UIKit.apply_root_theme(self)
	_page = 1 if OnboardingProgress.state().gift_claimed else 0
	_build()

## Chapter title on the carved name plate, overlapping the window's top edge.
func _banner(ms: String, en: String) -> void:
	var banner := Panel.new()
	banner.name = "WelcomeBanner"
	banner.add_theme_stylebox_override("panel",GeraiSkin.box("name_plate",.72))
	JourneyArt.place(self,banner,Rect2(.07,.115,.86,.085))
	var title := JourneyArt.label(banner,JourneyArt.localized(ms,en),Rect2(.15,.12,.70,.74),46,Palette.PAPER)
	title.add_theme_color_override("font_outline_color",Palette.WOOD_DARK)
	title.add_theme_constant_override("outline_size",10)

func _label(ms: String, en: String, rect: Rect2, font_size: int = 38) -> Label:
	var label := JourneyArt.label(self,JourneyArt.localized(ms,en),rect,font_size)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return label

func _button(ms: String, en: String, rect: Rect2, action: Callable, style: String = "primary") -> Button:
	var button := GameButton.create(JourneyArt.localized(ms,en),style,42)
	button.name = en.split(" • ")[0].validate_node_name().to_pascal_case()+"Button"
	button.custom_minimum_size = Vector2.ZERO
	JourneyArt.place(self,button,rect)
	button.pressed.connect(action)
	return button

func _build() -> void:
	for child in get_children():
		remove_child(child)
		child.queue_free()
	var background := GeraiBackdrop.new()
	background.name = "StallBackground"
	JourneyArt.place(self,background,Rect2(0,0,1,1))
	var veil := ColorRect.new()
	veil.color = Color(0,0,0,.3)
	JourneyArt.place(self,veil,Rect2(0,0,1,1))
	var panel := Panel.new()
	panel.name = "WelcomeCard"
	panel.add_theme_stylebox_override("panel",GeraiSkin.box("list_panel",.72))
	JourneyArt.place(self,panel,Rect2(.04,.10,.92,.79))
	match _page:
		0:
			_banner("Hadiah untuk anda!","A gift for you!")
			_chest = WelcomeChest.new()
			_chest.name = "RewardChest"
			JourneyArt.place(self,_chest,Rect2(.18,.23,.64,.30))
			_label("Tutorial selesai. Buka hadiah untuk memulakan perjalanan!","Tutorial complete. Open your gift to begin your journey!",Rect2(.13,.55,.74,.11))
			_button("Buka hadiah","Open gift",Rect2(.15,.70,.70,.07),_open_gift)
		1:
			_banner("Gerai keluarga kita","Our family stall")
			_label("+500 coins • Free play 1 jam","+500 coins • 1 hour free play",Rect2(.12,.21,.76,.05),38)
			var preview := GeraiBackdrop.new()
			preview.name = "StarterStallPreview"
			preview.clip_contents = true
			JourneyArt.place(self,preview,Rect2(.12,.27,.76,.23))
			var preview_frame := Panel.new()
			var preview_border := StyleBoxFlat.new()
			preview_border.draw_center = false
			preview_border.set_border_width_all(8)
			preview_border.border_color = Palette.GOLD
			preview_frame.add_theme_stylebox_override("panel",preview_border)
			JourneyArt.place(self,preview_frame,Rect2(.12,.27,.76,.23))
			_label("Gunakan bintang untuk membaiki gerai lama. Upgrade besar dibuka selepas Stage 10, 20 dan 30.","Use stars to restore the old stall. Bigger upgrades unlock after Stages 10, 20 and 30.",Rect2(.12,.51,.76,.12),36)
			if OnboardingProgress.restored():
				_button("Gerai dah cantik! Seterusnya","Stall restored! Next",Rect2(.15,.67,.7,.07),_next_page)
			else:
				var restore := _button("Baiki gerai • 1 star","Restore stall • 1 star",Rect2(.15,.64,.7,.07),func() -> void:
					if OnboardingProgress.restore_stall():
						_build()
				)
				restore.disabled = not EconomyManager.can_afford_stars(OnboardingProgress.RESTORE_COST)
				_button("Nanti dahulu","Maybe later",Rect2(.22,.72,.56,.055),_next_page,"secondary")
		2:
			_banner("Hias ikut citarasa anda","Make it your own")
			_label("Bunga, lampu dan kain batik boleh dibeli dengan bintang di Shop → Decor. Beli, pakai atau tukar aksesori bila-bila masa.","Buy flowers, lamps and batik cloth with stars in Shop → Decor. Buy, equip or change accessories anytime.",Rect2(.12,.215,.76,.17),36)
			for i in 3:
				var art := TextureRect.new()
				art.texture = load("res://assets/stalls/accessories_v3/hibiscus_counter.png") if i == 2 else StallComponentArt.texture(["lamp","cloth"][i])
				art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
				art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
				JourneyArt.place(self,art,Rect2(.14+i*.25,.39,.22,.15))
			_label("Stage 1 bermula dengan 3×3. Board membesar sepanjang 10 stage pertama.","Stage 1 starts at 3×3. The board grows over the first 10 stages.",Rect2(.12,.55,.76,.11),36)
			_button("Ke Journey • Stage 1","Journey • Stage 1",Rect2(.15,.70,.70,.07),_finish)

func _open_gift() -> void:
	for child in get_children():
		if child is Button:
			child.disabled = true
	OnboardingProgress.claim_gift()
	AudioManager.play(AudioManager.Sfx.REWARD)
	var tween := create_tween()
	tween.tween_property(_chest,"opening",1.0,.7).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	await tween.finished
	for child in get_children():
		if child is Button or (child is Label and child.anchor_top > .5):
			child.visible = false
	_label("+500 coins\nFree play • 1 jam","+500 coins\nFree play • 1 hour",Rect2(.13,.54,.74,.13),42)
	_button("Terima hadiah","Collect rewards",Rect2(.15,.70,.70,.07),_next_page)

func _next_page() -> void:
	_page += 1
	_build()

func _finish() -> void:
	OnboardingProgress.finish_intro()
	GameManager.pending_level_id = ProgressionManager.current_level()
	GameManager.pending_tutorial_index = 0
	SceneManager.goto(SceneManager.JOURNEY)
