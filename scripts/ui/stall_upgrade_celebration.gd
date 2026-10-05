class_name StallUpgradeCelebration
extends RefCounted

static func show_upgrade(parent: Control, id: StringName, state: int) -> void:
	if not is_instance_valid(parent) or not parent.is_inside_tree():
		return
	var overlay := Control.new()
	overlay.name = "StallUpgradeCelebration"
	overlay.z_index = 250
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	parent.add_child(overlay)
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, .65)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(dim)
	var panel := Panel.new()
	panel.add_theme_stylebox_override("panel", UIKit.cream_box())
	JourneyArt.place(overlay, panel, Rect2(.065,.21,.87,.58))
	JourneyArt.label(panel,"STALL UPGRADED!",Rect2(.05,.025,.9,.09),48)
	var location := LocationDefinition.find(id)
	JourneyArt.label(panel,location.state_name(state),Rect2(.05,.115,.9,.07),34)
	for i in 2:
		var image := GeraiBackdrop.new()
		JourneyArt.place(panel,image,Rect2(.07+i*.48,.25,.38,.57))
		image.apply_environment(id,null,maxi(0,state-1) if i == 0 else state)
		JourneyArt.label(panel,"Before" if i == 0 else "After",Rect2(.07+i*.48,.19,.38,.06),30)
	JourneyArt.label(panel,"A sweeter home for every customer.",Rect2(.04,.85,.92,.08),30)
	AudioManager.play(AudioManager.Sfx.REWARD)
	UIKit.sparkle_burst(overlay, parent.size*.5, Palette.GOLD_PALE, 18)
	var tween := overlay.create_tween()
	tween.tween_interval(2.4)
	tween.tween_property(overlay,"modulate:a",0.0,.3)
	tween.tween_callback(overlay.queue_free)
