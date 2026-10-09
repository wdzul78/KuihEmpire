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
		_sync_selection_motion()
		queue_redraw()
var hinted: bool = false:
	set(value):
		hinted = value
		if not value:
			_stop_hint()
		queue_redraw()

var _pulse: float = 0.0
var _pulse_tween: Tween = null
var _hint_nudge := false
var _hint_origin := Vector2.ZERO
var _special_idle_tween: Tween = null
var _selection_tween: Tween = null
var _formation_shake_tween: Tween = null
var _order_activation_tween: Tween = null
var _electric_flash_tween: Tween = null
var _idle_special_kind := BoardCell.Special.NONE
var _wiggle_amplitude := 0.0
var _rim_phase := 0.0
var _rim_light: Control


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	pivot_offset = size * 0.5
	icon = KuihIcon.new()
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon.cell_ratio = 0.92
	add_child(icon)
	_rim_light = Control.new()
	_rim_light.name = "DulangRimSparkle"
	_rim_light.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_rim_light)
	_rim_light.draw.connect(_draw_rim_light)
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
		icon.special_kind = cell.special
	_sync_special_idle()
	_sync_selection_motion()


func _sync_icon() -> void:
	if icon == null:
		return
	pivot_offset = size * 0.5
	icon.position = Vector2.ZERO
	icon.size = size
	icon.pivot_offset = size * .5
	icon.queue_redraw()
	if _rim_light != null:
		_rim_light.size = size
		_rim_light.queue_redraw()


func set_cell(value: BoardCell) -> void:
	cell = value
	_sync_icon()
	if icon != null and value != null:
		# Hoisted: a local named `kuih` in this scope breaks `icon.kuih = ...` in
		# GDScript 4.3, so never reuse the property name as a local.
		var data: KuihData = value.kuih
		icon.kuih = data
		icon.special_kind = value.special
		icon.show_outline = true
		icon.visible = value.blocker_kind != BlockerSpec.Kind.BANANA_LEAF or not value.has_overlay()
	_sync_special_idle()
	queue_redraw()


