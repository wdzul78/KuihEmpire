class_name TutorialArt
extends RefCounted

static var _textures: Dictionary = {}
const BOUNDS := {
	"swipe_arrow_green": Rect2(248, 14, 1770, 679),
	"hint_bulb": Rect2(287, 52, 682, 1149),
	"gold_coin": Rect2(48, 49, 1160, 1157),
}

static func texture(id: String) -> Texture2D:
	if not _textures.has(id):
		var atlas := AtlasTexture.new()
		var folder := "results_v2" if id == "gold_coin" else "tutorial_v1"
		atlas.atlas = load("res://assets/ui/%s/%s.png" % [folder, id])
		atlas.region = BOUNDS[id]
		_textures[id] = atlas
	return _textures[id]
