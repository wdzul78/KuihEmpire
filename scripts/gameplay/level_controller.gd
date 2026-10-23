class_name LevelController
extends Control

## Gameplay screen (Master Plan sections 11, 12, 19, 20 and 50).
##
## Two modes share one screen:
##   * campaign stages - the data-driven levels from [LevelLibrary]
##   * tutorial stages - the small coached lessons from [TutorialLibrary]
##
## In tutorial mode the board can be 3x3, nothing can be lost, and the
## [TutorialCoach] walks the player through one idea at a time.

const EXTRA_MOVES := 5

@export_group("Editable UI Layout")
@export var tutorial_layout: PackedScene = GameUILayout.TUTORIAL
@export var campaign_layout: PackedScene = GameUILayout.CAMPAIGN
@export var show_slot_background := false
@export_group("Stage")
@export var endless_mode := false
@export var level_id: int = 0
@export var tutorial_index: int = 0

var level: LevelDefinition = null
var orders: Array[CustomerOrder] = []
var active_index: int = 0
var moves_left: int = 0
var move_budget: int = 0
var finished: bool = false
var score := StageScoreController.new()
var stage_result: StageResult
var _failure_recorded := false
var _used_booster := false
var is_tutorial: bool = false
var _serving: bool = false
var _served_index: int = 0
var _tutorial_combo: StringName = &""
var _pause_overlay: Control = null

var _root: Control
var backdrop: GeraiBackdrop
var hud: HUD
var board: MatchBoard
var result: ResultOverlay
var story: StoryPopup
var coach: TutorialCoach
var _target_banner: PanelContainer
var _victory_bonus: VictoryBonus
var _victory_serial := 0
var _hand_origin := Vector2i(-1,-1)
var _blocker_intros: Array[int] = []
var _active_blocker_intro := -1
var _blocker_intro_prepared := false
var _target_label: Label


func _ready() -> void:
	AudioManager.set_music_ducked(false)
	process_mode = Node.PROCESS_MODE_PAUSABLE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_build()
	EconomyManager.booster_used.connect(func() -> void: _used_booster = true)
	_start_level()


func _build() -> void:
	_root = self
	UIKit.apply_root_theme(_root)

	is_tutorial = not endless_mode and (tutorial_index > 0 or GameManager.pending_tutorial_index > 0)
	var index := tutorial_index if tutorial_index > 0 else GameManager.pending_tutorial_index
	if is_tutorial:
		level = TutorialLibrary.get_stage(index)
	else:
		level = LevelLibrary.get_level(_resolve_level_id())

	if endless_mode:
		level = LevelDefinition.new()
		level.title = "Endless Test"
		level.tag = "8 Ã— 8 Â· Unlimited moves"
		level.width = 8
		level.height = 8
		level.kuih = KuihLibrary.starter_set()
		level.allow_fail = false

	backdrop = GeraiBackdrop.new()
	backdrop.gameplay_mode = true
	backdrop.name = "StallBackground"
	backdrop.follow_active_stall = true
	backdrop.location_id = LocationManager.active_stall_id()
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_root.add_child(backdrop)
	LocationManager.stall_upgraded.connect(func(id: StringName, state: int) -> void:
		if not is_tutorial and not endless_mode and id == backdrop.location_id:
			StallUpgradeCelebration.show_upgrade.call_deferred(self, id, state)
	)

	hud = HUD.new()
	hud.name = "GameplayHUD"
	hud.tutorial_layout = tutorial_layout
	hud.campaign_layout = campaign_layout
	hud.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_root.add_child(hud)
	# Must be after add_child: the HUD builds its children in _ready.
	hud.set_tutorial_mode(is_tutorial)
	hud.booster_bar.practice_mode = endless_mode
	hud.booster_bar.set_available(not is_tutorial)
	hud.set_stage(level.id, TutorialText.text(level.title) if is_tutorial else level.title)
	hud.set_coins(EconomyManager.coins())
	hud.settings_pressed.connect(_open_pause_menu)
	hud.restart_pressed.connect(_on_restart)
	hud.hint_pressed.connect(_on_hint)
	hud.booster_requested.connect(_on_booster_requested)

	board = MatchBoard.new()
	board.name = "MatchBoard"
	board.show_slot_background = show_slot_background
	board.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	hud.board_holder.add_child(board)
	score.score_changed.connect(func(total: int) -> void: hud.set_score(total))
	score.feedback.connect(board.show_score_feedback)
	board.clear_resolved.connect(func(cleared: BoardState.ClearResult, cascade: int) -> void:
		if not finished:
			score.add_clear(cleared, cascade)
			if coach != null:
				if cleared.combo != &"":
					_tutorial_combo = cleared.combo
			if not is_tutorial and not endless_mode and not cleared.activated.is_empty():
				GameplayEvents.specials_used.emit(cleared.activated.size(), cleared.activated.size() >= 2)
	)
	board.kuih_collected.connect(_on_kuih_collected)
	board.move_committed.connect(_on_move_committed)
	board.settled.connect(_on_settled)
	board.booster_targeted.connect(_on_booster_targeted)
	board.swap_attempted.connect(_on_swap_attempted)
	board.blocker_progress.connect(_on_blocker_progress)
	board.special_created.connect(_on_special_created)
	board.special_activated.connect(func(kind: int) -> void:
		if not endless_mode:
			PowerupRecipes.introduce(kind)
		if coach != null:
			coach.notify_special_activated(kind)
	)

	_build_target_banner()
	if endless_mode:
		_build_endless_controls()

	if is_tutorial:
		coach = TutorialCoach.new()
		coach.name = "TutorialCoach"
		coach.dialogue_host = hud.order_panel
		coach.finished.connect(_on_coach_finished)
		_root.add_child(coach)

	story = StoryPopup.new()
	story.name = "StoryDialogue"
	story.inline_mode = true
	story.dialogue_anchor = hud.order_panel._bubble
	story.highlighted_character = hud.order_panel._aina
	story.speaker_changed.connect(func(speaker: int) -> void: hud.order_panel.set_story_speaker(speaker); hud.order_panel.set_story_clearance(story._card))
	story.finished.connect(_on_story_finished)
	_root.add_child(story)

	result = ResultOverlay.new()
	result.name = "StageResult"
	result.visible = false
	_root.add_child(result)
	result.continue_pressed.connect(_on_result_continue)
	result.retry_pressed.connect(_on_result_retry)
	result.home_pressed.connect(_on_result_home)
	result.watch_ad_for_moves.connect(_on_watch_ad)
	result.booster_pressed.connect(_on_result_booster)

	EconomyManager.coins_changed.connect(_on_coins_changed)


