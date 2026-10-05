extends Node

signal achievement_unlocked(definition: AchievementDefinition)
signal changed()

## Historical stage/recipe metrics are derived; new event counters start at migration.
var definitions: Array[AchievementDefinition] = []
var _toast: PanelContainer
var _toast_label: Label
var _toast_tween: Tween
var _toast_count := 0
var _toast_coins := 0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	definitions = AchievementDefinition.all()
	achievement_unlocked.connect(_show_unlock)
	GameplayEvents.stage_completed.connect(_stage_completed)
	GameplayEvents.stage_failed.connect(_stage_failed)
	GameplayEvents.order_served.connect(func() -> void: _increment("orders_served"))
	GameplayEvents.specials_used.connect(func(count: int, combo: bool) -> void:
		_increment("specials_used", count)
		if combo:
			_increment("special_combos")
	)
	ProgressionManager.stars_changed.connect(func(_id: int, _stars: int) -> void: refresh())
	ProgressionManager.recipe_unlocked.connect(func(_id: StringName) -> void: refresh())
	ProgressionManager.chapter_unlocked.connect(func(_id: StringName) -> void: refresh())
	ProgressionManager.gerai_upgraded.connect(func() -> void: refresh())
	refresh.call_deferred()

func _increment(key: String, count: int = 1) -> void:
	var stats: Dictionary = SaveManager.data["stats"]
	stats[key] = int(stats.get(key, 0)) + maxi(0, count)
	SaveManager.mark_dirty()
	refresh()

func _stage_completed(_id: int, _stars: int, _score: int, used_booster: bool) -> void:
	var stats: Dictionary = SaveManager.data["stats"]
	stats["achievement_win_streak"] = int(stats.get("achievement_win_streak", 0)) + 1
	stats["best_win_streak"] = maxi(int(stats.get("best_win_streak", 0)), stats["achievement_win_streak"])
	if not used_booster:
		stats["unassisted_wins"] = int(stats.get("unassisted_wins", 0)) + 1
	SaveManager.mark_dirty()
	refresh()

func _stage_failed(_id: int) -> void:
	SaveManager.data["stats"]["achievement_win_streak"] = 0
	SaveManager.mark_dirty()
	refresh()

func metrics() -> Dictionary:
	var result: Dictionary = SaveManager.data["stats"].duplicate()
	result["stages"] = 0
	result["perfect"] = 0
	result["best_score"] = 0
	for id in range(1, LevelLibrary.count() + 1):
		var stars := ProgressionManager.stars_for(id)
		if stars > 0:
			result["stages"] += 1
		if stars == 3:
			result["perfect"] += 1
		result["best_score"] = maxi(result["best_score"], ProgressionManager.best_score(id))
	result["stars"] = ProgressionManager.total_stars()
	result["recipes"] = 0
	for kuih in KuihLibrary.all():
		if ProgressionManager.is_recipe_unlocked(kuih.recipe_id):
			result["recipes"] += 1
	result["stories"] = 0
	for story in range(int(LevelLibrary.count() / 30)):
		var complete := true
		for id in range(story * 30 + 1, story * 30 + 31):
			if ProgressionManager.stars_for(id) == 0:
				complete = false
		if complete:
			result["stories"] += 1
	result["next_story"] = 1 if ProgressionManager.is_chapter_unlocked(&"school_canteen") else 0
	result["structural_upgrades"] = 0
	for location in LocationDefinition.all():
		result["structural_upgrades"] += LocationManager.structural_level(location.id)
	result["gerai"] = ProgressionManager.gerai_level()
	return result

func refresh() -> void:
	var values := metrics()
	var table: Dictionary = SaveManager.data.get("achievements", {})
	for definition in definitions:
		var state: Dictionary = table.get(definition.id, {})
		state["progress"] = maxi(int(state.get("progress", 0)), mini(definition.target, int(values.get(definition.progress_type, 0))))
		if state["progress"] >= definition.target and not state.get("unlocked", false):
			state["unlocked"] = true
			state["unlocked_at"] = int(Time.get_unix_time_from_system())
			# Reward and claim share the same save snapshot. Re-entry cannot duplicate it.
			state["reward_claimed"] = true
			table[definition.id] = state
			SaveManager.data["achievements"] = table
			EconomyManager.add_coins(definition.reward_coins)
			SaveManager.mark_dirty()
			achievement_unlocked.emit(definition)
		elif state.get("unlocked", false) and not state.get("reward_claimed", false):
			state["reward_claimed"] = true
			table[definition.id] = state
			SaveManager.data["achievements"] = table
			EconomyManager.add_coins(definition.reward_coins)
		table[definition.id] = state
	SaveManager.data["achievements"] = table
	SaveManager.mark_dirty()
	changed.emit()

func state(id: String) -> Dictionary:
	return SaveManager.data.get("achievements", {}).get(id, {})

func completed_count() -> int:
	var count := 0
	for definition in definitions:
		if state(definition.id).get("unlocked", false):
			count += 1
	return count


func _show_unlock(definition: AchievementDefinition) -> void:
	if _toast == null:
		var layer := CanvasLayer.new()
		layer.layer = 115
		add_child(layer)
		var root := Control.new()
		root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		root.mouse_filter = Control.MOUSE_FILTER_IGNORE
		layer.add_child(root)
		_toast = PanelContainer.new()
		_toast.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_toast.add_theme_stylebox_override("panel", UIKit.cream_box())
		JourneyArt.place(root, _toast, Rect2(.08, .055, .84, .095))
		_toast_label = UIKit.label("", 34, Palette.WOOD_DARK)
		_toast_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_toast_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_toast_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_toast.add_child(_toast_label)
	if _toast_tween != null and _toast_tween.is_running():
		_toast_tween.kill()
	else:
		_toast_count = 0
		_toast_coins = 0
	_toast_count += 1
	_toast_coins += definition.reward_coins
	_toast_label.text = "★ %s\n+%d coins · Achievement unlocked" % [definition.title if _toast_count == 1 else "%d achievements" % _toast_count, _toast_coins]
	_toast.show()
	_toast.modulate.a = 1.0
	_toast_tween = create_tween()
	_toast_tween.tween_interval(3.0)
	_toast_tween.tween_property(_toast, "modulate:a", 0.0, .3)
	_toast_tween.tween_callback(_toast.hide)
