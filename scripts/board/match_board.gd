class_name MatchBoard
extends Control

## Temporary visual option: keeps the board rim/backing while hiding individual pockets.
@export var show_slot_background := false:
	set(value):
		show_slot_background = value
		if is_instance_valid(_slots):
			_slots.queue_redraw()

## Board view and game feel layer.
##
## Owns no rules - [BoardState] does. This node translates player input into
## logic calls, then animates every step of the resolution with bounce, squash,
## slide and cascade timing (Master Plan sections 16 and 17).

signal move_committed()
signal kuih_collected(totals: Dictionary)
signal blocker_progress(hits: Array)
signal target_progress(entries: Array)
signal special_built(pos: Vector2i)
signal settled()
signal booster_targeted(booster: int, pos: Vector2i)
## Emitted for every swap the player attempts, accepted or not, so the tutorial
## coach can give corrective feedback without ever blocking input.
signal swap_attempted(from: Vector2i, to: Vector2i, accepted: bool)
## Emitted when a special tile is created by a match.
signal special_created(kind: int)
signal special_activated(kind: int)
signal special_effect_preview(kind: int, cells: Array[Vector2i])
signal clear_resolved(result: BoardState.ClearResult, cascade: int)

const CROSS_PACKAGE_ART = preload("res://assets/specials/utensils_v1/roller.png")

const SWIPE_RATIO := 0.32
const DOUBLE_TAP_MS := 350
const SWAP_TIME := 0.15
const INVALID_TIME := 0.26
const CLEAR_TIME := 0.18
const FALL_TIME := 0.15
const SPAWN_TIME := 0.19
const BLOCKER_TIME := 0.30
const SETTLE_TIME := 0.06

var logic: BoardState = null
var busy: bool = true
var enabled: bool = false

var cell_size: float = 128.0
var board_origin: Vector2 = Vector2.ZERO
var frame_padding: float = 16.0

var _slots: Control
var _tiles: Dictionary = {}      # Vector2i -> TileView
var _overlays: Dictionary = {}   # Vector2i -> OverlayView
var _selected: Vector2i = Vector2i(-1, -1)
var _drag_from: Vector2i = Vector2i(-1, -1)
var _drag_start: Vector2 = Vector2.ZERO
var _drag_moved: bool = false
var _hint_cells: Array[Vector2i] = []
const AUTO_HINT_DELAY := 2.5
var auto_hints := false
var _idle_seconds := 0.0
var _hint_matches: Array[Vector2i] = []
var _idle_hint := false
var swap_filter: Callable
var activation_filter: Callable
var _last_tap_cell := Vector2i(-1, -1)
var _last_tap_ms := -1
var _guide_layer: Control
var _focus_cells: Array[Vector2i] = []
var _swipe_indicator: SwipeIndicator
var _delivery_text_shown := false
var _hold_created_specials := false
var _blast_preview: Array[Vector2i] = []
var _feedback_origin := Vector2(-1, -1)
var _feedback: MatchFeedback
var _combo_praise: ComboPraise
var _special_text: SpecialExecutionText
var _vfx: GameVfx
var _guide_time := 0.0
var _shake_tween: Tween
var _shake_origin := Vector2.ZERO
var targeting: int = -1


## Puts the board into booster targeting mode: the next tap is a target cell.
func begin_targeting(booster: int) -> void:
	_last_tap_ms = -1
	targeting = booster
	_clear_selection()


func cancel_targeting() -> void:
	targeting = -1


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	clip_contents = true
	resized.connect(_relayout)
	_vfx = GameVfx.new()
	_vfx.z_index = 15
	add_child(_vfx)
	_feedback = MatchFeedback.new()
	add_child(_feedback)
	_combo_praise = ComboPraise.new()
	add_child(_combo_praise)
	_special_text = SpecialExecutionText.new()
	add_child(_special_text)


func _process(delta: float) -> void:
	if auto_hints:
		if not enabled or busy or targeting >= 0 or _drag_from.x >= 0 or not bool(GameManager.setting("show_hints",true)):
			if not _hint_cells.is_empty():
				clear_hints()
			_idle_seconds = 0.0
		elif _hint_cells.is_empty() or _idle_hint:
			_idle_seconds += delta
			if _idle_seconds >= AUTO_HINT_DELAY:
				show_hint()
				_idle_seconds = 0.0
	if _guide_layer != null and _focus_cells.size() == 2:
		_guide_time += delta
		_guide_layer.queue_redraw()


# --- construction ----------------------------------------------------------

func build(level: LevelDefinition) -> void:
	auto_hints = level.tutorial_index == 0
	if _combo_praise != null:
		_combo_praise.reset()
	_last_tap_ms = -1
	_stop_burst_shake()
	if _special_text != null:
		_special_text.reset()
	if _feedback != null:
		_feedback.reset()
	if _vfx != null:
		_vfx.reset()
	_hold_created_specials = level.tutorial_index in [4, 5, 9, 10, 11]
	_clear_selection()
	clear_hints()
	cancel_targeting()
	for child in _tiles.values():
		child.queue_free()
	for child in _overlays.values():
		child.queue_free()
	_tiles.clear()
	_overlays.clear()

	logic = BoardState.new()
	logic.delivery_enabled = level.tutorial_index in [9, 5, 7, 8] or (level.tutorial_index == 0 and ProgressionManager.delivery_unlocked())
	logic.setup(level.width, level.height, level.kuih)
	if not level.fixed_layout.is_empty():
		# A hand-authored layout is the lesson. Never shuffle it - some of them
		# have exactly one legal move on purpose.
		logic.apply_layout(level.fixed_layout)
	logic.apply_blockers(level.blockers)
	if level.tutorial_index == 11:
		logic.get_cell(Vector2i(1,1)).special = BoardCell.Special.TAPAU
		logic.get_cell(Vector2i(2,1)).special = BoardCell.Special.TAPAU_VERTICAL

	if _slots == null:
		_slots = Control.new()
		_slots.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_slots.draw.connect(_draw_slots)
		add_child(_slots)
	if _guide_layer == null:
		_guide_layer = Control.new()
		_guide_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_guide_layer.z_index = 20
		_guide_layer.draw.connect(_draw_guide)
		add_child(_guide_layer)
	if _swipe_indicator == null:
		_swipe_indicator = SwipeIndicator.new()
		_swipe_indicator.board = self
		add_child(_swipe_indicator)

	_layout_metrics()
	if _slots != null:
		_slots.size = size
	for y in logic.height:
		for x in logic.width:
			var pos := Vector2i(x, y)
			_sync_overlay(pos)
			_sync_tile(pos)
	if level.fixed_layout.is_empty() and not logic.has_possible_move():
		logic.shuffle_board()
		_refresh_tiles()
	_relayout()
	busy = false
	enabled = true


## Consume optional starting specials only after the campaign board exists.
func apply_start_specials(picks: Array[int]) -> void:
	var candidates: Array[Vector2i] = []
	for y in logic.height:
		for x in logic.width:
			var pos := Vector2i(x, y)
			if logic.get_cell(pos).is_playable():
				candidates.append(pos)
	if candidates.size() < picks.size():
		return
	for booster in picks:
		if not EconomyManager.has_booster(booster):
			return
	candidates.shuffle()
	for booster in picks:
		var pos: Vector2i = candidates.pop_back()
		if EconomyManager.use_booster(booster):
			logic.get_cell(pos).special = BoardCell.Special.DULANG if booster == EconomyManager.Booster.TRAY else BoardCell.Special.TAPAU
			_sync_tile(pos)


func _layout_metrics() -> void:
	if logic == null:
		return
	frame_padding = clampf(minf(size.x, size.y) * .024, 12, 28)
	var usable := size - Vector2.ONE * frame_padding * 2
	cell_size = minf(usable.x / float(logic.width), usable.y / float(logic.height))
	cell_size = floorf(cell_size)
	var used := Vector2(cell_size * float(logic.width), cell_size * float(logic.height))
	board_origin = ((size - used) * 0.5).round()


