class_name MatchBoard
extends Control

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

const SWIPE_RATIO := 0.32
const SWAP_TIME := 0.15
const INVALID_TIME := 0.26
const CLEAR_TIME := 0.24
const FALL_TIME := 0.20
const SPAWN_TIME := 0.26
const BLOCKER_TIME := 0.30
const SETTLE_TIME := 0.09

var logic: BoardState = null
var busy: bool = true
var enabled: bool = false

var cell_size: float = 128.0
var board_origin: Vector2 = Vector2.ZERO

var _slots: Control
var _tiles: Dictionary = {}      # Vector2i -> TileView
var _overlays: Dictionary = {}   # Vector2i -> OverlayView
var _selected: Vector2i = Vector2i(-1, -1)
var _drag_from: Vector2i = Vector2i(-1, -1)
var _drag_start: Vector2 = Vector2.ZERO
var _drag_moved: bool = false
var _hint_cells: Array[Vector2i] = []
var targeting: int = -1


## Puts the board into booster targeting mode: the next tap is a target cell.
func begin_targeting(booster: int) -> void:
	targeting = booster
	_clear_selection()


func cancel_targeting() -> void:
	targeting = -1


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	clip_contents = true
	resized.connect(_relayout)


# --- construction ----------------------------------------------------------

func build(level: LevelDefinition) -> void:
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
	logic.setup(level.width, level.height, level.kuih)
	if not level.fixed_layout.is_empty():
		# A hand-authored layout is the lesson. Never shuffle it - some of them
		# have exactly one legal move on purpose.
		logic.apply_layout(level.fixed_layout)
	logic.apply_blockers(level.blockers)

	if _slots == null:
		_slots = Control.new()
		_slots.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_slots.draw.connect(_draw_slots)
		add_child(_slots)

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


func _layout_metrics() -> void:
	if logic == null:
		return
	cell_size = minf(size.x / float(logic.width), size.y / float(logic.height))
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
	var sb := StyleBoxFlat.new()
	sb.bg_color = Palette.BOARD_CELL_DEEP
	sb.set_corner_radius_all(int(cell_size * 0.18))
	sb.shadow_color = Color(0.2, 0.3, 0.1, 0.20)
	sb.shadow_size = 4
	sb.shadow_offset = Vector2(0, 2)
	var tray := StyleBoxFlat.new()
	tray.bg_color = Palette.WOOD
	tray.set_corner_radius_all(int(cell_size * 0.22))
	tray.border_color = Palette.WOOD_DARK
	tray.set_border_width_all(6)
	var frame := Rect2(
		board_origin - Vector2(cell_size * 0.10, cell_size * 0.10),
		Vector2(cell_size * float(logic.width), cell_size * float(logic.height)) + Vector2(cell_size * 0.20, cell_size * 0.20)
	)
	_slots.draw_style_box(tray, frame)
	for y in logic.height:
		for x in logic.width:
			var r := Rect2(cell_to_pos(Vector2i(x, y)), Vector2(cell_size, cell_size))
			_slots.draw_style_box(sb, r.grow(-cell_size * 0.045))


# --- input -----------------------------------------------------------------

func _gui_input(event: InputEvent) -> void:
	if not enabled or busy or logic == null:
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
		if _drag_moved:
			return
		var delta := drag.position - _drag_start
		var threshold := cell_size * SWIPE_RATIO
		if delta.length() < threshold:
			return
		_drag_moved = true
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
	if _drag_moved:
		_drag_moved = false
		return
	var cell := pos_to_cell(at)
	if cell.x < 0:
		_clear_selection()
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
		tile.scale = Vector2(1.12, 1.12)
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
	for c in _hint_cells:
		var tile: TileView = _tiles.get(c, null)
		if tile != null:
			tile.hinted = false
	_hint_cells.clear()


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
	var moves := logic.find_possible_moves(1)
	if moves.is_empty():
		return false
	var pair: Dictionary = moves[0]
	for key in [pair["a"], pair["b"]]:
		var pos: Vector2i = key
		var tile: TileView = _tiles.get(pos, null)
		if tile == null:
			continue
		tile.hinted = true
		_hint_cells.append(pos)
		tile.start_hint_pulse()
	return true


