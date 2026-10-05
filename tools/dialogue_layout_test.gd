extends Node

func _ready() -> void:
    SaveManager.save_path = "user://kuih_dialogue_layout_test.json"
    SaveManager.reset()
    run.call_deferred()

func check_heads(panel: OrderPanel) -> void:
    for character in [panel._aina, panel._portrait]:
        if not character.visible:
            continue
        var art: Texture2D = CharacterIcon.AINA_ART if character == panel._aina else character.customer.texture
        var bounds: Rect2 = character.artwork_rect(Rect2(art.get_image().get_used_rect()))
        var head_top: float = character.get_global_transform().origin.y + bounds.position.y
        for bubble in [character.dialogue_clearance, character.story_clearance]:
            if is_instance_valid(bubble) and bubble.is_visible_in_tree():
                var body_ratio := .80 if bubble == character.dialogue_clearance else 1.0
                assert(head_top >= bubble.get_global_transform().origin.y + bubble.size.y * body_ratio + 13.9)

func check_layout(screen: LevelController) -> void:
    var hud := screen.hud
    if hud._title_plaque.visible:
        assert(hud.order_panel._bubble.get_global_rect().position.y > hud._title_plaque.get_global_rect().end.y)
    var board_end: float = hud.board_holder.get_global_rect().end.y
    assert(board_end < hud.booster_bar.get_global_rect().position.y)
    assert(hud.booster_bar.get_global_rect().position.y - board_end < 45)
    for button in hud.booster_bar._buttons.values():
        assert(absf(button.size.x - button.size.y) < 1)

