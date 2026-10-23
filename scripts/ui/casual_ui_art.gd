class_name CasualUIArt
extends RefCounted

# Region-only extraction: the generated source pixels remain untouched.
const REGIONS := {
	"banner": Rect2(0,.06,.52,.34),
	"panel": Rect2(.52,.05,.48,.35),
	"green": Rect2(0,.42,.51,.175),
	"pink": Rect2(.52,.42,.48,.175),
	"orange": Rect2(0,.68,.51,.18),
	"offer": Rect2(.52,.60,.48,.34),
}
static var _cache: Dictionary = {}

static func texture(id: String) -> Texture2D:
	assert(REGIONS.has(id))
	if not _cache.has(id):
		var source: Texture2D = load("res://assets/ui/casual_clear_v1/ui_sheet.png")
		var region: Rect2 = REGIONS[id]
		var atlas := AtlasTexture.new()
		atlas.atlas = source
		atlas.region = Rect2(region.position*source.get_size(),region.size*source.get_size())
		_cache[id] = atlas
	return _cache[id]

static func button(caption: String, color: String = "green") -> Button:
	var result := UIKit.button(caption,44)
	ButtonArt.apply(result,texture(color))
	result.add_theme_font_override("font",UIKit.bold_font())
	result.add_theme_color_override("font_color",Color("fffdf2"))
	result.add_theme_color_override("font_outline_color",Color("54250f"))
	result.add_theme_constant_override("outline_size",3)
	result.custom_minimum_size = Vector2(0,120)
	return result
