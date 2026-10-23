class_name JourneyMilestonePopup
extends Control

signal dismissed

func show_milestone(stage: int) -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	z_index = 100
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, .68)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(dim)
	var card := PanelContainer.new()
	card.add_theme_stylebox_override("panel", UIKit.cream_box())
	JourneyArt.place(self, card, Rect2(.08, .17, .84, .66))
	var stack := UIKit.vbox(24)
	card.add_child(stack)
	stack.add_child(UIKit.title(JourneyArt.localized("Gerai Keluarga", "Family Stall"), 46))
	stack.add_child(UIKit.title(JourneyLibrary.name_for(stage), 34))
	var preview := GeraiBackdrop.new()
	preview.follow_active_stall = true
	preview.background_context = "journey"
	preview.custom_minimum_size = Vector2(0, 310)
	preview.clip_contents = true
	stack.add_child(preview)
	var snapshot := LocationManager.stall_snapshot()
	stack.add_child(UIKit.label(StallDefinition.find(snapshot.id).state(snapshot.state_index).display_name, 30))
	var renovate := GameButton.create(JourneyArt.localized("RENOVASI GERAI", "RENOVATE STALL"), "primary", 32)
	renovate.custom_minimum_size.y = 100
	stack.add_child(renovate)
	renovate.pressed.connect(func() -> void:
		ProgressionManager.mark_story_seen(StringName("milestone_scene_%d" % stage))
		SceneManager.goto(SceneManager.GERAI)
		queue_free()
	)
	stack.add_child(UIKit.wrap_label(JourneyLibrary.completion_text(stage), 30))
	stack.add_child(UIKit.wrap_label(JourneyArt.localized("Ganjaran milestone: resipi dan 30 minit Free Play. Upgrade gerai kini boleh dibeli dalam My Stalls.", "Milestone rewards: a recipe and 30 minutes of Free Play. A stall upgrade is now available in My Stalls."), 26))
	var next := UIKit.button(JourneyArt.localized("TERUSKAN JOURNEY", "CONTINUE JOURNEY"), 32, Palette.LEAF)
	next.custom_minimum_size = Vector2(0, 110)
	stack.add_child(next)
	next.pressed.connect(func() -> void:
		ProgressionManager.mark_story_seen(StringName("milestone_scene_%d" % stage))
		var beat := LevelLibrary.get_level(stage).story_after
		if beat != &"":
			ProgressionManager.mark_story_seen(beat)
		dismissed.emit()
		queue_free()
	)
