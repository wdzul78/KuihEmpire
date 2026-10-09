class_name GameUILayout
extends RefCounted

## Editor scenes are the source of truth for gameplay anchors, offsets and text sizes.
const TUTORIAL = preload("res://scenes/layout/tutorial_gameplay_layout.tscn")
const CAMPAIGN = preload("res://scenes/layout/campaign_gameplay_layout.tscn")

static func copy_control(source: Control, target: Control) -> void:
	target.anchor_left = source.anchor_left
	target.anchor_top = source.anchor_top
	target.anchor_right = source.anchor_right
	target.anchor_bottom = source.anchor_bottom
	target.offset_left = source.offset_left
	target.offset_top = source.offset_top
	target.offset_right = source.offset_right
	target.offset_bottom = source.offset_bottom
	if target is Label and source.has_theme_font_size_override("font_size"):
		target.add_theme_font_size_override("font_size", source.get_theme_font_size("font_size"))

static func apply_hud(hud: Control, scene: PackedScene) -> void:
	var guide := scene.instantiate()
	for key in ["Logo", "HeartMeter", "ScoreMeter", "PauseButton", "StageTitleFrame", "StageTitle", "MovesPanel", "LessonBadge", "CustomerQueue", "OrderArea", "PuzzleBoard", "SpecialItemsTray"]:
		var target := hud.get_node_or_null(NodePath(key)) as Control
		var source := guide.get_node_or_null(NodePath(key)) as Control
		if source != null and target != null:
			copy_control(source, target)
	for key in ["MovesPanel/MovesValue", "MovesPanel/MovesCaption", "ScoreMeter/ScoreValue"]:
		copy_control(guide.get_node(key), hud.get_node(key))
	hud.score_progress.number_font_size = guide.get_node("ScoreMeter/ScoreValue").get_theme_font_size("font_size")
	guide.free()

static func apply_order(panel: Control, scene: PackedScene) -> void:
	var guide := scene.instantiate()
	for key in ["CustomerCharacter", "AinaCharacter", "DialogueBubble", "OrderBoard", "OrderBoard/OrderTitle", "OrderBoard/KuihItems"]:
		copy_control(guide.get_node("OrderArea/" + key), panel.get_node(key))
	for pair in [["SpeakerName", "DialogueBubble/DialogueContents/SpeakerName"], ["InstructionText", "DialogueBubble/DialogueContents/InstructionText"]]:
		var source := guide.get_node("OrderArea/DialogueBubble/" + pair[0]) as Label
		var target := panel.get_node(pair[1]) as Label
		copy_control(source, target)
		target.custom_minimum_size = Vector2.ZERO
		(panel.get_node("DialogueBubble") as SpeechBubble).configure_text_fit(target, source.get_theme_font_size("font_size"))
	guide.free()
