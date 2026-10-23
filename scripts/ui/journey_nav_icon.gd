extends TextureRect
var index := 0
func _ready() -> void:
	var source: Texture2D = load("res://assets/ui/journey_icons_v2/icons.png")
	var atlas := AtlasTexture.new()
	atlas.atlas = source
	var cell := source.get_size()/2.0
	atlas.region = Rect2(Vector2(index%2,index/2)*cell,cell)
	texture = atlas
	expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	mouse_filter = Control.MOUSE_FILTER_IGNORE
