class_name JourneyMap
extends Control

const ROUTE := [
 {"id": 1, "place": "Gerai Keluarga · Mula Bangkit", "chapter": &"prologue"},
 {"id": 11, "place": "Gerai Keluarga · Kemas & Cantikkan", "chapter": &"kuching"},
 {"id": 21, "place": "Gerai Keluarga · Kembangkan Bisnes", "chapter": &"sarawak"},
 {"id": 31, "place": "Kantin Sekolah · Akan datang", "chapter": &"school_canteen"},
]
var selected_stage := 1
var page := 0
var _scroll: ScrollContainer
var _grid: Control
var _start: Button
var _stage_label: Label
var _place_label: Label
var _unlock_note: Label
var _coins: CoinDisplay
var _nodes: Dictionary = {}

func _ready() -> void:
 set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 UIKit.apply_root_theme(self)
 selected_stage = GameManager.pending_level_id if GameManager.pending_level_id > 0 else ProgressionManager.current_level()
 selected_stage = clampi(selected_stage, 1, LevelLibrary.count())
 page = (selected_stage - 1) / 10
 GameManager.pending_level_id = selected_stage
 ProgressionManager.claim_journey_milestones()
 _build()
 EconomyManager.coins_changed.connect(func(amount: int) -> void: _coins.amount = amount)
 resized.connect(_layout_nodes)
 call_deferred("_layout_nodes")

func _build() -> void:
 var bg := TextureRect.new()
 bg.texture = JourneyArt.texture("background")
 bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
 bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
 bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
 JourneyArt.place(self, bg, Rect2(0, 0, 1, 1))
 var logo := UIKit.brand_logo(Vector2.ZERO)
 JourneyArt.place(self, logo, Rect2(.015, .008, .28, .115))
 JourneyArt.place(self, HeartDisplay.new(), Rect2(.30, .030, .275, .045))
 _coins = CoinDisplay.new()
 _coins.illustrated_style = true
 _coins.uniform_bar_height = true
 _coins.amount = EconomyManager.coins()
 JourneyArt.place(self, _coins, Rect2(.595, .030, .275, .045))
 var settings := UIKit.button("", 30)
 settings.custom_minimum_size = Vector2.ZERO
 GameplaySkin.button(settings, "settings")
 JourneyArt.place(self, settings, Rect2(.895, .033, .085, .048))
 settings.pressed.connect(func() -> void: SceneManager.goto(SceneManager.SETTINGS))
 _place_label = JourneyArt.label(self, "", Rect2(.12, .105, .76, .034), 38, Palette.PAPER)
 _place_label.add_theme_constant_override("outline_size", 5)
 _place_label.add_theme_color_override("font_outline_color", Palette.WOOD_DARK)
 for i in 3:
  var chapter := UIKit.button(["1–10", "11–20", "21–30"][i], 25, Palette.WOOD_LIGHT)
  chapter.custom_minimum_size = Vector2.ZERO
  JourneyArt.place(self, chapter, Rect2(.13 + i * .25, .145, .24, .035))
  chapter.pressed.connect(func() -> void: _scroll.scroll_vertical = maxi(0, int(_point(i * 10).y - _scroll.size.y * .56)))
 _scroll = ScrollContainer.new()
 _scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
 JourneyArt.place(self, _scroll, Rect2(.075, .19, .85, .61))
 _grid = Control.new()
 _grid.custom_minimum_size = Vector2(0, 7500)
 _grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 _grid.mouse_filter = Control.MOUSE_FILTER_PASS
 _grid.draw.connect(_draw_route)
 _scroll.add_child(_grid)
 var character := TextureRect.new()
 var source_aina: Texture2D = load("res://assets/ui/results_v1/aina_success.png")
 var aina_crop := AtlasTexture.new()
 aina_crop.atlas = source_aina
 aina_crop.region = Rect2(138, 53, 739, 740)
 character.texture = aina_crop
 character.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
 character.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
 character.mouse_filter = Control.MOUSE_FILTER_IGNORE
 JourneyArt.place(self, character, Rect2(.64, .185, .35, .235))
 var welcome := Panel.new()
 welcome.mouse_filter = Control.MOUSE_FILTER_IGNORE
 welcome.add_theme_stylebox_override("panel", UIKit.wood_box(Palette.WOOD, Palette.WOOD_DARK))
 JourneyArt.place(self, welcome, Rect2(.66, .410, .33, .044))
 JourneyArt.label(welcome, JourneyArt.localized("Jom sambung!", "Let's continue!"), Rect2(.03, 0, .94, 1), 28, Palette.PAPER)
 _unlock_note = JourneyArt.label(self, "", Rect2(.06, .805, .88, .026), 26, Palette.PAPER)
 _unlock_note.add_theme_color_override("font_outline_color", Palette.WOOD_DARK)
 _unlock_note.add_theme_constant_override("outline_size", 4)
 var footer := Panel.new()
 footer.add_theme_stylebox_override("panel", UIKit.cream_box())
 JourneyArt.place(self, footer, Rect2(.03, .847, .94, .138))
 _stage_label = JourneyArt.label(footer, "", Rect2(.04, .07, .92, .23), 30)
 var back := GameButton.create(MenuText.text("back"), "back", 36)
 back.custom_minimum_size = Vector2.ZERO
 back.name = "JourneyBackButton"
 JourneyArt.place(footer, back, Rect2(.035, .40, .22, .46))
 back.pressed.connect(GameManager.go_home)
 var memories := GameButton.create(JourneyArt.localized("Cerita", "Memories"), "secondary", 32)
 memories.custom_minimum_size = Vector2.ZERO
 JourneyArt.place(footer, memories, Rect2(.275, .40, .25, .46))
 memories.pressed.connect(func() -> void:
  var entry: Dictionary = ROUTE[0 if selected_stage < 11 else 1 if selected_stage < 21 else 2]
  _show_stop(entry)
 )
 _start = GameButton.create(JourneyArt.localized("MULA", "START"), "primary", 38)
 _start.custom_minimum_size = Vector2.ZERO
 _start.name = "StartStageButton"
 JourneyArt.place(footer, _start, Rect2(.545, .40, .42, .46))
 _start.pressed.connect(func() -> void:
  if has_node("StagePreview"):
   return
  var preview := StagePreview.new()
  preview.name = "StagePreview"
  add_child(preview)
  preview.show_stage(selected_stage)
 )