func cell_to_pos(pos: Vector2i) -> Vector2:
	return board_origin + Vector2(float(pos.x) * cell_size, float(pos.y) * cell_size)


func pos_to_cell(local: Vector2) -> Vector2i:
	var rel := (local - board_origin) / cell_size
	if rel.x < 0.0 or rel.y < 0.0:
		return Vector2i(-1, -1)
	var c := Vector2i(int(floor(rel.x)), int(floor(rel.y)))
	if c.x < 0 or c.y < 0 or c.x >= logic.width or c.y >= logic.height:
		return Vector2i(-1, -1)
	return c


func _relayout() -> void:
	if logic == null:
		return
	_layout_metrics()
	if _slots != null:
		_slots.position = Vector2.ZERO
		_slots.size = size
		_slots.queue_redraw()
	for key in _tiles:
		var tile: TileView = _tiles[key]
		tile.size = Vector2(cell_size, cell_size)
		tile.pivot_offset = Vector2(cell_size, cell_size) * 0.5
		tile.position = cell_to_pos(key)
	for key in _overlays:
		var overlay: OverlayView = _overlays[key]
		overlay.size = Vector2(cell_size, cell_size)
		overlay.pivot_offset = Vector2(cell_size, cell_size) * 0.5
		overlay.position = cell_to_pos(key)


func _sync_tile(pos: Vector2i) -> void:
	var cell := logic.get_cell(pos)
	if cell == null:
		return
	var tile: TileView = _tiles.get(pos, null)
	if not cell.has_kuish():
		if tile != null:
			_tiles.erase(pos)
			tile.queue_free()
		return
	if tile == null:
		tile = TileView.new()
		tile.size = Vector2(cell_size, cell_size)
		tile.pivot_offset = Vector2(cell_size, cell_size) * 0.5
		tile.position = cell_to_pos(pos)
		add_child(tile)
		_tiles[pos] = tile
	tile.set_cell(cell)


func _sync_overlay(pos: Vector2i) -> void:
	var cell := logic.get_cell(pos)
	var overlay: OverlayView = _overlays.get(pos, null)
	if cell == null or not cell.has_obstacle():
		if overlay != null:
			_overlays.erase(pos)
			overlay.queue_free()
		return
	if overlay == null:
		overlay = OverlayView.new()
		overlay.size = Vector2(cell_size, cell_size)
		overlay.pivot_offset = Vector2(cell_size, cell_size) * 0.5
		overlay.position = cell_to_pos(pos)
		add_child(overlay)
		_overlays[pos] = overlay
		# pop in so placed obstacles read as "new"
		overlay.scale = Vector2(0.5, 0.5)
		overlay.modulate.a = 0.0
		var tw := overlay.create_tween()
		tw.set_parallel(true)
		tw.tween_property(overlay, "scale", Vector2.ONE, 0.32).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tw.tween_property(overlay, "modulate:a", 1.0, 0.32)
	overlay.kind = cell.blocker_kind
	overlay.max_hp = maxi(cell.blocker_hp, 1)
	overlay.hp = cell.blocker_hp
	overlay.need = cell.target_need
	overlay.progress = cell.target_progress
	overlay.target_kuih = KuihLibrary.get_kuih(cell.target_kuish) if cell.target_kuish != &"" else null


func _draw_slots() -> void:
	if logic == null:
		return
	var board_rect := Rect2(board_origin, Vector2(cell_size * logic.width, cell_size * logic.height))
	var frame_rect := board_rect.grow(frame_padding * .90)
	BoardSkin.draw_softwood(_slots, frame_rect, board_rect, logic.width, logic.height, frame_padding)
	if show_slot_background:
		var slot_art := BoardSkin.texture("slot")
		for y in logic.height:
			for x in logic.width:
				var pocket := Rect2(cell_to_pos(Vector2i(x, y)), Vector2.ONE * cell_size)
				_slots.draw_texture_rect(slot_art, pocket.grow(-cell_size * .025), false)
	BoardSkin.draw_frame(_slots, frame_rect, frame_padding * .82)


# --- input -----------------------------------------------------------------

## The OS may swallow touch-up when a call interrupts a gesture.
## Discard the gesture without changing an in-flight resolution or booster mode.
func cancel_interrupted_input() -> void:
	_drag_from = Vector2i(-1, -1)
	_drag_start = Vector2.ZERO
	_drag_moved = false
	_last_tap_cell = Vector2i(-1, -1)
	_last_tap_ms = -1
	_clear_selection()


func _gui_input(event: InputEvent) -> void:
	if (event is InputEventScreenTouch and event.pressed) or (event is InputEventMouseButton and event.pressed):
		clear_hints()
	# Touch-up can arrive while the swap animation is busy. Always end the
	# gesture, otherwise the idle timer keeps treating it as an active drag.
	if _is_tap_release(event):
		_drag_from = Vector2i(-1, -1)
	if not enabled or busy or logic == null:
		if _is_tap_release(event):
			_drag_moved = false
		return
	if targeting >= 0:
		if _is_tap_release(event):
			var tap := _tap_position(event)
			var cell := pos_to_cell(tap)
			if cell.x >= 0:
				var booster := targeting
				targeting = -1
				booster_targeted.emit(booster, cell)
		accept_event()
		return
	if event is InputEventScreenTouch:
		var touch := event as InputEventScreenTouch
		if touch.pressed:
			_drag_start = touch.position
			_drag_from = pos_to_cell(touch.position)
			_drag_moved = false
		else:
			_finish_drag(touch.position)
		accept_event()
	elif event is InputEventScreenDrag:
		var drag := event as InputEventScreenDrag
		if _drag_moved or _drag_from.x < 0:
			return
		var delta := drag.position - _drag_start
		var threshold := cell_size * SWIPE_RATIO
		if delta.length() < threshold:
			return
		_drag_moved = true
		_last_tap_ms = -1
		var target := _drag_from
		if absf(delta.x) > absf(delta.y):
			target.x += 1 if delta.x > 0.0 else -1
		else:
			target.y += 1 if delta.y > 0.0 else -1
		_clear_selection()
		if logic.is_inside(target):
			attempt_swap(_drag_from, target)


func _is_tap_release(event: InputEvent) -> bool:
	if event is InputEventScreenTouch:
		return not (event as InputEventScreenTouch).pressed
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		return not mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT
	return false


func _tap_position(event: InputEvent) -> Vector2:
	if event is InputEventScreenTouch:
		return (event as InputEventScreenTouch).position
	if event is InputEventMouseButton:
		return (event as InputEventMouseButton).position
	return Vector2.ZERO


func _finish_drag(at: Vector2) -> void:
	_drag_from = Vector2i(-1, -1)
	if _drag_moved:
		_drag_moved = false
		return
	var cell := pos_to_cell(at)
	if cell.x < 0:
		_last_tap_ms = -1
		_clear_selection()
		return
	var now := Time.get_ticks_msec()
	var double_tap := cell == _last_tap_cell and _last_tap_ms >= 0 and now - _last_tap_ms <= DOUBLE_TAP_MS
	_last_tap_cell = cell
	_last_tap_ms = now
	if double_tap and logic.is_playable(cell) and logic.get_cell(cell).special != BoardCell.Special.NONE:
		_last_tap_ms = -1
		_clear_selection()
		attempt_activate(cell)
		return
	if _selected.x < 0:
		_select(cell)
		return
	if _selected == cell:
		_clear_selection()
		return
	# second tap: swap with the neighbour, if there is one
	var delta := cell - _selected
	if absi(delta.x) + absi(delta.y) == 1:
		var from := _selected
		_clear_selection()
		attempt_swap(from, cell)
		return
	_select(cell)


