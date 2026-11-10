class_name GeraiBackdrop
extends Control
const MVP_BACKGROUND_PATH := "res://assets/backgrounds/gerai_mvp.png"
const SOFT_GAMEPLAY_PATH := "res://assets/backgrounds/gameplay_market_v2/market_stall_portrait.png"
const GAMEPLAY_BLUR := preload("res://shaders/gameplay_background_blur.gdshader")
var gameplay_mode := false
var background_context := "renovation"
var follow_active_stall := false
var _authored_background := false
var _previous_background: Texture2D
var _blend := 1.0
var _fade: Tween


var location_id: StringName = &"family_stall"
var structural_state := 0
var texture_path := ""
var _background: Texture2D
var _decor: Dictionary = {}
var _state_override := -1
var _decor_override: Variant = null
var _variant_override := ""
var _decor_styles_override: Variant = null
var renovation_focus := Vector2(.5, 0)
var _style_accent: TextureRect
var hidden_decor_slot := ""
var renovation_showcase := false
var hidden_structure := 0
var component_preview: Dictionary = {}
var showcase_focus := Rect2()
var showcase_pan := Vector2.ZERO
const SHOWCASE_BACKGROUND := "res://assets/stalls/kuching_v2/empty_stall.png"
var _showcase_texture: Texture2D

func showcase_active() -> bool:
	return renovation_showcase and location_id == &"family_stall" and ResourceLoader.exists(SHOWCASE_BACKGROUND)

func showcase_rect() -> Rect2:
	if _showcase_texture == null:
		_showcase_texture = load(SHOWCASE_BACKGROUND) as Texture2D
	var extent := _showcase_texture.get_size() * maxf(size.x / _showcase_texture.get_width(), size.y / _showcase_texture.get_height())
	return Rect2((size - extent) * .5 + showcase_pan,extent)

func component_rect(stage: int) -> Rect2:
	return [Rect2(.02,.245,.96,.13),Rect2(.20,.448,.24,.115),Rect2(.13,.34,.74,.105)][clampi(stage-1,0,2)]

func lantern_rect(side: int) -> Rect2:
	return Rect2(.15 if side == 0 else .73,.335,.12,.14)

func decor_rect(item: DecorDefinition) -> Rect2:
	if not showcase_active() and background_context == "menu" and not gameplay_mode and item.id == "pink_batik":
		return Rect2(-.035,.605,1.07,.31)
	if not showcase_active():
		return item.art_rect(location_id)
	return {"flower":Rect2(.77,.485,.15,.13),"lamp":Rect2(.77,.36,.10,.10),"cloth":Rect2(.115,.565,.77,.16),"food":Rect2(.15,.49,.70,.12),"sign":Rect2(.33,.35,.37,.055),"counter":Rect2(.13,.61,.74,.115)}[item.kind]

