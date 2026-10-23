class_name StallState
extends Resource

@export var id := "old"
@export var display_name := "Old Stall"
@export var milestone_required := 0
@export var star_cost := 0
@export var menu_background := ""
@export var gameplay_background := ""
@export var renovation_background := ""
@export var journey_background := ""
@export var task_name := ""
@export var hotspot := Vector2(.5, .7)
@export var component := "counter"
@export var variants: PackedStringArray = ["classic", "batik", "pandan"]

func background_path(context: String, variant: String = "classic") -> String:
	var path: String = get(context + "_background") if context in ["menu", "gameplay", "renovation", "journey"] else renovation_background
	if variant != "classic":
		var alternate := path.get_base_dir().path_join("variants/" + variant + "/" + path.get_file())
		if ResourceLoader.exists(alternate):
			return alternate
	return path