func _build_target_banner() -> void:
	_target_banner = PanelContainer.new()
	_target_banner.add_theme_stylebox_override("panel", UIKit.wood_box(Palette.LEAF, Palette.LEAF_DEEP, 8))
	_target_banner.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	_target_banner.offset_top = 40
	_target_banner.custom_minimum_size = Vector2(820, 84)
	_target_banner.visible = false
	_target_label = UIKit.label("", 30, Palette.WHITE)
	_target_banner.add_child(_target_label)
	_root.add_child(_target_banner)


func _on_coins_changed(amount: int) -> void:
	if is_instance_valid(hud):
		hud.set_coins(amount)


func _resolve_level_id() -> int:
	if level_id > 0:
		return level_id
	if GameManager.pending_level_id > 0:
		return GameManager.pending_level_id
	return ProgressionManager.current_level()


func _start_level() -> void:
	_blocker_intros.clear()
	_active_blocker_intro = -1
	_blocker_intro_prepared = false
	AudioManager.start_puzzle_music()
	_victory_serial += 1
	if is_instance_valid(_victory_bonus):
		_victory_bonus.cancel()
		_victory_bonus = null
	score.setup(level)
	hud.configure_score(level)
	stage_result = null
	orders.clear()
	for spec in level.customer_orders:
		orders.append(CustomerOrder.from_spec(spec))
	active_index = 0
	_served_index = 0
	_tutorial_combo = &""
	_serving = false
	_hint_signature = ""
	move_budget = level.move_budget()
	moves_left = move_budget
	finished = false
	_failure_recorded = false
	_used_booster = not GameManager.pending_start_specials.is_empty()
	if result != null:
		result.visible = false
	_hide_target_prompt()

	if not is_tutorial and not endless_mode:
		ProgressionManager.record_attempt()
	board.build(level)
	if not is_tutorial and not endless_mode:
		board.apply_start_specials(GameManager.pending_start_specials)
		GameManager.pending_start_specials.clear()
	hud.set_moves(moves_left, move_budget)
	if endless_mode:
		hud._moves_label.text = "âˆž"
		hud._moves_cap.text = "MOVES"
		_seed_test_specials()
	hud.booster_bar.refresh()
	_refresh_order_ui()
	if endless_mode:
		hud.order_panel.hide()
		hud._stage_title.text = "Endless\nPower-up Test"
		hud._fit_stage_text.call_deferred()

	if not endless_mode and not KuihIntroduction.unseen(level.kuih).is_empty():
		board.enabled = false
		if coach != null:
			coach.set_process_input(false)
		KuihIntroduction.present(self, level.kuih, _begin_presentation)
	else:
		_begin_presentation()


