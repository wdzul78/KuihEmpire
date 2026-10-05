class_name StallComponentArt
extends RefCounted

const SHEET := "res://assets/ui/stall_v1/components.png"
const REGIONS := {
	"sign": Rect2(40, 135, 535, 320),
	"shelf": Rect2(640, 40, 275, 575),
	"cabinet": Rect2(1080, 20, 360, 590),
	"trim": Rect2(20, 710, 600, 195),
	"lamp": Rect2(680, 615, 220, 385),
	"cloth": Rect2(970, 735, 565, 230),
}

static var _textures: Dictionary = {}

static func texture(kind: String) -> Texture2D:
	if _textures.has(kind):
		return _textures[kind]
	var atlas := AtlasTexture.new()
	atlas.atlas = load(SHEET)
	atlas.region = REGIONS.get(kind, REGIONS["sign"])
	_textures[kind] = atlas
	return atlas

static func draw_component(canvas: Control, kind: String, rect: Rect2) -> void:
	var image := texture(kind)
	var factor := minf(rect.size.x / image.get_width(), rect.size.y / image.get_height())
	var extent := image.get_size()*factor
	canvas.draw_texture_rect(image, Rect2(rect.get_center()-extent*.5, extent), false)
