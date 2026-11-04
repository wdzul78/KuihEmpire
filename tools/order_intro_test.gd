extends Node

## The opening of a stage: customer and Aina talk on the first visit, then the
## order card flies into the order panel and the board opens. Rendered runs save
## each screen to `.analysis/order-intro-*.png`.

var failures: Array[String] = []

func check(ok: bool, why: String) -> void:
	if not ok:
		failures.append(why)
		push_error(why)

func _ready() -> void:
	run.call_deferred()

func run() -> void:
	SaveManager.save_path = "user://kuih_order_intro_test.json"
	SaveManager.reset()
	ProgressionManager.complete_tutorial()
	for item in KuihLibrary.all():
		SaveManager.data.kuih_seen.append(String(item.id))
	for entry in PowerupRecipes.ENTRIES:
		SaveManager.data.kuih_seen.append("special_intro_%d" % int(entry[0]))
	for kind in BlockerSpec.Kind.values():
		ProgressionManager.mark_story_seen(StringName("blocker_intro_%d" % kind))
	SaveManager.set_setting("language", "ms")
	await _first_visit(32)
	await _story_stage(31)
	await _harness_default(33)
	print("Order intro: %s (%d problems)" % ["PASS" if failures.is_empty() else "FAIL", failures.size()])
	get_tree().quit(0 if failures.is_empty() else 1)

func _open(id: int, force: bool) -> LevelController:
	var screen := LevelController.new()
	screen.level_id = id
	screen.force_order_intro = force
	add_child(screen)
	for _i in 6:
		await get_tree().process_frame
	return screen

func _first_visit(id: int) -> void:
	var screen := await _open(id, true)
	var intro := screen.order_intro
	var order := screen.active_order()
	check(intro.visible and intro.is_talking(), "stage %d: the conversation opens the stage" % id)
	check(not screen.board.enabled, "stage %d: the board waits for the conversation" % id)
	var first := String(intro._line_label.text)
	for kuih in order.remaining:
		check(first.contains(KuihLibrary.get_display_name(kuih)), "stage %d: the customer asks for %s" % [id, kuih])
	check(intro._name_label.text == order.customer.display_name, "stage %d: the customer speaks first" % id)
	check(intro._guest.modulate == Color.WHITE and intro._aina.modulate != Color.WHITE, "stage %d: Aina listens in the shade" % id)
	await _capture("order-intro-1-customer")
	intro._on_input(_tap())
	check(intro._name_label.text == "Aina" and intro._aina.modulate == Color.WHITE, "stage %d: Aina answers" % id)
	await _capture("order-intro-2-aina")
	intro._on_input(_tap())
	await get_tree().create_timer(.4).timeout
	check(intro.is_showing_card() and not intro.is_talking(), "stage %d: the order card follows the talk" % id)
	check(intro._card.find_child("OrderIntroStart", true, false) != null, "stage %d: the card has a start button" % id)
	await _capture("order-intro-3-card")
	intro._on_input(_tap())
	check(intro.is_showing_card(), "stage %d: a stray tap does not skip the card" % id)
	await _start(screen)
	check(not intro.visible and screen.board.enabled, "stage %d: the board opens after the card" % id)
	check(ProgressionManager.story_seen(&"order_intro_%d" % id), "stage %d: the conversation is remembered" % id)
	await _capture("order-intro-4-play")
	# A retry opens on the card alone.
	screen._start_level()
	for _i in 4:
		await get_tree().process_frame
	check(intro.is_showing_card() and not intro.is_talking(), "stage %d: a retry shows only the order card" % id)
	await _start(screen)
	check(screen.board.enabled, "stage %d: the retry board opens" % id)
	screen.free()
	# Skip goes straight to the card on a fresh visit.
	SaveManager.data["story_seen"].erase("order_intro_%d" % id)
	screen = await _open(id, true)
	(screen.order_intro.find_child("OrderIntroSkip", true, false) as Button).pressed.emit()
	await get_tree().process_frame
	check(screen.order_intro.is_showing_card(), "stage %d: Skip goes to the order card" % id)
	await _start(screen)
	screen.free()
	await get_tree().process_frame

func _story_stage(id: int) -> void:
	var screen := await _open(id, true)
	check(screen.order_intro.is_showing_card() and not screen.order_intro.is_talking(), "stage %d: its story beat replaces the conversation" % id)
	await _start(screen)
	check(screen.story.visible, "stage %d: the story beat follows the card" % id)
	screen.free()
	await get_tree().process_frame

func _harness_default(id: int) -> void:
	var screen := await _open(id, false)
	check(not screen.order_intro.visible and screen.board.enabled, "stage %d: direct openings skip the intro" % id)
	screen.free()
	await get_tree().process_frame

func _start(screen: LevelController) -> void:
	var intro := screen.order_intro
	if not intro.is_showing_card():
		return
	(intro.find_child("OrderIntroStart", true, false) as Button).pressed.emit()
	await intro.finished
	for _i in 2:
		await get_tree().process_frame

func _tap() -> InputEventMouseButton:
	var tap := InputEventMouseButton.new()
	tap.button_index = MOUSE_BUTTON_LEFT
	tap.pressed = true
	return tap

func _capture(capture_name: String) -> void:
	if DisplayServer.get_name() == "headless":
		return
	for _i in 8:
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://.analysis"))
	get_viewport().get_texture().get_image().save_png("res://.analysis/%s.png" % capture_name)
