class_name BoardState
extends RefCounted

## Pure match-3 logic for an 8x8 kuih board.
##
## Deliberately node-free: no tweens, no timers, no signals. The view
## (`scripts/board/match_board.gd`) drives the resolution step by step so it can
## animate swap -> clear -> fall -> refill -> cascade with full game feel
## (Master Plan sections 11, 15, 16 and 17).

enum SwapOutcome {
	INVALID,          ## Rejected - play the bounce-back animation.
	PLAYED,           ## Normal match; call [method resolve].
	ACTIVATED_SPECIAL,## At least one special was swapped; call [method activate_specials].
}

const MIN_MATCH := 3
const DULANG_SINGLE_MASK := [[1,1,1], [1,1,1], [1,1,1]]
const DULANG_DOUBLE_MASK := [[0,1,1,1,0], [1,1,1,1,1], [1,1,1,1,1], [1,1,1,1,1], [0,1,1,1,0]]
const SHUFFLE_MAX_ATTEMPTS := 60


# --- Result payloads -------------------------------------------------------

class MatchRun extends RefCounted:
	var cells: Array[Vector2i] = []
	var horizontal: bool = true
	var square: bool = false


class MatchGroup extends RefCounted:
	var runs: Array[MatchRun] = []
	var cells: Dictionary = {}
	var special: int = BoardCell.Special.NONE
	var origin: Vector2i = Vector2i(-1, -1)

	func has(pos: Vector2i) -> bool:
		return cells.has(pos)


class FallMove extends RefCounted:
	var from: Vector2i = Vector2i.ZERO
	var to: Vector2i = Vector2i.ZERO
	var kuih: KuihData = null


class SpawnEntry extends RefCounted:
	var pos: Vector2i = Vector2i.ZERO
	var kuih: KuihData = null


class ClearInfo extends RefCounted:
	var kuih: KuihData = null
	var by_special: bool = false
	var source: int = BoardCell.Special.NONE


class BlockerHit extends RefCounted:
	var pos: Vector2i = Vector2i.ZERO
	var kind: int = -1
	var removed: bool = false
	var hp_left: int = 0


class TargetProgress extends RefCounted:
	var pos: Vector2i = Vector2i.ZERO
	var kuih_id: StringName = &""
	var progress: int = 0
	var need: int = 0
	var done: bool = false


class ClearResult extends RefCounted:
	## Vector2i -> [ClearInfo]
	var cleared: Dictionary = {}
	## Array of { pos, special, kuih } for freshly created special tiles.
	var created: Array[Dictionary] = []
	var match_runs: Array[MatchRun] = []
	## Activation entries include chain_depth for ordered visual waves.
	var activated: Array[Dictionary] = []
	var blockers: Array[BlockerHit] = []
	var targets: Array[TargetProgress] = []
	var direct_blocker_hits: Dictionary = {}
	var combo: StringName = &""
	var combo_origin := Vector2i(-1,-1)
	var combo_members: Dictionary = {}
	var combo_cells: Array[Vector2i] = []
	var delivery_targets: Array[Vector2i] = []
	var converted: Array[Vector2i] = []
	var conversion_kind: int = BoardCell.Special.NONE
	var conversion_kuih: StringName = &""

	func is_empty() -> bool:
		return cleared.is_empty() and blockers.is_empty() and targets.is_empty()

	func has_tiles() -> bool:
		return not cleared.is_empty()

	func collected_totals() -> Dictionary:
		var totals: Dictionary = {}
		for pos in cleared:
			var info: ClearInfo = cleared[pos]
			if info == null or info.kuih == null:
				continue
			totals[info.kuih.id] = int(totals.get(info.kuih.id, 0)) + 1
		return totals

	func collected_count() -> int:
		return cleared.size()


# --- Board state -----------------------------------------------------------

var width: int = 8
var height: int = 8
## grid[y][x] -> BoardCell
var grid: Array = []
var pool: Array[KuihData] = []
## id -> KuihData, so shuffling never has to reach back into the library.
var pool_by_id: Dictionary = {}
var rng := RandomNumberGenerator.new()
var shuffles_used: int = 0
var delivery_enabled := false
var order_remaining: Dictionary = {}
# Target priorities live in logic and can be configured independently of VFX.
var delivery_priorities: Array[StringName] = [&"order", &"blocker", &"objective", &"useful"]
## Emitted whenever a match creates a special tile, so the tutorial coach can
## react to the lesson actually landing.
signal special_created(kind: int)


# --- Setup -----------------------------------------------------------------