func _begin_presentation() -> void:
	board.enabled = true
	if coach != null:
		coach.set_process_input(true)
	if is_tutorial:
		_start_coach()
	elif level.story_before != &"" and not ProgressionManager.story_seen(level.story_before):
		if _play_blocker_intro():
			return
		story.play(BeatLibrary.get_beat(level.story_before))
	elif not endless_mode:
		_play_blocker_intro()

func _play_blocker_intro() -> bool:
	if not _blocker_intro_prepared:
		_blocker_intro_prepared = true
		for blocker in level.blockers:
			if not _blocker_intros.has(blocker.kind) and not ProgressionManager.story_seen(StringName("blocker_intro_%d" % blocker.kind)):
				_blocker_intros.append(blocker.kind)
	if _blocker_intros.is_empty():
		board.enabled = true
		return false
	_active_blocker_intro = _blocker_intros.pop_front()
	var lines := {
		BlockerSpec.Kind.BANANA_LEAF: ["Kuih ini ditutup daun pisang! Padankan kuih di petak sebelah untuk membuka daun.","This kuih is covered by a banana leaf! Match kuih in an adjacent tile to uncover it."],
		BlockerSpec.Kind.FOOD_COVER: ["Ada penutup berlapis! Setiap padanan di petak sebelah membuang satu lapisan. Ulang sehingga terbuka.","This cover has layers! Each adjacent match removes one layer. Keep matching until it opens."],
		BlockerSpec.Kind.STEAMER: ["Kuih masih dalam pengukus! Padankan kuih di petak sebelah untuk membuka penutupnya.","The kuih is in a steamer! Match kuih in an adjacent tile to open its lid."],
		BlockerSpec.Kind.STICKY_SYRUP: ["Alamak! Sirap tertumpah ke atas kuih! Kuih ini tak boleh di-swap. Padankan kuih di petak sebelah untuk bersihkan sirap.","Oh no! Syrup spilled onto the kuih! You cannot swap this tile. Match kuih in an adjacent tile to clean the syrup."],
		BlockerSpec.Kind.PACKAGING_BOX: ["Kotak ini perlu diisi! Kumpulkan jenis kuih dan jumlah yang ditunjukkan pada kotak untuk menyiapkannya.","This box needs filling! Collect the kuih type and quantity shown on the box to complete it."],
		BlockerSpec.Kind.EMPTY_TRAY: ["Dulang ini masih kosong! Kumpulkan jenis kuih dan jumlah yang ditunjukkan untuk memenuhi dulang.","This tray is empty! Collect the indicated kuih type and quantity to fill it."],
	}
	var beat := StoryBeat.make(StringName("blocker_intro_%d" % _active_blocker_intro),StoryBeat.Speaker.AINA,[JourneyArt.localized(lines[_active_blocker_intro][0],lines[_active_blocker_intro][1])])
	board.enabled = false
	story.play(beat)
	return true


func _start_coach() -> void:
	coach.begin(level.tutorial_steps)
	board.swap_filter = coach.allows_swap
	board.activation_filter = coach.allows_activation.bind(board.logic)
	# Teach the collection lesson against the kuih the customer actually wants.
	var order := active_order()
	if order != null:
		var ids := order.item_ids()
		if not ids.is_empty():
			coach.watch_kuih(ids[0])
	# Keep the saved progress in step with whatever is on screen.
	ProgressionManager.save_tutorial_index(level.tutorial_index)


func _on_story_finished() -> void:
	hud.order_panel.set_story_speaker(-1)
	if _active_blocker_intro >= 0:
		ProgressionManager.mark_story_seen(StringName("blocker_intro_%d" % _active_blocker_intro))
		_active_blocker_intro = -1
		_begin_presentation()
		return
	if level != null and level.story_before != &"":
		ProgressionManager.mark_story_seen(level.story_before)


func _order_collected_count() -> int:
	var total := 0
	for order in orders:
		total += order.total_collected
	return total

func _refresh_delivery_targets() -> void:
	if board == null or board.logic == null:
		return
	var current := active_order()
	board.logic.order_remaining = current.remaining.duplicate() if current != null else {}

func _refresh_order_ui() -> void:
	_refresh_delivery_targets()
	if active_index >= orders.size():
		# Retain the last fulfilled tray while the tutorial explains serving and
		# while the results arrive. Lessons without orders still hide the tray.
		hud.order_panel.bind(orders.back() if not orders.is_empty() else null)
		hud.set_queue([])
		return
	hud.order_panel.bind(orders[active_index])
	story.customer_name = orders[active_index].customer.display_name if orders[active_index].customer != null else "Customer"
	var waiting: Array = []
	for i in range(active_index + 1, orders.size()):
		var order: CustomerOrder = orders[i]
		if order.customer != null:
			waiting.append(order.customer)
	hud.set_queue(waiting)


func active_order() -> CustomerOrder:
	if active_index < orders.size():
		return orders[active_index]
	return null


