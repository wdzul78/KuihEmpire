extends Node

func _ready() -> void:
	SaveManager.data["kuih_seen"] = []
	var host := Control.new()
	host.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(host)
	var backdrop := GeraiBackdrop.new()
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	host.add_child(backdrop)
	KuihIntroduction.present(host, KuihLibrary.all().slice(0,2), func() -> void: print("Acknowledged both kuih"))
	await get_tree().create_timer(.3).timeout
	if DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("res://.shots/kuih_introduction.png")
	for i in 2:
		var overlay := host.get_node("KuihIntroductionOverlay")
		overlay.get_node("KuihIntroductionCard/AcknowledgeKuihButton").pressed.emit()
		await get_tree().process_frame
	assert(SaveManager.data["kuih_seen"].size() == 2)
	print("Kuih introduction: PASS (two cards, acknowledge, saved discovery)")
	get_tree().quit()