func setup(
	p_width: int,
	p_height: int,
	p_pool: Array[KuihData],
	seed_value: int = 0
) -> void:
	width = maxi(3, p_width)
	height = maxi(3, p_height)
	pool = p_pool.duplicate()
	if pool.is_empty():
		pool = KuihLibrary.starter_set()
	pool_by_id = {}
	for k in pool:
		pool_by_id[k.id] = k

	rng = RandomNumberGenerator.new()
	if seed_value != 0:
		rng.seed = seed_value
	else:
		rng.randomize()

	grid = []
	for y in height:
		var row: Array = []
		for x in width:
			row.append(BoardCell.new())
		grid.append(row)

	_fill_initial()


## Paints an authored board over a generated one.
##
## Tutorial stages use this so a lesson is deterministic: a 3x3 board has so few
## cells that a random fill is often unsolvable, while a hand-authored layout can
## be verified by the test harness to have exactly one legal move.
##
## [param rows] is row-major, each row an Array of kuih ids. Returns false when
## the shape does not match the board or an id is unknown.
func apply_layout(rows: Array) -> bool:
	if rows.size() != height:
		return false
	for y in range(height):
		var row: Array = rows[y]
		if row.size() != width:
			return false
		for x in range(width):
			var entry: Variant = pool_by_id.get(row[x], null)
			if entry == null:
				return false
			var target: BoardCell = grid[y][x]
			target.clear_kuish()
			target.kuih = entry as KuihData
	return true


## True when the board has no pre-existing match, i.e. the player has to work
## for every clear. Tutorial layouts must satisfy this.
func is_clean() -> bool:
	return not has_any_match()


func apply_blockers(specs: Array[BlockerSpec]) -> void:
	for spec in specs:
		if spec == null:
			continue
		for pos in spec.cells:
			if not is_inside(pos):
				continue
			var cell := get_cell(pos)
			if cell == null:
				continue
			if BlockerSpec.is_target_kind(spec.kind):
				cell.clear_kuish()
				cell.blocker_kind = spec.kind
				cell.blocker_hp = 0
				cell.target_kuish = spec.kuih_id
				cell.target_need = maxi(1, spec.need)
				cell.target_progress = 0
			else:
				cell.blocker_kind = spec.kind
				cell.blocker_hp = maxi(1, spec.hp)
				if cell.kuih == null:
					cell.kuih = random_kuish()


func get_cell(pos: Vector2i) -> BoardCell:
	if not is_inside(pos):
		return null
	var row: Array = grid[pos.y]
	if pos.x >= row.size():
		return null
	return row[pos.x]


func is_inside(pos: Vector2i) -> bool:
	return pos.x >= 0 and pos.y >= 0 and pos.x < width and pos.y < height


func is_playable(pos: Vector2i) -> bool:
	var cell := get_cell(pos)
	return cell != null and cell.is_playable()


func kuish_at(pos: Vector2i) -> KuihData:
	var cell := get_cell(pos)
	return cell.kuih if cell != null else null


func random_kuish() -> KuihData:
	if pool.is_empty():
		return null
	return pool[rng.randi() % pool.size()]


# --- Generation ------------------------------------------------------------

func _would_match(x: int, y: int, candidate: KuihData) -> bool:
	if candidate == null:
		return true
	if x >= 2:
		var a := get_cell(Vector2i(x - 1, y))
		var b := get_cell(Vector2i(x - 2, y))
		if a != null and b != null and a.kuish_id() == candidate.id and b.kuish_id() == candidate.id:
			return true
	if y >= 2:
		var c := get_cell(Vector2i(x, y - 1))
		var d := get_cell(Vector2i(x, y - 2))
		if c != null and d != null and c.kuish_id() == candidate.id and d.kuish_id() == candidate.id:
			return true
	if delivery_enabled and x > 0 and y > 0:
		if get_cell(Vector2i(x-1, y)).kuish_id() == candidate.id and get_cell(Vector2i(x, y-1)).kuish_id() == candidate.id and get_cell(Vector2i(x-1, y-1)).kuish_id() == candidate.id:
			return true
	return false


func _fill_initial() -> void:
	for y in height:
		for x in width:
			var choices: Array[KuihData] = []
			for k in pool:
				if not _would_match(x, y, k):
					choices.append(k)
			if choices.is_empty():
				choices = pool
			var cell: BoardCell = grid[y][x]
			cell.kuih = choices[rng.randi() % choices.size()]


# --- Match detection -------------------------------------------------------

