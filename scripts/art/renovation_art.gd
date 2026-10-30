class_name RenovationArt
extends RefCounted

const ROOT := "res://assets/stalls/accessories_v1/"
static var _textures: Dictionary = {}
const DESIGN_SHEET := "res://assets/stalls/accessories_v2/designs.png"
const DESIGN_ROWS := ["hibiscus", "rattan_lamp", "pink_batik", "office_plant", "modern_pendant", "steel_organizer"]
const STRUCTURE_SHEET := "res://assets/stalls/kuching_v2/empty_rack_parts.png"
const FOOD_SHEET := "res://assets/stalls/kuching_v2/food_displays.png"
const FOOD_IDS := ["kuih_display", "kuih_feast"]
const FINISH_IDS := ["shop_sign", "counter_finish"]
const FINISH_SHEET := "res://assets/stalls/shop_complete_v1/finishes.png"
const RUNNER_SHEET := "res://assets/stalls/counter_runner_v1/runners.png"
const HIBISCUS_COUNTER := "res://assets/stalls/accessories_v3/hibiscus_counter.png"

static func component_texture(stage: int, variant: String) -> Texture2D:
	var key := "component:%d:%s" % [stage,variant]
	if _textures.has(key):
		return _textures[key]
	var source := load(STRUCTURE_SHEET) as Texture2D
	var column := maxi(0,["classic","batik","pandan"].find(variant))
	var row := clampi(stage - 1,0,2)
	var rows := [0.0,.24,.624,1.0]
	var atlas := AtlasTexture.new()
	atlas.atlas = source
	atlas.region = Rect2(column * source.get_width() / 3.0,rows[row] * source.get_height(),source.get_width() / 3.0,(rows[row+1]-rows[row]) * source.get_height())
	atlas.filter_clip = true
	_textures[key] = atlas
	return atlas

static func lantern_side(variant: String, side: int) -> Texture2D:
	var key := "lantern:%s:%d" % [variant,side]
	if _textures.has(key):
		return _textures[key]
	var source := component_texture(3,variant)
	var atlas := AtlasTexture.new()
	atlas.atlas = source
	atlas.region = Rect2(Vector2(source.get_width() * .5 * side,0),Vector2(source.get_width() * .5,source.get_height()))
	atlas.filter_clip = true
	_textures[key] = atlas
	return atlas

static func design_texture(key: String, style: String = "original") -> Texture2D:
	if key == "pink_batik":
		var cache_key := "runner:" + style
		if _textures.has(cache_key):
			return _textures[cache_key]
		var source := load(RUNNER_SHEET) as Texture2D
		var column := maxi(0,DecorDefinition.STYLES.find(style))
		var atlas := AtlasTexture.new()
		atlas.atlas = source
		atlas.region = Rect2(column * 724 + 16,90,696,520)
		atlas.filter_clip = true
		_textures[cache_key] = atlas
		return atlas
	if key in FINISH_IDS:
		var cache_key := key + ":" + style
		if _textures.has(cache_key):
			return _textures[cache_key]
		if not ResourceLoader.exists(FINISH_SHEET):
			return null
		var source := load(FINISH_SHEET) as Texture2D
		var atlas := AtlasTexture.new()
		atlas.atlas = source
		var regions := [Rect2(35,210,475,215),Rect2(535,215,470,210),Rect2(1025,185,485,240),Rect2(35,580,475,260),Rect2(535,580,470,260),Rect2(1025,580,485,260)]
		atlas.region = regions[FINISH_IDS.find(key)*3 + maxi(0,DecorDefinition.STYLES.find(style))]
		atlas.filter_clip = true
		_textures[cache_key] = atlas
		return atlas
	if key in FOOD_IDS:
		var food_key := key + ":" + style
		if _textures.has(food_key):
			return _textures[food_key]
		if not ResourceLoader.exists(FOOD_SHEET):
			return null
		var source := load(FOOD_SHEET) as Texture2D
		var atlas := AtlasTexture.new()
		atlas.atlas = source
		var column := maxi(0,DecorDefinition.STYLES.find(style))
		var row := FOOD_IDS.find(key)
		var bounds := [Rect2(0,240,536,235),Rect2(540,65,465,430),Rect2(1025,200,511,310),Rect2(0,725,545,240),Rect2(540,515,470,455),Rect2(1015,600,521,375)]
		atlas.region = bounds[row * 3 + column]
		atlas.filter_clip = true
		_textures[food_key] = atlas
		return atlas
	if key == "hibiscus" and style == "original" and ResourceLoader.exists(HIBISCUS_COUNTER):
		# Counter-top pot with its own contact shadow.
		return texture_from(HIBISCUS_COUNTER)
	var row := DESIGN_ROWS.find(key)
	if row < 0 or not ResourceLoader.exists(DESIGN_SHEET):
		return texture(key)
	var cache_key := key + ":" + style
	if _textures.has(cache_key):
		return _textures[cache_key]
	var source := load(DESIGN_SHEET) as Texture2D
	var column := maxi(0, DecorDefinition.STYLES.find(style))
	# Authored rows have different heights (runners are shallow, plants are tall).
	var rows := [0.0, .188, .372, .474, .657, .812, 1.0]
	var cell := Vector2(source.get_width() / 3.0, source.get_height() * (rows[row + 1] - rows[row]))
	var origin := Vector2(column * cell.x, source.get_height() * rows[row])
	var atlas := AtlasTexture.new()
	atlas.atlas = source
	atlas.region = Rect2(origin, cell)
	atlas.filter_clip = true
	_textures[cache_key] = atlas
	return atlas

static func texture(key: String) -> Texture2D:
	if key in FOOD_IDS or key in FINISH_IDS:
		return design_texture(key)
	if _textures.has(key):
		return _textures[key]
	var path := ROOT + key + ".png"
	if not ResourceLoader.exists(path):
		return null
	return texture_from(path, key)

## Texture cropped to its painted pixels, cached by key (the path by default).
static func texture_from(path: String, key: String = "") -> Texture2D:
	if key.is_empty():
		key = path
	if _textures.has(key):
		return _textures[key]
	var source := load(path) as Texture2D
	var pixels := source.get_image()
	if pixels.is_compressed():
		pixels.decompress()
	var used := pixels.get_used_rect()
	var atlas := AtlasTexture.new()
	atlas.atlas = source
	atlas.region = Rect2(used)
	_textures[key] = atlas
	return atlas

static func icon(key: String, extent: float = 120.0) -> TextureRect:
	var view := TextureRect.new()
	view.texture = texture(key)
	view.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	view.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	view.custom_minimum_size = Vector2(extent,extent)
	view.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return view