# --- coach wiring ----------------------------------------------------------

func _on_swap_attempted(a: Vector2i, b: Vector2i, accepted: bool) -> void:
	if coach != null:
		coach.notify_swap(a, b, accepted)


func _on_special_created(kind: int) -> void:
	if not endless_mode:
		PowerupRecipes.introduce(kind)
	if coach != null:
		coach.notify_special_created(kind)


func _on_blocker_progress(hits: Array) -> void:
	if coach == null:
		return
	var removed := 0
	for hit in hits:
		if hit.removed:
			removed += 1
	if removed > 0:
		coach.notify_blocker_opened(removed)


func _on_coach_finished() -> void:
	# The lesson is taught; hand the player straight to the objective.
	hud.set_stage(level.id, TutorialText.text(level.title) if is_tutorial else level.title)
	if not board.busy:
		_on_settled.call_deferred()


var _hint_signature: String = ""


func _process(_delta: float) -> void:
	if coach == null or board == null:
		return
	if not board.busy and board.logic != null:
		coach.guide_special_activation(board.logic)
	var cells := coach.hint_cells()
	var signature := str(cells)
	if signature == _hint_signature:
		return
	_hint_signature = signature
	if cells.is_empty():
		board.clear_hints()
	else:
		if cells.size() == 2 and cells[0].distance_to(cells[1]) == 1:
			board.focus_cells(cells)
		else:
			board.highlight_cells(cells)


# --- gameplay --------------------------------------------------------------

func _on_move_committed() -> void:
	if endless_mode:
		return
	moves_left -= 1
	if not is_tutorial and not endless_mode:
		ProgressionManager.record_moves(1)
	hud.set_moves(moves_left, move_budget)


func _on_kuih_collected(totals: Dictionary) -> void:
	if endless_mode:
		return
	if finished or totals.is_empty():
		return
	if not is_tutorial and not endless_mode:
		for id in totals:
			ProgressionManager.add_mastery(id, int(totals[id]))

	var before := _order_collected_count()
	var leftover: Dictionary = totals
	var i := active_index
	while i < orders.size() and not leftover.is_empty():
		leftover = orders[i].collect(leftover)
		if not orders[i].is_complete():
			break
		i += 1
	score.add_collection(_order_collected_count() - before)
	if i > active_index:
		# Advance immediately: the next cascade must collect for the next guest,
		# even while the previous guest's celebration is still playing.
		active_index = i
		if not _serving:
			_serve_pending()
	else:
		hud.order_panel.animate_progress()
	_refresh_delivery_targets()
	if coach != null:
		coach.notify_collected(totals)


func _serve_pending() -> void:
	_serving = true
	board.enabled = false
	while _served_index < active_index:
		# Collection may already target the next guest; show this guest's ticks
		# during their serving celebration before moving on to the next order.
		hud.order_panel.bind(orders[_served_index])
		orders[_served_index].served = true
		if not is_tutorial and not endless_mode:
			GameplayEvents.order_served.emit()
		hud.order_panel.cheer()
		AudioManager.play(AudioManager.Sfx.SERVE, 1.0, -3.0)
		UIKit.sparkle_burst(_root, _root.get_global_rect().get_center(), Palette.GOLD_PALE, 14)
		await get_tree().create_timer(0.75, false).timeout
		_served_index += 1
		if coach != null:
			coach.notify_served()
	_serving = false
	board.enabled = not finished
	_refresh_order_ui()
	if not board.busy:
		_on_settled()


func _on_settled() -> void:
	if endless_mode:
		return
	if finished or _serving or board.busy:
		return
	if coach != null and _tutorial_combo != &"":
		var combo := _tutorial_combo
		_tutorial_combo = &""
		coach.notify_combo(combo)
	if _objectives_met():
		_win()
	elif moves_left <= 0 and level.allow_fail:
		if not _failure_recorded:
			HeartManager.consume_on_failure(is_tutorial)
			_failure_recorded = true
			if not is_tutorial and not endless_mode:
				GameplayEvents.stage_failed.emit(level.id)
		finished = true
		board.enabled = false
		result.stage_number = level.id
		result.tutorial_stage = is_tutorial
		stage_result = StageResultCalculator.calculate(false, score.total, moves_left, level)
		GameManager.pending_score = stage_result.final_score
		GameManager.pending_stars = 0
		GameManager.pending_coins = 0
		GameManager.report_result(false)
		result.show_fail(_missing_summary(), true, stage_result)


func _objectives_met() -> bool:
	if is_tutorial and coach != null and not coach.is_done():
		return false
	if orders.is_empty():
		return true
	for order in orders:
		if not order.is_complete():
			return false
	if level.require_blockers_cleared and board.logic != null:
		return board.logic.remaining_blockers() == 0
	return true


