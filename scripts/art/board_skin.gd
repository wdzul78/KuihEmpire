class_name BoardSkin
extends RefCounted

static var _textures: Dictionary = {}
static var _frame: StyleBoxTexture

static func texture(id: String) -> Texture2D:
	if not _textures.has(id):
		var source: Texture2D = load("res://assets/ui/board_v1/%s.png" % id)
		var atlas := AtlasTexture.new()
		atlas.atlas = source
		# Ignore faint export shadows outside the painted wooden silhouette.
		atlas.region = Rect2(72, 84, 1110, 1088) if id == "slot" else Rect2(36, 40, 1182, 1159)
		_textures[id] = atlas
	return _textures[id]

static func draw_frame(canvas: CanvasItem, rect: Rect2, rim_width: float) -> void:
	if _frame == null:
		_frame = StyleBoxTexture.new()
		_frame.texture = texture("frame")
		_frame.draw_center = false
		for side in [SIDE_LEFT, SIDE_TOP, SIDE_RIGHT, SIDE_BOTTOM]:
			_frame.set_texture_margin(side, 120)
	# Scale a native nine-patch so its painted corners retain a thin rim at
	# every board size; stretching the entire frame would widen the borders.
	var scale_factor := rim_width / 90.0
	canvas.draw_set_transform(Vector2.ZERO, 0, Vector2.ONE * scale_factor)
	canvas.draw_style_box(_frame, Rect2(rect.position / scale_factor, rect.size / scale_factor))
	canvas.draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)

## Pale wooden tray surface. Grain and grid stay behind the food and never pulse.
static func draw_softwood(canvas: CanvasItem, frame: Rect2, board: Rect2, columns: int, rows: int, padding: float) -> void:
	var surface := StyleBoxFlat.new()
	surface.bg_color = Color("dfb77f")
	surface.set_corner_radius_all(int(padding * 1.2))
	canvas.draw_style_box(surface, frame)
	# Broad, gentle tonal bands read as wood rather than separate sunken pockets.
	for band in range(24):
		var t := float(band) / 24.0
		var warmth := Color("eccb98").lerp(Color("d4a66d"), t)
		warmth.a = .35
		canvas.draw_rect(Rect2(board.position + Vector2(0, board.size.y * t), Vector2(board.size.x, board.size.y / 24.0 + .5)), warmth)
	for grain in range(30):
		var baseline := board.position.y + board.size.y * (grain + .5) / 30.0
		var points := PackedVector2Array()
		for step in range(33):
			var t := float(step) / 32.0
			var wave := sin(t * 9.0 + grain * 1.73) * padding * .22 + sin(t * 19.0 + grain * .61) * padding * .07
			points.append(Vector2(board.position.x + board.size.x * t, clampf(baseline + wave, board.position.y, board.end.y)))
		canvas.draw_polyline(points, Color(.47, .29, .13, .065), 1.3, true)
	# Thin, low-contrast lines mark cell boundaries without enclosing each kuih.
	var grid := Color(.40, .24, .10, .16)
	for column in range(1, columns):
		var x := board.position.x + board.size.x * column / columns
		canvas.draw_line(Vector2(x, board.position.y), Vector2(x, board.end.y), grid, 2.4, true)
	for row in range(1, rows):
		var y := board.position.y + board.size.y * row / rows
		canvas.draw_line(Vector2(board.position.x, y), Vector2(board.end.x, y), grid, 2.4, true)
