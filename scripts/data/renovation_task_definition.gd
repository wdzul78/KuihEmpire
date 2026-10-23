class_name RenovationTaskDefinition
extends RefCounted

enum Kind { STRUCTURE, DECOR, STYLE }
var id: String
var location_id: StringName
var kind: Kind
var state_index := 0
var decor_id := ""
var title_key := ""
var icon_key := "renovate"
var required_stage := 0

func title() -> String:
	if location_id == &"family_stall" and kind in [Kind.STRUCTURE,Kind.STYLE] and title_key in ["sign","counter","lighting"]:
		return RenovationText.text(["canopy_task","rack_task","lights_task"][clampi(state_index-1,0,2)])
	return RenovationText.text(title_key)

func lock_reason() -> String:
	if not LocationManager.stall_unlocked(location_id):
		return RenovationText.text("locked_stall")
	if kind == Kind.DECOR:
		return RenovationText.text("food_previous")
	if LocationManager.structural_level(location_id) < state_index-1:
		return RenovationText.text("previous")
	return RenovationText.text("stage") % required_stage

func description() -> String:
	if kind == Kind.DECOR:
		return RenovationText.text("food_details" if DecorDefinition.find(decor_id).kind == "food" else "decor_hint")
	return RenovationText.text("structural_hint")

func choice_label(choice: String) -> String:
	if kind == Kind.DECOR:
		var art_kind := DecorDefinition.find(decor_id).kind
		if art_kind in ["food","sign","counter"]:
			return RenovationText.text(art_kind + "_" + choice)
	return RenovationText.text(choice)

func cost() -> int:
	if kind == Kind.STRUCTURE:
		return int(LocationDefinition.find(location_id).requirement(state_index).stars)
	if kind == Kind.DECOR:
		var item := DecorDefinition.find(decor_id)
		return 0 if LocationManager.owned(decor_id) else item.cost
	return 0

func complete() -> bool:
	if kind == Kind.STRUCTURE:
		return LocationManager.structural_level(location_id) >= state_index
	if kind == Kind.DECOR:
		var item := DecorDefinition.find(decor_id)
		return LocationManager.owned(decor_id) and (id in SaveManager.data.get("renovation_tasks_completed", []) or str(LocationManager.equipped(location_id).get(item.slot, "")) == decor_id)
	return false

func available() -> bool:
	if not LocationManager.stall_unlocked(location_id):
		return false
	if kind == Kind.STRUCTURE:
		return LocationManager.structural_level(location_id) == state_index - 1 and LocationManager.available_level(location_id) >= state_index
	if kind == Kind.STYLE:
		return LocationManager.structural_level(location_id) > 0
	var item := DecorDefinition.find(decor_id)
	if item != null and not item.prerequisite.is_empty():
		return LocationManager.owned(item.id) or LocationManager.owned(item.prerequisite)
	return true

func choices() -> PackedStringArray:
	if kind == Kind.DECOR:
		return PackedStringArray(DecorDefinition.STYLES)
	return StallDefinition.find(location_id).state(state_index).variants

static func for_location(location: StringName) -> Array[RenovationTaskDefinition]:
	var tasks: Array[RenovationTaskDefinition] = []
	for index in range(1, 4):
		var task := RenovationTaskDefinition.new()
		task.id = "%s:structure:%d" % [location, index]
		task.location_id = location
		task.kind = Kind.STRUCTURE
		task.state_index = index
		task.required_stage = int(LocationDefinition.find(location).requirement(index).stage)
		task.title_key = ["sign", "counter", "lighting"][index - 1]
		tasks.append(task)
	for item in DecorDefinition.for_location(location):
		var task := RenovationTaskDefinition.new()
		task.id = "%s:decor:%s" % [location, item.id]
		task.location_id = location
		task.kind = Kind.DECOR
		task.decor_id = item.id
		task.title_key = item.id if item.family_only else {"PLANT_1": "plant_task", "LIGHTING_1": "light_task", "COUNTER_DECOR": "cloth_task"}[item.slot]
		task.icon_key = item.id
		tasks.append(task)
	return tasks

static func style_task(location: StringName) -> RenovationTaskDefinition:
	var task := RenovationTaskDefinition.new()
	task.id = "%s:style" % location
	task.location_id = location
	task.kind = Kind.STYLE
	task.state_index = LocationManager.structural_level(location)
	task.title_key = "design_mode"
	task.icon_key = "style"
	return task
