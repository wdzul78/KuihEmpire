extends Node

var problems := 0
func check(ok: bool, message: String) -> void:
	if not ok:
		problems += 1
		push_error(message)

func _ready() -> void:
	run.call_deferred()

func run() -> void:
	var board := MatchBoard.new()
	board.size = Vector2(400,400)
	add_child(board)
	board.build(TutorialLibrary.get_stage(8))
	var origin := Vector2i(3,4)
	board.logic.get_cell(origin).special = BoardCell.Special.HANTAR
	board.logic.get_cell(origin).order_kuish = &"onde_onde"
	board._refresh_tiles()
	var icon: KuihIcon = board._tiles[origin].icon
	var initial := icon._rotor_time
	await get_tree().create_timer(.1).timeout
	check(icon._rotor_time > initial,"idle rotor spins independently")
	var result := board.logic.activate_specials([origin])
	var target: Vector2i = result.activated[0].cells.back()
	var food := board._delivery_payload(result,target)
	check(food != null,"payload is the selected kuih's actual texture")
	board._play_step(result,0)
	await get_tree().create_timer(.1).timeout
	check(board._vfx.effects.any(func(effect): return effect.kind == "robot_cross"),"robotic arms extend to local cross first")
	check(not board._vfx.effects.any(func(effect): return effect.kind == "delivery"),"remote flight waits for cross pickup")
	check(board._tiles[origin].visible and board._tiles[target].visible,"source and remote target remain during cross phase")
	await get_tree().create_timer(.52).timeout
	for local in board.logic.delivery_cross(origin):
		if board._delivery_payload(result,local) != null:
			check(not board._tiles[local].visible,"local kuih disappear before flight")
	var flights := board._vfx.effects.filter(func(effect): return effect.kind == "delivery")
	check(flights.size() == 1 and flights[0].payload == food,"flying propeller carries correct texture metadata")
	check(not board._tiles[origin].visible and board._tiles[target].visible,"origin departs while target waits for pickup")
	check(AudioManager._voices.any(func(voice): return voice.stream == AudioManager._streams[AudioManager.Sfx.HANTAR_LAUNCH]),"rotor launch plays with flight")
	await get_tree().create_timer(.46).timeout
	check(not board._tiles[target].visible,"target hides when claw picks it up")
	check(flights[0].life >= 1.1,"flight includes pickup and exit phases")
	check(AudioManager._voices.any(func(voice): return voice.stream == AudioManager._streams[AudioManager.Sfx.HANTAR_HIT]),"claw click plays at pickup")
	await get_tree().create_timer(.16).timeout
	check(AudioManager._voices.any(func(voice): return voice.stream == AudioManager._streams[AudioManager.Sfx.HANTAR_EXIT]),"departure swoosh plays as the drone leaves")
	await get_tree().create_timer(2.84).timeout
	check(board._vfx.effects.is_empty(),"flight finishes before refill accepts input")
	board.free()
	AudioManager.stop_music()
	print("Propeller delivery tests: %s (%d problems)" % ["PASS" if problems == 0 else "FAIL",problems])
	get_tree().quit(0 if problems == 0 else 1)
