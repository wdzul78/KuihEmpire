class_name OnboardingFinish
extends Control

var _page := 0
var _chest: WelcomeChest

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	UIKit.apply_root_theme(self)
	_page = 1 if OnboardingProgress.state().gift_claimed else 0
	_build()

func _label(ms: String, en: String, rect: Rect2, font_size: int = 32) -> Label:
	var label := JourneyArt.label(self,JourneyArt.localized(ms,en),rect,font_size)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return label

func _button(ms: String, en: String, rect: Rect2, action: Callable, style: String = "primary") -> Button:
	var button := GameButton.create(JourneyArt.localized(ms,en),style,30)
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
	panel.add_theme_stylebox_override("panel",UIKit.cream_box())
	JourneyArt.place(self,panel,Rect2(.06,.14,.88,.71))
	match _page:
		0:
			_label("Hadiah untuk anda!","A gift for you!",Rect2(.1,.18,.8,.08),44)
			_chest = WelcomeChest.new()
			_chest.name = "RewardChest"
			JourneyArt.place(self,_chest,Rect2(.18,.28,.64,.29))
			_label("Tutorial selesai. Buka hadiah untuk memulakan perjalanan!","Tutorial complete. Open your gift to begin your journey!",Rect2(.14,.59,.72,.1))
			_button("Buka hadiah","Open gift",Rect2(.16,.74,.68,.065),_open_gift)
		1:
			_label("Gerai keluarga kita","Our family stall",Rect2(.1,.17,.8,.065),40)
			_label("+500 coins • Free play 1 jam","+500 coins • 1 hour free play",Rect2(.12,.25,.76,.06),30)
			var preview := GeraiBackdrop.new()
			preview.name = "StarterStallPreview"
			preview.clip_contents = true
			JourneyArt.place(self,preview,Rect2(.30,.33,.40,.24))
			_label("Gunakan coins untuk membaiki gerai lama. Upgrade besar dibuka selepas Stage 10, 20 dan 30.","Use coins to restore the old stall. Bigger upgrades unlock after Stages 10, 20 and 30.",Rect2(.13,.59,.74,.10),28)
			if OnboardingProgress.restored():
				_button("Gerai dah cantik! Seterusnya","Stall restored! Next",Rect2(.15,.72,.7,.06),_next_page)
			else:
				var restore := _button("Baiki gerai • 300 coins","Restore stall • 300 coins",Rect2(.15,.71,.7,.06),func() -> void:
					if OnboardingProgress.restore_stall():
						_build()
				)
				restore.disabled = not EconomyManager.can_afford(OnboardingProgress.RESTORE_COST)
				_button("Nanti dahulu","Maybe later",Rect2(.23,.78,.54,.045),_next_page,"secondary")
		2:
			_label("Hias ikut citarasa anda","Make it your own",Rect2(.1,.18,.8,.07),40)
			_label("Bunga, lampu dan kain batik boleh dibeli dengan coins di Shop → Decor. Beli, pakai atau tukar aksesori bila-bila masa.","Buy flowers, lamps and batik cloth with coins in Shop → Decor. Buy, equip or change accessories anytime.",Rect2(.14,.30,.72,.16),30)
			var flower := Control.new()
			JourneyArt.place(self,flower,Rect2(.65,.49,.21,.15))
			flower.draw.connect(func() -> void:
				var at := Vector2(flower.size.x*.5,flower.size.y*.42)
				var radius := flower.size.x*.17
				flower.draw_line(at,at+Vector2(0,flower.size.y*.3),Palette.LEAF,7,true)
				for petal in 5:
					flower.draw_circle(at+Vector2.from_angle(petal*TAU/5)*radius*.7,radius*.65,Palette.PINK)
				flower.draw_circle(at,radius*.35,Palette.GOLD)
				flower.draw_style_box(UIKit.wood_box(Palette.WOOD_LIGHT),Rect2(flower.size.x*.2,flower.size.y*.68,flower.size.x*.6,flower.size.y*.22))
			)
			for i in 2:
				var art := TextureRect.new()
				art.texture = StallComponentArt.texture(["lamp","cloth","shelf"][i])
				art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
				art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
				JourneyArt.place(self,art,Rect2(.15+i*.24,.49,.21,.15))
			_label("Stage 1 bermula dengan 3×3. Board membesar sepanjang 10 stage pertama.","Stage 1 starts at 3×3. The board grows over the first 10 stages.",Rect2(.14,.65,.72,.08),27)
			_button("Ke Journey • Stage 1","Journey • Stage 1",Rect2(.15,.76,.70,.065),_finish)

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
	_label("+500 coins\nFree play • 1 jam","+500 coins\nFree play • 1 hour",Rect2(.14,.55,.72,.15),36)
	_button("Terima hadiah","Collect rewards",Rect2(.16,.74,.68,.065),_next_page)

func _next_page() -> void:
	_page += 1
	_build()

func _finish() -> void:
	OnboardingProgress.finish_intro()
	GameManager.pending_level_id = ProgressionManager.current_level()
	GameManager.pending_tutorial_index = 0
	SceneManager.goto(SceneManager.JOURNEY)
