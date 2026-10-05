class_name AchievementsScreen
extends Control

var _ranking := false
var _filter := "current_story"
var _category := "ALL"
var _content: VBoxContainer
var _status: Label
var _sticky: Label
var _scroll: ScrollContainer
var _options: OptionButton
var _notice: Label
var _sample_toggle: CheckButton

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	UIKit.apply_root_theme(self)
	var backdrop := GeraiBackdrop.new()
	backdrop.background_id = &"stall_dawn"
	backdrop.show_counter = false
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(backdrop)
	var back := GameButton.create("Back", "back", 38)
	back.custom_minimum_size = Vector2.ZERO
	JourneyArt.place(self, back, Rect2(.035, .015, .23, .055))
	back.pressed.connect(func() -> void: SceneManager.goto(SceneManager.HOME))
	var heading := JourneyArt.label(self, "Achievements", Rect2(.28, .015, .68, .055), 52, Palette.PAPER)
	heading.add_theme_color_override("font_outline_color", Palette.WOOD_DARK)
	heading.add_theme_constant_override("outline_size", 8)
	var panel := Panel.new()
	panel.add_theme_stylebox_override("panel", UIKit.cream_box())
	JourneyArt.place(self, panel, Rect2(.025, .085, .95, .89))
	var personal := GameButton.create("Personal", "primary", 38)
	var ranking := GameButton.create("Ranking", "secondary", 38)
	personal.name = "PersonalTab"
	ranking.name = "RankingTab"
	for button in [personal, ranking]:
		button.custom_minimum_size = Vector2.ZERO
	JourneyArt.place(self, personal, Rect2(.065, .108, .42, .060))
	JourneyArt.place(self, ranking, Rect2(.515, .108, .42, .060))
	personal.pressed.connect(func() -> void: _ranking = false; _refresh_options())
	ranking.pressed.connect(func() -> void: _ranking = true; _refresh_options())
	_status = JourneyArt.label(self, "", Rect2(.07, .18, .86, .08), 32, Palette.WOOD_DARK)
	_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_options = OptionButton.new()
	_options.add_theme_font_size_override("font_size", 36)
	JourneyArt.place(self, _options, Rect2(.07, .275, .86, .057))
	_options.item_selected.connect(_option_selected)
	_scroll = ScrollContainer.new()
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	JourneyArt.place(self, _scroll, Rect2(.065, .35, .87, .465))
	_content = UIKit.vbox(24)
	_content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_scroll.add_child(_content)
	_sticky = JourneyArt.label(self, "", Rect2(.07, .832, .86, .095), 32, Palette.WOOD_DARK)
	_sticky.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_notice = JourneyArt.label(self, "", Rect2(.07, .918, .86, .025), 26, Palette.WOOD_DARK)
	if OS.has_feature("debug"):
		var sample := CheckButton.new()
		_sample_toggle = sample
		for style in ["normal", "hover", "pressed", "disabled", "focus"]:
			sample.add_theme_stylebox_override(style, StyleBoxEmpty.new())
		sample.text = "Show sample rankings (development)"
		sample.add_theme_font_size_override("font_size", 30)
		for color in ["font_color", "font_hover_color", "font_pressed_color"]:
			sample.add_theme_color_override(color, Palette.WOOD_DARK)
		JourneyArt.place(self, sample, Rect2(.07, .947, .86, .024))
		sample.toggled.connect(func(enabled: bool) -> void:
			RankingManager.refresh()
			if RankingManager.service is LocalLeaderboardService:
				RankingManager.service.set_samples(enabled)
			refresh()
		)
	AchievementManager.changed.connect(refresh)
	RankingManager.updated.connect(_rankings_ready)
	AchievementManager.refresh()
	_refresh_options()

func _rankings_ready() -> void:
	if _ranking:
		_draw_rankings()

func _refresh_options() -> void:
	if _sample_toggle != null:
		_sample_toggle.visible = _ranking
	_options.clear()
	if _ranking:
		for text in ["Current Story", "All Journey", "Current Milestone", "Friends (coming later)"]:
			_options.add_item(text)
		_options.set_item_disabled(3, true)
		_options.select(["current_story", "all", "current_milestone"].find(_filter))
	else:
		_options.add_item("ALL")
		for definition in AchievementManager.definitions:
			var found := false
			for i in _options.item_count:
				if _options.get_item_text(i) == definition.category:
					found = true
			if not found:
				_options.add_item(definition.category)
		for i in _options.item_count:
			if _options.get_item_text(i) == _category:
				_options.select(i)
	refresh()

func _option_selected(index: int) -> void:
	if _ranking:
		_filter = ["current_story", "all", "current_milestone"][index]
	else:
		_category = _options.get_item_text(index)
	_scroll.scroll_vertical = 0
	refresh()

func _clear() -> void:
	for child in _content.get_children():
		_content.remove_child(child)
		child.queue_free()

