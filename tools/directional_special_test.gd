extends Node

var problems := 0
const H := BoardCell.Special.TAPAU
const V := BoardCell.Special.TAPAU_VERTICAL

func check(ok: bool, message: String) -> void:
    if not ok:
        problems += 1
        push_error(message)

func board() -> BoardState:
    var state := BoardState.new()
    state.setup(6, 5, [KuihLibrary.get_kuih(&"onde_onde"), KuihLibrary.get_kuih(&"kuih_koci"), KuihLibrary.get_kuih(&"ang_ku_kueh"), KuihLibrary.get_kuih(&"kuih_ketayap")], 84)
    return state

func _ready() -> void:
    run.call_deferred()

func run() -> void:
    # Swipe direction wins even when the four-match runs the opposite way.
    for horizontal in [true, false]:
        for reverse in [true, false]:
            var state := BoardState.new()
            var stage := TutorialLibrary.get_stage(4 if horizontal else 10)
            state.setup(stage.width,stage.height,stage.kuih,81)
            state.apply_layout(stage.fixed_layout)
            var pair: Array = stage.tutorial_steps[0].highlight.duplicate()
            if reverse:
                pair.reverse()
            check(state.try_swap(pair[0],pair[1]) == BoardState.SwapOutcome.PLAYED, "four-match swipe is legal")
            var made := state.resolve(pair)
            check(made.created.size() == 1 and made.created[0].special == (H if horizontal else V), "four-match direction follows swipe in both signs")
    for kind in [H, V]:
        for origin in [Vector2i(2,2), Vector2i.ZERO]:
            var state := board()
            state.get_cell(origin).special = kind
            var result := state.activate_specials([origin])
            check(result.combo == &"", "single special must not form cross")
            check(result.cleared.size() == (6 if kind == H else 5), "single special clears exactly its native line")
            for pos in result.cleared:
                check(pos.y == origin.y if kind == H else pos.x == origin.x, "single blast stays directional")
    for kinds in [[H,H], [H,V], [V,H], [V,V]]:
        for pair in [[Vector2i(1,2),Vector2i(2,2)], [Vector2i(2,1),Vector2i(2,2)], [Vector2i(1,0),Vector2i.ZERO]]:
            var state := board()
            var a: Vector2i = pair[0]
            var b: Vector2i = pair[1]
            state.get_cell(a).special = kinds[0]
            state.get_cell(b).special = kinds[1]
            check(state.try_swap(a,b) == BoardState.SwapOutcome.ACTIVATED_SPECIAL, "adjacent directional pair accepts special swap")
            var result := state.activate_specials([a,b])
            check(result.combo == &"sweet_cross" and result.combo_origin == b, "pair creates cross at swap destination")
            check(result.cleared.size() == 10 and result.activated.size() == 2, "cross clears one row plus one column, specials activate once")
            for pos in result.cleared:
                check(pos.y == b.y or pos.x == b.x, "cross does not add extra offset lines")
    var chain := board()
    chain.get_cell(Vector2i(1,2)).special = H
    chain.get_cell(Vector2i(4,2)).special = V
    var reaction := chain.activate_specials([Vector2i(1,2)])
    check(reaction.combo == &"" and reaction.activated.size() == 2 and reaction.cleared.size() == 10, "chain hits retain native directions without combo metadata")
    for pos in reaction.cleared:
        check(pos.y == 2 or pos.x == 4, "chain column is centered on vertical special")
    var remote := board()
    remote.get_cell(Vector2i.ZERO).special = H
    remote.get_cell(Vector2i(5,4)).special = H
    check(remote.activate_specials([Vector2i.ZERO,Vector2i(5,4)]).combo == &"", "nonadjacent seeds do not form cross")
    var blocked := board()
    blocked.get_cell(Vector2i(2,2)).special = H
    var covered := blocked.get_cell(Vector2i(4,2))
    covered.blocker_kind = BlockerSpec.Kind.STEAMER
    covered.blocker_hp = 2
    blocked.activate_specials([Vector2i(2,2)])
    check(covered.has_kuish() and covered.blocker_hp >= 1, "directional effect preserves covered food and blocker layers")
    var vfx := GameVfx.new()
    for kind in [H,V]:
        vfx.reset()
        vfx.special(Vector2(100,100),kind,PackedVector2Array([Vector2.ZERO,Vector2(200,200)]),50)
        var beams := 0
        for effect in vfx.effects:
            if effect.kind == "beam":
                beams += 1
                check(effect.a.y == effect.b.y if kind == H else effect.a.x == effect.b.x, "native visual beam follows its direction")
                check(effect.a == Vector2(100,100), "directional beams start at special origin")
                check(effect.get("tapau",false) and effect.width >= 50*.30, "Tapau has a thick electric lane and travelling direction marker")
        check(beams == 2, "two outward beams per directional activation")
    vfx.reset()
    vfx.cross(Vector2(100,100),PackedVector2Array([Vector2.ZERO,Vector2(200,200)]),50)
    var cross_beams := 0
    for effect in vfx.effects:
        if effect.kind == "beam":
            cross_beams += 1
            check(effect.a == Vector2(100,100), "cross beams start at merged package")
    check(cross_beams == 4, "cross visual has four outward beams, plus decorative flash/ring")
    vfx.free()
    check(BoardArt.special_texture(H) != BoardArt.special_texture(V), "directional sprites use distinct assets")
    var tile := TileView.new()
    tile.size = Vector2(50,50)
    tile.cell = board().get_cell(Vector2i.ZERO)
    tile.cell.special = H
    add_child(tile)
    await get_tree().create_timer(.30).timeout
    check(tile.icon.directional_alpha > .9 and tile.icon.directional_spread > 0, "new Tapau shows moving arrows")
    await get_tree().create_timer(1.0).timeout
    check(tile.icon.directional_alpha == 0 and is_instance_valid(tile.icon), "arrows disappear while packaging remains")
    await get_tree().create_timer(3.1).timeout
    check(tile.icon.directional_alpha > .9, "arrows reappear after idle rest")
    tile.animate_directional_activation()
    await get_tree().create_timer(.20).timeout
    check(tile.icon.directional_alpha == 0 and tile._special_idle_tween == null, "activation hands arrows to VFX and stops idle loop")
    tile.free()
    print("Directional special tests: %s (%d problems)" % ["PASS" if problems == 0 else "FAIL",problems])
    get_tree().quit(0 if problems == 0 else 1)
