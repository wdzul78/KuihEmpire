extends Node
func _ready() -> void:
 run.call_deferred()
func run() -> void:
 SaveManager.data.kuih_seen = []
 var controller := LevelController.new()
 controller.tutorial_index = 1
 add_child(controller)
 await get_tree().process_frame
 assert(controller.has_node("KuihIntroductionOverlay"))
 assert(not controller.board.enabled)
 var guard := 0
 while controller.has_node("KuihIntroductionOverlay"):
  var intro := controller.get_node("KuihIntroductionOverlay")
  var card := intro.get_node_or_null("KuihIntroductionCard")
  if card == null:
   await get_tree().process_frame
   continue
  var acknowledge := card.get_node("AcknowledgeKuihButton")
  acknowledge.pressed.emit()
  guard += 1
  assert(guard <= 20)
  await get_tree().process_frame
 assert(controller.board.enabled)
 assert(KuihIntroduction.unseen(controller.level.kuih).is_empty())
 controller._start_level()
 assert(not controller.has_node("KuihIntroductionOverlay"))
 controller.free()
 AudioManager.stop_music()
 print("Kuih introductions: PASS (before tutorial, input locked, acknowledgement, once per kuih, retry skips)")
 get_tree().quit()