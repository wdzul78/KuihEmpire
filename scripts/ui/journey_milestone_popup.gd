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
	var dialog := GeraiSkin.dialog(JourneyArt.localized("Gerai Keluarga", "Family Stall"))
	var card: PanelContainer = dialog.panel
	JourneyArt.place(self, card, Rect2(.025, .10, .95, .80))
	var stack: VBoxContainer = dialog.stack
	stack.add_theme_constant_override("separation", 18)
	stack.add_child(UIKit.title(JourneyLibrary.name_for(stage), 50))
	var preview := GeraiBackdrop.new()
	preview.follow_active_stall = true
	preview.background_context = "journey"
	preview.custom_minimum_size = Vector2(0, 420)
	preview.clip_contents = true
	stack.add_child(preview)
	var snapshot := LocationManager.stall_snapshot()
	stack.add_child(UIKit.label(StallDefinition.find(snapshot.id).state(snapshot.state_index).display_name, 38))
	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var renovate := GameButton.create(JourneyArt.localized("RENOVASI GERAI", "RENOVATE STALL"), "primary", 40)
	renovate.custom_minimum_size.y = 110
	stack.add_child(renovate)
	renovate.pressed.connect(func() -> void:
		ProgressionManager.mark_story_seen(StringName("milestone_scene_%d" % stage))
		SceneManager.goto(SceneManager.GERAI)
		queue_free()
	)
	stack.add_child(UIKit.wrap_label(JourneyLibrary.completion_text(stage), 38))
	stack.add_child(UIKit.wrap_label(JourneyArt.localized("Ganjaran milestone: resipi dan 30 minit Free Play. Upgrade gerai kini boleh dibeli dalam My Stalls.", "Milestone rewards: a recipe and 30 minutes of Free Play. A stall upgrade is now available in My Stalls."), 34))
	stack.add_child(spacer)
	var next := GameButton.create(JourneyArt.localized("TERUSKAN JOURNEY", "CONTINUE JOURNEY"), "secondary", 40)
	next.custom_minimum_size.y = 110
	stack.add_child(next)
	next.pressed.connect(func() -> void:
		ProgressionManager.mark_story_seen(StringName("milestone_scene_%d" % stage))
		var beat := LevelLibrary.get_level(stage).story_after
		if beat != &"":
			ProgressionManager.mark_story_seen(beat)
		dismissed.emit()
		queue_free()
	)
