class_name GeraiBackdrop
extends Control
const MVP_BACKGROUND_PATH := "res://assets/backgrounds/gerai_mvp.png"
const SOFT_GAMEPLAY_PATH := "res://assets/backgrounds/gameplay_market_v2/market_stall_portrait.png"
const GAMEPLAY_BLUR := preload("res://shaders/gameplay_background_blur.gdshader")
var gameplay_mode := false

var location_id: StringName = &"family_stall"
var structural_state := 0
var texture_path := ""
var _background: Texture2D
var _decor: Dictionary = {}
var _state_override := -1
var _decor_override: Variant = null

## Painted market backdrop for the stall and gameplay screens.
##
## Drawn in layers so the board always sits on top of a readable, warm scene:
## sky -> distant stalls -> stall frame -> counter -> props (Master Plan
## sections 51 and 52).

const PRESETS := {
	&"ramadan": {"sky_top": Color("694e94"), "sky_bottom": Color("ffbd79"), "canopy": Color("427534"), "canopy_alt": Color("fff0ca"), "skyline": Color("94637f"), "ground": Color("cc965d"), "accent": Color("e5af38")},
	&"school": {"sky_top": Color("c8e8f1"), "sky_bottom": Color("fff6db"), "canopy": Color("527ba4"), "canopy_alt": Color("fff0ca"), "skyline": Color("96b3c1"), "ground": Color("cbb695"), "accent": Color("6cad46")},
	&"city": {"sky_top": Color("a1c9f3"), "sky_bottom": Color("fff6db"), "canopy": Color("423a58"), "canopy_alt": Color("ffd571"), "skyline": Color("8b91ad"), "ground": Color("bba391"), "accent": Color("efb935")},
	&"stall_dawn": {
		"sky_top": Color("ffd9a8"), "sky_bottom": Color("fff3dd"),
		"canopy": Color("e4576c"), "canopy_alt": Color("fff0e0"),
		"skyline": Color("e0b98d"), "ground": Color("d8b183"),
		"accent": Color("6fae45"),
	},
	&"kuching_market": {
		"sky_top": Color("ffe7b8"), "sky_bottom": Color("fffaf0"),
		"canopy": Color("3f7f2a"), "canopy_alt": Color("f6efdc"),
		"skyline": Color("d6b38a"), "ground": Color("caa375"),
		"accent": Color("f0a93b"),
	},
	&"weekend_market": {
		"sky_top": Color("ffc98d"), "sky_bottom": Color("ffeccd"),
		"canopy": Color("f0a93b"), "canopy_alt": Color("7b4a86"),
		"skyline": Color("c99a6d"), "ground": Color("b98456"),
		"accent": Color("e4576c"),
	},
	&"chapter_boss": {
		"sky_top": Color("ffb3a0"), "sky_bottom": Color("ffe0c0"),
		"canopy": Color("8a5a33"), "canopy_alt": Color("f6d9a8"),
		"skyline": Color("b98a63"), "ground": Color("9c6c47"),
		"accent": Color("f76f8e"),
	},
	&"festival": {
		"sky_top": Color("ffd0e0"), "sky_bottom": Color("fff2d6"),
		"canopy": Color("d94f70"), "canopy_alt": Color("ffe0a8"),
		"skyline": Color("d3a074"), "ground": Color("c39063"),
		"accent": Color("ffc94d"),
	},
}

@export var background_id: StringName = &"stall_dawn":
	set(value):
		background_id = value
		queue_redraw()
## Draws only the top portion - used behind HUD-heavy screens.
@export var show_counter: bool = true
## Storyline pages sit on a calm sky rather than inside the stall, so the stall
## frame, counter and props are left out.
@export var simple: bool = false:
	set(value):
		simple = value
		queue_redraw()


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	if gameplay_mode:
		# Smooth source pixels when the cover scale exceeds 1 on larger phones.
		texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
		var blur := ShaderMaterial.new()
		blur.shader = GAMEPLAY_BLUR
		material = blur
	resized.connect(queue_redraw)
	LocationManager.location_state_changed.connect(_location_changed)
	_sync_environment()


