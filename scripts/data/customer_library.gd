class_name CustomerLibrary
extends Resource

## Archetypes for the customer system (Master Plan section 19).
##
## Kept as a [Resource] so designers can convert entries into `.tres` files
## later without touching level data.

static var _cache: Resource = null


static func _make(
	p_id: StringName,
	p_name: String,
	p_kind: CustomerData.Kind,
	p_cloth: Color,
	p_accent: Color,
	p_skin: Color,
	p_headwear: int,
	p_line: String,
	p_order_scale: float = 1.0,
	p_reward_scale: float = 1.0
) -> CustomerData:
	var c := CustomerData.new()
	c.id = p_id
	c.display_name = p_name
	c.kind = p_kind
	c.cloth = p_cloth
	c.cloth_accent = p_accent
	c.skin = p_skin
	c.headwear = p_headwear
	c.line = p_line
	c.order_scale = p_order_scale
	c.reward_scale = p_reward_scale
	return c


static func _build() -> Resource:
	if _cache != null:
		return _cache

	var root := Resource.new()
	root.set_meta("customers", {
		&"pakyai": _make(
			&"pakyai", "Pakyai", CustomerData.Kind.NORMAL,
			Color("c9a227"), Color("f4dfa0"), Color("e0b48c"), 1,
			"One kuih for the ride home, please."
		),
		&"makcik": _make(
			&"makcik", "Makcik Ros", CustomerData.Kind.REGULAR,
			Color("7b4a86"), Color("e9d7f2"), Color("d9a274"), 0,
			"My regular. Two extra, as usual!",
			1.05, 1.2
		),
		&"abang": _make(
			&"abang", "Abang Amir", CustomerData.Kind.NORMAL,
			Color("2f5d8a"), Color("cfe3f5"), Color("c68a5c"), 0,
			"Something sweet for my sister, eh."
		),
		&"kakak": _make(
			&"kakak", "Kak Yan", CustomerData.Kind.FAMILY,
			Color("e0719c"), Color("ffd9e8"), Color("ecc39c"), 0,
			"For the whole family! Extra, extra.",
			1.15, 1.3
		),
		&"encik": _make(
			&"encik", "Encik Lim", CustomerData.Kind.OFFICE,
			Color("2b2b33"), Color("cfd4e0"), Color("e6bd96"), 1,
			"Thirty pieces for the office. Packed neatly, please.",
			1.2, 1.45
		),
		&"runner": _make(
			&"runner", "Runner Din", CustomerData.Kind.LAST_MINUTE,
			Color("e2543f"), Color("ffd7cd"), Color("b87a4e"), 3,
			"Quick quick! Market closes in ten minutes!",
			0.85, 1.15
		),
		&"tourist": _make(
			&"tourist", "Pelancong", CustomerData.Kind.NORMAL,
			Color("f0a93b"), Color("fff0c9"), Color("f0c9a4"), 2,
			"I have seen this in a video! One for my mother.",
			0.9, 1.1
		),
		&"festival": _make(
			&"festival", "Tetamu Festival", CustomerData.Kind.FESTIVAL,
			Color("d94f70"), Color("ffe0a8"), Color("dcae83"), 0,
			"Festival Kuih Kita! Fill the whole tray!",
			1.3, 1.6
		),
		&"nenek": _make(
			&"nenek", "Nenek Halimah", CustomerData.Kind.REGULAR,
			Color("8e9aa6"), Color("e6ecf2"), Color("cfa582"), 2,
			"Small pieces, Nenek only has small teeth, heh.",
			0.8, 1.25
		),
	})

	_cache = root
	return root


static func _table() -> Dictionary:
	return _build().get_meta("customers", {})


static func get_customer(id: StringName) -> CustomerData:
	return _table().get(id, null)


static func all_ids() -> Array:
	return _table().keys()


static func fallback() -> CustomerData:
	return get_customer(&"pakyai")
