class_name StallDefinition
extends Resource

@export var id: StringName = &"family_stall"
@export var display_name := "Family Stall"
@export var stage_start := 1
@export var preset: StringName = &"stall_dawn"
@export var states: Array[StallState] = []

func state(index: int) -> StallState:
	return states[clampi(index, 0, states.size() - 1)]

static func find(key: StringName) -> StallDefinition:
	var path := "res://resources/stalls/%s.tres" % key
	if ResourceLoader.exists(path):
		return load(path) as StallDefinition
	return load("res://resources/stalls/family_stall.tres") as StallDefinition
