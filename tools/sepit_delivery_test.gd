extends Node
var problems := 0
func check(ok: bool, message: String) -> void:
	if not ok:
		problems += 1
		push_error(message)

func _ready() -> void:
	run.call_deferred()

func run() -> void:
	var state := BoardState.new()
	state.setup(7,7,KuihLibrary.starter_set(),1234)
	state.delivery_enabled = true
	var origin := Vector2i(3,3)
	for row in state.grid:
		for cell in row:
			cell.special = BoardCell.Special.NONE
			cell.kuih = KuihLibrary.get_kuih(&"kuih_koci")
	state.get_cell(origin).special = BoardCell.Special.HANTAR
	state.get_cell(origin+Vector2i.LEFT).kuih = KuihLibrary.get_kuih(&"onde_onde")
	state.get_cell(origin+Vector2i.RIGHT).kuih = KuihLibrary.get_kuih(&"onde_onde")
	state.get_cell(origin+Vector2i.UP).kuih = KuihLibrary.get_kuih(&"keria")
	state.get_cell(origin+Vector2i.DOWN).kuih = KuihLibrary.get_kuih(&"keria")
	var sampled := {}
	for i in 100:
		var kind := state.delivery_local_kuih(origin)
		check(kind in [&"onde_onde",&"keria"],"random type belongs to adjacent ordinary kuih, excluding origin")
		sampled[kind] = true
	check(sampled.size() == 2,"seeded random selection can choose either adjacent type")
	var far := Vector2i(0,0)
	state.get_cell(far).kuih = KuihLibrary.get_kuih(&"onde_onde")
	state.get_cell(Vector2i(5,3)).kuih = KuihLibrary.get_kuih(&"onde_onde")
	state.get_cell(origin).order_kuish = &"onde_onde"
	var result := state.activate_specials([origin])
	check(result.activated[0].cells.back() == far,"preferred swapped type lands on farthest matching kuih")
	for offset in [Vector2i.LEFT,Vector2i.RIGHT,Vector2i.UP,Vector2i.DOWN]:
		check(result.cleared.has(origin+offset),"wind clears all four adjacent positions")
	check(result.cleared.size() == 6,"single delivery clears origin, four neighbours and remote target")
	var fx := GameVfx.new()
	add_child(fx)
	fx.delivery(Vector2(100,300),Vector2(400,100),60)
	var sprite: SepitFlight = fx.get_child(0)
	check(sprite is Sprite2D,"flight uses a native animated sprite")
	check(sprite.flight_position(0).is_equal_approx(Vector2(100,300)),"flight starts at origin")
	check(sprite.flight_position(SepitFlight.LAND_TIME).is_equal_approx(Vector2(400,100)),"flight lands exactly on target")
	check(sprite.flight_position(.16).distance_to(Vector2(100,300)) > 20,"launch makes a visible orbit")
	await get_tree().create_timer(1.6).timeout
	check(fx.effects.is_empty() and fx.get_child_count() == 0,"landing cleans up sprite and trail")
	fx.free()
	print("Sepit delivery: %s (%d problems)" % ["PASS" if problems == 0 else "FAIL",problems])
	get_tree().quit(problems)
