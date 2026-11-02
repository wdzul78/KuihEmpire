class_name LocationDefinition
extends RefCounted

static var _all: Array[LocationDefinition] = []

var id: StringName
var display_name: String
var story_id: StringName
var stage_start: int
var stage_end: int
## A location opens once its stages are authored.
var playable: bool:
	get:
		return LevelLibrary.has_level(stage_start)
var preset: StringName
var upgrade_requirements: Array[Dictionary] = []
var state_names: Array[String] = ["Starting Stall", "Revived Stall", "Polished Stall", "Completed Stall"]
var backgrounds: Array[String] = []
var background_mode := "layered" # Or "full_texture" for authored state wallpapers.
var layers: Array[Dictionary] = [
	{"kind": "sign", "level": 1, "rect": Rect2(.025,.10,.30,.09)},
	{"kind": "shelf", "level": 2, "rect": Rect2(.0,.38,.12,.38)},
	{"kind": "cabinet", "level": 2, "rect": Rect2(.88,.38,.12,.38)},
	{"kind": "trim", "level": 3, "rect": Rect2(.01,.055,.98,.09)},
	{"kind": "lamp", "level": 3, "rect": Rect2(.89,.18,.10,.11)},
]
var decor_slots: Array[String] = ["PLANT_1", "LIGHTING_1", "COUNTER_DECOR"]

func _init(key: StringName, label: String, start: int, mood: StringName) -> void:
	id = key
	story_id = key
	display_name = label
	stage_start = start
	stage_end = start + 29
	preset = mood
	for state in range(1,4):
		upgrade_requirements.append({"stage": stage_start + state*10 - 1, "stars": StallDefinition.find(id).state(state).star_cost, "coins": 0})

func requirement(level: int) -> Dictionary:
	# Milestones unlock purchases; the star wallet pays for renovations.
	return upgrade_requirements[clampi(level,1,3)-1].duplicate()

func state_name(level: int) -> String:
	return state_names[clampi(level, 0, 3)]

## Built once: each location reads its stall files, and a win asks for these many times.
static func all() -> Array[LocationDefinition]:
	if _all.is_empty():
		_all = _build_all()
	return _all

static func _build_all() -> Array[LocationDefinition]:
	var family := LocationDefinition.new(&"family_stall", "Family Stall", 1, &"stall_dawn")
	family.decor_slots.append("COUNTER_FOOD")
	family.decor_slots.append_array(["SIGN_BOARD", "COUNTER_FRONT"])
	family.state_names = ["Old Family Stall", "Revived Stall", "Polished Stall", "New Family Stall"]
	family.backgrounds = ["res://assets/backgrounds/gerai_mvp.png"]
	var bazaar := LocationDefinition.new(&"bazaar_ramadan", "Ramadan Bazaar", 181, &"ramadan")
	bazaar.backgrounds = ["res://assets/backgrounds/locations_v1/bazaar_ramadan_0.png"]
	bazaar.state_names = ["Bazaar Setup", "Preparing for Iftar", "A Lively Bazaar", "Sweetness Together"]
	return [family,
		LocationDefinition.new(&"school_canteen", "School Canteen", 31, &"school"),
		LocationDefinition.new(&"morning_market", "Morning Market", 61, &"kuching_market"),
		LocationDefinition.new(&"town", "Town", 91, &"weekend_market"),
		LocationDefinition.new(&"city", "City", 121, &"city"),
		LocationDefinition.new(&"festival", "Kuih Festival", 151, &"festival"), bazaar,
		LocationDefinition.new(&"government_canteen", "Government Office Canteen", 211, &"government")]

static func find(key: StringName) -> LocationDefinition:
	for location in all():
		if location.id == key:
			return location
	return all()[0]

static func for_stage(stage: int) -> LocationDefinition:
	for location in all():
		if stage >= location.stage_start and stage <= location.stage_end:
			return location
	return all()[0]