func _col(key: String) -> Color:
	var preset: Dictionary = PRESETS.get(background_id, PRESETS[&"stall_dawn"])
	return preset.get(key, Palette.CREAM)


func _draw() -> void:
	if size.x <= 0 or size.y <= 0:
		return
	if not simple and _background != null:
		var source_size := _background.get_size()
		var scale_factor := maxf(size.x / source_size.x, size.y / source_size.y)
		var drawn_size := source_size * scale_factor
		draw_texture_rect(_background, Rect2((size - drawn_size) * 0.5, drawn_size), false, Color(.92,.92,.92) if gameplay_mode else Color.WHITE)
		if not gameplay_mode:
			_draw_structure()
			_draw_decor()
		return
	var w := size.x
	var h := size.y
	_draw_sky(Rect2(Vector2.ZERO, size))
	_draw_skyline(Vector2(0, h * 0.42))
	_draw_canopy(Vector2(0, 0), Vector2(w, h * 0.16))
	if simple:
		_draw_ground(Vector2(0, h * 0.86), w, h)
		return
	_draw_frame()
	if show_counter:
		_draw_counter(Rect2(0, h * 0.86, w, h * 0.14))
		_draw_props()
	_draw_structure()
	_draw_decor()


## Soft ground band for the simple (story) variant, so the lower half is not a
## flat slab of colour.
func _draw_ground(at: Vector2, w: float, h: float) -> void:
	var rect := Rect2(at, Vector2(w, h - at.y))
	draw_rect(rect, Color(_col("ground"), 0.55))
	draw_rect(Rect2(at, Vector2(w, h * 0.02)), Color(_col("skyline"), 0.45))
	for i in 7:
		var x := w * (0.06 + float(i) * 0.14)
		draw_circle(Vector2(x, at.y - h * 0.01), w * 0.012, Color(0.42, 0.30, 0.18, 0.18))


func _draw_sky(r: Rect2) -> void:
	var steps := 18
	for i in steps:
		var t := float(i) / float(steps - 1)
		var c := _col("sky_bottom").lerp(_col("sky_top"), t)
		draw_rect(Rect2(r.position + Vector2(0, r.size.y * t), Vector2(r.size.x, r.size.y / float(steps) + 2.0)), c)
	# sun glow
	var sun := r.position + Vector2(r.size.x * 0.82, r.size.y * 0.20)
	draw_circle(sun, r.size.x * 0.16, Color(1, 0.98, 0.86, 0.35))
	draw_circle(sun, r.size.x * 0.10, Color(1, 0.99, 0.92, 0.55))


func _draw_skyline(base: Vector2) -> void:
	var w := size.x
	var color := _col("skyline")
	# far stalls
	for i in 5:
		var x := w * (0.04 + float(i) * 0.21)
		var bw := w * 0.17
		var bh := size.y * (0.10 + 0.03 * float((i * 7) % 3))
		draw_rect(Rect2(Vector2(x, base.y - bh), Vector2(bw, bh)), Color(color.r, color.g, color.b, 0.55))
		# little awning
		var awn := Palette.PINK_PALE if i % 2 == 0 else Palette.GOLD_PALE
		draw_rect(Rect2(Vector2(x - bw * 0.08, base.y - bh - size.y * 0.02), Vector2(bw * 1.16, size.y * 0.02)), awn)
	# palm hints
	for i in 3:
		var px := w * (0.18 + float(i) * 0.33)
		draw_line(Vector2(px, base.y), Vector2(px + w * 0.01, base.y - size.y * 0.16), Palette.WOOD, 6.0)
		for f in 5:
			var a := -PI * 0.5 + (float(f) - 2.0) * 0.42
			draw_line(
				Vector2(px + w * 0.01, base.y - size.y * 0.16),
				Vector2(px + w * 0.01, base.y - size.y * 0.16) + Vector2(cos(a), sin(a)) * w * 0.07,
				Palette.LEAF_DARK, 5.0
			)


