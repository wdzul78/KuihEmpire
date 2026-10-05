class_name ResourceIconArt
extends RefCounted

static var _icons: Dictionary = {}
const BOUNDS := {
	"heart": Rect2(135, 194, 984, 867),
	"star": Rect2(129, 140, 996, 966),
}

static func texture(id: String) -> Texture2D:
	if not _icons.has(id):
		var source: Texture2D = load("res://assets/ui/resources_v1/%s.png" % id)
		var icon := AtlasTexture.new()
		icon.atlas = source
		# Ignore nearly transparent export specks that inflate the visible bounds.
		icon.region = BOUNDS[id]
		icon.filter_clip = true
		_icons[id] = icon
	return _icons[id]