func reveal_leaf_item() -> void:
	if icon == null:
		return
	icon.show()
	icon.modulate.a = 0.0
	icon.scale = Vector2.ONE*.55
	var reveal := icon.create_tween()
	reveal.tween_property(icon,"scale",Vector2.ONE,.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	reveal.parallel().tween_property(icon,"modulate:a",1.0,.16)
	reveal.tween_property(icon,"rotation",-.12,.08)
	reveal.tween_property(icon,"rotation",.10,.10)
	reveal.tween_property(icon,"rotation",0.0,.12)


func refresh() -> void:
	if cell == null:
		return
	if icon != null:
		var data: KuihData = cell.kuih
		icon.kuih = data
		icon.special_kind = cell.special
	_sync_special_idle()
	queue_redraw()


## Animate only the artwork, so swap/clear tweens retain control of the tile.
## Slow sine-wave wiggle keeps the size fixed and the loop seamless.
func _sync_special_idle() -> void:
	if icon == null:
		return
	var kind: int = cell.special if cell != null and cell.has_kuish() else BoardCell.Special.NONE
	if kind == _idle_special_kind and (kind == BoardCell.Special.NONE or (_special_idle_tween != null and _special_idle_tween.is_valid())):
		return
	if _special_idle_tween != null and _special_idle_tween.is_valid():
		_special_idle_tween.kill()
	_special_idle_tween = null
	_idle_special_kind = kind
	icon.scale = Vector2.ONE
	icon.rotation = 0.0
	icon.directional_spread = 0.0
	icon.directional_alpha = 1.0
	if kind == BoardCell.Special.NONE:
		return
	if kind in [BoardCell.Special.TAPAU,BoardCell.Special.TAPAU_VERTICAL]:
		# Show the new special immediately, then repeat after a three-second rest.
		_set_directional_idle(0.0)
		_special_idle_tween = icon.create_tween().set_loops()
		_special_idle_tween.tween_method(_set_directional_idle,0.0,4.2,4.2)
		return
	# One gentle left-right cycle over 4.8 seconds, without a scale pulse.
	_wiggle_amplitude = deg_to_rad(1.2 if kind in [BoardCell.Special.TAPAU, BoardCell.Special.TAPAU_VERTICAL] else 2.0)
	var phase := randf()*TAU
	_set_special_wiggle(phase)
	_special_idle_tween = icon.create_tween().set_loops()
	_special_idle_tween.tween_method(_set_special_wiggle, phase, phase+TAU, 4.8).set_trans(Tween.TRANS_LINEAR)


func _set_special_wiggle(phase: float) -> void:
	_rim_phase = phase
	if _rim_light != null:
		_rim_light.queue_redraw()
	if icon != null:
		icon.rotation = sin(phase)*_wiggle_amplitude



func _set_directional_idle(seconds: float) -> void:
	if icon == null:
		return
	icon.directional_spread = smoothstep(.16,1.05,seconds)
	icon.directional_alpha = smoothstep(0,.18,seconds)*(1-smoothstep(.75,1.15,seconds))


func animate_directional_activation() -> void:
	if icon == null:
		return
	if _special_idle_tween != null and _special_idle_tween.is_valid():
		_special_idle_tween.kill()
	_special_idle_tween = null
	icon.directional_alpha = 1.0
	icon.directional_spread = 0.0
	var tween := icon.create_tween()
	tween.tween_property(icon,"directional_spread",1.0,.15).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_method(func(seconds: float): icon.directional_alpha = .3+.7*pow(cos(seconds*PI*18),2),0.0,.15,.15)
	tween.tween_property(icon,"directional_alpha",0.0,.03)


func set_selected(value: bool) -> void:
	selected = value


func animate_order_activation() -> void:
	if icon == null:
		return
	if _special_idle_tween != null and _special_idle_tween.is_valid():
		_special_idle_tween.kill()
	_special_idle_tween = null
	icon.rotation = 0.0
	if _order_activation_tween != null and _order_activation_tween.is_valid():
		_order_activation_tween.kill()
	icon.order_activation = 0.0
	_order_activation_tween = create_tween()
	_order_activation_tween.tween_property(icon,"order_activation",1.0,.78)


func animate_electric_flash() -> void:
	if icon == null:
		return
	if _electric_flash_tween != null and _electric_flash_tween.is_valid():
		_electric_flash_tween.kill()
	_electric_flash_tween = create_tween()
	for tint in [Color(1.45,1.55,1.75),Color(1.75,1.55,1.15)]:
		_electric_flash_tween.tween_property(icon,"modulate",tint,.055)
		_electric_flash_tween.tween_property(icon,"modulate",Color.WHITE,.055)


## Move only the artwork, leaving swap animation and special rotation independent.
func _sync_selection_motion() -> void:
	if _selection_tween != null and _selection_tween.is_valid():
		_selection_tween.kill()
	_selection_tween = null
	if icon == null:
		return
	icon.position = Vector2.ZERO
	if selected:
		_selection_tween = icon.create_tween().set_loops()
		_selection_tween.tween_method(_set_selection_motion, 0.0, TAU, 1.6)


func _set_selection_motion(phase: float) -> void:
	if icon != null:
		icon.position = Vector2(0.0, sin(phase) * size.y * .018)


## A brief, decaying ripple moves artwork without changing the tile's grid position.
func play_formation_shake() -> void:
	if icon == null or selected:
		return
	if _formation_shake_tween != null and _formation_shake_tween.is_valid():
		_formation_shake_tween.kill()
	_formation_shake_tween = create_tween()
	_formation_shake_tween.tween_method(_set_formation_shake, 0.0, 1.0, .18)


func _set_formation_shake(progress: float) -> void:
	if icon != null:
		var amplitude := minf(size.x, size.y) * .028 * (1.0-progress)
		icon.position = Vector2(sin(progress*TAU*3), sin(progress*TAU*2)*.45) * amplitude


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


## Move the artwork toward the suggested slot without changing board state.
func start_hint_nudge(direction: Vector2) -> void:
	_stop_hint()
	hinted = true
	_hint_nudge = true
	_hint_origin = position
	var target := _hint_origin + direction.normalized() * size.x * .12
	_pulse_tween = create_tween().set_loops()
	_pulse_tween.tween_property(self,"position",target,.32).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_pulse_tween.tween_property(self,"position",_hint_origin,.48).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_pulse_tween.tween_interval(1.70)


func _stop_hint() -> void:
	if _pulse_tween != null and _pulse_tween.is_valid():
		_pulse_tween.kill()
	_pulse_tween = null
	_pulse = 0.0
	if _hint_nudge:
		position = _hint_origin
	_hint_nudge = false


func _draw() -> void:
	if cell == null:
		return
	if selected:
		var r := Rect2(Vector2.ZERO, size).grow(-size.x * 0.06)
		var highlight := StyleBoxFlat.new()
		highlight.bg_color = Color(1.0, .97, .84, .42)
		highlight.set_corner_radius_all(int(size.x * .10))
		draw_style_box(highlight, r)
	elif hinted and not _hint_nudge:
		# Kept strictly inside the cell so the ring can never reach a neighbour.
		var radius := size.x * (0.38 + 0.08 * _pulse)
		draw_circle(size * 0.5, radius, Color(1, 1, 1, 0.14 + 0.16 * _pulse))
	if cell.special != BoardCell.Special.NONE:
		if cell.special != BoardCell.Special.HANTAR:
			BoardArt.draw_special(self, Rect2(Vector2.ZERO, size), cell.special)


func _draw_rim_light() -> void:
	# The shared animated artwork draws the new tray rim and rotating rays.
	pass
