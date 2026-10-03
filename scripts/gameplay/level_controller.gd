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

@export var level_id: int = 0
@export var tutorial_index: int = 0

var level: LevelDefinition = null
var orders: Array[CustomerOrder] = []
var active_index: int = 0
var moves_left: int = 0
var move_budget: int = 0
var finished: bool = false
var is_tutorial: bool = false
var _serving: bool = false
var _served_index: int = 0
var _pause_overlay: Control = null

var _root: Control
var backdrop: GeraiBackdrop
var hud: HUD
var board: MatchBoard
var result: ResultOverlay
var story: StoryPopup
var coach: TutorialCoach
var _target_banner: PanelContainer
var _target_label: Label


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_PAUSABLE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_build()
	_start_level()


func _build() -> void:
	_root = self
	UIKit.apply_root_theme(_root)

	is_tutorial = tutorial_index > 0 or GameManager.pending_tutorial_index > 0
	var index := tutorial_index if tutorial_index > 0 else GameManager.pending_tutorial_index
	if is_tutorial:
		level = TutorialLibrary.get_stage(index)
	else:
		level = LevelLibrary.get_level(_resolve_level_id())

	backdrop = GeraiBackdrop.new()
	backdrop.background_id = level.background_id
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_root.add_child(backdrop)

	hud = HUD.new()
	hud.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_root.add_child(hud)
	# Must be after add_child: the HUD builds its children in _ready.
	hud.set_tutorial_mode(is_tutorial)
	hud.set_stage(level.id, level.title)
	hud.set_coins(EconomyManager.coins())
	hud.settings_pressed.connect(_open_pause_menu)
	hud.restart_pressed.connect(_on_restart)
	hud.hint_pressed.connect(_on_hint)
	hud.booster_requested.connect(_on_booster_requested)

	board = MatchBoard.new()
	board.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	hud.board_holder.add_child(board)
	board.kuih_collected.connect(_on_kuih_collected)
	board.move_committed.connect(_on_move_committed)
	board.settled.connect(_on_settled)
	board.booster_targeted.connect(_on_booster_targeted)
	board.swap_attempted.connect(_on_swap_attempted)
	board.blocker_progress.connect(_on_blocker_progress)
	board.special_created.connect(_on_special_created)

	_build_target_banner()

	if is_tutorial:
		coach = TutorialCoach.new()
		coach.finished.connect(_on_coach_finished)
		_root.add_child(coach)

	story = StoryPopup.new()
	story.finished.connect(_on_story_finished)
	_root.add_child(story)

	result = ResultOverlay.new()
	result.visible = false
	_root.add_child(result)
	result.continue_pressed.connect(_on_result_continue)
	result.retry_pressed.connect(_on_result_retry)
	result.home_pressed.connect(_on_result_home)
	result.watch_ad_for_moves.connect(_on_watch_ad)

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
	orders.clear()
	for spec in level.customer_orders:
		orders.append(CustomerOrder.from_spec(spec))
	active_index = 0
	_served_index = 0
	_serving = false
	_hint_signature = ""
	move_budget = level.move_budget()
	moves_left = move_budget
	finished = false
	if result != null:
		result.visible = false
	_hide_target_prompt()

	if not is_tutorial:
		ProgressionManager.record_attempt()
	board.build(level)
	hud.set_moves(moves_left, move_budget)
	hud.booster_bar.refresh()
	_refresh_order_ui()

	if is_tutorial:
		_start_coach()
	elif level.story_before != &"" and not ProgressionManager.story_seen(level.story_before):
		story.play(BeatLibrary.get_beat(level.story_before))


func _start_coach() -> void:
	coach.begin(level.tutorial_steps)
	# Teach the collection lesson against the kuih the customer actually wants.
	var order := active_order()
	if order != null:
		var ids := order.item_ids()
		if not ids.is_empty():
			coach.watch_kuih(ids[0])
	# Keep the saved progress in step with whatever is on screen.
	ProgressionManager.save_tutorial_index(level.tutorial_index)


func _on_story_finished() -> void:
	if level != null and level.story_before != &"":
		ProgressionManager.mark_story_seen(level.story_before)


func _refresh_order_ui() -> void:
	if active_index >= orders.size():
		hud.order_panel.bind(null)
		hud.set_queue([])
		return
	hud.order_panel.bind(orders[active_index])
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
	hud.set_stage(level.id, level.title)


var _hint_signature: String = ""


func _process(_delta: float) -> void:
	if coach == null or board == null:
		return
	var cells := coach.hint_cells()
	var signature := str(cells)
	if signature == _hint_signature:
		return
	_hint_signature = signature
	if cells.is_empty():
		board.clear_hints()
	else:
		board.highlight_cells(cells)