func _point(index: float) -> Vector2:
 return Vector2(_grid.size.x * (.50 + sin(index * 1.7) * .20), 7280 - index * 238)

func _layout_nodes() -> void:
 if _grid == null:
  return
 for node in _nodes.values():
  node.queue_free()
 _nodes.clear()
 _place_label.text = JourneyArt.localized("Gerai Keluarga", "Family Stall") + " · " + JourneyLibrary.name_for(selected_stage)
 for i in LevelLibrary.count():
  var id := i + 1
  var unlocked := ProgressionManager.is_level_unlocked(id)
  var stars := ProgressionManager.stars_for(id)
  var fill := Color("8b9396") if not unlocked else Palette.GOLD if id == selected_stage else Palette.LEAF if stars > 0 else Palette.GOLD
  var button := JourneyStageDisc.button(str(id), fill)
  button.name = "Stage%d" % id
  var milestone := not JourneyLibrary.milestone(id).is_empty()
  button.position = _point(i) - Vector2.ONE * 104
  button.size = Vector2.ONE * 208
  button.disabled = not unlocked
  button.add_theme_color_override("font_color", Palette.PAPER)
  button.add_theme_color_override("font_outline_color", Palette.WOOD_DARK)
  button.add_theme_constant_override("outline_size", 5)
  _grid.add_child(button)
  _nodes[id] = button
  button.pressed.connect(func() -> void: _select_stage(id))
  if milestone:
   var ribbon := PanelContainer.new()
   ribbon.mouse_filter = Control.MOUSE_FILTER_IGNORE
   ribbon.add_theme_stylebox_override("panel", UIKit.cream_box())
   JourneyArt.place(button, ribbon, Rect2(-.55, -.40, 2.1, .30))
   ribbon.add_child(UIKit.label(JourneyLibrary.name_for(id), 24, Palette.WOOD_DARK))
   var landmark := TextureRect.new()
   landmark.texture = load("res://assets/menu/v2/nav_shop.png")
   landmark.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
   landmark.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
   landmark.mouse_filter = Control.MOUSE_FILTER_IGNORE
   landmark.modulate = Color.WHITE if stars > 0 else Color(.65, .65, .65)
   JourneyArt.place(button, landmark, Rect2(-.75 if i % 2 == 0 else 1.05, .0, .7, .85))
  if stars > 0:
   for s in 3:
    var star := TextureRect.new()
    star.texture = GameplaySkin.texture("star")
    star.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    star.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
    star.modulate = Color.WHITE if s < stars else Color(.45, .45, .45)
    star.mouse_filter = Control.MOUSE_FILTER_IGNORE
    JourneyArt.place(button, star, Rect2(.10 + s * .27, .83, .26, .32))
   var done := JourneyStageDisc.CompletedBadge.new()
   JourneyArt.place(button, done, Rect2(.76, .70, .32, .32))
  elif not unlocked:
   var lock := BoosterLockIcon.new()
   JourneyArt.place(button, lock, Rect2(.68, .62, .30, .44))
  if id == selected_stage:
   var here := SpeechBubble.new()
   here.mouse_filter = Control.MOUSE_FILTER_IGNORE
   JourneyArt.place(button, here, Rect2(.28, -.48, 1.0, .40))
   var here_label := UIKit.label(JourneyArt.localized("Di sini!", "Here!"), 34, Palette.WOOD_DARK)
   here.add_child(here_label)
 var destination := UIKit.label(JourneyArt.localized("Kantin Sekolah", "School Canteen") + " · " + JourneyArt.localized("Akan datang", "Coming soon"), 30, Palette.PAPER)
 destination.position = Vector2(20, 40)
 destination.size = Vector2(_grid.size.x - 40, 90)
 destination.add_theme_constant_override("outline_size", 5)
 _grid.add_child(destination)
 _nodes[31] = destination
 _grid.queue_redraw()
 _refresh()
 _scroll.set_deferred("scroll_vertical", maxi(0, int(_point(selected_stage - 1).y - _scroll.size.y * .56)))

