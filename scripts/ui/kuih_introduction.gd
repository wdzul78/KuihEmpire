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
	var veil := ColorRect.new()
	veil.name = "ModalDimmer"
	veil.color = Color(0,0,0,.65)
	JourneyArt.place(self,veil,Rect2(0,0,1,1))
	var card := Panel.new()
	card.name = "KuihIntroductionCard"
	card.add_theme_stylebox_override("panel",UIKit.cream_box())
	JourneyArt.place(self,card,Rect2(.08,.22,.84,.54))
	JourneyArt.label(self,JourneyArt.localized("Kenali kuih kita", "Meet our kuih"),Rect2(.13,.25,.74,.05),38)
	var icon := KuihIcon.new()
	icon.name = "KuihPortrait"
	icon.kuih = item
	JourneyArt.place(self,icon,Rect2(.34,.32,.32,.19))
	JourneyArt.label(self,item.display_name,Rect2(.13,.53,.74,.05),40)
	var note: Array = NOTES.get(String(item.id),[item.note,item.note])
	var caption := JourneyArt.label(self,JourneyArt.localized(note[0],note[1]),Rect2(.15,.59,.70,.08),28)
	caption.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var button := GameButton.create(JourneyArt.localized("Kenal!", "Got it!"),"primary",32)
	button.name = "AcknowledgeKuihButton"
	button.custom_minimum_size = Vector2.ZERO
	JourneyArt.place(self,button,Rect2(.22,.69,.56,.055))
	button.pressed.connect(func() -> void:
		if not String(item.id) in SaveManager.data.kuih_seen:
			SaveManager.data.kuih_seen.append(String(item.id))
			SaveManager.mark_dirty()
		_show_items(items,index+1,done)
	)