func _draw_showcase() -> void:
	var frame := showcase_rect()
	draw_rect(Rect2(Vector2.ZERO,size), Color("435d32"))
	if showcase_pan != Vector2.ZERO:
		draw_texture_rect(_showcase_texture,Rect2(frame.position-showcase_pan,frame.size),false)
	draw_texture_rect(_showcase_texture,frame,false)
	var styles: Dictionary = _decor_styles_override if _decor_styles_override is Dictionary else LocationManager.decor_styles(location_id)
	for stage in range(1, structural_state + 1):
		if stage == hidden_structure:
			continue
		var uv := component_rect(stage)
		var choice: String = component_preview.get(stage, _effective_variant() if stage == structural_state else LocationManager.variant_for(location_id,stage))
		if stage == 3:
			for side in 2:
				var lamp_uv := lantern_rect(side)
				var lamp_target := Rect2(art_point(lamp_uv.position),art_point(lamp_uv.end)-art_point(lamp_uv.position))
				var lamp_texture := RenovationArt.lantern_side(choice,side)
				var extent := lamp_texture.get_size() * minf(lamp_target.size.x / lamp_texture.get_width(),lamp_target.size.y / lamp_texture.get_height())
				draw_texture_rect(lamp_texture,Rect2(lamp_target.get_center()-extent*.5,extent),false)
			continue
		draw_texture_rect(RenovationArt.component_texture(stage,choice),Rect2(art_point(uv.position),art_point(uv.end)-art_point(uv.position)),false)
	if _decor.has("COUNTER_FRONT") and hidden_decor_slot != "COUNTER_FRONT":
		_draw_decor_texture(DecorDefinition.find(str(_decor.COUNTER_FRONT)),Color.WHITE,str(styles.get("COUNTER_FRONT","original")))
	# The runner rests on the counter, underneath every food display regardless of purchase order.
	if _decor.has("COUNTER_DECOR") and hidden_decor_slot != "COUNTER_DECOR":
		_draw_decor_texture(DecorDefinition.find(str(_decor.COUNTER_DECOR)),Color.WHITE,str(styles.get("COUNTER_DECOR","original")))
	for slot in _decor:
		if slot == hidden_decor_slot or slot in ["COUNTER_FRONT","COUNTER_DECOR"]:
			continue
		var item := DecorDefinition.find(str(_decor[slot]))
		if item != null:
			_draw_decor_texture(item,Color.WHITE,str(styles.get(slot,"original")))
	if showcase_focus.size != Vector2.ZERO:
		var target := Rect2(art_point(showcase_focus.position),art_point(showcase_focus.end)-art_point(showcase_focus.position))
		draw_rect(target.grow(4),Color(1,.85,.24,.28),false,8,true)
		draw_rect(target,Color("ffe680"),false,3,true)
	var sign := Rect2(art_point(Vector2(.35,.357)),art_point(Vector2(.68,.395))-art_point(Vector2(.35,.357)))
	_draw_sign_name(sign)

## Light lettering with a dark rim, as on the stall name plate; dark text sinks into the wood.
func _draw_sign_name(sign: Rect2) -> void:
	var font := UIKit.bold_font()
	var text := JourneyLibrary.location_name(location_id)
	var font_size := int(sign.size.y*.60)
	while font_size > 12 and font.get_string_size(text,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size).x > sign.size.x*.86:
		font_size -= 1
	var baseline := sign.position + Vector2(0,sign.size.y*.5 + font_size*.36)
	draw_string_outline(font,baseline,text,HORIZONTAL_ALIGNMENT_CENTER,sign.size.x,font_size,maxi(4,font_size/5),Palette.WOOD_DARK)
	draw_string(font,baseline,text,HORIZONTAL_ALIGNMENT_CENTER,sign.size.x,font_size,Palette.PAPER)
const FABRIC_ACCENT := preload("res://shaders/stall_fabric_accent.gdshader")

## Painted market backdrop for the stall and gameplay screens.
##
## Drawn in layers so the board always sits on top of a readable, warm scene:
## sky -> distant stalls -> stall frame -> counter -> props (Master Plan
## sections 51 and 52).