func find_matches(preferred: Array = []) -> Array[MatchGroup]:
	var runs: Array[MatchRun] = []
	runs.append_array(_scan_runs(true))
	runs.append_array(_scan_runs(false))
	if delivery_enabled:
		runs.append_array(_scan_squares())
	if runs.is_empty():
		return []

	var parent: Array[int] = []
	for i in runs.size():
		parent.append(i)

	var cell_runs: Dictionary = {}
	for i in runs.size():
		for pos in runs[i].cells:
			if not cell_runs.has(pos):
				cell_runs[pos] = []
			cell_runs[pos].append(i)

	for pos in cell_runs:
		var list: Array = cell_runs[pos]
		for i in range(1, list.size()):
			_uf_union(parent, list[0], list[i])

	var groups: Array[MatchGroup] = []
	var by_root: Dictionary = {}
	for i in runs.size():
		var root := _uf_find(parent, i)
		if not by_root.has(root):
			var g := MatchGroup.new()
			by_root[root] = g
			groups.append(g)
		var group: MatchGroup = by_root[root]
		group.runs.append(runs[i])
		for pos in runs[i].cells:
			group.cells[pos] = true

	for g in groups:
		_classify_group(g, preferred)
	return groups


func _scan_squares() -> Array[MatchRun]:
	var squares: Array[MatchRun] = []
	for y in height - 1:
		for x in width - 1:
			var positions: Array[Vector2i] = [Vector2i(x,y), Vector2i(x+1,y), Vector2i(x,y+1), Vector2i(x+1,y+1)]
			var id := get_cell(positions[0]).kuish_id()
			var valid := id != &""
			for pos in positions:
				var cell := get_cell(pos)
				if not cell.is_playable() or cell.special != BoardCell.Special.NONE or cell.kuish_id() != id:
					valid = false
			if valid:
				var square := MatchRun.new()
				square.cells = positions
				square.square = true
				squares.append(square)
	return squares

func _scan_runs(horizontal: bool) -> Array[MatchRun]:
	# Specials are independent items; their hidden creation kuih must never
	# count towards a normal match or detonate during refill cascades.
	var runs: Array[MatchRun] = []
	if horizontal:
		for y in height:
			var x := 0
			while x < width:
				var cell := get_cell(Vector2i(x, y))
				if not cell.is_playable() or cell.special != BoardCell.Special.NONE:
					x += 1
					continue
				var id := cell.kuish_id()
				var run_cells: Array[Vector2i] = [Vector2i(x, y)]
				var nx := x + 1
				while nx < width:
					var other := get_cell(Vector2i(nx, y))
					if not other.is_playable() or other.special != BoardCell.Special.NONE or other.kuish_id() != id:
						break
					run_cells.append(Vector2i(nx, y))
					nx += 1
				if run_cells.size() >= MIN_MATCH:
					var run := MatchRun.new()
					run.cells = run_cells
					run.horizontal = true
					runs.append(run)
					x = nx
				else:
					x += 1
	else:
		for x in width:
			var y := 0
			while y < height:
				var cell := get_cell(Vector2i(x, y))
				if not cell.is_playable() or cell.special != BoardCell.Special.NONE:
					y += 1
					continue
				var id := cell.kuish_id()
				var run_cells: Array[Vector2i] = [Vector2i(x, y)]
				var ny := y + 1
				while ny < height:
					var other := get_cell(Vector2i(x, ny))
					if not other.is_playable() or other.special != BoardCell.Special.NONE or other.kuish_id() != id:
						break
					run_cells.append(Vector2i(x, ny))
					ny += 1
				if run_cells.size() >= MIN_MATCH:
					var run := MatchRun.new()
					run.cells = run_cells
					run.horizontal = false
					runs.append(run)
					y = ny
				else:
					y += 1
	return runs


func _classify_group(group: MatchGroup, preferred: Array) -> void:
	var max_h := 0
	var max_v := 0
	var h_count := 0
	var v_count := 0
	var has_square := false
	for run in group.runs:
		if run.square:
			has_square = true
			continue
		if run.horizontal:
			max_h = maxi(max_h, run.cells.size())
			h_count += 1
		else:
			max_v = maxi(max_v, run.cells.size())
			v_count += 1

	if max_h >= 5 or max_v >= 5:
		group.special = BoardCell.Special.ORDER
	elif max_h >= MIN_MATCH and max_v >= MIN_MATCH:
		group.special = BoardCell.Special.DULANG
	elif max_h == 4 or max_v == 4:
		# A deliberate swipe determines the package's firing direction.
		# Cascades have no swipe, so use the matched line's orientation.
		group.special = BoardCell.Special.TAPAU if max_h == 4 else BoardCell.Special.TAPAU_VERTICAL
		if preferred.size() == 2:
			var from: Vector2i = preferred[0]
			var to: Vector2i = preferred[1]
			if from.distance_to(to) == 1 and (group.has(from) or group.has(to)):
				group.special = BoardCell.Special.TAPAU if from.y == to.y else BoardCell.Special.TAPAU_VERTICAL
	elif has_square:
		group.special = BoardCell.Special.HANTAR
	else:
		group.special = BoardCell.Special.NONE

	group.origin = _pick_origin(group, preferred)