func _select(cell: Vector2i) -> void:
	_clear_selection()
	if not logic.is_playable(cell):
		return
	_selected = cell
	var tile: TileView = _tiles.get(cell, null)
	if tile != null:
		tile.selected = true
		tile.scale = Vector2(1.035, 1.035)
		var tw := tile.create_tween()
		tw.tween_property(tile, "scale", Vector2.ONE, 0.16).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _clear_selection() -> void:
	if _selected.x >= 0:
		var tile: TileView = _tiles.get(_selected, null)
		if tile != null:
			tile.selected = false
			tile.scale = Vector2.ONE
	_selected = Vector2i(-1, -1)


func clear_hints() -> void:
	_idle_seconds = 0.0
	_idle_hint = false
	_hint_matches.clear()
	_focus_cells.clear()
	if _swipe_indicator != null:
		_swipe_indicator.visible = false
	for tile in _tiles.values():
		tile.modulate = Color.WHITE
	if _guide_layer != null:
		_guide_layer.queue_redraw()
	for c in _hint_cells:
		var tile: TileView = _tiles.get(c, null)
		if tile != null:
			tile.hinted = false
	_hint_cells.clear()


func focus_cells(cells: Array[Vector2i]) -> void:
	highlight_cells(cells)
	_focus_cells.assign(cells)
	for pos in _tiles:
		_tiles[pos].modulate = Color.WHITE if pos in cells else Color(.38, .38, .38)
	_guide_layer.queue_redraw()
	if cells.size() == 2 and cells[0].distance_to(cells[1]) == 1:
		_swipe_indicator.show_swipe(cells[0], cells[1])


## Trace exposed cell edges as closed contours; shared edges disappear.
func _hint_outlines() -> Array[PackedVector2Array]:
	var edges: Dictionary = {}
	for pos in _hint_matches:
		var corners := [pos,pos+Vector2i.RIGHT,pos+Vector2i.ONE,pos+Vector2i.DOWN]
		var neighbours := [Vector2i.UP,Vector2i.RIGHT,Vector2i.DOWN,Vector2i.LEFT]
		for side in 4:
			if not _hint_matches.has(pos+neighbours[side]):
				edges[corners[side]] = corners[(side+1)%4]
	var outlines: Array[PackedVector2Array] = []
	while not edges.is_empty():
		var start: Vector2i = edges.keys()[0]
		var at := start
		var corners: Array[Vector2] = []
		while edges.has(at):
			corners.append(cell_to_pos(at))
			var next: Vector2i = edges[at]
			edges.erase(at)
			at = next
			if at == start:
				break
		if corners.size() < 3:
			continue
		var path := PackedVector2Array()
		for index in corners.size():
			var corner := corners[index]
			var previous := corners[(index+corners.size()-1)%corners.size()]
			var following := corners[(index+1)%corners.size()]
			var entry := corner+(previous-corner).normalized()*cell_size*.04
			var leave := corner+(following-corner).normalized()*cell_size*.04
			for step in 5:
				var t := float(step)/4.0
				path.append(entry.lerp(corner,t).lerp(corner.lerp(leave,t),t))
		path.append(path[0])
		outlines.append(path)
	return outlines


func _draw_guide() -> void:
	var shine := .65+.35*sin(_guide_time*TAU/1.2)
	for outline in _hint_outlines():
		_guide_layer.draw_polyline(outline,Color(1,.88,.4,.07*shine),cell_size*.22,true)
		_guide_layer.draw_polyline(outline,Color(1,.92,.55,.16*shine),cell_size*.13,true)
		_guide_layer.draw_polyline(outline,Color(1,.96,.72,.38*shine),cell_size*.065,true)
		_guide_layer.draw_polyline(outline,Color(1,1,.95,.85+.15*shine),cell_size*.025,true)
	if _focus_cells.size() != 2:
		return
	if _idle_hint:
		return
	for pos in _focus_cells:
		var box := Rect2(cell_to_pos(pos), Vector2.ONE * cell_size).grow(-cell_size * .04)
		_guide_layer.draw_style_box(UIKit.flat_box(Color.TRANSPARENT, Palette.GOLD_PALE, 0, 5, 18), box)
	var start := cell_to_pos(_focus_cells[0]) + Vector2.ONE * cell_size * .5
	var end := cell_to_pos(_focus_cells[1]) + Vector2.ONE * cell_size * .5
	var direction := (end - start).normalized()
	# Align the arrow with the centres of the two highlighted swipe cells.
	var arrow_size := Vector2(cell_size * .88, cell_size * .34)
	var nudge := sin(_guide_time * TAU / 1.4) * cell_size * .055
	_guide_layer.draw_set_transform((start + end) * .5 + direction * nudge, direction.angle())
	_guide_layer.draw_texture_rect(TutorialArt.texture("swipe_arrow_green"), Rect2(-arrow_size * .5, arrow_size), false)
	_guide_layer.draw_set_transform(Vector2.ZERO)


## Points the player's eye at specific cells without locking anything.
## Used by the tutorial coach, which stays deliberately soft.
func highlight_cells(cells: Array[Vector2i]) -> void:
	clear_hints()
	for c in cells:
		var pos: Vector2i = c
		if not logic.is_inside(pos):
			continue
		_hint_cells.append(pos)
		var tile: TileView = _tiles.get(pos, null)
		if tile != null:
			tile.start_hint_pulse()


func show_hint() -> bool:
	clear_hints()
	if logic == null or busy or not enabled:
		return false
	var moves := logic.find_possible_moves(logic.width*logic.height*2)
	if moves.is_empty():
		return false
	var pair: Dictionary = moves[0]
	# Prefer an ordinary match; special activation is a fallback when necessary.
	for candidate in moves:
		if logic.get_cell(candidate.a).special == BoardCell.Special.NONE and logic.get_cell(candidate.b).special == BoardCell.Special.NONE:
			pair = candidate
			break
	logic.swap_cells(pair.a,pair.b)
	for group in logic.find_matches():
		if not group.cells.has(pair.a) and not group.cells.has(pair.b):
			continue
		for pos in group.cells:
			if not _hint_matches.has(pos):
				_hint_matches.append(pos)
	logic.swap_cells(pair.a,pair.b)
	# Point towards the destination that forms the previewed match.
	_focus_cells.assign([pair.b,pair.a] if _hint_matches.has(pair.a) and not _hint_matches.has(pair.b) else [pair.a,pair.b])
	# Include the moving source along with the future match's destination cells.
	for pos in _focus_cells:
		if not _hint_matches.has(pos):
			_hint_matches.append(pos)
	_idle_hint = true
	_guide_time = 0.0
	_guide_layer.queue_redraw()
	for key in [pair["a"], pair["b"]]:
		var pos: Vector2i = key
		var tile: TileView = _tiles.get(pos, null)
		if tile == null:
			continue
		tile.hinted = true
		_hint_cells.append(pos)
		if pos == _focus_cells[0]:
			tile.start_hint_nudge(Vector2(_focus_cells[1]-_focus_cells[0]))
	return true


# --- move resolution -------------------------------------------------------

func attempt_swap(a: Vector2i, b: Vector2i) -> void:
	if busy or not enabled:
		return
	clear_hints()
	if swap_filter.is_valid() and not swap_filter.call(a, b):
		swap_attempted.emit(a, b, false)
		_play_invalid(a, b)
		return
	var outcome := logic.try_swap(a, b)
	swap_attempted.emit(a, b, outcome != BoardState.SwapOutcome.INVALID)
	if outcome == BoardState.SwapOutcome.INVALID:
		_play_invalid(a, b)
		return
	clear_hints()
	move_committed.emit()
	await _play_move(a, b, [] if outcome == BoardState.SwapOutcome.PLAYED else [a, b])


