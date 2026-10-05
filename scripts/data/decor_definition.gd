class_name DecorDefinition
extends RefCounted

var id: String
var title: String
var slot: String
var cost: int
var kind: String
var gameplay_safe := true

func _init(key: String, label: String, place: String, price: int, art: String) -> void:
	id = key
	title = label
	slot = place
	cost = price
	kind = art

static func all() -> Array[DecorDefinition]:
	return [DecorDefinition.new("hibiscus", "Hibiscus Pot", "PLANT_1", 120, "flower"),
		DecorDefinition.new("rattan_lamp", "Rattan Lantern", "LIGHTING_1", 160, "lamp"),
		DecorDefinition.new("pink_batik", "Pink Batik Runner", "COUNTER_DECOR", 100, "cloth")]

static func find(key: String) -> DecorDefinition:
	for item in all():
		if item.id == key:
			return item
	return null
