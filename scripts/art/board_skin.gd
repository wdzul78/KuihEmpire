class_name BoardSkin
extends RefCounted

static var _textures: Dictionary = {}
static var _frame: StyleBoxTexture

static func texture(id: String) -> Texture2D:
	if not _textures.has(id):
		var source: Texture2D = load("res://assets/ui/board_v3/bamboo_frame.png" if id == "frame" else "res://assets/ui/board_v1/%s.png" % id)
		var atlas := AtlasTexture.new()
		atlas.atlas = source
		# Ignore faint export shadows outside the painted wooden silhouette.
		atlas.region = Rect2(72, 84, 1110, 1088) if id == "slot" else Rect2(31,39,1192,1175)
		_textures[id] = atlas
	return _textures[id]

static func draw_frame(canvas: CanvasItem, rect: Rect2, rim_width: float) -> void:
	if _frame == null:
		_frame = StyleBoxTexture.new()
		_frame.texture = texture("frame")
		_frame.draw_center = false
		for side in [SIDE_LEFT, SIDE_TOP, SIDE_RIGHT, SIDE_BOTTOM]:
			_frame.set_texture_margin(side, 160)
	# Scale a native nine-patch so its painted corners retain a thin rim at
	# every board size; stretching the entire frame would widen the borders.
	var scale_factor := rim_width / 54.0
	canvas.draw_set_transform(Vector2.ZERO, 0, Vector2.ONE * scale_factor)
	canvas.draw_style_box(_frame, Rect2(rect.position / scale_factor, rect.size / scale_factor))
	canvas.draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)

## Pale wooden tray surface. Grain and grid stay behind the food and never pulse.
static func draw_softwood(canvas: CanvasItem, frame: Rect2, board: Rect2, columns: int, rows: int, padding: float) -> void:
	var surface := StyleBoxFlat.new()
	surface.bg_color = Color("3f485c", .80)
	surface.set_corner_radius_all(int(padding * 1.6))
	# The edited PNG contains only the wooden frame. The playing surface and
	# grid are generated here, independent of the number of cells.
	canvas.draw_style_box(surface, frame.grow(-padding*.2))
	# Thin, low-contrast lines mark cell boundaries without enclosing each kuih.
	var grid := Color(.72, .77, .88, .13)
	for column in range(1, columns):
		var x := board.position.x + board.size.x * column / columns
		canvas.draw_line(Vector2(x, board.position.y), Vector2(x, board.end.y), grid, 1.0, true)
	for row in range(1, rows):
		var y := board.position.y + board.size.y * row / rows
		canvas.draw_line(Vector2(board.position.x, y), Vector2(board.end.x, y), grid, 1.0, true)
