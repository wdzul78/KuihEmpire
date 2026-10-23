extends Node
func _ready() -> void:
 process_mode = Node.PROCESS_MODE_ALWAYS
 SaveManager.save_path = "user://leave_dialog_preview.json"
 var overlay := PauseOverlay.new()
 overlay.stage_title = "Big Community Order - Family Stall finale"
 overlay.extra_available = true
 overlay.extra_count = 2
 add_child(overlay)
 get_tree().paused = true
 overlay.confirm_leave("Leaving costs 1 heart. Return to the stall?",func(): pass)
 await get_tree().create_timer(0.4).timeout
 await RenderingServer.frame_post_draw
 get_viewport().get_texture().get_image().save_png("res://tools/leave_dialog_preview.png")
 overlay._leave_dialog.canceled.emit()
 await get_tree().process_frame
 assert(overlay._leave_dialog == null)
 overlay.confirm_leave("Leaving costs 1 heart. Return to the stall?",func(): pass)
 assert(overlay._leave_dialog != null)
 print("PASS: leave dialog theme, cancel and reopen")
 get_tree().paused = false
 get_tree().quit()