func _play_invalid(a: Vector2i, b: Vector2i) -> void:
	var tile_a: TileView = _tiles.get(a, null)
	var tile_b: TileView = _tiles.get(b, null)
	AudioManager.play(AudioManager.Sfx.INVALID)
	if tile_a == null or tile_b == null:
		return
	busy = true
	var pos_a := cell_to_pos(a)
	var pos_b := cell_to_pos(b)
	var tw_a := tile_a.create_tween()
	tw_a.tween_property(tile_a, "position", pos_a.lerp(pos_b, 0.35), INVALID_TIME * 0.5)
	tw_a.tween_property(tile_a, "position", pos_a, INVALID_TIME * 0.5)
	var tw_b := tile_b.create_tween()
	tw_b.tween_property(tile_b, "position", pos_b.lerp(pos_a, 0.35), INVALID_TIME * 0.5)
	tw_b.tween_property(tile_b, "position", pos_b, INVALID_TIME * 0.5)
	await tw_a.finished
	busy = false


## Direct activation shares the swap resolution pipeline and costs one move.
func attempt_activate(pos: Vector2i) -> void:
	if busy or not enabled or logic == null or targeting >= 0 or not logic.is_playable(pos):
		return
	var cell := logic.get_cell(pos)
	if cell.special == BoardCell.Special.NONE:
		return
	if activation_filter.is_valid() and not activation_filter.call(pos):
		return
	_last_tap_ms = -1
	if cell.special == BoardCell.Special.HANTAR:
		cell.order_kuish = logic.delivery_local_kuih(pos)
	clear_hints()
	move_committed.emit()
	await _play_move(pos, pos, [pos], false)


func _play_move(a: Vector2i, b: Vector2i, special_positions: Array, perform_swap: bool = true) -> void:
	_delivery_text_shown = false
	busy = true
	_last_tap_ms = -1
	_clear_selection()
	if perform_swap:
		await _animate_swap(a, b)
		AudioManager.play(AudioManager.Sfx.SWAP)

	var step := 0
	var preferred: Array = [a, b] if perform_swap else []
	var activated: Array[int] = []
	for pos in special_positions:
		var kind := int(logic.get_cell(pos).special)
		if kind != BoardCell.Special.NONE and not activated.has(kind):
			activated.append(kind)
	# Outline the actual affected cells before they disappear. The Dulang
	# effect used to look like a normal match followed immediately by refill.
	for pos in special_positions:
		var cell := logic.get_cell(pos)
		if cell.special == BoardCell.Special.DULANG:
			_blast_preview.assign(logic._blast_cells(pos, cell))
			_guide_layer.queue_redraw()
			special_effect_preview.emit(cell.special, _blast_preview.duplicate())
			await _wait(.65 if _hold_created_specials else .3)
	while true:
		var result: BoardState.ClearResult
		if special_positions.is_empty():
			result = logic.resolve(preferred)
		else:
			result = logic.activate_specials(special_positions)
			special_positions = []
			preferred = []
		if result.is_empty():
			break
		await _play_step(result, step)
		preferred = [] # Refill cascades must not inherit the player's swipe.
		# Preserve the lesson's newly made special for the player's next swap.
		# Refill matches resolve with that activation, rather than detonating it
		# in an automatic cascade before Aina can explain how to use it.
		if _hold_created_specials and not result.created.is_empty():
			break
		step += 1
		if step > 40:
			break

	if not logic.has_possible_move():
		await _play_shuffle()

	for kind in activated:
		special_activated.emit(kind)
	busy = false
	settled.emit()


func _animate_swap(a: Vector2i, b: Vector2i) -> void:
	var tile_a: TileView = _tiles.get(a, null)
	var tile_b: TileView = _tiles.get(b, null)
	if tile_a == null or tile_b == null:
		_swap_keys(a, b)
		_refresh_tiles()
		return
	var pos_a := cell_to_pos(a)
	var pos_b := cell_to_pos(b)
	var tw_a := tile_a.create_tween()
	tw_a.tween_property(tile_a, "position", pos_b, SWAP_TIME).set_trans(Tween.TRANS_QUAD)
	var tw_b := tile_b.create_tween()
	tw_b.tween_property(tile_b, "position", pos_a, SWAP_TIME).set_trans(Tween.TRANS_QUAD)
	await tw_a.finished
	_swap_keys(a, b)
	_refresh_tiles()


func _swap_keys(a: Vector2i, b: Vector2i) -> void:
	var tile_a: TileView = _tiles.get(a, null)
	var tile_b: TileView = _tiles.get(b, null)
	_tiles[a] = tile_b
	_tiles[b] = tile_a
	if tile_b != null:
		tile_b.position = cell_to_pos(a)
	if tile_a != null:
		tile_a.position = cell_to_pos(b)


func _refresh_tiles() -> void:
	for y in logic.height:
		for x in logic.width:
			var pos := Vector2i(x, y)
			var tile: TileView = _tiles.get(pos, null)
			var cell := logic.get_cell(pos)
			if cell == null or not cell.has_kuish():
				if tile != null:
					_tiles.erase(pos)
					tile.queue_free()
				continue
			if tile == null:
				_sync_tile(pos)
			else:
				tile.set_cell(cell)
				tile.position = cell_to_pos(pos)


## Briefly merge the directional tiles into the original Tapau graphic.
## This presentation never changes the logical special types or clear payload.
func _animate_cross_package(result: BoardState.ClearResult) -> TextureRect:
	var destination := cell_to_pos(result.combo_origin)
	var merge := create_tween().set_parallel(true)
	for pos in result.combo_members:
		var tile: TileView = _tiles.get(pos, null)
		if tile != null:
			merge.tween_property(tile, "position", destination, .12).set_trans(Tween.TRANS_QUAD)
			merge.tween_property(tile, "scale", Vector2.ONE*.55, .12)
			merge.tween_property(tile, "modulate:a", 0.0, .12)
	await merge.finished
	var package := TextureRect.new()
	package.name = "CrossComboRoller"
	var cropped := AtlasTexture.new()
	cropped.atlas = CROSS_PACKAGE_ART
	cropped.region = Rect2(40,66,1176,1120)
	package.texture = cropped
	package.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	package.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	package.mouse_filter = Control.MOUSE_FILTER_IGNORE
	package.size = Vector2.ONE*cell_size
	package.position = destination
	package.pivot_offset = package.size*.5
	package.z_index = 20
	package.scale = Vector2.ONE*.45
	package.modulate.a = 0.0
	add_child(package)
	var pop := package.create_tween().set_parallel(true)
	pop.tween_property(package, "scale", Vector2.ONE*1.15, .16).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	pop.tween_property(package, "modulate:a", 1.0, .10)
	pop.set_parallel(false)
	pop.tween_property(package, "scale", Vector2.ONE, .10).set_trans(Tween.TRANS_SINE)
	pop.tween_interval(.14)
	await pop.finished
	return package