func _draw_canopy(origin: Vector2, s: Vector2) -> void:
	draw_rect(Rect2(origin, s), _col("canopy"))
	var stripes := 8
	var stripe_w := s.x / float(stripes)
	for i in range(0, stripes, 2):
		draw_rect(Rect2(origin + Vector2(stripe_w * float(i), 0), Vector2(stripe_w, s.y)), _col("canopy_alt"))
	# scalloped hem
	for i in stripes:
		var c := origin + Vector2(stripe_w * (float(i) + 0.5), s.y)
		draw_circle(c, stripe_w * 0.5, _col("canopy") if i % 2 == 0 else _col("canopy_alt"))
	draw_rect(Rect2(origin, Vector2(s.x, s.y * 0.12)), Palette.darken(_col("canopy"), 0.18))


func _draw_frame() -> void:
	var w := size.x
	var post := w * 0.045
	var top := size.y * 0.16
	var bottom := size.y * 0.86
	draw_rect(Rect2(0, top, post, bottom - top), Palette.WOOD)
	draw_rect(Rect2(w - post, top, post, bottom - top), Palette.WOOD)
	for side in [0.0, 1.0]:
		var x := post * 0.5 if side == 0.0 else w - post * 0.5
		draw_rect(Rect2(x - post * 0.18, top, post * 0.36, bottom - top), Palette.WOOD_LIGHT)
	# hanging lanterns
	for i in 3:
		var lx := w * (0.22 + float(i) * 0.28)
		var ly := top + size.y * 0.05
		draw_line(Vector2(lx, top), Vector2(lx, ly), Palette.WOOD_DARK, 4.0)
		draw_circle(Vector2(lx, ly + 18.0), 16.0, Palette.PINK_LIGHT)
		draw_circle(Vector2(lx, ly + 18.0), 8.0, Palette.GOLD_PALE)


func _draw_counter(r: Rect2) -> void:
	draw_rect(r, Palette.WOOD)
	draw_rect(Rect2(r.position, Vector2(r.size.x, r.size.y * 0.14)), Palette.WOOD_LIGHT)
	# plank seams
	var planks := 6
	for i in range(1, planks):
		var x := r.position.x + r.size.x * float(i) / float(planks)
		draw_line(Vector2(x, r.position.y), Vector2(x, r.position.y + r.size.y), Palette.WOOD_DARK, 3.0)


func _draw_props() -> void:
	var w := size.x
	var base := size.y * 0.86
	# plants in baskets
	for side in [0, 1]:
		var x := w * (0.10 if side == 0 else 0.90)
		draw_rect(Rect2(x - w * 0.05, base - size.y * 0.05, w * 0.10, size.y * 0.05), Palette.WOOD_PALE)
		for i in 5:
			var a := -PI * 0.5 + (float(i) - 2.0) * 0.38
			var from := Vector2(x, base - size.y * 0.05)
			draw_line(from, from + Vector2(cos(a), sin(a)) * size.y * 0.055, _col("accent"), 7.0)
# chalkboard sign
	var board := Rect2(w * 0.26, base - size.y * 0.135, w * 0.48, size.y * 0.085)
	draw_rect(board, Palette.WOOD_DARK)
	draw_rect(board.grow(-5.0), Color("2f3b33"))
	var sign_text := "Good Kuih, Brighter Days"
	var font := UIKit.bold_font()
	var text_size := UIKit.fit_font_size(sign_text, board.size.x - 44.0, int(board.size.y * 0.44))
	draw_string(
		font,
		Vector2(board.position.x + 22.0, board.position.y + board.size.y * 0.5 + text_size * 0.36),
		sign_text,
		HORIZONTAL_ALIGNMENT_LEFT,
		board.size.x - 44.0,
		text_size,
		Palette.PAPER
	)


func apply_environment(id: StringName, decor_preview: Variant = null, state_preview: int = -1) -> void:
	location_id = id
	_state_override = mini(state_preview, LocationManager.structural_level(id)) if state_preview >= 0 else -1
	_decor_override = decor_preview
	_sync_environment()

