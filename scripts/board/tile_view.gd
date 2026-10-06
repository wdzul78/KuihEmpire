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
var _special_idle_tween: Tween = null
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
	_sync_special_idle()
	queue_redraw()


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
		if cell.special != BoardCell.Special.HANTAR:
			BoardArt.draw_special(self, Rect2(Vector2.ZERO, size), cell.special)


func _draw_rim_light() -> void:
	if _idle_special_kind != BoardCell.Special.DULANG:
		return
	var edge := minf(size.x,size.y)
	var center := size*Vector2(.5,.60)
	var angle := _rim_phase*.7
	var rim := PackedVector2Array()
	for i in 15:
		var sweep := angle + float(i)*.5/14.0
		rim.append(center + Vector2(cos(sweep)*edge*.35,sin(sweep)*edge*.23))
	_rim_light.draw_polyline(rim,Color(1,.95,.70,.65),maxf(1,edge*.018),true)
	for i in 3:
		var glint := angle + i*TAU/3.0
		var point := center+Vector2(cos(glint)*edge*.35,sin(glint)*edge*.23)
		var extent := Vector2.ONE*edge*(.08+.035*sin(_rim_phase+i*2.0))
		_rim_light.draw_texture_rect(GameVfx.SPARKLE,Rect2(point-extent*.5,extent),false,Color(1,.97,.78,.65+.2*sin(_rim_phase+i)))
