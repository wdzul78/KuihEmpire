extends Node

## Gula melaka syrup, the big blocker picture in Aina's explanation and the big
## booster tick. Rendered runs save screens to `.analysis/syrup-*.png`.

var failures: Array[String] = []

func check(ok: bool, why: String) -> void:
	if not ok:
		failures.append(why)
		push_error(why)

func _ready() -> void:
	run.call_deferred()

func run() -> void:
	SaveManager.save_path = "user://kuih_syrup_visual_test.json"
	SaveManager.reset()
	ProgressionManager.complete_tutorial()
	for item in KuihLibrary.all():
		SaveManager.data.kuih_seen.append(String(item.id))
	for entry in PowerupRecipes.ENTRIES:
		SaveManager.data.kuih_seen.append("special_intro_%d" % int(entry[0]))
	SaveManager.set_setting("language", "ms")
	await _blocker_intro(42)
	await _booster_tick()
	print("Syrup visual: %s (%d problems)" % ["PASS" if failures.is_empty() else "FAIL", failures.size()])
	get_tree().quit(0 if failures.is_empty() else 1)

func _blocker_intro(id: int) -> void:
	var screen := LevelController.new()
	screen.level_id = id
	add_child(screen)
	for _i in 6:
		await get_tree().process_frame
	var picture := screen.story.find_child("BlockerPicture", true, false) as BlockerPicture
	check(screen.story.visible, "stage %d: Aina explains the syrup" % id)
	check(picture != null and picture.visible and picture.kind == BlockerSpec.Kind.STICKY_SYRUP, "stage %d: the explanation shows the syrup picture" % id)
	check(picture != null and picture.size.y >= 300, "stage %d: the picture is large" % id)
	await get_tree().create_timer(.6).timeout
	await _capture("syrup-1-intro")
	screen.story.advance()
	for _i in 4:
		await get_tree().process_frame
	check(screen.board.enabled, "stage %d: the board opens after the explanation" % id)
	var layer: Control = screen.board._syrup_layer
	check(layer != null and layer.get_index() < screen.board._tiles.values()[0].get_index(), "stage %d: the puddle sits behind the kuih" % id)
	await get_tree().create_timer(.6).timeout
	check(layer != null and not layer._amounts.is_empty(), "stage %d: the puddle is drawn" % id)
	var panel := screen.hud.order_panel
	check(panel._chips.has(OrderPanel.SYRUP_GOAL) and panel._syrup_left == screen.level.syrup_cells(), "stage %d: the syrup to clean is shown as a goal (left %d of %d)" % [id, panel._syrup_left, screen.level.syrup_cells()])
	check(not screen._objectives_met(), "stage %d: the stage is not won while syrup is left" % id)
	await _capture("syrup-2-board")
	screen.free()
	await get_tree().process_frame

func _booster_tick() -> void:
	EconomyManager.grant_booster(EconomyManager.Booster.TRAY, 2)
	var preview := StagePreview.new()
	add_child(preview)
	preview.show_stage(42)
	await get_tree().process_frame
	var button: Button = null
	for child in preview.find_children("*", "Button", true, false):
		if child.toggle_mode and not child.disabled:
			button = child
			break
	check(button != null, "the stage preview offers an owned booster")
	if button != null:
		button.button_pressed = true
		var tick := button.find_child("SelectedTick", true, false) as Control
		check(tick != null and tick.visible, "a chosen booster shows the big tick")
		check(tick != null and tick.size.x >= button.size.x * .6, "the tick is big")
	await get_tree().create_timer(.6).timeout
	await _capture("syrup-3-booster-tick")
	preview.free()

func _capture(capture_name: String) -> void:
	if DisplayServer.get_name() == "headless":
		return
	for _i in 8:
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://.analysis"))
	get_viewport().get_texture().get_image().save_png("res://.analysis/%s.png" % capture_name)