func _missing_summary() -> String:
	var order := active_order()
	var parts: PackedStringArray = []
	if order != null:
		for id in order.item_ids():
			var left := int(order.remaining.get(id, 0))
			if left > 0:
				parts.append("%d %s" % [left, KuihLibrary.get_display_name(id)])
	if parts.is_empty() and level.require_blockers_cleared and board.logic != null:
		var leftover := board.logic.remaining_blockers()
		if leftover > 0:
			parts.append("%d still covered" % leftover)
	if parts.is_empty():
		return "So close! One more try."
	return "Still need: " + ", ".join(parts)


func _win() -> void:
	if finished or not _objectives_met():
		return
	finished = true
	board.enabled = false
	stage_result = StageResultCalculator.calculate(true, score.total, moves_left, level, not is_tutorial and ProgressionManager.first_clear_available(level.id), 0 if is_tutorial else ProgressionManager.best_score(level.id))
	if is_tutorial or moves_left <= 0:
		score.add_points(stage_result.move_bonus)
	var stars := stage_result.earned_stars
	hud.score_progress.set_completed(true)
	var coins := stage_result.total_coins
	var unlocks: Array[StringName] = []
	var is_new_best := stage_result.is_new_best and not is_tutorial

	if is_tutorial:
		# Tutorial stages never touch the campaign progress.
		if not ProgressionManager.claim_tutorial_reward(level.tutorial_index):
			coins = 0
			stage_result.total_coins = 0
			stage_result.base_coins = 0
			stage_result.score_bonus = 0
			stage_result.star_bonus = 0
		EconomyManager.add_coins(coins)
		ProgressionManager.save_tutorial_index(level.tutorial_index)
		if level.tutorial_index == 9:
			ProgressionManager.unlock_delivery()
	else:
		ProgressionManager.record_win(level.id, stars, moves_left, stage_result.final_score)
		ProgressionManager.record_win_count()
		EconomyManager.add_coins(coins)
		if level.kuih_unlock != &"" and KuihLibrary.has(level.kuih_unlock):
			unlocks.append(level.kuih_unlock)
		if level.recipe_unlock != &"" and ProgressionManager.unlock_recipe(level.recipe_unlock):
			unlocks.append(level.recipe_unlock)
		if level.id == LevelLibrary.CHAPTER_FINALE:
			ProgressionManager.unlock_chapter(&"map")
		if not endless_mode and level.recipe_unlock_id != &"":
			var discovery := RecipeBookManager.discover_recipe(level.recipe_unlock_id, "stage", level.id)
			if not discovery.get("ok", false):
				push_warning("Recipe discovery could not be saved: %s" % discovery.get("error", "unknown"))

	GameManager.pending_score = stage_result.final_score
	GameManager.pending_stars = stars
	GameManager.pending_coins = coins
	GameManager.pending_moves_left = moves_left
	GameManager.pending_unlocks = unlocks
	if not is_tutorial and not endless_mode:
		GameplayEvents.stage_completed.emit(level.id, stars, stage_result.final_score, _used_booster)
	GameManager.report_result(true)

	hud.set_coins(EconomyManager.coins())
	result.stage_number = TutorialLibrary.lesson_number(level.tutorial_index) if is_tutorial else level.id
	result.tutorial_final = is_tutorial and TutorialLibrary.is_last(level.tutorial_index)
	result.tutorial_stage = is_tutorial
	var free_bonus := HeartManager.reward_win(level.id, is_tutorial)
	if not is_tutorial and not endless_mode and moves_left > 0:
		var serial := _victory_serial
		result.show_win(level.title, stars, coins, unlocks, is_new_best, stage_result, false)
		board.clear_hints()
		board._feedback.reset()
		board._combo_praise.reset()
		board._special_text.reset()
		_victory_bonus = VictoryBonus.new()
		board.add_child(_victory_bonus)
		_victory_bonus.steps_converted.connect(func(remaining: int, points: int) -> void:
			if serial == _victory_serial:
				hud.set_moves(remaining, move_budget, true)
				score.add_points(points)
		)
		var bonus := _victory_bonus
		await bonus.play(board, moves_left, level.scoring.remaining_move)
		bonus.queue_free()
		if serial != _victory_serial:
			return
		_victory_bonus = null
	result.show_win(level.title, stars, coins, unlocks, is_new_best, stage_result)
	if free_bonus > 0:
		var celebration := UIKit.label("Free Play Â· %d min!" % [free_bonus / 60], 30, Palette.PINK_DARK)
		celebration.name = "FreePlayReward"
		JourneyArt.place(result, celebration, Rect2(.20, .20, .60, .04))

	if not is_tutorial and not endless_mode and JourneyLibrary.milestone(level.id).is_empty() and level.story_after != &"":
		if not ProgressionManager.story_seen(level.story_after):
			ProgressionManager.mark_story_seen(level.story_after)
			story.play(BeatLibrary.get_beat(level.story_after))
	if not is_tutorial and not endless_mode:
		RecipePresentation.present_pending(self)