# --- gameplay --------------------------------------------------------------

func _on_move_committed() -> void:
	moves_left -= 1
	if not is_tutorial:
		ProgressionManager.record_moves(1)
	hud.set_moves(moves_left, move_budget)


func _on_kuih_collected(totals: Dictionary) -> void:
	if finished or totals.is_empty():
		return
	if not is_tutorial:
		for id in totals:
			ProgressionManager.add_mastery(id, int(totals[id]))

	var leftover: Dictionary = totals
	var i := active_index
	while i < orders.size() and not leftover.is_empty():
		leftover = orders[i].collect(leftover)
		if not orders[i].is_complete():
			break
		i += 1
	if i > active_index:
		# Advance immediately: the next cascade must collect for the next guest,
		# even while the previous guest's celebration is still playing.
		active_index = i
		if not _serving:
			_serve_pending()
	else:
		hud.order_panel.animate_progress()
	if coach != null:
		coach.notify_collected(totals)


func _serve_pending() -> void:
	_serving = true
	board.enabled = false
	while _served_index < active_index:
		orders[_served_index].served = true
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
	if finished or _serving:
		return
	if _objectives_met():
		_win()
	elif moves_left <= 0 and level.allow_fail:
		finished = true
		board.enabled = false
		result.show_fail(_missing_summary(), true)


func _objectives_met() -> bool:
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
				parts.append("%d %s" % [left, KuihLibrary.get_name(id)])
	if parts.is_empty() and level.require_blockers_cleared and board.logic != null:
		var leftover := board.logic.remaining_blockers()
		if leftover > 0:
			parts.append("%d still covered" % leftover)
	if parts.is_empty():
		return "So close! One more try."
	return "Still need: " + ", ".join(parts)


func _win() -> void:
	if finished:
		return
	finished = true
	board.enabled = false
	var stars := 3 if level.always_three_stars else level.stars_for_moves_left(moves_left)
	var coins := level.coin_reward()
	var unlocks: Array[StringName] = []
	var is_new_best := false

	if is_tutorial:
		# Tutorial stages never touch the campaign progress.
		EconomyManager.add_coins(coins)
		ProgressionManager.save_tutorial_index(level.tutorial_index)
	else:
		var previous_best := ProgressionManager.stars_for(level.id)
		is_new_best = stars > previous_best
		ProgressionManager.record_win(level.id, stars, moves_left)
		ProgressionManager.record_win_count()
		EconomyManager.add_coins(coins)
		if level.kuih_unlock != &"" and KuihLibrary.has(level.kuih_unlock):
			unlocks.append(level.kuih_unlock)
		if level.recipe_unlock != &"" and ProgressionManager.unlock_recipe(level.recipe_unlock):
			unlocks.append(level.recipe_unlock)
		if level.id == LevelLibrary.CHAPTER_FINALE:
			ProgressionManager.unlock_chapter(&"map")

	GameManager.pending_stars = stars
	GameManager.pending_coins = coins
	GameManager.pending_moves_left = moves_left
	GameManager.pending_unlocks = unlocks
	GameManager.report_result(true)

	hud.set_coins(EconomyManager.coins())
	result.show_win(level.title, stars, coins, unlocks, is_new_best)

	if not is_tutorial and level.story_after != &"":
		if not ProgressionManager.story_seen(level.story_after):
			ProgressionManager.mark_story_seen(level.story_after)
			story.play(BeatLibrary.get_beat(level.story_after))


# --- boosters --------------------------------------------------------------

func _on_booster_requested(booster: int) -> void:
	if _pause_overlay != null or finished or _serving or board == null or board.busy or not board.enabled:
		return
	board.cancel_targeting()
	_hide_target_prompt()
	match booster:
		EconomyManager.Booster.SHUFFLE:
			if not EconomyManager.use_booster(booster):
				return
			await board.booster_shuffle()
		EconomyManager.Booster.GIFT:
			var order := active_order()
			var wanted: Array = []
			if order != null:
				for id in order.item_ids():
					if int(order.remaining.get(id, 0)) > 0:
						wanted.append(id)
			if wanted.is_empty():
				return
			if not EconomyManager.use_booster(booster):
				return
			await board.booster_gift(wanted)
		EconomyManager.Booster.EXTRA_MOVES:
			if not EconomyManager.use_booster(booster):
				return
			_grant_moves(EXTRA_MOVES)
		EconomyManager.Booster.SPATULA, EconomyManager.Booster.TRAY:
			if not EconomyManager.has_booster(booster):
				return
			_show_target_prompt(booster)
			board.begin_targeting(booster)
		_:
			return
	hud.booster_bar.refresh()