func _pick_origin(group: MatchGroup, preferred: Array) -> Vector2i:
	for p in preferred:
		var pos: Vector2i = p
		if pos.x >= 0 and group.has(pos):
			return pos
	if group.special == BoardCell.Special.DULANG:
		var crossing := _find_crossing(group)
		if crossing != Vector2i(-1, -1):
			return crossing
	var best: MatchRun = null
	for run in group.runs:
		if best == null or run.cells.size() > best.cells.size():
			best = run
	if best == null:
		return Vector2i(-1, -1)
	return best.cells[best.cells.size() / 2]


func _find_crossing(group: MatchGroup) -> Vector2i:
	var h_cells: Dictionary = {}
	for run in group.runs:
		if not run.horizontal:
			continue
		for pos in run.cells:
			h_cells[pos] = true
	for run in group.runs:
		if run.horizontal:
			continue
		for pos in run.cells:
			if h_cells.has(pos):
				return pos
	return Vector2i(-1, -1)


static func _uf_find(parent: Array, start: int) -> int:
	var root := start
	while int(parent[root]) != root:
		root = int(parent[root])
	var walker := start
	while int(parent[walker]) != root:
		var nxt := int(parent[walker])
		parent[walker] = root
		walker = nxt
	return root


static func _uf_union(parent: Array, a: int, b: int) -> void:
	var ra := _uf_find(parent, a)
	var rb := _uf_find(parent, b)
	if ra != rb:
		parent[rb] = ra


func has_any_match() -> bool:
	return not find_matches().is_empty()


# --- Swapping --------------------------------------------------------------

func try_swap(a: Vector2i, b: Vector2i) -> SwapOutcome:
	if a == b:
		return SwapOutcome.INVALID
	if absi(a.x-b.x) + absi(a.y-b.y) != 1:
		return SwapOutcome.INVALID
	var ca := get_cell(a)
	var cb := get_cell(b)
	if ca == null or cb == null:
		return SwapOutcome.INVALID
	if not ca.is_playable() or not cb.is_playable():
		return SwapOutcome.INVALID
	if ca.kuish_id() == cb.kuish_id() and ca.special == BoardCell.Special.NONE and cb.special == BoardCell.Special.NONE:
		return SwapOutcome.INVALID

	swap_cells(a, b)
	if ca.special != BoardCell.Special.NONE or cb.special != BoardCell.Special.NONE:
		# Special Order targets the kuih deliberately swapped with it.
		# Keep creation's fallback type for chain hits without a swap partner.
		if ca.special == BoardCell.Special.ORDER and cb.special != BoardCell.Special.ORDER:
			ca.order_kuish = cb.kuish_id()
		if cb.special == BoardCell.Special.ORDER and ca.special != BoardCell.Special.ORDER:
			cb.order_kuish = ca.kuish_id()
		if ca.special == BoardCell.Special.HANTAR and cb.special == BoardCell.Special.NONE:
			ca.order_kuish = cb.kuish_id()
		if cb.special == BoardCell.Special.HANTAR and ca.special == BoardCell.Special.NONE:
			cb.order_kuish = ca.kuish_id()
		return SwapOutcome.ACTIVATED_SPECIAL
	if has_any_match():
		return SwapOutcome.PLAYED
	swap_cells(a, b)
	return SwapOutcome.INVALID


func swap_cells(a: Vector2i, b: Vector2i) -> void:
	var ca := get_cell(a)
	var cb := get_cell(b)
	if ca == null or cb == null:
		return
	var moved: KuihData = ca.kuih
	var other: KuihData = cb.kuih
	var moved_special: int = ca.special
	var moved_order: StringName = ca.order_kuish
	ca.kuih = other
	ca.special = cb.special
	ca.order_kuish = cb.order_kuish
	cb.kuih = moved
	cb.special = moved_special
	cb.order_kuish = moved_order


# --- Resolution ------------------------------------------------------------

## Clears every match currently on the board. Cascades call this again after
## gravity + refill until it returns an empty result.
func resolve(preferred: Array = []) -> ClearResult:
	var result := ClearResult.new()
	var groups := find_matches(preferred)
	if groups.is_empty():
		return result

	var protect: Dictionary = {}
	var queue: Array[Vector2i] = []
	for group in groups:
		result.match_runs.append_array(group.runs)
		if group.special != BoardCell.Special.NONE:
			var origin := group.origin
			var origin_cell := get_cell(origin)
			if origin_cell != null and origin_cell.is_playable():
				origin_cell.special = group.special
				if group.special == BoardCell.Special.ORDER:
					origin_cell.order_kuish = origin_cell.kuish_id()
				protect[origin] = true
			var created: Dictionary = {
				"pos": origin,
				"special": group.special,
				"kuih": origin_cell.kuih,
			}
			result.created.append(created)
			special_created.emit(group.special)
		for pos in group.cells:
			queue.append(pos)

	_run_clear(queue, result, protect)
	_register_blocker_progress(result)
	_register_target_progress(result)
	return result


