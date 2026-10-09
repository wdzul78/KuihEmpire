extends Node
var problems := 0
func check(ok: bool, message: String) -> void:
	if not ok:
		problems += 1
		push_error(message)
func _ready() -> void:
	run.call_deferred()
func run() -> void:
	var background := ColorRect.new()
	background.color = Color("fceab4")
	background.size = Vector2(720,960)
	add_child(background)
	var icons: Array[KuihIcon] = []
	var foods := [&"kuih_bom",&"seri_muka",&"agar_agar_ros",&"karipap",&"tart"]
	for index in foods.size():
		var data := KuihLibrary.get_kuih(foods[index])
		check(data != null and data.texture is AtlasTexture,"new food registered and framed")
		var icon := KuihIcon.new()
		icon.kuih = data
		icon.position = Vector2(30+index%3*225,30+index/3*180)
		icon.size = Vector2(155,155)
		add_child(icon)
	for index in 4:
		var icon := KuihIcon.new()
		icon.kuih = KuihLibrary.get_kuih(&"onde_onde")
		icon.special_kind = [BoardCell.Special.TAPAU,BoardCell.Special.TAPAU_VERTICAL,BoardCell.Special.ORDER,BoardCell.Special.DULANG][index]
		icon.position = Vector2(20+index*170,395)
		icon.size = Vector2(160,160)
		add_child(icon)
		icons.append(icon)
	var fx := GameVfx.new()
	fx.size = Vector2(720,960)
	add_child(fx)
	await get_tree().create_timer(.15).timeout
	for icon in icons:
		check(icon.is_processing() and icon._rotor_time > 0,"special streak clock runs")
	if DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("res://.shots/new_foods_and_specials.png")
	fx.cross(Vector2(360,750),PackedVector2Array([Vector2(90,750),Vector2(630,750),Vector2(360,610),Vector2(360,890)]),80)
	var roller_count := 0
	for effect in fx.effects:
		if effect.kind == "roller_lane":
			roller_count += 1
			check(effect.a == Vector2(360,750),"roller starts at combination origin")
	check(roller_count == 4,"roller launches in four directions")
	await get_tree().create_timer(.18).timeout
	if DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("res://.shots/roller_four_directions.png")
	await get_tree().create_timer(.7).timeout
	check(fx.effects.is_empty(),"combo effects finish without lingering")
	var board := MatchBoard.new()
	board.position = Vector2(740,20)
	board.size = Vector2(650,650)
	add_child(board)
	board.build(LevelLibrary.get_level(20))
	await get_tree().process_frame
	var origins := [Vector2i(3,3),Vector2i(4,3)]
	for index in origins.size():
		board.logic.get_cell(origins[index]).special = BoardCell.Special.TAPAU if index == 0 else BoardCell.Special.TAPAU_VERTICAL
		board._tiles[origins[index]].refresh()
	var result := board.logic.activate_specials(origins)
	check(result.combo == &"sweet_cross","horizontal plus vertical creates cross")
	await board._play_step(result,1)
	check(board.get_node_or_null("CrossComboRoller") == null or board.get_node("CrossComboRoller").is_queued_for_deletion(),"roller combo graphic removed after activation")
	board.free()
	print("Illustrated specials: %s (%d problems)" % ["PASS" if problems == 0 else "FAIL",problems])
	get_tree().quit(problems)
