class_name DialogueSpotlight
extends Control

var target: Control
var characters: Array[Control] = []
var _character_states: Dictionary = {}
var _previous_z := 0

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	z_index = 80
	for character in characters:
		_character_states[character] = {"z": character.z_index, "color": character.modulate}
	if is_instance_valid(target):
		_previous_z = target.z_index
		_sync_target()
	visibility_changed.connect(_sync_target)

func _sync_target() -> void:
	if is_instance_valid(target):
		target.z_index = 81 if is_visible_in_tree() else _previous_z
	for character in characters:
		if is_instance_valid(character) and _character_states.has(character):
			character.z_index = 81 if is_visible_in_tree() else _character_states[character]["z"]
			character.modulate = Color.WHITE if is_visible_in_tree() else _character_states[character]["color"]

func _exit_tree() -> void:
	if is_instance_valid(target):
		target.z_index = _previous_z
	for character in characters:
		if is_instance_valid(character) and _character_states.has(character):
			character.z_index = _character_states[character]["z"]
			character.modulate = _character_states[character]["color"]

func _process(_delta: float) -> void:
	if is_visible_in_tree():
		for character in characters:
			if is_instance_valid(character):
				character.modulate = Color.WHITE
		queue_redraw()

func _draw() -> void:
	if not is_instance_valid(target) or not target.is_visible_in_tree():
		return
	var dim := Color(.08, .045, .025, .62)
	draw_rect(Rect2(Vector2.ZERO, size), dim)
