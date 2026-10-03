class_name CustomerData
extends Resource

## A customer archetype. Levels reference these instead of hard-coding orders so
## the same handful of archetypes can be reused across 190+ future levels.

enum Kind {
	NORMAL,        ## Straightforward single order.
	FAMILY,        ## Bigger quantities, happier tip.
	OFFICE,        ## Packaging heavy order.
	REGULAR,       ## Recurring character with a mini story.
	LAST_MINUTE,   ## Fewer moves than the level default.
	FESTIVAL,      ## Special objective customer.
}

@export var id: StringName = &""
@export var display_name: String = ""
@export var kind: Kind = Kind.NORMAL

@export_group("Order tuning")
## Multiplier applied to the level's base order quantities.
@export_range(0.5, 3.0, 0.05) var order_scale: float = 1.0
## Extra moves granted on top of the level budget.
@export var move_bonus: int = 0
## Multiplier applied to coin rewards.
@export_range(0.5, 3.0, 0.05) var reward_scale: float = 1.0

@export_group("Portrait")
## Drives the procedural customer art (hijab colour).
@export var cloth: Color = Color(0.9, 0.45, 0.55)
@export var cloth_accent: Color = Color(1, 0.85, 0.6)
@export var skin: Color = Color(0.86, 0.68, 0.53)
## 0 = hijab, 1 = songkok, 2 = wide brim hat, 3 = short hair + spectacles.
@export var headwear: int = 0
@export var line: String = ""


func is_last_minute() -> bool:
	return kind == Kind.LAST_MINUTE