# --- move resolution -------------------------------------------------------

func attempt_swap(a: Vector2i, b: Vector2i) -> void:
	if busy or not enabled:
		return
	var outcome := logic.try_swap(a, b)
	swap_attempted.emit(a, b, outcome != BoardState.SwapOutcome.INVALID)
	if outcome == BoardState.SwapOutcome.INVALID:
		_play_invalid(a, b)
		return
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


func _play_move(a: Vector2i, b: Vector2i, special_positions: Array) -> void:
	busy = true
	_clear_selection()
	await _animate_swap(a, b)
	AudioManager.play(AudioManager.Sfx.SWAP)

	var step := 0
	var preferred: Array = [a, b]
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
		step += 1
		if step > 40:
			break

	if not logic.has_possible_move():
		await _play_shuffle()

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


func _play_step(result: BoardState.ClearResult, step: int) -> void:
	# 1. new special tiles announce themselves
	if not result.created.is_empty():
		AudioManager.play(AudioManager.Sfx.SPECIAL)
		for entry in result.created:
			var pos: Vector2i = entry["pos"]
			special_created.emit(int(entry["special"]))
			special_built.emit(pos)
			var tile: TileView = _tiles.get(pos, null)
			if tile == null:
				continue
			tile.scale = Vector2(1.45, 1.45)
			var tw := tile.create_tween()
			tw.tween_property(tile, "scale", Vector2.ONE, 0.28).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
			_burst(cell_to_pos(pos) + Vector2(cell_size, cell_size) * 0.5, Palette.GOLD_PALE, 8)
	else:
		AudioManager.play_match(step)
		AudioManager.haptic(12, 0.25)

	# 2. clear
	var cleared_tiles: Array[TileView] = []
	for pos in result.cleared:
		var tile: TileView = _tiles.get(pos, null)
		if tile != null:
			cleared_tiles.append(tile)
			_tiles.erase(pos)
		if randf() < 0.34:
			var p := cell_to_pos(pos) + Vector2(randf_range(0.2, 0.8), randf_range(0.2, 0.8)) * cell_size
			_burst(p, _sparkle_color(result, pos), 5, 0.6)
	await _play_clear(cleared_tiles)

	# 3. blockers and packaging targets react to what was collected
	await _play_blockers(result.blockers)
	if not result.targets.is_empty():
		_play_targets(result.targets)
		target_progress.emit(result.targets)

	# 4. report the kuih the player actually earned
	if not result.cleared.is_empty():
		kuih_collected.emit(result.collected_totals())

	# 5. fall + refill, then let cascades resolve
	await _play_gravity()
	await _play_refill()
	await _wait(SETTLE_TIME)


func _sparkle_color(result: BoardState.ClearResult, pos: Vector2i) -> Color:
	var info: BoardState.ClearInfo = result.cleared.get(pos, null)
	if info != null and info.kuih != null:
		return info.kuih.detail
	return Palette.WHITE


func _play_clear(tiles: Array[TileView]) -> void:
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


func _play_gravity() -> void:
	var moves := logic.apply_gravity()
	if moves.is_empty():
		return
	var tweens: Array[Tween] = []
	for move in moves:
		# `from` is the cell the kuih is leaving, `to` is where it lands. The view
		# has to be fetched by `from`: looking it up by `to` grabs an empty cell,
		# erases the real entry and orphans the falling tile, which leaves the cell
		# blank and lets the next spawn stack a second kuih on top of it.
		var tile: TileView = _tiles.get(move.from, null)
		_tiles.erase(move.from)
		if tile == null:
			# The logic moved a kuih we have no view for. Build one already in
			# place rather than leaving the cell empty for good.
			_sync_tile(move.to)
			continue
		_tiles[move.to] = tile
		tile.set_cell(logic.get_cell(move.to))
		tile.position = cell_to_pos(move.from)
		tile.z_index = 3
		var tw := tile.create_tween()
		tw.tween_property(
			tile, "position", cell_to_pos(move.to), FALL_TIME
		).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		tweens.append(tw)
		tw.tween_callback(func() -> void:
			if is_instance_valid(tile):
				tile.z_index = 0
				tile.scale = Vector2(1.12, 0.88)
				var land := tile.create_tween()
				land.tween_property(tile, "scale", Vector2.ONE, 0.16).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		)
	if not tweens.is_empty():
		await tweens[0].finished
	AudioManager.play(AudioManager.Sfx.DROP, randf_range(0.95, 1.05), -12.0)