## Fires the specials involved in a special swap (Master Plan section 16 combos).
func activate_specials(positions: Array) -> ClearResult:
	var result := ClearResult.new()
	var queue: Array[Vector2i] = []
	for p in positions:
		var pos: Vector2i = p
		if not is_inside(pos):
			continue
		var cell := get_cell(pos)
		if cell != null and cell.is_playable() and cell.special != BoardCell.Special.NONE:
			queue.append(pos)
	if queue.is_empty():
		return result
	# Only a deliberate swap of two directional specials forms a cross.
	# Chain hits keep each individual special's native direction.
	if queue.size() == 2:
		var a := queue[0]
		var b := queue[1]
		if absi(a.x-b.x) + absi(a.y-b.y) == 1 and _is_directional(get_cell(a).special) and _is_directional(get_cell(b).special):
			result.combo = &"sweet_cross"
			result.combo_origin = b
			result.combo_members = {a: true, b: true}
			result.combo_cells = _cross_cells(b)
		elif absi(a.x-b.x) + absi(a.y-b.y) == 1 and get_cell(a).special == BoardCell.Special.DULANG and get_cell(b).special == BoardCell.Special.DULANG:
			result.combo = &"rounded_dulang"
			result.combo_origin = b
			result.combo_members = {a: true, b: true}
			result.combo_cells = area_mask_cells(b, DULANG_DOUBLE_MASK)
		elif absi(a.x-b.x) + absi(a.y-b.y) == 1 and get_cell(a).special == BoardCell.Special.HANTAR and get_cell(b).special == BoardCell.Special.HANTAR:
			result.combo = &"triple_delivery"
			result.combo_origin = b
			result.combo_members = {a: true, b: true}
			var excluded: Dictionary = {}
			for origin in [a, b]:
				for local in delivery_cross(origin):
					var cell := get_cell(local)
					if not excluded.has(local) and (cell.is_playable() or cell.has_overlay()):
						result.combo_cells.append(local)
					excluded[local] = true
			for i in 3:
				var target := select_delivery_target(b, excluded)
				if target == Vector2i(-1,-1):
					break
				result.delivery_targets.append(target)
				result.combo_cells.append(target)
				excluded[target] = true
		elif absi(a.x-b.x) + absi(a.y-b.y) == 1 and get_cell(a).special == BoardCell.Special.ORDER and get_cell(b).special == BoardCell.Special.ORDER:
			result.combo = &"order_wipe"
			result.combo_origin = b
			result.combo_members = {a: true, b: true}
			for y in height:
				for x in width:
					var pos := Vector2i(x,y)
					var cell := get_cell(pos)
					if cell.is_playable() or cell.has_overlay():
						result.combo_cells.append(pos)
		elif absi(a.x-b.x) + absi(a.y-b.y) == 1 and (get_cell(a).special == BoardCell.Special.ORDER or get_cell(b).special == BoardCell.Special.ORDER):
			var order_pos := a if get_cell(a).special == BoardCell.Special.ORDER else b
			var partner_pos := b if order_pos == a else a
			result.combo = &"order_conversion"
			result.combo_origin = order_pos
			# Consume Order without its normal same-colour clear. The partner and
			# converted specials execute their native footprints exactly once.
			result.combo_members = {order_pos: true}
			result.conversion_kind = get_cell(partner_pos).special
			var types: Array[StringName] = []
			for row in grid:
				for cell in row:
					if cell.is_playable() and cell.special == BoardCell.Special.NONE and not types.has(cell.kuish_id()):
						types.append(cell.kuish_id())
			if not types.is_empty():
				result.conversion_kuih = types[rng.randi_range(0,types.size()-1)]
				for y in height:
					for x in width:
						var pos := Vector2i(x,y)
						var cell := get_cell(pos)
						if cell.is_playable() and cell.special == BoardCell.Special.NONE and cell.kuish_id() == result.conversion_kuih:
							cell.special = result.conversion_kind
							cell.order_kuish = &""
							result.converted.append(pos)
							queue.append(pos)
	_run_clear(queue, result, {})
	_register_blocker_progress(result)
	_register_target_progress(result)
	return result


