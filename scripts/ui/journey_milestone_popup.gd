class_name JourneyMilestonePopup
extends Control

signal dismissed

## Painted "before" picture, shown until the location's first upgrade is bought.
const BEFORE_ART := {
	&"school_canteen": "res://assets/ui/milestone_v1/school_canteen.png",
}

func show_milestone(stage: int) -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	z_index = 100
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, .68)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(dim)
	var location := LocationDefinition.for_stage(stage)
	var next := LocationDefinition.for_stage(stage + 1)
	var opens_next := LevelLibrary.is_chapter_finale(stage) and next.id != location.id and LocationManager.accessible(next.id)
	var dialog := GeraiSkin.dialog(JourneyLibrary.location_name(location.id))
	var card: PanelContainer = dialog.panel
	JourneyArt.place(self, card, Rect2(.025, .10, .95, .80))
	var stack: VBoxContainer = dialog.stack
	stack.add_theme_constant_override("separation", 18)
	stack.add_child(UIKit.title(JourneyLibrary.name_for(stage), 50))
	var snapshot := LocationManager.stall_snapshot(location.id)
	var preview: Control
	if snapshot.state_index == 0 and BEFORE_ART.has(location.id):
		var art := TextureRect.new()
		art.name = "MilestoneBeforeArt"
		art.texture = load(BEFORE_ART[location.id])
		art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		preview = art
	else:
		var backdrop := GeraiBackdrop.new()
		backdrop.location_id = location.id
		backdrop.background_context = "journey"
		preview = backdrop
	preview.custom_minimum_size = Vector2(0, 280 if opens_next else 420)
	preview.clip_contents = true
	stack.add_child(preview)
	stack.add_child(UIKit.label(JourneyLibrary.state_name(StallDefinition.find(snapshot.id).state(snapshot.state_index).display_name), 38))
	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var renovate := GameButton.create(JourneyArt.localized("RENOVASI GERAI", "RENOVATE STALL"), "primary", 40)
	renovate.custom_minimum_size.y = 110
	stack.add_child(renovate)
	renovate.pressed.connect(func() -> void:
		ProgressionManager.mark_story_seen(StringName("milestone_scene_%d" % stage))
		GeraiScreen.requested_location = location.id
		SceneManager.goto(SceneManager.GERAI)
		queue_free()
	)
	stack.add_child(UIKit.wrap_label(JourneyLibrary.completion_text(stage), 38))
	stack.add_child(UIKit.wrap_label(JourneyArt.localized("Ganjaran milestone: resipi dan 30 minit Free Play. Upgrade gerai kini boleh dibeli di skrin Gerai.", "Milestone rewards: a recipe and 30 minutes of Free Play. A stall upgrade is now available in My Stalls."), 34))
	stack.add_child(spacer)
	if opens_next:
		var activate := GameButton.create(JourneyArt.localized("JADIKAN GERAI AKTIF", "MAKE IT MY STALL"), "back", 36)
		activate.name = "ActivateNextStallButton"
		activate.custom_minimum_size.y = 100
		activate.disabled = LocationManager.active_stall_id() == next.id
		activate.pressed.connect(func() -> void:
			LocationManager.set_active_stall(next.id)
			activate.disabled = true
		)
		stack.add_child(activate)
	var caption := JourneyArt.localized("TERUSKAN JOURNEY", "CONTINUE JOURNEY")
	if opens_next:
		caption = JourneyArt.localized("JOM KE ", "ON TO THE ").to_upper() + JourneyLibrary.location_name(next.id).to_upper()
	var proceed := GameButton.create(caption, "secondary", 40)
	proceed.custom_minimum_size.y = 110
	stack.add_child(proceed)
	proceed.pressed.connect(func() -> void:
		ProgressionManager.mark_story_seen(StringName("milestone_scene_%d" % stage))
		var beat := LevelLibrary.get_level(stage).story_after
		if beat != &"":
			ProgressionManager.mark_story_seen(beat)
		dismissed.emit()
		queue_free()
	)