# --- boosters --------------------------------------------------------------

func _consume_booster(booster: int) -> bool:
	if endless_mode:
		return true
	if is_tutorial:
		return false
	return EconomyManager.use_booster(booster)

func _on_booster_requested(booster: int) -> void:
	if is_tutorial:
		return
	if _pause_overlay != null or finished or _serving or board == null or board.busy or not board.enabled:
		return
	board.cancel_targeting()
	_hand_origin = Vector2i(-1,-1)
	_hide_target_prompt()
	match booster:
		EconomyManager.Booster.SHUFFLE:
			if not _consume_booster(booster):
				return
			await board.booster_shuffle()
		EconomyManager.Booster.ROYAL:
			if not _consume_booster(booster):
				return
			await board.booster_clear(Vector2i(board.logic.width/2,board.logic.height/2), &"royal")
		EconomyManager.Booster.EXTRA_MOVES:
			if not _consume_booster(booster):
				return
			_grant_moves(EXTRA_MOVES)
		EconomyManager.Booster.SPATULA, EconomyManager.Booster.TRAY, EconomyManager.Booster.HAND, EconomyManager.Booster.GIFT:
			if not hud.booster_bar.practice_mode and not EconomyManager.has_booster(booster):
				return
			_show_target_prompt(booster)
			board.begin_targeting(booster)
		_:
			return
	hud.booster_bar.refresh()


func _show_target_prompt(booster: int) -> void:
	_target_label.text = TutorialText.text("Pilih kuih untuk swap percuma" if booster == EconomyManager.Booster.HAND else "Pilih pusat silang 3 baris dan 3 lajur" if booster == EconomyManager.Booster.GIFT else "Tap a kuih to scoop it out" if booster == EconomyManager.Booster.SPATULA else "Tap the middle of the 3 x 3 area")
	_target_banner.visible = true
	_target_banner.pivot_offset = Vector2(410, 42)
	_target_banner.scale = Vector2(0.8, 0.8)
	var tw := _target_banner.create_tween()
	tw.tween_property(_target_banner, "scale", Vector2.ONE, 0.26).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _hide_target_prompt() -> void:
	_target_banner.visible = false


func _on_booster_targeted(booster: int, pos: Vector2i) -> void:
	if is_tutorial:
		return
	if _pause_overlay != null or finished or _serving or board == null or board.busy or not board.enabled:
		return
	if booster not in [EconomyManager.Booster.SPATULA, EconomyManager.Booster.TRAY, EconomyManager.Booster.HAND, EconomyManager.Booster.GIFT]:
		return
	if not board.logic.is_inside(pos):
		return
	if booster == EconomyManager.Booster.SPATULA and not board.logic.get_cell(pos).has_kuish() and not board.logic.get_cell(pos).has_obstacle():
		return
	if booster == EconomyManager.Booster.HAND:
		if not board.logic.is_playable(pos):
			board.begin_targeting(booster)
			return
		if _hand_origin.x < 0 or absi(pos.x-_hand_origin.x)+absi(pos.y-_hand_origin.y) != 1:
			_hand_origin = pos
			board.begin_targeting(booster)
			board._select(pos)
			_target_label.text = JourneyArt.localized("Pilih kuih bersebelahan untuk swap percuma", "Choose an adjacent tile for a free swap")
			return
		if not _consume_booster(booster):
			return
		var first := _hand_origin
		_hand_origin = Vector2i(-1,-1)
		_hide_target_prompt()
		board.cancel_targeting()
		hud.booster_bar.cancel_selection()
		await board.booster_hand(first,pos)
		hud.booster_bar.refresh()
		return
	_hide_target_prompt()
	board.cancel_targeting()
	hud.booster_bar.cancel_selection()
	if not _consume_booster(booster):
		return
	if booster == EconomyManager.Booster.SPATULA:
		await board.booster_clear(pos, &"sudip")
	elif booster == EconomyManager.Booster.GIFT:
		await board.booster_clear(pos, &"cross")
	elif booster == EconomyManager.Booster.TRAY:
		pos.x = clampi(pos.x, 1, board.logic.width - 2)
		pos.y = clampi(pos.y, 1, board.logic.height - 2)
		await board.booster_tray(pos)
	hud.booster_bar.refresh()


