class_name BoardCell
extends RefCounted

## One logical board position. A cell always knows its kuih (if any), its
## special power, and whatever obstacle sits on top of it.

enum Special {
	NONE,   ## Plain match-3 tile.
	TAPAU,  ## Gift box - clears a full row and column.
	DULANG, ## Round tray - clears a 3x3 area.
	ORDER,  ## Special order - collects every tile of one kuih type.
}

const NO_BLOCKER := -1

var kuih: KuihData = null
var special: Special = Special.NONE
## For [constant Special.ORDER]: which kuih type this tile collects.
var order_kuish: StringName = &""

## [enum BlockerSpec.Kind] or [constant NO_BLOCKER].
var blocker_kind: int = NO_BLOCKER
var blocker_hp: int = 0

## Packaging Box / Empty Tray target.
var target_kuish: StringName = &""
var target_progress: int = 0
var target_need: int = 0


func has_kuish() -> bool:
	return kuih != null


## Leaf / cover / steamer / syrup sitting on top of the kuih.
func has_overlay() -> bool:
	return blocker_kind != NO_BLOCKER and target_need == 0


func is_target() -> bool:
	return target_need > 0


func has_obstacle() -> bool:
	return has_overlay() or is_target()


## A tile the player can drag, match and swap.
func is_playable() -> bool:
	return has_kuish() and not has_overlay() and not is_target()


## An empty cell that gravity and refill move through.
func is_hole() -> bool:
	return not has_kuish() and not has_overlay() and not is_target()


func kuish_id() -> StringName:
	return kuih.id if kuih != null else &""


func clear_kuish() -> void:
	kuih = null
	special = Special.NONE
	order_kuish = &""


func remove_obstacle() -> void:
	blocker_kind = NO_BLOCKER
	blocker_hp = 0
	target_kuish = &""
	target_progress = 0
	target_need = 0
