class_name KuihLibrary
extends RefCounted

## Central registry of every kuih in the game.
##
## MVP plays with the first six; the rest are already registered so the Recipe
## Book can show locked entries and chapters can unlock them later without any
## code change (Master Plan sections 13, 23 and 24).
##
## Cultural wording follows the "Popular in..." rule - no origin claims without
## a solid source (Master Plan section 23).

static var _by_id: Dictionary = {}
static var _order: Array[KuihData] = []


static func _build() -> void:
	if not _by_id.is_empty():
		return

	var defs: Array[Dictionary] = [
		{
			"id": &"onde_onde",
			"name": "Onde-onde",
			"shape": KuihData.Shape.ORB,
			"cat": KuihData.Category.STEAMED,
			"color": Color("7cc152"),
			"accent": Color("4e8f36"),
			"detail": Color("fffdf3"),
			"chapter": 1,
			"note": "Green glutinous rice balls rolled in fresh coconut.\nPopular across Malaysia, especially at pasar pagi.",
		},
		{
			"id": &"kuih_koci",
			"name": "Kuih Koci",
			"shape": KuihData.Shape.PYRAMID,
			"cat": KuihData.Category.STEAMED,
			"color": Color("fff1d8"),
			"accent": Color("fff3dc"),
			"detail": Color("7cc152"),
			"chapter": 1,
			"note": "White glutinous rice kuih served on banana leaf.",
		},
		{
			"id": &"ang_ku_kueh",
			"name": "Ang Ku",
			"shape": KuihData.Shape.ORB,
			"cat": KuihData.Category.STEAMED,
			"color": Color("ef4638"),
			"accent": Color("ad241c"),
			"detail": Color("ffab72"),
			"chapter": 1,
			"note": "Red oval glutinous rice cake with an embossed tortoise-shell pattern.",
		},
		{
			"id": &"kuih_ketayap",
			"name": "Kuih Ketayap",
			"shape": KuihData.Shape.LEAF_ROLL,
			"cat": KuihData.Category.STEAMED,
			"color": Color("5fa83c"),
			"accent": Color("a8d16a"),
			"detail": Color("3f7f2a"),
			"chapter": 1,
			"note": "A rolled pandan crepe filled with sweet coconut.",
		},
		{
			"id": &"kuih_lapis",
			"name": "Kuih Lapis",
			"shape": KuihData.Shape.LAYER_CAKE,
			"cat": KuihData.Category.LAYERED,
			"color": Color("f76f8e"),
			"accent": Color("b4682e"),
			"detail": Color("ffd79a"),
			"chapter": 1,
			"note": "Pink and cream layers of steamed kuih.",
		},
		{
			"id": &"keria",
			"name": "Keria",
			"shape": KuihData.Shape.FRIED_RING,
			"cat": KuihData.Category.FRIED,
			"color": Color("e0a23c"),
			"accent": Color("b9741f"),
			"detail": Color("ffe0a8"),
			"chapter": 1,
			"note": "A golden ring-shaped sweet-potato kuih.",
		},
		{
			"id": &"penyaram",
			"name": "Penyaram",
			"shape": KuihData.Shape.PAPER_CUP,
			"cat": KuihData.Category.BAKED,
			"color": Color("a2622f"),
			"accent": Color("f4e6cf"),
			"detail": Color("d9954f"),
			"chapter": 2,
			"note": "A sweet banana and sugar cake baked in a pleated cup.",
		},
		{
			"id": &"kuih_cina",
			"name": "Kuih Cina",
			"shape": KuihData.Shape.FLAKY,
			"cat": KuihData.Category.FRIED,
			"color": Color("e6a34b"),
			"accent": Color("b87333"),
			"detail": Color("ffe6b8"),
			"chapter": 2,
			"note": "Flaky pastry strands fried into nests and drizzled with syrup.",
		},
		{
			"id": &"acar",
			"name": "Acar",
			"shape": KuihData.Shape.PICKLE,
			"cat": KuihData.Category.PICKLE,
			"color": Color("8cbf4a"),
			"accent": Color("4e8f36"),
			"detail": Color("e8d24c"),
			"chapter": 3,
			"note": "Crunchy fruit and vegetable pickle with a gentle chilli warmth.",
		},
		{
			"id": &"dodol",
			"name": "Dodol",
			"shape": KuihData.Shape.DARK_SLICE,
			"cat": KuihData.Category.SNACK,
			"color": Color("8a4a22"),
			"accent": Color("5d2f13"),
			"detail": Color("d9a86a"),
			"chapter": 3,
			"note": "Slow-stirred sweet of flour, coconut milk and palm sugar.",
		},
		{
			"id": &"kuih_kukus",
			"name": "Kuih Kukus",
			"shape": KuihData.Shape.LEAF_CUP,
			"cat": KuihData.Category.STEAMED,
			"color": Color("c77dbb"),
			"accent": Color("4e9a3f"),
			"detail": Color("ffe9f4"),
			"chapter": 4,
			"note": "Soft steamed cakes set in a leaf cup, coloured with fresh ingredients.",
		},
		{
			"id": &"kuih_goreng",
			"name": "Kuih Goreng",
			"shape": KuihData.Shape.FRIED_RING,
			"cat": KuihData.Category.FRIED,
			"color": Color("d98c3a"),
			"accent": Color("9d5a1c"),
			"detail": Color("ffdca0"),
			"chapter": 4,
			"note": "Golden fried dough rings, crisp outside and soft within.",
		},
	]

	for def in defs:
		var kuih := KuihData.new()
		kuih.id = def["id"]
		kuih.display_name = def["name"]
		kuih.shape = def["shape"]
		kuih.category = def["cat"]
		kuih.color = def["color"]
		kuih.accent = def["accent"]
		kuih.detail = def["detail"]
		kuih.chapter = def["chapter"]
		kuih.recipe_id = def["id"]
		kuih.note = def["note"]
		var art_path := "res://assets/kuih/cartoon_v3/%s.png" % String(kuih.id)
		if not ResourceLoader.exists(art_path):
			art_path = "res://assets/kuih/cartoon_v2/%s.png" % String(kuih.id)
		if not ResourceLoader.exists(art_path):
			art_path = "res://assets/kuih/%s.png" % String(kuih.id)
		if ResourceLoader.exists(art_path):
			kuih.texture = load(art_path) as Texture2D
		_by_id[kuih.id] = kuih
		_order.append(kuih)


static func all() -> Array[KuihData]:
	_build()
	return _order


static func get_kuih(id: StringName) -> KuihData:
	_build()
	return _by_id.get(id, null)


static func has(id: StringName) -> bool:
	_build()
	return _by_id.has(id)


static func get_display_name(id: StringName) -> String:
	var kuih := get_kuih(id)
	return kuih.display_name if kuih != null else String(id)


static func count() -> int:
	_build()
	return _order.size()


## The six MVP kuih (Master Plan section 13).
static func starter_set() -> Array[KuihData]:
	var out: Array[KuihData] = []
	for id in [&"onde_onde", &"kuih_koci", &"ang_ku_kueh", &"kuih_ketayap", &"kuih_lapis", &"keria"]:
		var kuih := get_kuih(id)
		if kuih != null:
			out.append(kuih)
	return out
