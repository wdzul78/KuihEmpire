class_name DecorDefinition
extends RefCounted

const STYLES := ["original", "warm", "fresh"]

static func style_tint(style: String) -> Color:
	return {"original": Color.WHITE, "warm": Color(1, .75, .65), "fresh": Color(.65, 1, .75)}.get(style, Color.WHITE)

var id: String
var title: String
var slot: String
var cost: int
var kind: String
var gameplay_safe := true
var institutional := false
var family_only := false
var prerequisite := ""

func _init(key: String, label: String, place: String, price: int, art: String) -> void:
	id = key
	title = label
	slot = place
	cost = price
	kind = art

static func all() -> Array[DecorDefinition]:
	var items: Array[DecorDefinition] = [DecorDefinition.new("hibiscus", "Hibiscus Pot", "PLANT_1", 2, "flower"),
		DecorDefinition.new("rattan_lamp", "Rattan Lantern", "LIGHTING_1", 3, "lamp"),
		DecorDefinition.new("pink_batik", "Pink Batik Runner", "COUNTER_DECOR", 2, "cloth")]
	for item in [DecorDefinition.new("office_plant", "Indoor Plant", "PLANT_1", 2, "flower"),
		DecorDefinition.new("modern_pendant", "Steel Pendant Lamp", "LIGHTING_1", 3, "lamp"),
		DecorDefinition.new("steel_organizer", "Steel Utensil Organiser", "COUNTER_DECOR", 2, "cloth")]:
		item.institutional = true
		items.append(item)
	var starter := DecorDefinition.new("kuih_display", "Daily Kuih Display", "COUNTER_FOOD", 2, "food")
	starter.family_only = true
	items.append(starter)
	var feast := DecorDefinition.new("kuih_feast", "Variety Kuih Display", "COUNTER_FOOD", 4, "food")
	feast.family_only = true
	feast.prerequisite = "kuih_display"
	items.append(feast)
	for item in [DecorDefinition.new("shop_sign", "Personalise the Shop Sign", "SIGN_BOARD", 2, "sign"), DecorDefinition.new("counter_finish", "Finish the Counter", "COUNTER_FRONT", 3, "counter")]:
		item.family_only = true
		items.append(item)
	return items

func suitable_for(location: StringName) -> bool:
	if family_only:
		return location == &"family_stall"
	return institutional == (location in [&"school_canteen", &"government_canteen"])

static func for_location(location: StringName) -> Array[DecorDefinition]:
	var items: Array[DecorDefinition] = []
	for item in all():
		if item.suitable_for(location):
			items.append(item)
	return items

func art_rect(location: StringName) -> Rect2:
	if location in [&"school_canteen", &"government_canteen"]:
		return {"flower":Rect2(.005,.395 if location == &"school_canteen" else .45,.14,.15), "lamp":Rect2(.70,.025,.12,.14), "cloth":Rect2(.68,.61,.24,.10)}[kind]
	return {"flower":Rect2(.01,.365,.15,.17), "lamp":Rect2(.86,.005,.13,.18), "cloth":Rect2(.23,.63,.60,.10), "food":Rect2(.12,.54,.76,.08), "sign":Rect2(.33,.35,.37,.055), "counter":Rect2(.13,.61,.74,.115)}[kind]

static func find(key: String) -> DecorDefinition:
	for item in all():
		if item.id == key:
			return item
	return null
