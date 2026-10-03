class_name ObjectiveSpec
extends Resource

## A single objective slot shown in the HUD.
##
## The player never chases a score - every objective is tied to the customer
## order system or to cleaning the board (Master Plan sections 12 and 3.3).

enum Type {
	COLLECT_KUIH,   ## Collect N of one kuih type.
	CLEAR_BLOCKERS, ## Remove N blockers (optionally of one kind).
	FILL_TRAY,      ## Fill a Packaging Box / Empty Tray target.
	SERVE,          ## Serve the queued customers.
}

@export var type: Type = Type.COLLECT_KUIH
@export var target: int = 10

## For [constant Type.COLLECT_KUIH]: which kuih to gather.
@export var kuih_id: StringName = &""
## For [constant Type.CLEAR_BLOCKERS]: [enum BlockerSpec.Kind] value, or -1 for any.
@export var blocker_kind: int = -1
## Human readable label shown next to the icon.
@export var label: String = ""


static func make_collect(p_kuih: KuihData, p_target: int) -> ObjectiveSpec:
	var spec := ObjectiveSpec.new()
	spec.type = Type.COLLECT_KUIH
	spec.kuih_id = p_kuih.id
	spec.target = p_target
	spec.label = p_kuih.display_name
	return spec


static func make_blockers(p_target: int, p_kind: int = -1) -> ObjectiveSpec:
	var spec := ObjectiveSpec.new()
	spec.type = Type.CLEAR_BLOCKERS
	spec.target = p_target
	spec.blocker_kind = p_kind
	spec.label = "Clear"
	return spec