func _select_stage(id: int) -> void:
 if not ProgressionManager.is_level_unlocked(id):
  return
 selected_stage = id
 GameManager.pending_level_id = id
 GameManager.pending_tutorial_index = 0
 _layout_nodes()

func _refresh() -> void:
 var cleared := 0
 for id in range(1, LevelLibrary.count() + 1):
  if ProgressionManager.stars_for(id) > 0:
   cleared += 1
 _unlock_note.text = (MenuText.text("route_progress") % [cleared, LevelLibrary.count(), ProgressionManager.total_stars()]) + " · " + JourneyArt.localized("Gerai", "Stall") + " %d/3" % ProgressionManager.world_state()
 _stage_label.text = "%s %d · %s" % [MenuText.text("stage"), selected_stage, LevelLibrary.get_level(selected_stage).title]
 _start.disabled = not ProgressionManager.is_level_unlocked(selected_stage)

func _draw_route() -> void:
 var curve := Curve2D.new()
 curve.bake_interval = 3.0
 for i in LevelLibrary.count():
  curve.add_point(_point(i), Vector2(0, 170), Vector2(0, -170))
 var points := curve.get_baked_points()
 if points.size() < 2:
  return
 _grid.draw_polyline(points, Color("926031"), 114, true)
 _grid.draw_polyline(points, Color("f6d796"), 98, true)
 _grid.draw_circle(points[0], 57, Color("926031"))
 _grid.draw_circle(points[0], 49, Color("f6d796"))
 _grid.draw_circle(points[points.size() - 1], 57, Color("926031"))
 _grid.draw_circle(points[points.size() - 1], 49, Color("f6d796"))
 var length := curve.get_baked_length()
 for step in range(0, int(length), 58):
  var at := curve.sample_baked(step)
  _grid.draw_circle(at, 9, Color("cda767"))
  _grid.draw_arc(at, 9, 0, TAU, 16, Color("ffe9b8"), 2, true)

func cleared_chapter_one() -> bool:
 return ProgressionManager.highest_cleared() >= LevelLibrary.MORNING_RUSH

func _node_state(entry: Dictionary) -> String:
 var id := int(entry["id"])
 if id > LevelLibrary.count() or not ProgressionManager.is_level_unlocked(id):
  return "locked"
 var progress := stop_progress(entry)
 return "done" if progress["total"] > 0 and progress["cleared"] == progress["total"] else "open"



func stop_progress(entry: Dictionary) -> Dictionary:
 var first := int(entry["id"])
 var last := LevelLibrary.count()
 for point in ROUTE:
  if int(point["id"]) > first:
   last = mini(last, int(point["id"]) - 1)
 var cleared := 0
 var stars := 0
 for id in range(first, last + 1):
  var earned := ProgressionManager.stars_for(id)
  stars += earned
  if earned > 0:
   cleared += 1
 return {"first": first, "last": last, "total": maxi(0, last - first + 1), "cleared": cleared, "stars": stars}




