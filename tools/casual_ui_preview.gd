extends Control

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var background := ColorRect.new()
	background.color = Color("fff4db")
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(background)
	var column := UIKit.vbox(20)
	JourneyArt.place(self,column,Rect2(.07,.035,.86,.93))
	var banner := TextureRect.new()
	banner.texture = CasualUIArt.texture("banner")
	banner.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	banner.stretch_mode = TextureRect.STRETCH_SCALE
	banner.custom_minimum_size.y = 400
	column.add_child(banner)
	var heading := UIKit.title("Kuih Empire",58)
	heading.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	heading.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	banner.add_child(heading)
	column.add_child(UIKit.label("UI jelas · Aset boleh guna semula",32))
	for caption in ["Stage 30 · Aina", "Score 9,986    Moves 32", "Gold 1,000    Nyawa 5", "Resipi tradisi, keseronokan tanpa henti."]:
		column.add_child(UIKit.label(caption,38))
	column.add_child(CasualUIArt.button("Teruskan", "green"))
	column.add_child(CasualUIArt.button("Mula Semula", "pink"))
	column.add_child(CasualUIArt.button("Kembali ke Gerai", "orange"))
	for id in CasualUIArt.REGIONS:
		assert(CasualUIArt.texture(id).get_width() > 0)
	assert(UIKit.bold_font().has_char("A".unicode_at(0)))
	await get_tree().process_frame
	await get_tree().process_frame
	if DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("res://.shots/casual_ui_preview.png")
	print("Casual UI: PASS (6 reusable atlas assets, live Fredoka text)")
	get_tree().quit()