func _grant_moves(amount: int) -> void:
	if endless_mode:
		return
	moves_left += amount
	hud.set_moves(moves_left, move_budget)
	hud.pivot_offset = hud.size * 0.5
	var tw := hud.create_tween()
	tw.tween_property(hud, "scale", Vector2(1.03, 1.03), 0.16)
	tw.tween_property(hud, "scale", Vector2.ONE, 0.20).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _on_hint() -> void:
	if _pause_overlay != null or finished or board == null or board.busy:
		return
	if not bool(GameManager.setting("show_hints", true)):
		return
	if coach != null:
		var guided := coach.guided_cells()
		if not guided.is_empty():
			board.focus_cells(guided)
			AudioManager.play(AudioManager.Sfx.TAP, 1.2, -6.0)
			return
	if board.show_hint():
		AudioManager.play(AudioManager.Sfx.TAP, 1.2, -6.0)


# --- flow ------------------------------------------------------------------

func _open_pause_menu() -> void:
	if finished or _pause_overlay != null or not is_node_ready() or board == null or level == null:
		return
	board.cancel_interrupted_input()
	AudioManager.play(AudioManager.Sfx.TAP)
	var overlay := PauseOverlay.new()
	_pause_overlay = overlay
	overlay.stage_title = "%s Â· %s" % [level.title, JourneyArt.localized("Tutorial", "Tutorial") if is_tutorial else level.tag]
	overlay.tutorial = is_tutorial
	overlay.restart_available = not (board.busy or _serving or finished)
	overlay.extra_count = EconomyManager.booster_count(EconomyManager.Booster.EXTRA_MOVES)
	overlay.extra_coin_purchase = not endless_mode and overlay.extra_count == 0
	overlay.extra_available = overlay.restart_available and (endless_mode or overlay.extra_count > 0 or EconomyManager.can_afford(EconomyManager.EXTRA_MOVES_COST))
	overlay.resume_pressed.connect(func() -> void:
		AudioManager.play(AudioManager.Sfx.TAP)
		_resume_level()
	)
	overlay.restart_pressed.connect(func() -> void:
		_resume_level()
		_on_restart()
	)
	overlay.extra_moves_pressed.connect(func() -> void:
		_resume_level()
		if overlay.extra_coin_purchase:
			if not finished and not _serving and board != null and not board.busy and board.enabled and EconomyManager.spend_coins(EconomyManager.EXTRA_MOVES_COST):
				_grant_moves(EXTRA_MOVES)
		else:
			_on_booster_requested(EconomyManager.Booster.EXTRA_MOVES)
	)
	overlay.quit_pressed.connect(_request_leave_stage)
	_root.add_child(overlay)
	get_tree().paused = true
	SaveManager._flush()


func _request_leave_stage() -> void:
	if finished or _pause_overlay == null:
		return
	AudioManager.play(AudioManager.Sfx.TAP)
	var message := JourneyArt.localized("Keluar akan menolak 1 hati. Kembali ke gerai?", "Leaving costs 1 heart. Return to the stall?")
	if is_tutorial or endless_mode:
		message = JourneyArt.localized("Kembali ke gerai?", "Return to the stall?")
	elif HeartManager.is_free_play_active():
		message = JourneyArt.localized("Keluar akan menamatkan mod hati tanpa had dan baki masanya, serta menolak 1 hati. Kembali ke gerai?", "Leaving ends unlimited hearts and its remaining time, and costs 1 heart. Return to the stall?")
	_pause_overlay.leave_costs_heart = not is_tutorial and not endless_mode
	_pause_overlay.confirm_leave(message, _confirm_leave_stage)

func _confirm_leave_stage() -> void:
	if finished:
		return
	finished = true
	var hearts_before := HeartManager.current()
	HeartManager.consume_on_abandon(is_tutorial or endless_mode)
	SaveManager._flush()
	await _pause_overlay.play_heart_loss(hearts_before,HeartManager.current())
	_resume_level()
	board.enabled = false
	GameManager.go_home()

func _resume_level() -> void:
	if _pause_overlay == null:
		return
	get_tree().paused = false
	_pause_overlay.queue_free()
	_pause_overlay = null


func _exit_tree() -> void:
	if _pause_overlay != null:
		get_tree().paused = false


var _closing := false

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		_closing = true
		return
	# A call/OS overlay can take focus without backgrounding the activity.
	# Keep the existing pause menu until the player explicitly presses Resume.
	if what in [NOTIFICATION_APPLICATION_PAUSED, NOTIFICATION_APPLICATION_FOCUS_OUT] and is_node_ready() and is_inside_tree():
		# Notification propagation can lock the parent's child list. Adding the
		# overlay there fails, leaving a paused tree without a usable Resume.
		_pause_after_interruption.call_deferred()


func _pause_after_interruption() -> void:
	if not _closing and is_inside_tree() and SceneManager.is_current(self) and not SceneManager._busy:
		_open_pause_menu()


