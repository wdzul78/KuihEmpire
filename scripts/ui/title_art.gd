class_name TitleArt
extends RefCounted

static var _textures: Dictionary = {}
const BOUNDS := {
	"combo": Rect2(36, 119, 1871, 535),
	"score": Rect2(27, 99, 2117, 504),

	"play": Rect2(56, 191, 1678, 481),
	"journey": Rect2(28, 139, 1735, 612),
	"order_served": Rect2(36, 179, 2112, 366),
	"paused": Rect2(67, 131, 2045, 478),
	"stage_failed": Rect2(64, 152, 2062, 385),
	"sweetness_smile": Rect2(11, 189, 2150, 331),
}

static func texture(id: String) -> Texture2D:
	if not _textures.has(id):
		var source: Texture2D = load("res://assets/ui/titles_v1/%s.png" % id)
		var atlas := AtlasTexture.new()
		atlas.atlas = source
		atlas.region = BOUNDS[id]
		atlas.filter_clip = true
		_textures[id] = atlas
	return _textures[id]

static func create(id: String, caption: String) -> TextureRect:
	var graphic := TextureRect.new()
	graphic.texture = texture(id)
	graphic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	graphic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	graphic.mouse_filter = Control.MOUSE_FILTER_IGNORE
	graphic.accessibility_name = caption
	return graphic