func refresh() -> void:
	if _content == null:
		return
	if _ranking:
		RankingManager.refresh()
		_draw_rankings()
		return
	_clear()
	var metrics := AchievementManager.metrics()
	_status.text = "%d / %d achievements completed\n★ %d  ·  Recipes %d  ·  Orders %d  ·  Stories %d" % [AchievementManager.completed_count(), AchievementManager.definitions.size(), metrics["stars"], metrics["recipes"], metrics.get("orders_served", 0), metrics["stories"]]
	_sticky.text = "Celebrate every small step.\nRewards are added automatically once unlocked."
	_notice.text = "Personal accomplishments · saved on this device"
	var groups: Dictionary = {}
	for definition in AchievementManager.definitions:
		if _category != "ALL" and definition.category != _category:
			continue
		if definition.hidden and not AchievementManager.state(definition.id).get("unlocked", false):
			continue
		if not groups.has(definition.category):
			groups[definition.category] = []
		groups[definition.category].append(definition)
	for category in groups:
		var complete := 0
		for definition in groups[category]:
			if AchievementManager.state(definition.id).get("unlocked", false):
				complete += 1
		_content.add_child(UIKit.label("%s  ·  %d / %d" % [category.capitalize(), complete, groups[category].size()], 38, Palette.WOOD_DARK))
		for definition in groups[category]:
			var state := AchievementManager.state(definition.id)
			var unlocked: bool = state.get("unlocked", false)
			var box := _card(unlocked)
			var column := UIKit.vbox(12)
			box.add_child(column)
			column.add_child(_text(("✓  " if unlocked else "★  ") + definition.title, 40))
			column.add_child(_text(definition.description, 32))
			var progress := ProgressBar.new()
			progress.max_value = definition.target
			progress.value = state.get("progress", 0)
			progress.show_percentage = false
			progress.custom_minimum_size.y = 18
			column.add_child(progress)
			column.add_child(_text("%d / %d  ·  %s%d coins%s" % [state.get("progress", 0), definition.target, "+", definition.reward_coins, "  ·  Reward received" if unlocked else ""], 30))
			if not definition.tier.is_empty():
				column.add_child(_text(definition.tier.capitalize(), 28))

func _draw_rankings() -> void:
	if _content == null:
		return
	_clear()
	var rows := RankingManager.service.get_rankings(_filter)
	var own := RankingManager.service.get_player_rank(_filter)
	var samples := false
	for entry in rows:
		samples = samples or entry.is_sample
	_status.text = "Journey Ranking\nJourney → Story → Stage → Stars → Score"
	_notice.text = "SAMPLE DATA · development only" if samples else "Local snapshot · online ranking is not connected"
	if own == null:
		_sticky.text = "Your Journey snapshot is loading…"
		return
	var own_index := rows.find(own)
	# Around-player window, with the full rank retained and a permanent own card.
	var first := maxi(0, own_index - 3)
	var last := mini(rows.size(), first + 10)
	for i in range(first, last):
		var entry := rows[i]
		var is_own := entry.player_id == own.player_id
		var box := _card(is_own)
		var line := HBoxContainer.new()
		line.add_theme_constant_override("separation", 22)
		box.add_child(line)
		var avatar := AvatarLibrary.icon(entry.avatar_id)
		avatar.custom_minimum_size = Vector2(100, 100)
		line.add_child(avatar)
		var column := UIKit.vbox(8)
		column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		line.add_child(column)
		column.add_child(_text("#%d  %s%s" % [entry.rank, entry.nickname, " · YOU" if is_own else ""], 38))
		column.add_child(_text(entry.title, 28))
		column.add_child(_text("Story %d  ·  Stage %d  ·  ★ %d" % [entry.story_index, entry.highest_stage_completed, entry.total_stars], 32))
	_sticky.text = "YOUR RANK  #%d  ·  Story %d / Milestone %d\nStage %d  ·  ★ %d  ·  Best relevant score %d" % [own.rank, own.story_index, own.milestone_index, own.highest_stage_completed, own.total_stars, own.tie_break_score]
	if own_index > 0:
		var next := rows[own_index - 1]
		if next.highest_stage_completed > own.highest_stage_completed:
			_sticky.text += "\n%d more stage(s) to reach the next position." % (next.highest_stage_completed - own.highest_stage_completed)
		elif next.total_stars > own.total_stars:
			_sticky.text += "\n%d more stars to share the next position." % (next.total_stars - own.total_stars)
		elif next.tie_break_score > own.tie_break_score:
			_sticky.text += "\nTry for a new best on Stage %d." % own.highest_stage_completed

func _card(highlight: bool) -> PanelContainer:
	var box := PanelContainer.new()
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_theme_stylebox_override("panel", UIKit.flat_box(Color("f5dfaf") if highlight else Color("fff7e7"), Palette.WOOD_LIGHT, 22, 3, 20))
	_content.add_child(box)
	return box

func _text(value: String, font_size: int) -> Label:
	var label := UIKit.label(value, font_size, Palette.WOOD_DARK)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return label