func _run_clear(queue: Array[Vector2i], result: ClearResult, protect: Dictionary) -> void:
	var chain_depth: Dictionary = {}
	for origin in queue:
		chain_depth[origin] = 0
	for i in result.converted.size():
		chain_depth[result.converted[i]] = 1 + i / 6
	var order_count := 0
	for pos in queue:
		var probe := get_cell(pos)
		if probe != null and probe.special == BoardCell.Special.ORDER:
			order_count += 1

	# Special Order + Special Order wipes the whole board.
	if order_count >= 2:
		for y in height:
			for x in width:
				var c := get_cell(Vector2i(x, y))
				if c != null and c.is_playable():
					queue.append(Vector2i(x, y))

	var seen: Dictionary = {}
	var head := 0
	while head < queue.size():
		var pos: Vector2i = queue[head]
		head += 1
		if seen.has(pos):
			continue
		seen[pos] = true
		if protect.has(pos):
			continue
		var cell := get_cell(pos)
		if cell == null:
			continue
		if cell.has_overlay():
			_damage_delivery_blocker(pos, result)
			continue
		if not cell.has_kuish():
			continue
		var info := ClearInfo.new()
		var cleared_kuih: KuihData = cell.kuih
		info.kuih = cleared_kuih
		info.by_special = cell.special != BoardCell.Special.NONE
		info.source = cell.special
		result.cleared[pos] = info

		if info.by_special:
			var excluded := protect.duplicate()
			for pending in queue:
				excluded[pending] = true
			var affected: Array[Vector2i] = result.combo_cells.duplicate() if result.combo_members.has(pos) else _blast_cells(pos, cell, excluded)
			result.activated.append({"pos": pos, "kind": cell.special, "cells": affected,
				"chain_depth": int(chain_depth.get(pos, 0))})
			for bp in affected:
				if not seen.has(bp) and not protect.has(bp):
					if not chain_depth.has(bp):
						chain_depth[bp] = int(chain_depth.get(pos, 0)) + 1
					queue.append(bp)

	for pos in result.cleared:
		var cell := get_cell(pos)
		if cell != null:
			cell.clear_kuish()


static func _is_directional(kind: int) -> bool:
	return kind in [BoardCell.Special.TAPAU, BoardCell.Special.TAPAU_VERTICAL]

func _cross_cells(origin: Vector2i) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	for x in width:
		var pos := Vector2i(x, origin.y)
		if is_playable(pos) or get_cell(pos).has_overlay():
			out.append(pos)
	for y in height:
		var pos := Vector2i(origin.x, y)
		if not out.has(pos) and (is_playable(pos) or get_cell(pos).has_overlay()):
			out.append(pos)
	return out

func _blast_cells(pos: Vector2i, cell: BoardCell, excluded: Dictionary = {}) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	match cell.special:
		BoardCell.Special.HANTAR:
			out.assign(delivery_cross(pos))
			var unavailable := excluded.duplicate()
			for local in out:
				unavailable[local] = true
			var target := select_delivery_target(pos, unavailable, cell.order_kuish)
			if target != Vector2i(-1, -1):
				out.append(target)
		BoardCell.Special.TAPAU:
			for x in width:
				out.append(Vector2i(x, pos.y))
		BoardCell.Special.TAPAU_VERTICAL:
			for y in height:
				out.append(Vector2i(pos.x, y))
		BoardCell.Special.DULANG:
			out.assign(area_mask_cells(pos, DULANG_SINGLE_MASK))
		BoardCell.Special.ORDER:
			var wanted := cell.order_kuish
			for y in height:
				for x in width:
					var other := get_cell(Vector2i(x, y))
					# Packages are separate items, not the hidden kuih used to create them.
					if other != null and (other.is_playable() or other.has_overlay()) and other.special == BoardCell.Special.NONE and other.kuish_id() == wanted:
						out.append(Vector2i(x, y))
	var filtered: Array[Vector2i] = []
	for p in out:
		if not is_inside(p):
			continue
		var c := get_cell(p)
		if c != null and (c.is_playable() or c.has_overlay()):
			filtered.append(p)
	return filtered


## Centered matrix mask, clipped before access. Keep empty cells so presentation
## can reuse the footprint after the logical clear has already removed kuih.
func area_mask_cells(origin: Vector2i, mask: Array) -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	var half_y := mask.size() / 2
	for y in mask.size():
		var row: Array = mask[y]
		var half_x := row.size() / 2
		for x in row.size():
			var pos := origin + Vector2i(x-half_x, y-half_y)
			if row[x] != 0 and is_inside(pos):
				cells.append(pos)
	return cells