func run() -> void:
    var badge_panel := OrderPanel.new()
    badge_panel.size = Vector2(980, 432)
    add_child(badge_panel)
    var order := CustomerOrder.new()
    order.customer = CustomerLibrary.get_customer(&"makcik")
    order.target = {&"onde_onde": 8, &"kuih_koci": 6}
    order.remaining = order.target.duplicate()
    badge_panel.bind(order)
    var completed: Array = []
    badge_panel.line_completed.connect(func(id: StringName) -> void: completed.append(id))
    await get_tree().process_frame
    assert(badge_panel._chips[&"onde_onde"]["label"].text == "8")
    assert(badge_panel._chips[&"onde_onde"]["badge"].visible)
    assert(not badge_panel._chips[&"onde_onde"]["tick"].visible)
    order.collect({&"onde_onde": 3})
    badge_panel.animate_progress()
    assert(badge_panel._chips[&"onde_onde"]["label"].text == "5")
    assert(completed.is_empty())
    order.collect({&"onde_onde": 20})
    badge_panel.animate_progress()
    assert(not badge_panel._chips[&"onde_onde"]["badge"].visible)
    assert(badge_panel._chips[&"onde_onde"]["tick"].visible)
    assert(badge_panel._chips[&"kuih_koci"]["label"].text == "6")
    assert(completed == [&"onde_onde"])
    badge_panel.animate_progress()
    assert(completed.size() == 1)
    badge_panel._refresh_chips()
    assert(badge_panel._chips[&"onde_onde"]["tick"].visible)
    await get_tree().create_timer(.4).timeout
    badge_panel.free()
    # Real tutorial collection -> serving -> final explanation must retain ticks.
    var served_screen := LevelController.new()
    served_screen.tutorial_index = 3
    add_child(served_screen)
    await get_tree().process_frame
    served_screen.coach._advance()
    served_screen._on_kuih_collected({&"onde_onde": 3})
    assert(served_screen.hud.order_panel._card.visible)
    assert(served_screen.hud.order_panel._chips[&"onde_onde"]["tick"].visible)
    await get_tree().create_timer(.9).timeout
    assert(served_screen.active_order() == null)
    assert(not served_screen.coach.is_done())
    assert(served_screen.hud.order_panel._card.visible)
    assert(served_screen.hud.order_panel._chips[&"onde_onde"]["tick"].visible)
    assert(not served_screen.hud.order_panel._chips[&"onde_onde"]["badge"].visible)
    assert(served_screen.coach._spotlight.characters.has(served_screen.hud.order_panel._card))
    served_screen.free()
    GameManager.pending_tutorial_index = 0
    for lesson in [1, 5, 8]:
        var screen := LevelController.new()
        screen.tutorial_index = lesson
        add_child(screen)
        await get_tree().process_frame
        await get_tree().process_frame
        await get_tree().create_timer(.35).timeout
        check_heads(screen.hud.order_panel)
        check_layout(screen)
        screen.hud.order_panel._line_label.text = "Match the kuih your customer ordered, then serve the next guest waiting at your stall."
        await get_tree().process_frame
        await get_tree().process_frame
        check_heads(screen.hud.order_panel)
        # Reproduce the recorded transition: instruction gates finish while the
        # tutorial board is still collecting/serving. Keep the authored size.
        var panel := screen.hud.order_panel
        var aina_rect: Rect2 = panel._aina.get_rect()
        var customer_rect: Rect2 = panel._portrait.get_rect()
        var bubble_anchors := Vector4(panel._bubble.anchor_left, panel._bubble.anchor_top, panel._bubble.anchor_right, panel._bubble.anchor_bottom)
        var art_region := Rect2(CharacterIcon.AINA_ART.get_image().get_used_rect())
        var artwork_size: Vector2 = panel._aina.artwork_rect(art_region).size
        screen.coach._finish()
        await get_tree().process_frame
        await get_tree().process_frame
        assert(not panel._coaching)
        assert(panel._aina.get_rect().is_equal_approx(aina_rect))
        assert(panel._portrait.get_rect().is_equal_approx(customer_rect))
        assert(Vector4(panel._bubble.anchor_left, panel._bubble.anchor_top, panel._bubble.anchor_right, panel._bubble.anchor_bottom).is_equal_approx(bubble_anchors))
        assert(panel._aina.artwork_rect(art_region).size.is_equal_approx(artwork_size))
        check_heads(panel)
        screen.hud.order_panel.set_coaching(false)
        await get_tree().process_frame
        check_heads(screen.hud.order_panel)
        screen.free()
    # A custom saved scene must drive runtime layout, not be overwritten by mode code.
    var guide := GameUILayout.TUTORIAL.instantiate()
    guide.get_node("PuzzleBoard").offset_left = 21
    guide.get_node("PuzzleBoard").offset_right = 21
    guide.get_node("OrderArea/DialogueBubble").offset_top = 9
    guide.get_node("OrderArea/DialogueBubble").offset_bottom = 9
    guide.get_node("OrderArea/DialogueBubble/SpeakerName").add_theme_font_size_override("font_size", 31)
    guide.get_node("ScoreMeter/ScoreValue").add_theme_font_size_override("font_size", 34)
    var custom := PackedScene.new()
    assert(custom.pack(guide) == OK)
    guide.free()
    var authored := LevelController.new()
    authored.tutorial_index = 8
    authored.tutorial_layout = custom
    add_child(authored)
    await get_tree().process_frame
    await get_tree().process_frame
    assert(authored.hud.board_holder.offset_left == 21)
    assert(authored.hud.order_panel._bubble.offset_top == 9)
    assert(authored.hud.order_panel._bubble._text_fit[authored.hud.order_panel._name_label].maximum == 31)
    assert(authored.hud.order_panel._name_label.get_theme_font_size("font_size") <= 31)
    assert(authored.hud.score_progress.number_font_size == 34)
    assert(authored.hud.get_node("PauseButton") != null)
    assert(authored.hud.order_panel.get_node("AinaCharacter") != null)
    authored.hud.order_panel.set_coaching(false)
    assert(authored.hud.order_panel._bubble.offset_top == 0)
    authored.free()
    GameManager.pending_tutorial_index = 0
    var live := LevelController.new()
    live.level_id = 4
    add_child(live)
    await get_tree().process_frame
    await get_tree().process_frame
    check_heads(live.hud.order_panel)
    live.story.close()
    await get_tree().process_frame
    check_heads(live.hud.order_panel)
    live.free()
    print("PASS dialogue layout: order count badges and retained served ticks, stable tutorial completion, head clearance, title spacing, square specials, scene overrides and gameplay")
    get_tree().quit(0)

