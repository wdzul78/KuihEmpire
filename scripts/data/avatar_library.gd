class_name AvatarLibrary
extends RefCounted

static var _portraits: Dictionary = {}

static func ids() -> Array:
	var result: Array = ["aina"]
	for id in CustomerLibrary.all_ids():
		if CustomerLibrary.get_customer(id).texture != null:
			result.append(String(id))
	return result

static func valid(id: Variant) -> bool:
	return id is String and id in ids()

static func display_name(id: String) -> String:
	return "Aina" if id == "aina" else CustomerLibrary.get_customer(StringName(id)).display_name

static func portrait(id: String) -> Texture2D:
	if not valid(id):
		id = "aina"
	if not _portraits.has(id):
		var head := AtlasTexture.new()
		if id == "aina":
			head.atlas = load("res://assets/menu/v1/aina.png")
			head.region = Rect2(165, 20, 500, 500)
		else:
			head.atlas = CustomerLibrary.get_customer(StringName(id)).texture
			var bounds := Rect2(head.atlas.get_image().get_used_rect())
			var side := bounds.size.y * .38
			head.region = Rect2(bounds.position.x + (bounds.size.x - side) * .5, bounds.position.y, side, side)
		_portraits[id] = head
	return _portraits[id]

static func icon(id: String) -> TextureRect:
	var image := TextureRect.new()
	image.texture = portrait(id)
	image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	image.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var mask := ShaderMaterial.new()
	mask.shader = load("res://scripts/art/shaders/avatar_circle.gdshader")
	image.material = mask
	# Atlas UVs refer to the source sheet. Mask in local control coordinates instead.
	image.resized.connect(func() -> void: mask.set_shader_parameter("mask_size", image.size))
	return image