## Each stop stores only memories already encountered in its stage range.
func memories_for(entry: Dictionary) -> Array[Dictionary]:
 var memories: Array[Dictionary] = []
 var first := int(entry["id"])
 var last := LevelLibrary.count()
 for point in ROUTE:
  if int(point["id"]) > first:
   last = mini(last, int(point["id"]) - 1)
 var group: StringName = entry["chapter"]
 if StoryLibrary.has_pages(group) and ProgressionManager.story_read(group):
  memories.append({"group": group, "label": StoryLibrary.label_for(group)})
 for id in range(first, last + 1):
  var level := LevelLibrary.get_level(id)
  for beat_id in [level.story_before, level.story_after]:
   if beat_id != &"" and ProgressionManager.story_seen(beat_id) and BeatLibrary.get_beat(beat_id) != null:
    memories.append({"beat": beat_id, "stage": id, "label": "%s %d · %s" % [MenuText.text("stage"), id, level.title]})
 return memories


func _show_stop(entry: Dictionary) -> void:
 if has_node("StopPopup"):
  return
 var overlay := Control.new()
 overlay.name = "StopPopup"
 overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 add_child(overlay)
 var dim := ColorRect.new()
 dim.color = Color(0, 0, 0, .65)
 dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 overlay.add_child(dim)
 var card := PanelContainer.new()
 card.add_theme_stylebox_override("panel", UIKit.cream_box())
 card.anchor_left = .08
 card.anchor_right = .92
 card.anchor_top = .18
 card.anchor_bottom = .82
 overlay.add_child(card)
 var stack := UIKit.vbox(18)
 card.add_child(stack)
 stack.add_child(UIKit.title(String(entry["place"]), 38))
 var progress := stop_progress(entry)
 stack.add_child(UIKit.label(MenuText.text("stop_progress") % [progress["cleared"], progress["total"], progress["stars"], progress["total"] * 3], 26, Palette.WOOD_DARK))
 var next := clampi(ProgressionManager.current_level(), progress["first"], progress["last"])
 var caption := MenuText.text("play") if ProgressionManager.needs_tutorial() else "%s · %s %d" % [MenuText.text("play"), MenuText.text("stage"), next]
 var play := UIKit.button(caption, 30, Palette.LEAF)
 play.pressed.connect(func() -> void:
  if ProgressionManager.needs_tutorial():
   GameManager.play_next()
  else:
   GameManager.play_level(next)
 )
 stack.add_child(play)
 stack.add_child(UIKit.label(MenuText.text("memories"), 30, Palette.WOOD_DARK))
 var scroll := ScrollContainer.new()
 scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
 stack.add_child(scroll)
 var list := UIKit.vbox(16)
 list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 scroll.add_child(list)
 var memories := memories_for(entry)
 if memories.is_empty():
  list.add_child(UIKit.wrap_label(MenuText.text("no_memories"), 26))
 for memory in memories:
  var button := UIKit.button(String(memory["label"]), 26, Palette.CREAM_DEEP)
  button.add_theme_color_override("font_color", Palette.WOOD_DARK)
  button.add_theme_color_override("font_hover_color", Palette.WOOD_DARK)
  button.pressed.connect(func() -> void: _replay_memory(memory))
  list.add_child(button)
 var close := GameButton.create(MenuText.text("close"), "back")
 close.pressed.connect(overlay.queue_free)
 stack.add_child(close)


func _replay_memory(memory: Dictionary) -> void:
 if memory.has("group"):
  SceneManager.goto_story(memory["group"], true, SceneManager.JOURNEY)
  return
 if not memory.has("beat") or not ProgressionManager.story_seen(memory["beat"]):
  return
 var memory_stage := int(memory["stage"])
 if not JourneyLibrary.milestone(memory_stage).is_empty() and memory["beat"] == LevelLibrary.get_level(memory_stage).story_after:
  var milestone := JourneyMilestonePopup.new()
  add_child(milestone)
  milestone.show_milestone(memory_stage)
  return
 var replay := StoryPopup.new()
 replay.name = "MemoryReplay"
 var level := LevelLibrary.get_level(int(memory["stage"]))
 if not level.customer_orders.is_empty():
  replay.customer_name = level.customer_orders[0].customer.display_name
 add_child(replay)
 replay.finished.connect(replay.queue_free)
 replay.play(BeatLibrary.get_beat(memory["beat"]))