func debug_preview(id: StringName, level: int, decor_preview: Variant = null) -> void:
	if not OS.has_feature("debug"):
		return
	location_id = id
	_state_override = clampi(level, 0, 3)
	_decor_override = decor_preview
	_sync_environment()

func _location_changed(id: StringName) -> void:
	if id == location_id and _state_override < 0:
		_sync_environment()

func _sync_environment() -> void:
	var location := LocationDefinition.find(location_id)
	structural_state = _state_override if _state_override >= 0 else LocationManager.structural_level(location.id)
	background_id = location.preset
	var path := LocationManager.effective_background(location, structural_state)
	# The supplied complete stall artwork is the puzzle backdrop. Location and
	# restoration artwork continue to be displayed on the stall/shop screens.
	if gameplay_mode:
		path = SOFT_GAMEPLAY_PATH
	if path != texture_path or (_background == null and not path.is_empty()):
		texture_path = path
		_background = load(path) if not path.is_empty() else null
	_decor = _decor_override if _decor_override is Dictionary else LocationManager.equipped(location_id)
	queue_redraw()

func _draw_structure() -> void:
	if simple:
		return
	if location_id == &"family_stall" and structural_state == 0:
		if OnboardingProgress.restored():
			StallComponentArt.draw_component(self,"trim",Rect2(0,0,size.x,size.y*.07))
			StallComponentArt.draw_component(self,"cloth",Rect2(size.x*.14,size.y*.87,size.x*.72,size.y*.09))
		else:
			draw_rect(Rect2(Vector2.ZERO,size),Color(.27,.19,.10,.16))
			for side in [0.04,0.96]:
				var at := Vector2(size.x*side,size.y*.18)
				draw_polyline(PackedVector2Array([at,at+Vector2(-size.x*.012,size.y*.04),at+Vector2(size.x*.01,size.y*.07),at+Vector2(0,size.y*.11)]),Color(.17,.09,.04,.65),maxf(2,size.x*.004),true)
	var location := LocationDefinition.find(location_id)
	if location.background_mode == "full_texture":
		return
	for layer in location.layers:
		if structural_state < int(layer.get("level", 0)):
			continue
		var relative: Rect2 = layer.rect
		var rect := Rect2(relative.position*size, relative.size*size)
		StallComponentArt.draw_component(self, layer.kind, rect)
		if layer.kind == "sign":
			var label := "KUIH EMPIRE" if structural_state == 3 else "KUIH"
			draw_string(UIKit.bold_font(), rect.position+Vector2(rect.size.x*.1,rect.size.y*.69),label,HORIZONTAL_ALIGNMENT_CENTER,rect.size.x*.8,int(size.x*.030),Palette.PAPER)

func _draw_decor() -> void:
	if simple:
		return
	for slot in _decor:
		var item := DecorDefinition.find(str(_decor[slot]))
		if item == null or not item.gameplay_safe:
			continue
		match item.kind:
			"flower":
				var at := Vector2(size.x*.065, size.y*.72)
				draw_style_box(UIKit.wood_box(Palette.WOOD_LIGHT), Rect2(at + Vector2(-size.x*.035, 0), Vector2(size.x*.07, size.y*.045)))
				draw_line(at, at-Vector2(0,size.y*.05), Palette.LEAF, size.x*.008, true)
				_draw_flower(at-Vector2(0,size.y*.05), size.x*.035)
			"lamp":
				StallComponentArt.draw_component(self,"lamp",Rect2(size.x*.89,size.y*.19,size.x*.10,size.y*.12))
			"cloth":
				StallComponentArt.draw_component(self,"cloth",Rect2(size.x*.16,size.y*.88,size.x*.68,size.y*.075))

func _draw_flower(at: Vector2, radius: float) -> void:
	for petal in 5:
		var angle := petal * TAU / 5
		draw_circle(at + Vector2.from_angle(angle)*radius*.6, radius*.6, Palette.PINK)
	draw_circle(at, radius*.3, Palette.GOLD_PALE)
