class_name VictoryBonus
extends Control

## Presentation on a snapshot: no board rules, inventory or reward mutations.
signal steps_converted(remaining: int, points: int)
var skipped := false
var cancelled := false
var _board: MatchBoard
var _originals: Dictionary = {}
var _copies: Dictionary = {}
var _vfx: GameVfx
var _caption: Label

func skip() -> void:
	skipped = true

func cancel() -> void:
	cancelled = true
	skipped = true
	hide()
	_restore()

func _restore() -> void:
	for tile in _originals:
		if is_instance_valid(tile):
			tile.visible = _originals[tile]
	_originals.clear()

func _exit_tree() -> void:
	_restore()

func _wait(seconds: float) -> void:
	var elapsed := 0.0
	while elapsed < seconds and not skipped:
		await get_tree().process_frame
		if can_process():
			elapsed += get_process_delta_time()

func play(board: MatchBoard, moves: int, points_per_move: int) -> void:
	_board = board
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	z_index = 40
	var positions: Array[Vector2i] = []
	var existing_specials: Array[Vector2i] = []
	for pos in board._tiles:
		var original: TileView = board._tiles[pos]
		if not is_instance_valid(original) or original.cell == null or not original.visible:
			continue
		_originals[original] = original.visible
		original.hide()
		var copy_cell := BoardCell.new()
		copy_cell.kuih = original.cell.kuih
		copy_cell.special = original.cell.special
		copy_cell.order_kuish = original.cell.order_kuish
		var tile := TileView.new()
		tile.size = original.size
		tile.position = original.position
		tile.set_cell(copy_cell)
		add_child(tile)
		_copies[pos] = tile
		if board.logic.is_playable(pos):
			positions.append(pos)
			if copy_cell.special != BoardCell.Special.NONE:
				existing_specials.append(pos)
	_vfx = GameVfx.new()
	_vfx.z_index = 15
	add_child(_vfx)
	var banner := Panel.new()
	banner.name = "MoveBonusBanner"
	banner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	banner.z_index = 30
	banner.position = Vector2(size.x * .06, maxf(8, board.board_origin.y - 78))
	banner.size = Vector2(size.x * .88, 65)
	banner.add_theme_stylebox_override("panel", UIKit.cream_box())
	add_child(banner)
	_caption = UIKit.label("", 36, Palette.WOOD_DARK)
	banner.add_child(_caption)
	_caption.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_caption.offset_left = 12
	_caption.offset_right = -12
	_caption.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	var skip_button := UIKit.button(JourneyArt.localized("Langkau bonus", "Skip bonus"), 28, Palette.LEAF)
	skip_button.name = "SkipBonus"
	skip_button.z_index = 30
	skip_button.position = Vector2(size.x * .28, size.y - 88)
	skip_button.size = Vector2(size.x * .44, 68)
	skip_button.pressed.connect(skip)
	add_child(skip_button)
	var remaining := maxi(0, moves)
	var awarded := 0
	var groups := mini(8, mini(remaining, positions.size()))
	var queue: Array[Vector2i] = []
	for pos in existing_specials:
		if queue.size() < 8:
			queue.append(pos)
	for index in groups:
		if skipped:
			break
		var pos := positions[roundi(float(index) * (positions.size() - 1) / maxi(1, groups - 1))]
		var tile: TileView = _copies[pos]
		var batch := ceili(float(remaining) / (groups - index))
		remaining -= batch
		var gained := batch * maxi(0, points_per_move)
		awarded += gained
		steps_converted.emit(remaining, gained)
		_caption.text = JourneyArt.localized("Bonus langkah", "Move bonus") + " · +%d" % awarded
		# Large move budgets are grouped into at most eight visible specials.
		tile.cell.special = BoardCell.Special.DULANG if index % 3 == 2 else (BoardCell.Special.TAPAU if index % 2 == 0 else BoardCell.Special.TAPAU_VERTICAL)
		tile.refresh()
		tile.scale = Vector2.ONE * 1.25
		var pop := tile.create_tween()
		pop.tween_property(tile, "scale", Vector2.ONE, .16).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		_vfx.special_formation(board._cell_center(pos), PackedVector2Array(), board.cell_size, tile.cell.special)
		if not queue.has(pos):
			queue.append(pos)
		await _wait(.12)
	if not cancelled:
		steps_converted.emit(0, remaining * maxi(0, points_per_move))
		_caption.text = JourneyArt.localized("Bonus langkah", "Move bonus") + " · +%d" % (moves * maxi(0, points_per_move))
	for pos in queue:
		if skipped:
			break
		var tile: TileView = _copies[pos]
		var kind: int = tile.cell.special
		var points := PackedVector2Array()
		var fragments: Array[Dictionary] = []
		var footprint: Array[Vector2i] = []
		if kind == BoardCell.Special.HANTAR:
			footprint.assign(board.logic.delivery_cross(pos))
			if not positions.is_empty():
				footprint.append(positions.back())
		else:
			footprint.assign(board.logic._blast_cells(pos, tile.cell))
		for affected in footprint:
			points.append(board._cell_center(affected))
			var hit: TileView = _copies.get(affected)
			if hit != null and hit.visible and not queue.has(affected):
				fragments.append({"at": board._cell_center(affected), "color": hit.cell.kuih.detail})
				hit.hide()
		tile.hide()
		if kind == BoardCell.Special.HANTAR and not footprint.is_empty():
			_vfx.delivery(board._cell_center(pos), board._cell_center(footprint.back()), board.cell_size)
		else:
			_vfx.special(board._cell_center(pos), kind, points, board.cell_size)
		_vfx.kuih_dissolve(fragments, board.cell_size, 0)
		AudioManager.play_special(kind)
		await _wait(.16)
	await _wait(.45)
	_restore()
