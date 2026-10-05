class_name ScoreRules
extends Resource

@export_range(0, 100000, 1) var points_per_kuih := 10
@export_range(0, 100000, 1) var match_three := 30
@export_range(0, 100000, 1) var match_four := 80
@export_range(0, 100000, 1) var match_five := 150
@export_range(0, 100000, 1) var special_activation := 100
@export_range(0, 100000, 1) var special_combo := 250
@export_range(0, 100000, 1) var order_item := 5
@export_range(0, 100000, 1) var remaining_move := 100
@export_range(0.0, 2.0, 0.05) var cascade_step := .25
@export_range(1.0, 10.0, 0.25) var cascade_max := 3.0