func _on_restart() -> void:
	if endless_mode and not board.busy and _pause_overlay == null:
		_start_level()
		return
	if _pause_overlay != null or finished or _serving or board.busy:
		return
	AudioManager.play(AudioManager.Sfx.TAP)
	if is_tutorial:
		_start_level()
	else:
		GameManager.play_level(level.id)


func _on_result_continue() -> void:
	if result != null and result.is_win and not is_tutorial and not endless_mode:
		if RecipePresentation.present_pending(self, _continue_after_recipe):
			return
	_continue_after_recipe()


func _continue_after_recipe() -> void:
	if result == null:
		return
	if not result.is_win:
		result.visible = false
		if finished:
			finished = false
			board.enabled = true
			_grant_moves(EXTRA_MOVES)
		return
	result.visible = false
	if is_tutorial:
		var next := TutorialLibrary.next_index(level.tutorial_index)
		if not TutorialLibrary.is_last(level.tutorial_index) and TutorialLibrary.has(next):
			GameManager.play_tutorial(next)
		else:
			ProgressionManager.complete_tutorial()
			GameManager.pending_tutorial_index = 0
			GameManager.pending_level_id = ProgressionManager.current_level()
			SceneManager.goto(SceneManager.WELCOME if OnboardingProgress.pending() else SceneManager.JOURNEY)
		return
	if not JourneyLibrary.milestone(level.id).is_empty() and not ProgressionManager.story_seen(StringName("milestone_scene_%d" % level.id)):
		var milestone := JourneyMilestonePopup.new()
		add_child(milestone)
		milestone.show_milestone(level.id)
		milestone.dismissed.connect(_advance_campaign)
		return
	_advance_campaign()


func _advance_campaign() -> void:
	var next_level := level.id + 1
	if LevelLibrary.has_level(next_level):
		GameManager.play_level(next_level)
	else:
		GameManager.go_journey()


func _on_result_retry() -> void:
	if is_tutorial:
		_start_level()
	else:
		GameManager.play_level(level.id)


func _on_result_booster() -> void:
	if not result.is_win and EconomyManager.use_booster(EconomyManager.Booster.EXTRA_MOVES):
		_on_result_continue()
		hud.booster_bar.refresh()


func _on_result_home() -> void:
	GameManager.go_home()


func _on_watch_ad() -> void:
	if await HeartManager.request_rewarded_ad():
		if is_instance_valid(result) and result.visible and not result.is_win:
			_on_result_continue()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("go_back"):
		_open_pause_menu()
	elif event.is_action_pressed("restart_level"):
		_on_restart()
	elif event.is_action_pressed("show_hint"):
		_on_hint()


const TEST_SPECIALS := [BoardCell.Special.TAPAU, BoardCell.Special.TAPAU_VERTICAL, BoardCell.Special.DULANG, BoardCell.Special.ORDER, BoardCell.Special.HANTAR]

func _seed_test_specials() -> void:
	for entry in [[Vector2i(2,3),BoardCell.Special.ORDER],[Vector2i(3,3),BoardCell.Special.ORDER],[Vector2i(5,3),BoardCell.Special.DULANG],[Vector2i(6,3),BoardCell.Special.DULANG],[Vector2i(2,5),BoardCell.Special.TAPAU],[Vector2i(3,5),BoardCell.Special.TAPAU_VERTICAL],[Vector2i(5,5),BoardCell.Special.HANTAR]]:
		var cell := board.logic.get_cell(entry[0])
		cell.special = entry[1]
		cell.order_kuish = &"onde_onde"
	board._refresh_tiles()

func _build_endless_controls() -> void:
	hud.order_panel.hide()
	var row := HBoxContainer.new()
	row.name = "TestPowerControls"
	row.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	row.anchor_left = .08
	row.anchor_right = .92
	row.anchor_top = .22
	row.anchor_bottom = .265
	add_child(row)
	var choice := OptionButton.new()
	choice.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for caption in ["Horizontal", "Vertical", "Badak Berendam", "Kek Lapis Sarawak", "Drone"]:
		choice.add_item(caption)
	choice.add_theme_font_size_override("font_size",24)
	row.add_child(choice)
	var add := Button.new()
	add.text = "+ Power-up"
	add.add_theme_font_size_override("font_size",24)
	row.add_child(add)
	add.pressed.connect(func():
		if board.busy or not board.enabled or _pause_overlay != null:
			return
		var candidates: Array[Vector2i] = []
		for y in 8:
			for x in 8:
				var pos := Vector2i(x,y)
				if board.logic.get_cell(pos).special == BoardCell.Special.NONE:
					candidates.append(pos)
		if candidates.is_empty():
			return
		var pos := candidates.pick_random() as Vector2i
		var cell := board.logic.get_cell(pos)
		cell.special = TEST_SPECIALS[choice.selected]
		cell.order_kuish = &"onde_onde"
		board._sync_tile(pos)
	)
