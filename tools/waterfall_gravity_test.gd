extends Node

func _ready() -> void:
	for seed_value in range(20):
		var ordinary := BoardState.new()
		ordinary.setup(5,5,KuihLibrary.all(),seed_value+1)
		for hole in [Vector2i(2,4),Vector2i(2,3),Vector2i(1,4),Vector2i(3,2)]:
			ordinary.get_cell(hole).clear_kuish()
		for move in ordinary.apply_gravity():
			assert(move.from.x == move.to.x)
			for waypoint in move.path:
				assert(waypoint.x == move.from.x)
	var chosen: Dictionary = {}
	for seed_value in range(20):
		var board := BoardState.new()
		board.setup(5,5,KuihLibrary.all(),seed_value+1)
		var blocker := Vector2i(2,1)
		var covered := board.get_cell(blocker)
		covered.blocker_kind = BlockerSpec.Kind.BANANA_LEAF
		covered.blocker_hp = 2
		var hidden := covered.kuih
		board.get_cell(Vector2i(2,2)).clear_kuish()
		board.get_cell(Vector2i(2,3)).clear_kuish()
		board.get_cell(Vector2i(2,4)).clear_kuish()
		var moves := board.apply_gravity()
		assert(covered.kuih == hidden and covered.blocker_hp == 2)
		assert(board.get_cell(Vector2i(2,4)).has_kuish())
		var origins: Dictionary = {}
		var destinations: Dictionary = {}
		for move in moves:
			assert(not origins.has(move.from) and not destinations.has(move.to))
			origins[move.from] = true
			destinations[move.to] = true
			var previous: Vector2i = move.from
			for waypoint in move.path:
				assert(waypoint.y-previous.y == 1 and absi(waypoint.x-previous.x) <= 1)
				assert(waypoint != blocker)
				if waypoint == Vector2i(2,2):
					chosen[previous.x] = true
				previous = waypoint
		assert(board.apply_gravity().is_empty())
		var spawns := board.refill()
		assert(spawns.size() == 3)
		for y in board.height:
			for x in board.width:
				assert(board.get_cell(Vector2i(x,y)).has_kuish())
	assert(chosen.has(1) and chosen.has(3))
	print("Waterfall gravity: PASS (fixed blockers, side flow, no crossing, unique paths, both sides, refill)")
	get_tree().quit()
