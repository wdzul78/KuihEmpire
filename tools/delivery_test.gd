extends Node

var problems := 0
const LAYOUT := [
    [&"onde_onde", &"onde_onde", &"kuih_koci", &"ang_ku_kueh"],
    [&"onde_onde", &"kuih_koci", &"onde_onde", &"kuih_ketayap"],
    [&"ang_ku_kueh", &"kuih_ketayap", &"onde_onde", &"ang_ku_kueh"],
    [&"kuih_ketayap", &"ang_ku_kueh", &"kuih_ketayap", &"kuih_koci"],
]

func check(ok: bool, message: String) -> void:
    if not ok:
        problems += 1
        push_error(message)

func board(enabled: bool = true) -> BoardState:
    var state := BoardState.new()
    state.delivery_enabled = enabled
    state.setup(4,4,[KuihLibrary.get_kuih(&"onde_onde"), KuihLibrary.get_kuih(&"kuih_koci"), KuihLibrary.get_kuih(&"ang_ku_kueh"), KuihLibrary.get_kuih(&"kuih_ketayap")], 42)
    state.apply_layout(LAYOUT)
    return state

func _ready() -> void:
    SaveManager.save_path = "user://kuih_delivery_test.json"
    SaveManager.reset()
    run.call_deferred()

func run() -> void:
    for partner in KuihLibrary.starter_set():
        for reverse in [true,false]:
            var swapped := board()
            var origin := Vector2i(1,1)
            var neighbour := Vector2i(2,1)
            swapped.get_cell(origin).special = BoardCell.Special.HANTAR
            swapped.get_cell(neighbour).kuih = partner
            swapped.get_cell(Vector2i(0,3)).kuih = partner
            swapped.order_remaining = {&"kuih_ketayap":99,&"ang_ku_kueh":99}
            var pair := [neighbour,origin] if reverse else [origin,neighbour]
            check(swapped.try_swap(pair[0],pair[1]) == BoardState.SwapOutcome.ACTIVATED_SPECIAL, "delivery accepts either swap direction")
            check(swapped.get_cell(neighbour).order_kuish == partner.id, "delivery remembers partner type")
            var collected := swapped.activate_specials(pair)
            check(collected.activated.size() == 1 and collected.activated[0].cells.size() == 6, "delivery clears five cross cells and one remote target")
            for local in swapped.delivery_cross(neighbour):
                check(collected.cleared.has(local), "swap includes every local cross cell")
            check(not collected.activated[0].cells.has(Vector2i(3,2)), "cross excludes diagonals")
            var chosen: Vector2i = collected.activated[0].cells.back()
            check(collected.cleared[chosen].kuih.id == partner.id, "swapped partner type wins over unmet-order priority")
    var locked := board(false)
    locked.swap_cells(Vector2i(2,1), Vector2i(1,1))
    check(not locked.has_any_match(), "square must not match before unlock")
    check(locked.try_swap(Vector2i(0,0), Vector2i(3,0)) == BoardState.SwapOutcome.INVALID, "only adjacent swaps are accepted")
    var state := board()
    check(not state.has_any_match(), "authored lesson starts clean")
    check(state.try_swap(Vector2i(2,1),Vector2i(1,1)) == BoardState.SwapOutcome.PLAYED, "2x2-only swap is valid")
    var created := state.resolve([Vector2i(2,1),Vector2i(1,1)])
    check(created.created.size() == 1 and created.created[0].special == BoardCell.Special.HANTAR, "square creates one delivery")
    check(created.cleared.size() == 3 and created.activated.is_empty(), "new package survives creation")
    check(state.get_cell(Vector2i(1,1)).special == BoardCell.Special.HANTAR, "package stays at the swapped square cell")
    var targets := board()
    targets.order_remaining = {&"kuih_ketayap": 2}
    var target := targets.select_delivery_target(Vector2i(0,0))
    check(targets.get_cell(target).kuish_id() == &"kuih_ketayap", "delivery prioritizes unmet order")
    targets.order_remaining = {&"kuih_ketayap": 0}
    var blocked := Vector2i(3,3)
    targets.get_cell(blocked).blocker_kind = BlockerSpec.Kind.STEAMER
    targets.get_cell(blocked).blocker_hp = 2
    check(targets.select_delivery_target(Vector2i(0,0)) == blocked, "blocker is next priority")
    targets.get_cell(Vector2i.ZERO).special = BoardCell.Special.HANTAR
    var hit := targets.activate_specials([Vector2i.ZERO])
    check(targets.get_cell(blocked).blocker_hp == 1 and hit.blockers.size() == 1, "delivery hits one blocker layer")
    check(hit.cleared.size() == 3 and targets.get_cell(blocked).has_kuish(), "corner cross clears three cells and covered kuih remains")
    var blank_blocker := board()
    blank_blocker.get_cell(Vector2i.ZERO).special = BoardCell.Special.HANTAR
    blank_blocker.get_cell(blocked).clear_kuish()
    blank_blocker.get_cell(blocked).blocker_kind = BlockerSpec.Kind.STEAMER
    blank_blocker.get_cell(blocked).blocker_hp = 2
    blank_blocker.activate_specials([Vector2i.ZERO])
    check(blank_blocker.get_cell(blocked).blocker_hp == 1, "empty covered position still takes delivery damage")
    var chain := board()
    chain.get_cell(Vector2i.ZERO).special = BoardCell.Special.HANTAR
    chain.get_cell(Vector2i(1,0)).special = BoardCell.Special.DULANG
    var reaction := chain.activate_specials([Vector2i.ZERO])
    var seen: Dictionary = {}
    for activation in reaction.activated:
        check(not seen.has(activation.pos), "chain activates every special once")
        seen[activation.pos] = true
    check(reaction.activated.size() == 2, "delivery triggers another special")
    var empty := board()
    for row in empty.grid:
        for cell in row:
            cell.clear_kuish()
    check(empty.select_delivery_target(Vector2i.ZERO) == Vector2i(-1,-1), "empty fallback is safe")
    var generated := board()
    for i in 20:
        generated.setup(8,8,generated.pool, i+1)
        check(not generated.has_any_match(), "unlocked random fill is square-free")
    check(TutorialLibrary.next_index(11) == 9 and TutorialLibrary.has(9), "new lesson joins tutorial flow")
    check(not ProgressionManager.delivery_unlocked(), "fresh save starts locked")
    SaveManager.data["tutorial_done"] = true
    SaveManager.data["tutorial_index"] = 8
    check(GameManager.next_play_target().get("tutorial") == 9, "old completed save routes to new lesson")
    var screen := LevelController.new()
    screen.tutorial_index = 9
    add_child(screen)
    await get_tree().process_frame
    await get_tree().process_frame
    check(screen.board.logic.delivery_enabled, "delivery available inside its lesson")
    screen.coach.tap_through()
    check(not screen.coach.allows_swap(Vector2i(0,0),Vector2i(1,0)), "creation move is guided")
    await screen.board.attempt_swap(Vector2i(2,1),Vector2i(1,1))
    check(screen.coach._current().gate == TutorialStepData.Gate.ACTIVATED_SPECIAL, "creation advances to activation")
    check(not screen.finished and not ProgressionManager.delivery_unlocked(), "creation alone does not unlock")
    screen.coach.guide_special_activation(screen.board.logic)
    var hint := screen.coach.hint_cells()
    check(hint.size() == 2, "hand guides the actual package after gravity")
    if hint.size() == 2:
        await screen.board.attempt_swap(hint[0],hint[1])
    check(screen.coach.can_tap_through(), "completed delivery advances to recap")
    check(not ProgressionManager.delivery_unlocked(), "recap must be acknowledged")
    screen.coach.tap_through()
    await get_tree().process_frame
    await get_tree().process_frame
    check(screen.finished and screen.result.is_win, "lesson completes after creation and delivery")
    check(ProgressionManager.delivery_unlocked(), "winning lesson unlocks gameplay")
    screen.free()
    check(SaveManager.save_game(), "unlock saves")
    SaveManager.load_game()
    check(ProgressionManager.delivery_unlocked(), "unlock survives save reload")
    GameManager.pending_tutorial_index = 0
    var campaign := LevelController.new()
    campaign.level_id = 1
    add_child(campaign)
    check(campaign.board.logic.delivery_enabled, "campaign enables square after lesson")
    campaign.free()
    var was_sfx := AudioManager.sfx_enabled
    AudioManager.sfx_enabled = false
    for voice in AudioManager._voices:
        voice.stop()
    AudioManager.play(AudioManager.Sfx.HANTAR_LAUNCH)
    var playing := false
    for voice in AudioManager._voices:
        playing = playing or voice.playing
    check(not playing, "delivery audio respects mute")
    AudioManager.sfx_enabled = was_sfx
    AudioManager.stop_music()
    for voice in AudioManager._voices:
        voice.stop()
        voice.stream = null
    await get_tree().create_timer(.15).timeout
    print("Delivery tests: %s (%d problems)" % ["PASS" if problems == 0 else "FAIL", problems])
    get_tree().quit(0 if problems == 0 else 1)