func _play_refill() -> void:
	var spawns := logic.refill()
	if spawns.is_empty():
		return
	var tweens: Array[Tween] = []
	for entry in spawns:
		var existing: TileView = _tiles.get(entry.pos, null)
		if existing != null:
			# A view is already sitting here. Refresh it in place instead of adding
			# a second one, which would draw two kuih on the same kuih.
			existing.set_cell(logic.get_cell(entry.pos))
			continue
		var cell := logic.get_cell(entry.pos)
		var tile := TileView.new()
		tile.size = Vector2(cell_size, cell_size)
		tile.pivot_offset = Vector2(cell_size, cell_size) * 0.5
		tile.set_cell(cell)
		tile.position = cell_to_pos(entry.pos) - Vector2(0, cell_size * 1.2)
		add_child(tile)
		_tiles[entry.pos] = tile
		tile.scale = Vector2(0.8, 0.8)
		tile.modulate.a = 0.0
		var tw := tile.create_tween()
		tw.set_parallel(true)
		tw.tween_property(tile, "position", cell_to_pos(entry.pos), SPAWN_TIME).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tw.tween_property(tile, "modulate:a", 1.0, SPAWN_TIME * 0.6)
		tw.tween_property(tile, "scale", Vector2.ONE, SPAWN_TIME)
		tweens.append(tw)
	if not tweens.is_empty():
		await tweens[0].finished


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
	var cell := logic.get_cell(pos)
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
	var totals: Dictionary = {}
	var tiles: Array[TileView] = []
	for dy in range(-1, 2):
		for dx in range(-1, 2):
			var pos := center + Vector2i(dx, dy)
			if not logic.is_playable(pos):
				continue
			var c := logic.get_cell(pos)
			var id := c.kuish_id()
			totals[id] = int(totals.get(id, 0)) + 1
			c.clear_kuish()
			var tile: TileView = _tiles.get(pos, null)
			if tile != null:
				tiles.append(tile)
				_tiles.erase(pos)
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
			c.clear_kuish()
			var tile: TileView = _tiles.get(pos, null)
			if tile != null:
				tiles.append(tile)
				_tiles.erase(pos)
	if tiles.is_empty():
		busy = false
		return
	await _play_clear(tiles)
	kuih_collected.emit(totals)
	await _wait(0.28)
	await _finish_booster()


func booster_shuffle() -> void:
	if busy or not enabled or logic == null:
		return
	busy = true
	AudioManager.play(AudioManager.Sfx.SWAP, 0.8, -4.0)
	await _play_shuffle()
	busy = false
	settled.emit()


## Refill and resolve cascades before accepting another player action.
func _finish_booster() -> void:
	await _play_gravity()
	await _play_refill()
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


func _burst(at: Vector2, color: Color, count: int = 6, scale_mul: float = 1.0) -> void:
	var dots := ColorRect.new()
	dots.color = color
	dots.size = Vector2(14, 14) * scale_mul
	dots.pivot_offset = dots.size * 0.5
	dots.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(dots)
	dots.position = at - dots.size * 0.5
	var tw := dots.create_tween()
	tw.set_parallel(true)
	for i in count:
		var angle := float(i) * TAU / float(count) + randf() * 0.5
		var dist := randf_range(cell_size * 0.35, cell_size * 0.8) * scale_mul
		tw.tween_property(dots, "position", at - dots.size * 0.5 + Vector2(cos(angle), sin(angle)) * dist, 0.42)
	tw.tween_property(dots, "scale", Vector2(0.15, 0.15), 0.42)
	tw.parallel().tween_property(dots, "modulate:a", 0.0, 0.42)
	tw.chain().tween_callback(dots.queue_free)
