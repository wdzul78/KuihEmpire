class_name KuihData
extends Resource

## Immutable definition of a single kuih tile type.
##
## Gameplay logic never depends on texture file names - it always resolves a
## tile back to its [KuihData] through [member id].
##
## The [Shape] enum drives the procedural placeholder art (see
## `scripts/art/kuih_icon.gd`) so the whole set stays visually consistent until
## final illustrated assets land in `res://assets/kuih/`.

enum Shape {
	ORB,          ## Onde-onde - green ball rolled in coconut
	LAYER_CAKE,   ## Kuih Lapis - stacked coloured layers
	PYRAMID,      ## Seri Muka - pink pyramid in a leaf cup
	LEAF_ROLL,    ## Kuih Ketayap - folded pandan leaf
	FLOWER_RING,  ## Ang Ku Kueh - flower shaped biscuit
	BALL_RING,    ## Vadai - ring of golden dough balls
	PAPER_CUP,    ## Penyaram - brown kuih in a pleated cup
	FLAKY,        ## Kuih Cina - flaky golden pastry
	PICKLE,       ## Acar - sliced cucumber pickle
	DARK_SLICE,   ## Dodol - dense brown slice
	LEAF_CUP,     ## Kuih Kukus - flower cake in a leaf cup
	FRIED_RING,   ## Kuih Goreng - fried dough ring
}

enum Category {
	STEAMED,
	LAYERED,
	FRIED,
	BAKED,
	SNACK,
	PICKLE,
	OTHER,
}

@export var id: StringName = &""
@export var display_name: String = ""
@export var shape: Shape = Shape.ORB
@export var category: Category = Category.OTHER

@export_group("Palette")
@export var color: Color = Color(0.85, 0.85, 0.8)
@export var accent: Color = Color(0.4, 0.6, 0.3)
@export var detail: Color = Color(1, 1, 1)

@export_group("Content")
@export var recipe_id: StringName = &""
## Chapter (1-based) where this kuih first becomes playable.
@export var chapter: int = 1
## Short, culturally careful blurb shown in the Recipe Book.
@export_multiline var note: String = ""

@export_group("Art")
@export var texture: Texture2D = null


func _init(
	p_id: StringName = &"",
	p_name: String = "",
	p_shape: Shape = Shape.ORB
) -> void:
	id = p_id
	display_name = p_name
	shape = p_shape


func has_final_art() -> bool:
	return texture != null
