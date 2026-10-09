class_name GameplaySkin
extends RefCounted

static var _textures: Dictionary = {}
const BOUNDS := {
	"booster_blue": Rect2(112, 109, 1029, 1009),
	"booster_gold": Rect2(92, 90, 1068, 1074),
	"booster_green": Rect2(97, 99, 1058, 1025),
	"booster_purple": Rect2(103, 118, 1048, 995),
	"booster_tray": Rect2(28, 109, 2116, 498),
	"coin_pill": Rect2(157, 110, 1893, 455),
	"moves_board": Rect2(41, 99, 1172, 1016),
	"order_board": Rect2(23, 39, 1728, 804),
	"progress_track": Rect2(18, 158, 2136, 391),
	"settings": Rect2(95, 99, 1064, 1058),
	"star": Rect2(38, 49, 1177, 1121),
	"star_meter": Rect2(45, 104, 2001, 500),
}

static func texture(id: String) -> Texture2D:
	if id == "star":
		return ResourceIconArt.texture("star")
	if not _textures.has(id):
		if id in ["booster_tray", "booster_hand", "booster_count"]:
			var asset := AtlasTexture.new()
			var files := {"booster_tray": "wooden_tray", "booster_hand": "hand", "booster_count": "red_chip"}
			var regions := {"booster_tray": Rect2(53,90,2064,524), "booster_hand": Rect2(78,50,1102,1161), "booster_count": Rect2(71,61,1112,1114)}
			asset.atlas = load("res://assets/ui/booster_tray_v1/%s.png" % files[id])
			asset.region = regions[id]
			_textures[id] = asset
			return asset
		if id == "settings":
			var settings_art := AtlasTexture.new()
			settings_art.atlas = load("res://assets/ui/settings_v1/settings_pink.png")
			settings_art.region = Rect2(147,152,951,949)
			_textures[id] = settings_art
			return settings_art
		if id == "moves_hanging":
			var hanging := AtlasTexture.new()
			hanging.atlas = load("res://assets/ui/moves_board_v1/hanging_moves_board.png")
			hanging.region = Rect2(89,0,1039,1078)
			_textures[id] = hanging
			return hanging
		var booster_index := ["booster_blue", "booster_gold", "booster_green", "booster_purple"].find(id)
		if booster_index >= 0:
			var sheet: Texture2D = load("res://assets/ui/gameplay_v5/booster_surfaces.png")
			var edge := sheet.get_width()/2
			var origin := Vector2i(booster_index%2, booster_index/2)*edge
			var bounds := sheet.get_image().get_region(Rect2i(origin,Vector2i(edge,edge))).get_used_rect()
			var surface := AtlasTexture.new()
			surface.atlas = sheet
			surface.region = Rect2(bounds.position+origin,bounds.size)
			_textures[id] = surface
			return surface
		var folder := "gameplay_v4" if id in ["moves_board", "star_meter"] else "gameplay_v3" if id == "speech_bubble" else "gameplay_v2"
		var source: Texture2D = load("res://assets/ui/%s/%s.png" % [folder, id])
		if BOUNDS.has(id) or id == "star_meter":
			var atlas := AtlasTexture.new()
			atlas.atlas = source
			atlas.region = source.get_image().get_used_rect() if folder == "gameplay_v4" and id != "star_meter" else BOUNDS[id]
			_textures[id] = atlas
		else:
			_textures[id] = source
	return _textures[id]

static func box(id: String, margins: Vector4 = Vector4.ZERO) -> StyleBoxTexture:
	var style := StyleBoxTexture.new()
	style.texture = texture(id)
	style.content_margin_left = margins.x
	style.content_margin_top = margins.y
	style.content_margin_right = margins.z
	style.content_margin_bottom = margins.w
	return style

static func button(node: Button, id: String) -> void:
	if id == "settings":
		for state in ["normal","hover","pressed","disabled","focus"]:
			node.add_theme_stylebox_override(state,StyleBoxEmpty.new())
		var icon := TextureRect.new()
		icon.name = "SettingsArtwork"
		icon.texture = texture(id)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		node.add_child(icon)
		icon.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		node.mouse_entered.connect(func() -> void: icon.modulate = Color(1.08,1.08,1.08))
		node.mouse_exited.connect(func() -> void: icon.modulate = Color.WHITE)
		node.button_down.connect(func() -> void: icon.modulate = Color(.82,.82,.82))
		node.button_up.connect(func() -> void: icon.modulate = Color.WHITE)
		return
	for state in ["normal", "hover", "pressed", "disabled"]:
		var style := box(id)
		style.modulate_color = Color(.65, .65, .65, .8) if state == "disabled" else Color(.85, .85, .85) if state == "pressed" else Color(1.08, 1.08, 1.08) if state == "hover" else Color.WHITE
		node.add_theme_stylebox_override(state, style)
	var focus := UIKit.flat_box(Color.TRANSPARENT, Palette.GOLD, 0, 3)
	node.add_theme_stylebox_override("focus", focus)