func _play_step(result: BoardState.ClearResult, step: int) -> void:
	_feedback_origin = Vector2.ZERO
	for pos in result.cleared:
		_feedback_origin += _cell_center(pos)
	_feedback_origin = _feedback_origin / result.cleared.size() if not result.cleared.is_empty() else size * .5
	clear_resolved.emit(result, step)
	var activation_waves: Dictionary = {}
	for activation in result.activated:
		var depth: int = activation.get("chain_depth", 0)
		if not activation_waves.has(depth):
			activation_waves[depth] = []
		activation_waves[depth].append(activation)
	var cross_package: TextureRect = null
	if result.combo == &"sweet_cross":
		cross_package = await _animate_cross_package(result)
		var cross_points := PackedVector2Array()
		for pos in result.combo_cells:
			cross_points.append(_cell_center(pos))
		cross_package.hide()
		_vfx.cross(_cell_center(result.combo_origin), cross_points, cell_size)
		AudioManager.play(AudioManager.Sfx.CROSS_BLAST, 1.0, -4)
		await _wait(.30)
	elif result.combo == &"order_wipe":
		_animate_order_art(result.combo_members.keys(),result.combo_cells)
		var wipe_points := PackedVector2Array()
		for pos in result.combo_cells:
			wipe_points.append(_cell_center(pos))
		_vfx.order_electric(_cell_center(result.combo_origin), wipe_points, cell_size)
		AudioManager.play_special(BoardCell.Special.ORDER)
	elif result.combo == &"order_conversion":
		await _animate_order_conversion(result)
	# Show each hit triggering the next specials, instead of firing the entire
	# chain at once. All affected tiles remain visible until the waves finish.
	var depths: Array = activation_waves.keys()
	depths.sort()
	var pulled: Dictionary = {}
	for depth in depths:
		var wave: Array = activation_waves[depth]
		var wave_kinds: Array = []
		for activation in wave:
			wave_kinds.append(activation.kind)
		await _animate_delivery_cross(result,wave)
		if not wave_kinds.has(BoardCell.Special.DULANG):
			_special_text.show_wave(wave_kinds,size,cell_size)
		var launched := 0
		var pickup_cells: Array[Vector2i] = []
		if int(depth) == 0 and result.combo == &"triple_delivery":
			for member in result.combo_members:
				var drone_tile: TileView = _tiles.get(member,null)
				if drone_tile != null:
					drone_tile.visible = false
			for target in result.delivery_targets:
				_vfx.delivery(_cell_center(result.combo_origin), _cell_center(target), cell_size,_delivery_payload(result,target))
				pickup_cells.append(target)
				launched += 1
		var dulang_centers: Array[Vector2i] = []
		var double_dulang := int(depth) == 0 and result.combo == &"rounded_dulang"
		if double_dulang:
			dulang_centers.append(result.combo_origin)
			for member in result.combo_members:
				if _tiles.has(member):
					_tiles[member].visible = false
		for activation in wave:
			if activation.kind == BoardCell.Special.HANTAR and activation.cells.size() > 1 and not result.combo_members.has(activation.pos):
				if launched < 8:
					var drone_tile: TileView = _tiles.get(activation.pos,null)
					if drone_tile != null:
						drone_tile.visible = false
					var target: Vector2i = activation.cells.back()
					_vfx.delivery(_cell_center(activation.pos), _cell_center(target), cell_size,_delivery_payload(result,target))
					pickup_cells.append(target)
				launched += 1
			if activation.kind == BoardCell.Special.DULANG and not result.combo_members.has(activation.pos):
				dulang_centers.append(activation.pos)
		if launched > 0:
			# One soft rotor per wave also bounds the triple-delivery mix.
			AudioManager.play(AudioManager.Sfx.HANTAR_LAUNCH, 1, -11)
			await _wait(.45)
			for target in pickup_cells:
				if _delivery_payload(result,target) != null and _tiles.has(target):
					_tiles[target].visible = false
			AudioManager.play(AudioManager.Sfx.HANTAR_HIT, 1, -9)
			await _wait(.15)
			AudioManager.play(AudioManager.Sfx.HANTAR_EXIT, 1, -11)
			# The drone's exit is presentation only. Resolve the holes while it
			# flies away instead of holding the board for another half second.
		if not dulang_centers.is_empty():
			await _charge_dulang(dulang_centers, result, double_dulang)
		if double_dulang:
			var combo_points := PackedVector2Array()
			for pos in result.combo_cells:
				combo_points.append(_cell_center(pos))
			_vfx.dulang_burst(_cell_center(result.combo_origin), combo_points, cell_size, true)
			_burst_shake()
			AudioManager.play_special(BoardCell.Special.DULANG)
		if wave_kinds.has(BoardCell.Special.DULANG):
			# Keep the loaded tray visible; announce Dulang at the explosion.
			_special_text.show_wave(wave_kinds,size,cell_size,double_dulang)
		var heard: Dictionary = {}
		for activation in wave:
			var points := PackedVector2Array()
			for pos in activation.cells:
				points.append(_cell_center(pos))
			if not result.combo_members.has(activation.pos):
				if activation.kind == BoardCell.Special.DULANG:
					_burst_shake()
				var effect_origin := _cell_center(activation.pos)
				if activation.kind == BoardCell.Special.ORDER:
					_animate_order_art([activation.pos],activation.cells)
				if activation.kind in [BoardCell.Special.TAPAU,BoardCell.Special.TAPAU_VERTICAL]:
					var directional_tile: TileView = _tiles.get(activation.pos,null)
					if directional_tile != null:
						directional_tile.animate_directional_activation()
				_vfx.special(effect_origin, activation.kind, points, cell_size)
			if not heard.has(activation.kind):
				heard[activation.kind] = true
				if activation.kind != BoardCell.Special.HANTAR and not result.combo_members.has(activation.pos):
					AudioManager.play_special(activation.kind)
		AudioManager.haptic(35, .5)
		# Let the gold light reach all nine slots before continuing the chain.
		var has_tapau := wave_kinds.has(BoardCell.Special.TAPAU) or wave_kinds.has(BoardCell.Special.TAPAU_VERTICAL)
		var drone_only := not wave_kinds.is_empty()
		for kind in wave_kinds:
			if kind != BoardCell.Special.HANTAR:
				drone_only = false
		await _wait(.04 if drone_only else ((.48 if double_dulang else .16) if _hold_created_specials and not dulang_centers.is_empty() else (.12 if not dulang_centers.is_empty() else (.18 if has_tapau else .14))))
		var wave_pulls := await _pull_order_targets(result,wave,pulled,.0 if not dulang_centers.is_empty() else .14)
		pulled.merge(wave_pulls)
	if is_instance_valid(cross_package):
		cross_package.queue_free()
	# 1. new special tiles announce themselves
	if not result.created.is_empty():
		# Keep the original kuih visible while their light gathers, then
		# reveal the special at the matched group's origin.
		for created in result.created:
			var points := PackedVector2Array()
			for pos in _formation_cells(result, created.pos):
				points.append(_cell_center(pos))
			_vfx.special_formation(_cell_center(created.pos), points, cell_size, created.special)
		await _wait(.22)
		var has_delivery := false
		for created in result.created:
			if created.special == BoardCell.Special.HANTAR:
				has_delivery = true
				_show_delivery_created(created.pos)
		AudioManager.play(AudioManager.Sfx.HANTAR_CREATE if has_delivery else AudioManager.Sfx.SPECIAL)
		var shaken: Dictionary = {}
		for created in result.created:
			shaken[created.pos] = true
		for entry in result.created:
			var pos: Vector2i = entry["pos"]
			# A newly made special can stay in the same cell during gravity.
			# Refresh its cached icon now; falling/refill alone will not repaint it.
			var tile: TileView = _tiles.get(pos, null)
			if tile != null:
				tile.set_cell(logic.get_cell(pos))
			special_created.emit(int(entry["special"]))
			special_built.emit(pos)
			if tile == null:
				continue
			tile.scale = Vector2.ONE*(1.2 if int(entry["special"]) == BoardCell.Special.DULANG else 1.45)
			var tw := tile.create_tween()
			tw.tween_property(tile, "scale", Vector2.ONE, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
			for dy in range(-1, 2):
				for dx in range(-1, 2):
					var neighbour := pos + Vector2i(dx, dy)
					if neighbour == pos or shaken.has(neighbour) or result.cleared.has(neighbour):
						continue
					var nearby: TileView = _tiles.get(neighbour, null)
					if nearby != null and nearby.visible and nearby.cell != null and nearby.cell.has_kuish():
						nearby.play_formation_shake()
						shaken[neighbour] = true
			_burst(cell_to_pos(pos) + Vector2(cell_size, cell_size) * 0.5, Palette.GOLD_PALE, 8)
	else:
		AudioManager.play_match(step)
		AudioManager.haptic(12, 0.25)

	# 2. clear
	var cleared_tiles: Array[TileView] = []
	var dissolve_items: Array[Dictionary] = []
	for pos in result.cleared:
		var tile: TileView = _tiles.get(pos, null)
		if tile != null:
			# Drone pickups have already hidden their tiles. Order pulls emit
			# particles at their destination during the pull animation instead.
			if not pulled.has(pos) and tile.visible and tile.modulate.a > .01:
				dissolve_items.append({"at": _cell_center(pos), "color": _sparkle_color(result, pos)})
			if pulled.has(pos):
				tile.queue_free()
			else:
				cleared_tiles.append(tile)
			_tiles.erase(pos)
	_vfx.kuih_dissolve(dissolve_items, cell_size)
	await _play_clear(cleared_tiles, false)
	if not _blast_preview.is_empty():
		# Keep the empty 3Ãƒâ€”3 area visible before gravity/refill hides it.
		await _wait(.45 if _hold_created_specials else .15)
		_blast_preview.clear()
		_guide_layer.queue_redraw()

	# 3. blockers and packaging targets react to what was collected
	await _play_blockers(result.blockers)
	if not result.targets.is_empty():
		_play_targets(result.targets)
		target_progress.emit(result.targets)

	# 4. report the kuih the player actually earned
	if not result.cleared.is_empty():
		kuih_collected.emit(result.collected_totals())

	# 5. fall + refill, then let cascades resolve
	await _play_fall_and_refill()
	await _wait(SETTLE_TIME)


func _formation_cells(result: BoardState.ClearResult, origin: Vector2i) -> Array[Vector2i]:
	# Connected runs cover L/T matches and squares without lighting an
	# unrelated simultaneous match elsewhere on the board.
	var group: Array[Vector2i] = [origin]
	var changed := true
	while changed:
		changed = false
		for run in result.match_runs:
			var connects := false
			for pos in run.cells:
				if group.has(pos):
					connects = true
					break
			if connects:
				for pos in run.cells:
					if not group.has(pos):
						group.append(pos)
						changed = true
	return group


func _show_delivery_created(pos: Vector2i) -> void:
	if _delivery_text_shown:
		return
	_delivery_text_shown = true
	var text := UIKit.label("PESANAN HANTAR!", 34, Palette.GOLD_PALE)
	text.add_theme_color_override("font_outline_color", Palette.WOOD_DARK)
	text.add_theme_constant_override("outline_size", 5)
	text.mouse_filter = Control.MOUSE_FILTER_IGNORE
	text.z_index = 30
	add_child(text)
	text.size = Vector2(minf(size.x, cell_size * 3.2), 55)
	text.position = Vector2(clampf(_cell_center(pos).x - text.size.x*.5, 0, size.x-text.size.x), maxf(0, _cell_center(pos).y - cell_size*.6))
	text.pivot_offset = text.size*.5
	text.scale = Vector2.ONE*.5
	text.modulate.a = 0
	var tween := text.create_tween()
	tween.set_parallel(true)
	tween.tween_property(text, "scale", Vector2.ONE*1.2, .08)
	tween.tween_property(text, "modulate:a", 1, .08)
	tween.chain().tween_property(text, "scale", Vector2.ONE*.95, .10)
	tween.set_parallel(false)
	tween.tween_property(text, "scale", Vector2.ONE, .12)
	tween.tween_interval(.20)
	tween.set_parallel(true)
	tween.tween_property(text, "position:y", text.position.y-25, .4)
	tween.tween_property(text, "modulate:a", 0, .4)
	tween.chain().tween_callback(text.queue_free)

func _animate_delivery_cross(result: BoardState.ClearResult, wave: Array) -> void:
	var pickups: Dictionary = {}
	for activation in wave:
		if activation.kind != BoardCell.Special.HANTAR:
			continue
		var targets := PackedVector2Array()
		for pos in logic.delivery_cross(activation.pos):
			if pos == activation.pos or pos not in activation.cells or pickups.has(pos) or _delivery_payload(result,pos) == null or not _tiles.has(pos):
				continue
			if not _tiles[pos].visible:
				continue
			pickups[pos] = activation.pos
			targets.append(_cell_center(pos))
		if not targets.is_empty():
			_vfx.delivery_cross(_cell_center(activation.pos),targets,cell_size)
	if pickups.is_empty():
		return
	await _wait(.22)
	AudioManager.play(AudioManager.Sfx.HANTAR_HIT,1,-8)
	for pos in pickups:
		var tile: TileView = _tiles[pos]
		tile.z_index = 12
		var pull := tile.create_tween().set_parallel(true)
		pull.tween_property(tile,"position",cell_to_pos(pickups[pos]),.28).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		pull.tween_property(tile,"scale",Vector2.ONE*.15,.28)
		pull.tween_property(tile,"modulate:a",0.0,.12).set_delay(.16)
	await _wait(.28)
	for pos in pickups:
		_tiles[pos].visible = false
	await _wait(.08)


func _animate_order_conversion(result: BoardState.ClearResult) -> void:
	_animate_order_art(result.combo_members.keys(),result.converted)
	var points := PackedVector2Array()
	for pos in result.converted:
		points.append(_cell_center(pos))
	_vfx.order_electric(_cell_center(result.combo_origin),points,cell_size)
	AudioManager.play_special(BoardCell.Special.ORDER)
	await _wait(.25)
	for pos in result.converted:
		var tile: TileView = _tiles.get(pos,null)
		if tile == null:
			continue
		var visual := BoardCell.new()
		visual.kuih = result.cleared[pos].kuih
		visual.special = result.conversion_kinds.get(pos,result.conversion_kind)
		tile.set_cell(visual)
		var pop := tile.create_tween()
		pop.tween_property(tile,"scale",Vector2.ONE*1.20,.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		pop.tween_property(tile,"scale",Vector2.ONE,.12).set_trans(Tween.TRANS_SINE)
	await _wait(.30)


func _animate_order_art(origins: Array, targets: Array) -> void:
	for pos in origins:
		var tile: TileView = _tiles.get(pos,null)
		if tile != null and tile.icon.special_kind == BoardCell.Special.ORDER:
			tile.animate_order_activation()
	for pos in targets:
		if not origins.has(pos):
			var tile: TileView = _tiles.get(pos,null)
			if tile != null and tile.visible:
				tile.animate_electric_flash()


func _delivery_payload(result: BoardState.ClearResult, pos: Vector2i) -> Texture2D:
	var info: BoardState.ClearInfo = result.cleared.get(pos,null)
	return info.kuih.texture if info != null and not info.by_special and info.kuih != null else null


func _sparkle_color(result: BoardState.ClearResult, pos: Vector2i) -> Color:
	var info: BoardState.ClearInfo = result.cleared.get(pos, null)
	if info != null and info.kuih != null:
		return info.kuih.detail
	return Palette.WHITE

func _pull_order_targets(result: BoardState.ClearResult, wave: Array, already_pulled: Dictionary, charge_delay: float) -> Dictionary:
	var pulls: Dictionary = {}
	var special_origins: Dictionary = {}
	for activation in result.activated:
		special_origins[activation.pos] = true
	for activation in wave:
		if activation.kind != BoardCell.Special.ORDER:
			continue
		for pos in activation.cells:
			if result.cleared.has(pos) and not special_origins.has(pos) and not pulls.has(pos) and not already_pulled.has(pos) and _tiles.has(pos) and _tiles[pos].visible:
				pulls[pos] = cell_to_pos(result.combo_origin if result.combo == &"order_wipe" else activation.pos)
	if pulls.is_empty():
		return pulls
	# The first .18 seconds already played the electrical connection cue.
	if charge_delay > 0:
		await _wait(charge_delay)
	for pos in pulls:
		var tile: TileView = _tiles[pos]
		tile.z_index = 12
		var tween := tile.create_tween().set_parallel(true)
		tween.tween_property(tile,"position",pulls[pos],.42).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		tween.tween_property(tile,"scale",Vector2.ONE*.12,.42).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		tween.tween_property(tile,"modulate:a",0.0,.18).set_delay(.24)
	await _wait(.24)
	var dissolve_items: Array[Dictionary] = []
	for pos in pulls:
		var tile: TileView = _tiles[pos]
		dissolve_items.append({"at": tile.position + Vector2.ONE * cell_size * .5, "color": _sparkle_color(result, pos)})
	_vfx.kuih_dissolve(dissolve_items, cell_size, 0)
	await _wait(.18)
	return pulls


func _play_clear(tiles: Array[TileView], play_pack_sound: bool = true) -> void:
	if tiles.is_empty():
		await _wait(CLEAR_TIME * 0.4)
		return
	for tile in tiles:
		tile.z_index = 4
		var tw := tile.create_tween()
		tw.set_parallel(true)
		tw.tween_property(tile, "scale", Vector2(1.35, 1.35), CLEAR_TIME * 0.35).set_trans(Tween.TRANS_QUAD)
		tw.chain().tween_property(tile, "scale", Vector2(0.05, 0.05), CLEAR_TIME * 0.55).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
		tw.parallel().tween_property(tile, "modulate:a", 0.0, CLEAR_TIME)
	if play_pack_sound:
		AudioManager.play(AudioManager.Sfx.PACK, randf_range(0.95, 1.12), -8.0)
	var tw2 := create_tween()
	tw2.tween_interval(CLEAR_TIME * 0.9)
	await tw2.finished
	for tile in tiles:
		if is_instance_valid(tile):
			tile.queue_free()


func _play_blockers(hits: Array) -> void:
	if hits.is_empty():
		return
	AudioManager.play(AudioManager.Sfx.DROP, randf_range(0.9, 1.1), -6.0)
	for hit in hits:
		var overlay: OverlayView = _overlays.get(hit.pos, null)
		if overlay == null:
			continue
		if hit.removed:
			if hit.kind == BlockerSpec.Kind.BANANA_LEAF:
				var revealed: TileView = _tiles.get(hit.pos,null)
				if revealed != null:
					revealed.reveal_leaf_item()
				_vfx.burst(_cell_center(hit.pos),Color("fff5b0"),6,cell_size*.25)
			overlay.hp = 0
			var tw := overlay.create_tween()
			tw.set_parallel(true)
			tw.tween_property(overlay, "scale", Vector2(1.4, 1.4), BLOCKER_TIME * 0.5).set_trans(Tween.TRANS_QUAD)
			tw.chain().tween_property(overlay, "scale", Vector2(0.1, 0.1), BLOCKER_TIME * 0.5)
			tw.parallel().tween_property(overlay, "modulate:a", 0.0, BLOCKER_TIME)
			_burst(cell_to_pos(hit.pos) + Vector2(cell_size, cell_size) * 0.5, Palette.LEAF_LIGHT, 7)
			_overlays.erase(hit.pos)
			overlay.queue_free()
		else:
			overlay.hp = hit.hp_left
			overlay.scale = Vector2(1.25, 0.8)
			var tw := overlay.create_tween()
			tw.tween_property(overlay, "scale", Vector2.ONE, 0.22).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	var tw2 := create_tween()
	tw2.tween_interval(BLOCKER_TIME)
	await tw2.finished
	blocker_progress.emit(hits)


func _play_targets(entries: Array) -> void:
	for entry in entries:
		var pos: Vector2i = entry.pos
		var overlay: OverlayView = _overlays.get(pos, null)
		if overlay == null:
			continue
		overlay.progress = entry.progress
		if entry.done:
			_burst(cell_to_pos(pos) + Vector2(cell_size, cell_size) * 0.5, Palette.GOLD_PALE, 10)
			_overlays.erase(pos)
			var tw := overlay.create_tween()
			tw.tween_property(overlay, "scale", Vector2(0.2, 0.2), 0.26).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
			tw.parallel().tween_property(overlay, "modulate:a", 0.0, 0.26)
			tw.tween_callback(overlay.queue_free)
		else:
			overlay.scale = Vector2(1.18, 1.18)
			var tw := overlay.create_tween()
			tw.tween_property(overlay, "scale", Vector2.ONE, 0.2).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)


## Existing kuih and fresh entries share one fall, preserving their column order.
func _play_fall_and_refill() -> void:
	var moves := logic.apply_gravity()
	var spawns := logic.refill()
	await _animate_falls(moves, spawns)

func _play_gravity() -> void:
	await _animate_falls(logic.apply_gravity(), [])

func _play_refill() -> void:
	await _animate_falls([], logic.refill())

func _animate_falls(moves: Array, spawns: Array) -> void:
	var entries: Array[Dictionary] = []
	var distances: Dictionary = {}
	var spawn_counts: Dictionary = {}
	for entry in spawns:
		spawn_counts[entry.pos.x] = int(spawn_counts.get(entry.pos.x, 0)) + 1
	for move in moves:
		var tile: TileView = _tiles.get(move.from, null)
		_tiles.erase(move.from)
		if tile == null:
			_sync_tile(move.to)
			continue
		_tiles[move.to] = tile
		tile.set_cell(logic.get_cell(move.to))
		entries.append({"tile": tile, "from": cell_to_pos(move.from), "to": move.to})
		distances[move.to.x] = maxf(distances.get(move.to.x, 0.0), move.to.y - move.from.y)
	for entry in spawns:
		var existing: TileView = _tiles.get(entry.pos, null)
		if existing != null:
			existing.set_cell(logic.get_cell(entry.pos))
			continue
		var tile := TileView.new()
		tile.size = Vector2.ONE * cell_size
		tile.set_cell(logic.get_cell(entry.pos))
		add_child(tile)
		_tiles[entry.pos] = tile
		var distance: int = spawn_counts[entry.pos.x]
		entries.append({"tile": tile, "from": cell_to_pos(entry.pos - Vector2i(0, distance)), "to": entry.pos})
		distances[entry.pos.x] = maxf(distances.get(entry.pos.x, 0.0), distance)
	if entries.is_empty():
		return
	var longest := 0.0
	for entry in entries:
		var tile: TileView = entry.tile
		var destination: Vector2i = entry.to
		var duration := clampf(.12 + sqrt(float(distances[destination.x])) * .045, FALL_TIME, .34)
		var delay := float(destination.x % 3) * .018
		longest = maxf(longest, duration + delay)
		tile.position = entry.from
		tile.scale = Vector2.ONE
		tile.modulate.a = 1.0
		tile.z_index = 3
		var tween := tile.create_tween()
		tween.tween_interval(delay)
		tween.tween_property(tile, "position", cell_to_pos(destination), duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		tween.tween_callback(_land_tile.bind(tile))
	# Wait for the slowest column and its landing, not the first tile's tween.
	await _wait(longest + .11)
	AudioManager.play(AudioManager.Sfx.DROP, randf_range(.96, 1.04), -14.0)

func _land_tile(tile: TileView) -> void:
	if not is_instance_valid(tile):
		return
	tile.z_index = 0
	tile.scale = Vector2(1.07, .93)
	var landing := tile.create_tween()
	landing.tween_property(tile, "scale", Vector2.ONE, .10).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _play_shuffle() -> void:
	var changes := logic.shuffle_board()
	if changes.is_empty():
		return
	for entry in changes:
		var pos: Vector2i = entry["pos"]
		var tile: TileView = _tiles.get(pos, null)
		var cell := logic.get_cell(pos)
		if tile == null:
			_sync_tile(pos)
			continue
		tile.set_cell(cell)
		tile.position = cell_to_pos(pos)
		tile.scale = Vector2(0.1, 0.1)
		var delay := randf() * 0.14
		var tw := tile.create_tween()
		tw.tween_interval(delay)
		tw.tween_property(tile, "scale", Vector2.ONE, 0.30).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	await _wait(0.34)


# --- boosters --------------------------------------------------------------

## Sudip: scoop one kuih out of the board (Master Plan section 38).
func booster_scoop(pos: Vector2i) -> void:
	if busy or not enabled or logic == null or not logic.is_playable(pos):
		return
	busy = true
	_vfx.scoop(_cell_center(pos), cell_size)
	AudioManager.play(AudioManager.Sfx.SPATULA, 1.0, -5)
	var cell := logic.get_cell(pos)
	_report_booster_clear([pos])
	var totals := {cell.kuish_id(): 1}
	logic.get_cell(pos).clear_kuish()
	var tile: TileView = _tiles.get(pos, null)
	if tile != null:
		_tiles.erase(pos)
		var tw := tile.create_tween()
		tw.set_parallel(true)
		tw.tween_property(tile, "position", tile.position + Vector2(0, -cell_size * 1.6), 0.28).set_trans(Tween.TRANS_BACK)
		tw.tween_property(tile, "scale", Vector2(0.2, 0.2), 0.28)
		tw.parallel().tween_property(tile, "modulate:a", 0.0, 0.28)
		tw.chain().tween_callback(tile.queue_free)
	kuih_collected.emit(totals)
	await _wait(0.30)
	await _finish_booster()


## Dulang: scoop a whole 3x3 area.
func booster_tray(center: Vector2i) -> void:
	if busy or not enabled or logic == null or not logic.is_inside(center):
		return
	busy = true
	await _charge_dulang([center])
	_burst_shake()
	var totals: Dictionary = {}
	var tiles: Array[TileView] = []
	var affected := PackedVector2Array()
	for dy in range(-1, 2):
		for dx in range(-1, 2):
			var pos := center + Vector2i(dx, dy)
			if not logic.is_playable(pos):
				continue
			var c := logic.get_cell(pos)
			var id := c.kuish_id()
			totals[id] = int(totals.get(id, 0)) + 1
			affected.append(_cell_center(pos))
			c.clear_kuish()
			var tile: TileView = _tiles.get(pos, null)
			if tile != null:
				tiles.append(tile)
				_tiles.erase(pos)
	_vfx.special(_cell_center(center), BoardCell.Special.DULANG, affected, cell_size)
	AudioManager.play_special(BoardCell.Special.DULANG)
	_report_booster_clear(_tiles_from_points(affected))
	await _wait(.12)
	await _play_clear(tiles)
	kuih_collected.emit(totals)
	await _wait(0.30)
	await _finish_booster()


## Tapau: auto-collect every tile the current order still needs.
func booster_gift(wanted: Array) -> void:
	if busy or not enabled or logic == null or wanted.is_empty():
		return
	busy = true
	var tiles: Array[TileView] = []
	var affected := PackedVector2Array()
	var totals: Dictionary = {}
	for y in logic.height:
		for x in logic.width:
			var pos := Vector2i(x, y)
			if not logic.is_playable(pos):
				continue
			var c := logic.get_cell(pos)
			if not wanted.has(c.kuish_id()):
				continue
			totals[c.kuish_id()] = int(totals.get(c.kuish_id(), 0)) + 1
			affected.append(_cell_center(pos))
			c.clear_kuish()
			var tile: TileView = _tiles.get(pos, null)
			if tile != null:
				tiles.append(tile)
				_tiles.erase(pos)
	if tiles.is_empty():
		busy = false
		return
	_vfx.special(size * .5, BoardCell.Special.ORDER, affected, cell_size)
	AudioManager.play_special(BoardCell.Special.ORDER)
	_report_booster_clear(_tiles_from_points(affected))
	await _play_clear(tiles)
	kuih_collected.emit(totals)
	await _wait(0.28)
	await _finish_booster()


func booster_shuffle() -> void:
	if busy or not enabled or logic == null:
		return
	busy = true
	_vfx.shuffle(Rect2(Vector2.ZERO, size), cell_size)
	AudioManager.play(AudioManager.Sfx.SHUFFLE, 1.0, -5.0)
	await _play_shuffle()
	busy = false
	settled.emit()


## Refill and resolve cascades before accepting another player action.
func _finish_booster() -> void:
	await _play_fall_and_refill()
	var step := 0
	while step < 40:
		var result := logic.resolve([])
		if result.is_empty():
			break
		await _play_step(result, step)
		step += 1
	if not logic.has_possible_move():
		await _play_shuffle()
	busy = false
	settled.emit()


func collect_all() -> Dictionary:
	if logic == null:
		return {}
	var totals: Dictionary = {}
	for key in _tiles:
		var tile: TileView = _tiles[key]
		if tile != null and tile.cell != null and tile.cell.kuih != null:
			var id := tile.cell.kuish_id()
			totals[id] = int(totals.get(id, 0)) + 1
	return totals


# --- helpers ---------------------------------------------------------------

func _wait(seconds: float) -> void:
	var tw := create_tween()
	tw.tween_interval(seconds)
	await tw.finished


func show_score_feedback(points: int, cascade: int, multiplier: float = 1.0) -> void:
	_feedback.show_clear(points, cascade, size, multiplier, _feedback_origin)
	_combo_praise.show_combo(cascade+1,size)
	if cascade+1 in [3,4,5]:
		_feedback.position.y = size.y*.32

func _tiles_from_points(points: PackedVector2Array) -> Array:
	var cells: Array = []
	for at in points:
		cells.append(Vector2i(((at - board_origin) / cell_size).floor()))
	return cells

func _report_booster_clear(cells: Array) -> void:
	var cleared := BoardState.ClearResult.new()
	for pos in cells:
		cleared.cleared[pos] = BoardState.ClearInfo.new()
	clear_resolved.emit(cleared, 0)


func _cell_center(pos: Vector2i) -> Vector2:
	return cell_to_pos(pos) + Vector2.ONE * cell_size * .5

func _burst(at: Vector2, color: Color, count: int = 6, scale_mul: float = 1.0) -> void:
	if _vfx != null:
		_vfx.burst(at, color, count, cell_size * .5 * scale_mul)


func _charge_dulang(centers: Array[Vector2i], result: BoardState.ClearResult = null, double_blast: bool = false) -> void:
	if double_blast:
		# One vocal per combined reveal; ordinary Badak activations stay silent.
		var voice_cue := create_tween()
		voice_cue.tween_interval(.12)
		voice_cue.tween_callback(func() -> void: AudioManager.play(AudioManager.Sfx.PUTERI_VOCAL,1.0,-5.0))
	var gathered: Dictionary = {}
	for center in centers:
		var points := PackedVector2Array()
		var foods: Array[Dictionary] = []
		var mask := BoardState.DULANG_DOUBLE_MASK if double_blast else BoardState.DULANG_SINGLE_MASK
		for pos in logic.area_mask_cells(center,mask):
			points.append(_cell_center(pos))
			var food_tile: TileView = _tiles.get(pos)
			if food_tile == null or not food_tile.visible or gathered.has(pos):
				continue
			var data: KuihData = null
			if result != null:
				var info: BoardState.ClearInfo = result.cleared.get(pos)
				if info != null and not info.by_special:
					data = info.kuih
			elif logic.is_playable(pos) and logic.get_cell(pos).special == BoardCell.Special.NONE:
				data = logic.get_cell(pos).kuih
			if data != null and data.texture != null:
				foods.append({"at": _cell_center(pos), "texture": data.texture})
				gathered[pos] = true
				food_tile.visible = false
		_vfx.dulang_charge(_cell_center(center),points,cell_size,foods,double_blast)
		var tile: TileView = _tiles.get(center)
		if is_instance_valid(tile) and tile.icon.special_kind == BoardCell.Special.DULANG:
			tile.visible = false
	await _wait(.64 if double_blast else .18)

func _stop_burst_shake() -> void:
	if _shake_tween != null and _shake_tween.is_valid():
		_shake_tween.kill()
		position = _shake_origin
	_shake_tween = null

func _burst_shake() -> void:
	_stop_burst_shake()
	_shake_origin = position
	_shake_tween = create_tween()
	for offset in [Vector2(3,-2),Vector2(-2,1),Vector2(1,0),Vector2.ZERO]:
		_shake_tween.tween_property(self,"position",_shake_origin+offset,.03).set_trans(Tween.TRANS_SINE)