const PRESETS := {
	&"government": {"sky_top": Color("bcdde0"), "sky_bottom": Color("fff6db"), "canopy": Color("35797f"), "canopy_alt": Color("f2ead7"), "skyline": Color("99aeb2"), "ground": Color("bcb6a6"), "accent": Color("55987c")},
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
	_style_accent = TextureRect.new()
	_style_accent.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_style_accent.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_style_accent.stretch_mode = TextureRect.STRETCH_SCALE
	var fabric := ShaderMaterial.new()
	fabric.shader = FABRIC_ACCENT
	_style_accent.material = fabric
	_style_accent.hide()
	add_child(_style_accent)
	if gameplay_mode:
		# Smooth source pixels when the cover scale exceeds 1 on larger phones.
		texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
		var blur := ShaderMaterial.new()
		blur.shader = GAMEPLAY_BLUR
		material = blur
	resized.connect(queue_redraw)
	LocationManager.location_state_changed.connect(_location_changed)
	LocationManager.active_stall_changed.connect(_active_changed)
	if follow_active_stall:
		location_id = LocationManager.active_stall_id()
	_sync_environment()

func _active_changed(id: StringName) -> void:
	if follow_active_stall:
		location_id = id
		_sync_environment()


func _col(key: String) -> Color:
	var preset: Dictionary = PRESETS.get(background_id, PRESETS[&"stall_dawn"])
	return preset.get(key, Palette.CREAM)


func cover_rect(texture_size: Vector2) -> Rect2:
	var scaled := texture_size * maxf(size.x / texture_size.x, size.y / texture_size.y)
	var focus := renovation_focus if background_context == "renovation" and not gameplay_mode else Vector2(.5, .5)
	return Rect2((size - scaled) * focus, scaled)

func art_point(uv: Vector2) -> Vector2:
	if showcase_active():
		var rect := showcase_rect()
		return rect.position + uv * rect.size
	if _background == null or size.x <= 0 or size.y <= 0:
		return uv * size
	var rectangle := cover_rect(_background.get_size())
	return rectangle.position + uv * rectangle.size

func _draw() -> void:
	if size.x <= 0 or size.y <= 0:
		return
	if showcase_active():
		if _style_accent != null:
			_style_accent.hide()
		_draw_showcase()
		return
	if not simple and _background != null:
		var source_size := _background.get_size()
		draw_texture_rect(_background, cover_rect(source_size), false, Color(.92,.92,.92) if gameplay_mode else Color.WHITE)
		if _previous_background != null and _blend < 1.0:
			var old_size := _previous_background.get_size()
			draw_texture_rect(_previous_background, cover_rect(old_size), false, Color(1, 1, 1, 1.0 - _blend))
		if not _authored_background:
			_draw_structure()
		_draw_style_accent()
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
	_variant_override = ""
	_decor_styles_override = null
	location_id = id
	_state_override = mini(state_preview, LocationManager.structural_level(id)) if state_preview >= 0 else -1
	_decor_override = decor_preview
	_sync_environment()

## An uncommitted visual preview. Never changes progression or saved choices.
func preview_design(id: StringName, state: int, variant: String, decor: Dictionary, styles: Dictionary) -> void:
	location_id = id
	_state_override = clampi(state, 0, 3)
	_variant_override = variant
	_decor_override = decor.duplicate()
	_decor_styles_override = styles.duplicate()
	_sync_environment()

func _effective_variant() -> String:
	return _variant_override if not _variant_override.is_empty() else LocationManager.variant_for(location_id, structural_state)

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
	var context := "gameplay" if gameplay_mode else background_context
	var visual := StallDefinition.find(location_id).state(structural_state)
	var path := visual.background_path(context, _effective_variant())
	_authored_background = ResourceLoader.exists(path)
	if not _authored_background:
		path = ""
		# Existing Family artwork is a temporary base; structural layers remain visible.
		if location_id == &"family_stall":
			path = "res://assets/menu/v1/background.png" if context == "menu" else SOFT_GAMEPLAY_PATH if context == "gameplay" else MVP_BACKGROUND_PATH

	if path != texture_path or (_background == null and not path.is_empty()):
		_previous_background = _background
		texture_path = path
		_background = load(path) if not path.is_empty() else null
		if is_inside_tree() and _previous_background != null and _background != null:
			if _fade != null:
				_fade.kill()
			_blend = 0.0
			_fade = create_tween()
			_fade.tween_method(func(value: float) -> void: _blend = value; queue_redraw(), 0.0, 1.0, .28)
			_fade.tween_callback(func() -> void: _previous_background = null)
		else:
			_previous_background = null

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
	var variant := _effective_variant()
	if structural_state > 0 and variant != "classic":
		var accent := Color("e885a3") if variant == "batik" else Color("75b542")
		draw_rect(Rect2(0, size.y * .125, size.x, size.y * .018), accent)
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
	var styles: Dictionary = _decor_styles_override if _decor_styles_override is Dictionary else LocationManager.decor_styles(location_id)
	# Use existing fabric artwork as a visible accent for the three stall styles.
	# Dedicated alternate background masters can replace these accents later.
	var variant := _effective_variant()
	if structural_state > 0 and variant != "classic" and not _decor.has("COUNTER_DECOR"):
		var accent_id := "steel_organizer" if location_id in [&"school_canteen", &"government_canteen"] else "pink_batik"
		var accent := DecorDefinition.find(accent_id)
		_draw_decor_texture(accent, Color(.65, 1, .75) if variant == "pandan" else Color.WHITE)
	for slot in _decor:
		if slot == hidden_decor_slot:
			continue
		var item := DecorDefinition.find(str(_decor[slot]))
		if item == null or not item.gameplay_safe or not item.suitable_for(location_id):
			continue
		if RenovationArt.texture(item.id) != null:
			_draw_decor_texture(item, Color.WHITE, str(styles.get(slot, "original")))
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

func _draw_decor_texture(item: DecorDefinition, tint: Color, style: String = "original") -> void:
	var texture := RenovationArt.design_texture(item.id, style)
	if texture == null:
		return
	var uv := decor_rect(item)
	var target := Rect2(art_point(uv.position), art_point(uv.end) - art_point(uv.position))
	if item.id == "pink_batik":
		# Same placement as the old draped runner, but only its counter-top band,
		# so the runner ends at the table's front edge.
		var full := target
		if not (showcase_active() or (background_context == "menu" and not gameplay_mode)):
			var fit := Vector2(RenovationArt.RUNNER_FULL_ASPECT, 1.0) * minf(target.size.x / RenovationArt.RUNNER_FULL_ASPECT, target.size.y)
			full = Rect2(target.get_center() - fit * .5, fit)
		draw_texture_rect(texture, Rect2(full.position, Vector2(full.size.x, full.size.y * RenovationArt.RUNNER_TOP_FRACTION)), false, tint)
		return
	if item.kind in ["sign","counter"] or (item.id == "pink_batik" and (showcase_active() or (background_context == "menu" and not gameplay_mode))):
		draw_texture_rect(texture,target,false,tint)
		# The showcase names its own painted board; elsewhere the bought sign carries the name.
		if item.kind == "sign" and not showcase_active():
			_draw_sign_name(target)
		return
	var extent := texture.get_size() * minf(target.size.x / texture.get_width(), target.size.y / texture.get_height())
	draw_texture_rect(texture, Rect2(target.get_center() - extent * .5, extent), false, tint)

func _draw_style_accent() -> void:
	if _style_accent == null:
		return
	_style_accent.hide()
	var variant := _effective_variant()
	if _background == null or not _authored_background or structural_state == 0 or variant == "classic":
		return
	var context := "gameplay" if gameplay_mode else background_context
	var visual := StallDefinition.find(location_id).state(structural_state)
	if visual.background_path(context,variant) != visual.background_path(context,"classic"):
		return # Dedicated future variants already contain their own style.
	# Reuse the painted awning pixels so the accent keeps the original texture.
	var uv := Rect2(.14,.018,.70,.14)
	var pixels := _background.get_size()
	var source := Rect2(uv.position * pixels, uv.size * pixels)
	var target := Rect2(art_point(uv.position), art_point(uv.end) - art_point(uv.position))
	var atlas := AtlasTexture.new()
	atlas.atlas = _background
	atlas.region = source
	atlas.filter_clip = true
	_style_accent.texture = atlas
	_style_accent.position = target.position
	_style_accent.size = target.size
	(_style_accent.material as ShaderMaterial).set_shader_parameter("accent",Color(.35,.72,.32) if variant == "pandan" else Color(1,.33,.64))
	_style_accent.show()

func _draw_flower(at: Vector2, radius: float) -> void:
	for petal in 5:
		var angle := petal * TAU / 5
		draw_circle(at + Vector2.from_angle(angle)*radius*.6, radius*.6, Palette.PINK)
	draw_circle(at, radius*.3, Palette.GOLD_PALE)
