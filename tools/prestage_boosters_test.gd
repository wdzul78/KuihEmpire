extends Node
func _ready() -> void:
 run.call_deferred()
func run() -> void:
 SaveManager.data.boosters["tray"] = 2
 SaveManager.data.boosters["start_order"] = 1
 SaveManager.data.boosters["start_delivery"] = 3
 var panel := StagePreview.new()
 add_child(panel)
 panel.show_stage(16)
 await get_tree().create_timer(.4).timeout
 if DisplayServer.get_name() != "headless":
  await RenderingServer.frame_post_draw
  get_viewport().get_texture().get_image().save_png("res://.analysis/prestage-booster-selector.png")
 var board := MatchBoard.new()
 board.size = Vector2(480,480)
 add_child(board)
 board.build(LevelLibrary.get_level(16))
 var picks: Array[int] = [EconomyManager.Booster.TRAY,EconomyManager.Booster.START_ORDER,EconomyManager.Booster.START_DELIVERY]
 board.apply_start_specials(picks)
 assert(EconomyManager.booster_count(EconomyManager.Booster.TRAY) == 1)
 assert(EconomyManager.booster_count(EconomyManager.Booster.START_ORDER) == 0)
 assert(EconomyManager.booster_count(EconomyManager.Booster.START_DELIVERY) == 2)
 var found := {}
 for row in board.logic.grid:
  for cell in row:
   found[cell.special] = true
 assert(found.has(BoardCell.Special.DULANG) and found.has(BoardCell.Special.ORDER) and found.has(BoardCell.Special.HANTAR))
 panel.free()
 board.free()
 AudioManager.stop_music()
 print("Prestage boosters: PASS (three real stocks, starting specials, one stock each)")
 get_tree().quit()