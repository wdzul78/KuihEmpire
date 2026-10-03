class_name TileView
extends Control

## Visual for one kuih on the board.
##
## Only the kuih itself is drawn here; the tray recess underneath lives in the
## board's slot layer so tiles can float freely while falling.

var cell: BoardCell = null
var icon: KuihIcon = null
var selected: bool = false:
	set(value):
		selected = value
		queue_redraw()
var hinted: bool = false:
	set(value):
		hinted = value
		if not value:
			_stop_hint()
		queue_redraw()

var _pulse: float = 0.0
var _pulse_tween: Tween = null


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	pivot_offset = size * 0.5
	icon = KuihIcon.new()
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon.cell_ratio = 0.84
	add_child(icon)
	# A plain Control does not lay out its children, so the icon has to follow
	# the tile size by hand - otherwise big tutorial boards render empty cells.
	resized.connect(_sync_icon)
	_sync_icon()
	if cell != null:
		# NOTE: `icon.kuih = cell.kuih` silently fails in GDScript 4.3 - the
		# property name on the left also appearing on the right breaks member
		# lookup. Always hoist the right-hand side into a different name.
		var initial: KuihData = cell.kuih
		icon.kuih = initial


func _sync_icon() -> void:
	if icon == null:
		return
	pivot_offset = size * 0.5
	icon.position = Vector2.ZERO
	icon.size = size
	icon.queue_redraw()


func set_cell(value: BoardCell) -> void:
	cell = value
	_sync_icon()
	if icon != null and value != null:
		# Hoisted: a local named `kuih` in this scope breaks `icon.kuih = ...` in
		# GDScript 4.3, so never reuse the property name as a local.
		var data: KuihData = value.kuih
		icon.kuih = data
		icon.show_outline = true
	queue_redraw()


func refresh() -> void:
	if cell == null:
		return
	if icon != null:
		var data: KuihData = cell.kuih
		icon.kuih = data
	queue_redraw()


func set_selected(value: bool) -> void:
	selected = value


## Gentle, repeating attention pulse. The tutorial coach uses this to point at
## cells without ever taking control away from the player.
##
## The pulse animates the drawn ring, never the node's scale: adjacent tiles sit
## exactly one pitch apart, so any scale above 1.0 pushes a tile into its
## neighbour and the kuih visibly collide.
func start_hint_pulse() -> void:
	hinted = true
	_stop_hint()
	_pulse_tween = create_tween()
	_pulse_tween.set_loops()
	_pulse_tween.tween_method(_set_pulse, 0.0, 1.0, 0.45).set_trans(Tween.TRANS_SINE)
	_pulse_tween.tween_method(_set_pulse, 1.0, 0.0, 0.45).set_trans(Tween.TRANS_SINE)


func _set_pulse(value: float) -> void:
	_pulse = value
	queue_redraw()


func _stop_hint() -> void:
	if _pulse_tween != null and _pulse_tween.is_valid():
		_pulse_tween.kill()
	_pulse_tween = null
	_pulse = 0.0


func _draw() -> void:
	if cell == null:
		return
	if selected:
		var r := Rect2(Vector2.ZERO, size).grow(-size.x * 0.06)
		draw_rect(r, Color(Palette.PINK.r, Palette.PINK.g, Palette.PINK.b, 0.28), true)
		draw_rect(r, Palette.PINK_DARK, false, maxf(3.0, size.x * 0.035))
	elif hinted:
		# Kept strictly inside the cell so the ring can never reach a neighbour.
		var radius := size.x * (0.38 + 0.08 * _pulse)
		draw_circle(size * 0.5, radius, Color(1, 1, 1, 0.14 + 0.16 * _pulse))
	if cell.special != BoardCell.Special.NONE:
		BoardArt.draw_special(self, Rect2(Vector2.ZERO, size), cell.special)
