extends Control

func _ready() -> void:
	var font := UIKit.title_font()
	assert(font != null)
	for character in "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789":
		var code := character.unicode_at(0)
		assert(font.has_char(code))
		assert(font.get_char_size(code,32).x > 0)
	assert(font.has_char(8734))
	var bg := ColorRect.new()
	bg.color = Color("3f485c")
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	var lines := ["ABCDEFGHIJKLMNOPQRSTUVWXYZ", "abcdefghijklmnopqrstuvwxyz", "0123456789 + - ! ?", "Main Kedai Cerita Tetapan", "Tahap 12 · Score 3,930 · ∞", "Resipi tradisi, keseronokan tanpa henti."]
	for index in lines.size():
		var label := UIKit.label(lines[index],32 if index < 3 else 38)
		label.position = Vector2(15,45+index*80)
		label.size = Vector2(1050,70)
		add_child(label)
	await get_tree().process_frame
	await get_tree().process_frame
	if DisplayServer.get_name() != "headless":
		get_viewport().get_texture().get_image().save_png("res://.shots/candy_font.png")
	print("UI font: PASS (A-Z, a-z, digits, dynamic text and Unicode fallback)")
	get_tree().quit()
