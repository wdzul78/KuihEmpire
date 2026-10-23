class_name KuihIntroduction
extends Control

const NOTES := {
	"onde_onde": ["Bebola hijau bersalut kelapa parut.", "Green rice balls coated in coconut."],
	"kuih_koci": ["Kuih putih lembut di atas daun pisang.", "Soft white kuih served on banana leaf."],
	"ang_ku_kueh": ["Kuih merah dengan corak tempurung kura-kura.", "Red kuih with a tortoise-shell pattern."],
	"kuih_ketayap": ["Gulungan pandan berinti kelapa manis.", "A pandan roll with sweet coconut filling."],
	"kuih_lapis": ["Kuih berlapis merah jambu dan putih krim.", "A pink and cream layered kuih."],
	"keria": ["Kuih berbentuk cincin dengan salutan gula.", "A ring-shaped kuih with a sugar coating."],
}

static func unseen(kuih: Array[KuihData]) -> Array[KuihData]:
	var result: Array[KuihData] = []
	for item in kuih:
		if not String(item.id) in SaveManager.data.kuih_seen:
			result.append(item)
	return result

static func present(host: Control, kuih: Array[KuihData], done: Callable) -> void:
	var overlay := KuihIntroduction.new()
	overlay.name = "KuihIntroductionOverlay"
	host.add_child(overlay)
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.z_index = 100
	overlay._show_items(unseen(kuih),0,done)

func _show_items(items: Array[KuihData], index: int, done: Callable) -> void:
	for child in get_children():
		remove_child(child)
		child.queue_free()
	if index >= items.size():
		queue_free()
		done.call()
		return
	var item := items[index]
	ProgressionManager.unlock_recipe(item.recipe_id)
	var veil := ColorRect.new()
	veil.name = "ModalDimmer"
	veil.color = Color(0,0,0,.65)
	JourneyArt.place(self,veil,Rect2(0,0,1,1))
	var card := Panel.new()
	card.name = "KuihIntroductionCard"
	var frame := StyleBoxTexture.new()
	frame.texture = load("res://assets/ui/introduction_v2/window.png")
	card.add_theme_stylebox_override("panel", frame)
	JourneyArt.place(self,card,Rect2(.035,.14,.93,.74))
	var heading := JourneyArt.label(card,JourneyArt.localized("Kenali kuih kita", "Meet our kuih"),Rect2(.16,.055,.68,.085),56,Color("fffbe9"))
	heading.add_theme_color_override("font_outline_color",Color("54250f"))
	heading.add_theme_constant_override("outline_size",3)
	var icon := KuihIcon.new()
	icon.name = "KuihPortrait"
	icon.kuih = item
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	JourneyArt.place(card,icon,Rect2(.235,.20,.53,.30))
	var title := JourneyArt.label(card,item.display_name,Rect2(.07,.505,.86,.09),66,Color("54250f"))
	title.add_theme_font_override("font",UIKit.bold_font())
	title.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	var note: Array = NOTES.get(String(item.id),[item.note,item.note])
	var caption := JourneyArt.label(card,JourneyArt.localized(note[0],note[1]),Rect2(.10,.605,.80,.12),44,Color("744524"))
	caption.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	caption.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	JourneyArt.label(card,JourneyArt.localized("Boleh dilihat semula dalam Koleksi Kuih", "View again in Kuih Collection"),Rect2(.10,.74,.80,.07),32,Color("426728"))
	var button := GameButton.create(JourneyArt.localized("Kenal!", "Got it!"),"primary",52)
	button.name = "AcknowledgeKuihButton"
	button.custom_minimum_size = Vector2.ZERO
	JourneyArt.place(card,button,Rect2(.17,.825,.66,.10))
	JourneyArt.label(card,"%d / %d" % [index+1,items.size()],Rect2(.40,.165,.20,.03),28,Color("744524"))
	card.modulate.a = 0
	var reveal := card.create_tween()
	reveal.tween_property(card,"modulate:a",1.0,.18)
	button.pressed.connect(func() -> void:
		if button.disabled:
			return
		button.disabled = true
		if not String(item.id) in SaveManager.data.kuih_seen:
			SaveManager.data.kuih_seen.append(String(item.id))
			SaveManager.mark_dirty()
		_show_items(items,index+1,done)
	)
