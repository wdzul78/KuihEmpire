class_name BlockerSpec
extends Resource

## Authoring-time description of one obstacle placed on a level board.

enum Kind {
	BANANA_LEAF,   ## Covered by a leaf - open it by matching next to it.
	FOOD_COVER,    ## Two layer cover - each neighbouring match removes a layer.
	STEAMER,       ## Kuih is inside a steamer - a neighbouring match lifts the lid.
	STICKY_SYRUP,  ## Cell is locked and cannot be swapped until cleaned.
	PACKAGING_BOX, ## Empty cell that needs N kuih of one type to be packed.
	EMPTY_TRAY,    ## Empty cell that catches N kuih of one type.
}

## Which counter feeds the progress display for target-type blockers.
const TARGET_KINDS := [Kind.PACKAGING_BOX, Kind.EMPTY_TRAY]

@export var kind: Kind = Kind.BANANA_LEAF
## Board coordinates, x = column, y = row.
@export var cells: Array[Vector2i] = []
@export var hp: int = 1

## For PACKAGING_BOX / EMPTY_TRAY only.
@export var kuih_id: StringName = &""
@export var need: int = 4


static func make(p_kind: Kind, p_cells: Array[Vector2i], p_hp: int = 1) -> BlockerSpec:
	var spec := BlockerSpec.new()
	spec.kind = p_kind
	spec.cells = p_cells
	spec.hp = p_hp
	return spec


static func make_target(
	p_kind: Kind,
	p_cells: Array[Vector2i],
	p_kuih_id: StringName,
	p_need: int
) -> BlockerSpec:
	var spec := BlockerSpec.new()
	spec.kind = p_kind
	spec.cells = p_cells
	spec.kuih_id = p_kuih_id
	spec.need = p_need
	return spec


static func is_target_kind(kind: int) -> bool:
	return kind == Kind.PACKAGING_BOX or kind == Kind.EMPTY_TRAY