func _show_target_prompt(booster: int) -> void:
	_target_label.text = "Tap a kuih to scoop it out" if booster == EconomyManager.Booster.SPATULA else "Tap the middle of the 3 x 3 area"
	_target_banner.visible = true
	_target_banner.pivot_offset = Vector2(410, 42)
	_target_banner.scale = Vector2(0.8, 0.8)
	var tw := _target_banner.create_tween()
	tw.tween_property(_target_banner, "scale", Vector2.ONE, 0.26).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _hide_target_prompt() -> void:
	_target_banner.visible = false


func _on_booster_targeted(booster: int, pos: Vector2i) -> void:
	if _pause_overlay != null or finished or _serving or board == null or board.busy or not board.enabled:
		return
	if booster not in [EconomyManager.Booster.SPATULA, EconomyManager.Booster.TRAY]:
		return
	if not board.logic.is_inside(pos):
		return
	if booster == EconomyManager.Booster.SPATULA and not board.logic.is_playable(pos):
		return
	_hide_target_prompt()
	board.cancel_targeting()
	hud.booster_bar.cancel_selection()
	if not EconomyManager.use_booster(booster):
		return
	if booster == EconomyManager.Booster.SPATULA:
		if not board.logic.is_playable(pos):
			return
		await board.booster_scoop(pos)
	elif booster == EconomyManager.Booster.TRAY:
		pos.x = clampi(pos.x, 1, board.logic.width - 2)
		pos.y = clampi(pos.y, 1, board.logic.height - 2)
		await board.booster_tray(pos)
	hud.booster_bar.refresh()


func _grant_moves(amount: int) -> void:
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
	if board.show_hint():
		AudioManager.play(AudioManager.Sfx.TAP, 1.2, -6.0)


# --- flow ------------------------------------------------------------------

func _open_pause_menu() -> void:
	if finished or _pause_overlay != null:
		return
	AudioManager.play(AudioManager.Sfx.TAP)
	var overlay := Control.new()
	_pause_overlay = overlay
	overlay.process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	var dim := ColorRect.new()
	dim.color = Color(0.15, 0.10, 0.05, 0.74)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(center)
	var card := UIKit.card(Vector2(840, 0))
	center.add_child(card)
	var stack := UIKit.vbox(16)
	card.add_child(stack)
	stack.add_child(UIKit.title("Paused", 68))
	stack.add_child(UIKit.label("%s  ·  %s" % [level.title, level.tag], 28, Palette.INK_SOFT))
	var resume := UIKit.primary_button("Resume")
	resume.pressed.connect(func() -> void:
		AudioManager.play(AudioManager.Sfx.TAP)
		_resume_level()
	)
	stack.add_child(resume)
	var quit := UIKit.button("Quit" if is_tutorial else "Quit to Stall", 32, Palette.WOOD_LIGHT)
	quit.pressed.connect(func() -> void:
		AudioManager.play(AudioManager.Sfx.TAP)
		_resume_level()
		finished = true
		board.enabled = false
		GameManager.go_home()
	)
	stack.add_child(quit)
	_root.add_child(overlay)
	get_tree().paused = true
	SaveManager._flush()


func _resume_level() -> void:
	if _pause_overlay == null:
		return
	get_tree().paused = false
	_pause_overlay.queue_free()
	_pause_overlay = null


func _exit_tree() -> void:
	if _pause_overlay != null:
		get_tree().paused = false


func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_PAUSED and is_inside_tree():
		if SceneManager.is_current(self):
			_open_pause_menu()


func _on_restart() -> void:
	if _pause_overlay != null or finished or _serving or board.busy:
		return
	AudioManager.play(AudioManager.Sfx.TAP)
	_start_level()


func _on_result_continue() -> void:
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
		var next := level.tutorial_index + 1
		if TutorialLibrary.has(next):
			GameManager.play_tutorial(next)
		else:
			ProgressionManager.complete_tutorial()
			# The prologue is replayed as a recap now that the player has read it
			# once, so Skip is offered - the first read is the only forced one.
			SceneManager.goto_story(
				StoryLibrary.PROLOGUE,
				ProgressionManager.story_read(StoryLibrary.PROLOGUE),
				SceneManager.HOME
			)
		return
	var next_level := level.id + 1
	if LevelLibrary.has_level(next_level):
		GameManager.play_level(next_level)
	else:
		GameManager.go_journey()


func _on_result_retry() -> void:
	_start_level()


func _on_result_home() -> void:
	GameManager.go_home()


func _on_watch_ad() -> void:
	_on_result_continue()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("go_back"):
		_open_pause_menu()
	elif event.is_action_pressed("restart_level"):
		_on_restart()
	elif event.is_action_pressed("show_hint"):
		_on_hint()