## Local plus footprint, clipped at board edges. The remote target is appended last.
func delivery_cross(origin: Vector2i) -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	for offset in [Vector2i.ZERO, Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
		var pos: Vector2i = origin + offset
		if is_inside(pos):
			cells.append(pos)
	return cells


## Double tap chooses a normal neighbour, favouring outstanding orders, then
## the most common local type. Stable cross order breaks ties.
func delivery_local_kuih(origin: Vector2i) -> StringName:
	var counts: Dictionary = {}
	for pos in delivery_cross(origin):
		var cell := get_cell(pos)
		if cell.is_playable() and cell.special == BoardCell.Special.NONE:
			var id := cell.kuish_id()
			counts[id] = int(counts.get(id, 0)) + 1
	var chosen: StringName = &""
	var best := -1
	for id in counts:
		var rank := int(counts[id]) + (10 if int(order_remaining.get(id, 0)) > 0 else 0)
		if rank > best:
			best = rank
			chosen = id
	return chosen


func select_delivery_target(origin: Vector2i, excluded: Dictionary = {}, preferred_kuih: StringName = &"") -> Vector2i:
	var candidates: Array[Vector2i] = []
	var objectives: Dictionary = {}
	for y in height:
		for x in width:
			var pos := Vector2i(x,y)
			var cell := get_cell(pos)
			if cell.is_target():
				objectives[cell.target_kuish] = true
			if pos != origin and not excluded.has(pos) and (cell.is_playable() or cell.has_overlay()):
				candidates.append(pos)
	# A deliberate ordinary-kuih swap overrides automatic order priorities.
	if preferred_kuih != &"":
		for pos in candidates:
			var cell := get_cell(pos)
			if cell.is_playable() and cell.special == BoardCell.Special.NONE and cell.kuish_id() == preferred_kuih:
				return pos
	for priority in delivery_priorities:
		for pos in candidates:
			var cell := get_cell(pos)
			if priority == &"order" and cell.is_playable() and int(order_remaining.get(cell.kuish_id(),0)) > 0:
				return pos
			if priority == &"blocker" and cell.has_overlay():
				return pos
			if priority == &"objective" and cell.is_playable() and objectives.has(cell.kuish_id()):
				return pos
			if priority == &"useful" and cell.is_playable():
				return pos
	return candidates[rng.randi_range(0, candidates.size()-1)] if not candidates.is_empty() else Vector2i(-1,-1)

func _damage_delivery_blocker(pos: Vector2i, result: ClearResult) -> void:
	if result.direct_blocker_hits.has(pos):
		return
	result.direct_blocker_hits[pos] = true
	var cell := get_cell(pos)
	var hit := BlockerHit.new()
	hit.pos = pos
	hit.kind = cell.blocker_kind
	cell.blocker_hp = maxi(0, cell.blocker_hp - 1)
	hit.hp_left = cell.blocker_hp
	hit.removed = cell.blocker_hp == 0
	if hit.removed:
		cell.remove_obstacle()
	result.blockers.append(hit)

## A leaf, cover, steamer or syrup is opened by matching right next to it.
func _register_blocker_progress(result: ClearResult) -> void:
	var touched: Dictionary = result.direct_blocker_hits.duplicate()
	for key in result.cleared:
		var origin: Vector2i = key
		for dy in range(-1, 2):
			for dx in range(-1, 2):
				if dx == 0 and dy == 0:
					continue
				var neighbour: Vector2i = origin + Vector2i(dx, dy)
				if touched.has(neighbour):
					continue
				if not is_inside(neighbour):
					continue
				var cell := get_cell(neighbour)
				if cell == null or not cell.has_overlay():
					continue
				touched[neighbour] = true
				var hit := BlockerHit.new()
				hit.pos = neighbour
				hit.kind = cell.blocker_kind
				cell.blocker_hp -= 1
				hit.hp_left = maxi(0, cell.blocker_hp)
				hit.removed = cell.blocker_hp <= 0
				if hit.removed:
					cell.blocker_kind = BoardCell.NO_BLOCKER
				result.blockers.append(hit)


## Collected kuih feed Packaging Box / Empty Tray targets.
func _register_target_progress(result: ClearResult) -> void:
	if result.cleared.is_empty():
		return
	var totals := result.collected_totals()
	if totals.is_empty():
		return
	for y in height:
		for x in width:
			var cell := get_cell(Vector2i(x, y))
			if cell == null or not cell.is_target():
				continue
			if not totals.has(cell.target_kuish):
				continue
			var gain := int(totals[cell.target_kuish])
			var before := cell.target_progress
			cell.target_progress = mini(cell.target_need, cell.target_progress + gain)
			var entry := TargetProgress.new()
			entry.pos = Vector2i(x, y)
			entry.kuih_id = cell.target_kuish
			entry.progress = cell.target_progress
			entry.need = cell.target_need
			entry.done = cell.target_progress >= cell.target_need
			if entry.progress == before:
				continue
			if entry.done:
				cell.remove_obstacle()
			result.targets.append(entry)


## Compacts every column downwards. Obstacles stay put, only kuih move.
func apply_gravity() -> Array[FallMove]:
	var moves: Array[FallMove] = []
	for x in width:
		var write_y := height - 1
		for y in range(height - 1, -1, -1):
			var source := get_cell(Vector2i(x, y))
			if source == null or not source.has_kuish():
				continue
			if write_y == y:
				write_y -= 1
				continue
			var target := get_cell(Vector2i(x, write_y))
			if target == null:
				continue
			var carried: KuihData = source.kuih
			var carried_special: int = source.special
			var carried_order: StringName = source.order_kuish
			target.kuih = carried
			target.special = carried_special
			target.order_kuish = carried_order
			source.clear_kuish()
			var move := FallMove.new()
			move.from = Vector2i(x, y)
			move.to = Vector2i(x, write_y)
			move.kuih = carried
			moves.append(move)
			write_y -= 1
	return moves


## Fills every remaining hole with fresh kuih.
func refill() -> Array[SpawnEntry]:
	var spawns: Array[SpawnEntry] = []
	for x in width:
		for y in height:
			var cell := get_cell(Vector2i(x, y))
			if cell == null:
				continue
			if cell.has_kuish() or cell.has_overlay() or cell.is_target():
				continue
			cell.kuih = random_kuish()
			var entry := SpawnEntry.new()
			var spawned: KuihData = cell.kuih
			entry.pos = Vector2i(x, y)
			entry.kuih = spawned
			spawns.append(entry)
	return spawns


# --- Move availability -----------------------------------------------------

func find_possible_moves(limit: int = 1) -> Array[Dictionary]:
	var found: Array[Dictionary] = []
	for y in height:
		for x in width:
			if found.size() >= limit:
				return found
			var a := Vector2i(x, y)
			if x + 1 < width:
				var b := Vector2i(x + 1, y)
				if _is_valid_pair(a, b):
					found.append({"a": a, "b": b})
			if y + 1 < height:
				var b2 := Vector2i(x, y + 1)
				if _is_valid_pair(a, b2):
					found.append({"a": a, "b": b2})
	return found


func _is_valid_pair(a: Vector2i, b: Vector2i) -> bool:
	var ca := get_cell(a)
	var cb := get_cell(b)
	if ca == null or cb == null:
		return false
	if not ca.is_playable() or not cb.is_playable():
		return false
	if ca.special != BoardCell.Special.NONE or cb.special != BoardCell.Special.NONE:
		return true
	if ca.kuish_id() == cb.kuish_id():
		return false
	swap_cells(a, b)
	var matched := has_any_match()
	swap_cells(a, b)
	return matched


func has_possible_move() -> bool:
	return not find_possible_moves(1).is_empty()


## Rearranges kuih so the board is solvable again. Returns the new layout so the
## view can play a little swirl.
func shuffle_board() -> Array[Dictionary]:
	shuffles_used += 1
	var positions: Array[Vector2i] = []
	for y in height:
		for x in width:
			var cell := get_cell(Vector2i(x, y))
			if cell != null and cell.is_playable():
				positions.append(Vector2i(x, y))
	if positions.is_empty():
		return []

	var ids: Array[StringName] = []
	for pos in positions:
		var source := get_cell(pos)
		ids.append(source.kuish_id())

	var attempts := 0
	while attempts < SHUFFLE_MAX_ATTEMPTS:
		ids.shuffle()
		for i in positions.size():
			var slot := get_cell(positions[i])
			var replacement: KuihData = pool_by_id.get(ids[i], KuihLibrary.get_kuih(ids[i]))
			slot.kuih = replacement
		attempts += 1
		if not has_any_match() and has_possible_move():
			break

	var changes: Array[Dictionary] = []
	for pos in positions:
		changes.append({"pos": pos, "kuih": get_cell(pos).kuih})
	return changes


# --- Introspection ---------------------------------------------------------

func remaining_blockers() -> int:
	var count := 0
	for y in height:
		for x in width:
			var cell := get_cell(Vector2i(x, y))
			if cell != null and cell.has_obstacle():
				count += 1
	return count


func remaining_blockers_of_kind(kind: int) -> int:
	var count := 0
	for y in height:
		for x in width:
			var cell := get_cell(Vector2i(x, y))
			if cell != null and cell.has_obstacle() and cell.blocker_kind == kind:
				count += 1
	return count


func snapshot() -> Array:
	var out: Array = []
	for y in height:
		var row: Array = []
		for x in width:
			var cell: BoardCell = grid[y][x]
			row.append({
				"kuih": cell.kuish_id(),
				"special": cell.special,
				"order_kuish": cell.order_kuish,
				"blocker": cell.blocker_kind,
				"hp": cell.blocker_hp,
				"target": cell.target_kuish,
				"target_progress": cell.target_progress,
				"target_need": cell.target_need,
			})
		out.append(row)
	return out
