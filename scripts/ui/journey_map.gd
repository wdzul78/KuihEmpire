class_name JourneyMap
extends Control

const ROUTE := [
 {"id": 1, "place": "Gerai Keluarga · Mula Bangkit", "chapter": &"prologue"},
 {"id": 11, "place": "Gerai Keluarga · Kemas & Cantikkan", "chapter": &"kuching"},
 {"id": 21, "place": "Gerai Keluarga · Kembangkan Bisnes", "chapter": &"sarawak"},
 {"id": 31, "place": "Kantin Sekolah · Akan datang", "chapter": &"school_canteen"},
]
const WORLD_ROOT := "res://assets/ui/journey_world_v2/"
const WORLD_NAMES := ["village","market","waterfront"]
var _worlds: Array[Texture2D] = []
var _world_layers: Array[TextureRect] = []
var _connectors: Array[TextureRect] = []
var _centers: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(WORLD_ROOT+"centers.json"))
var _chapter_height := 3240.0
var _view_chapter := -1
var selected_stage := 1
var page := 0
var _scroll: ScrollContainer
var _grid: Control
var _start: Button
var _stage_label: Label
var _stage_subtitle: Label
var _place_label: Label
var _unlock_note: Label
var _coins: CoinDisplay
var _nodes: Dictionary = {}
var _targets: HBoxContainer
var _chapters: Array[Button] = []

func _ready() -> void:
 set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 UIKit.apply_root_theme(self)
 selected_stage = GameManager.pending_level_id if GameManager.pending_level_id > 0 else ProgressionManager.current_level()
 selected_stage = clampi(selected_stage, 1, LevelLibrary.count())
 page = (selected_stage - 1) / 10
 GameManager.pending_level_id = selected_stage
 ProgressionManager.claim_journey_milestones()
 for name in WORLD_NAMES:
  _worlds.append(load(WORLD_ROOT+name+".png"))
 _build()
 EconomyManager.coins_changed.connect(func(amount: int) -> void: _coins.amount = amount)
 resized.connect(_layout_nodes)
 call_deferred("_layout_nodes")

func _build() -> void:
 var base := Control.new()
 base.name = "ScrollingWorldBackground"
 base.mouse_filter = Control.MOUSE_FILTER_IGNORE
 JourneyArt.place(self,base,Rect2(0,0,1,1))
 for chapter in 3:
  var layer := TextureRect.new()
  layer.texture = _worlds[chapter]
  layer.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
  layer.stretch_mode = TextureRect.STRETCH_SCALE
  layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
  var blend := ShaderMaterial.new()
  blend.shader = preload("res://shaders/journey_chapter_blend.gdshader")
  blend.set_shader_parameter("has_above",chapter < 2)
  blend.set_shader_parameter("has_below",chapter > 0)
  blend.set_shader_parameter("above_map",_worlds[mini(2,chapter+1)])
  blend.set_shader_parameter("below_map",_worlds[maxi(0,chapter-1)])
  layer.material = blend
  base.add_child(layer)
  _world_layers.append(layer)
 for index in 2:
  var connector := TextureRect.new()
  connector.texture = preload("res://assets/ui/journey_transitions_v1/connectors.png")
  connector.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
  connector.mouse_filter = Control.MOUSE_FILTER_IGNORE
  var blend := ShaderMaterial.new()
  blend.shader = preload("res://shaders/journey_connector.gdshader")
  blend.set_shader_parameter("frame",float(index))
  connector.material = blend
  base.add_child(connector)
  _connectors.append(connector)
 var header := Panel.new()
 header.add_theme_stylebox_override("panel",StyleBoxEmpty.new())
 JourneyArt.place(self,header,Rect2(0,0,1,.105))
 var logo := UIKit.brand_logo(Vector2.ZERO)
 JourneyArt.place(self, logo, Rect2(.008, .0, .215, .088))
 JourneyArt.place(self, HeartDisplay.new(), Rect2(.225, .020, .36, .0625))
 _coins = CoinDisplay.new()
 _coins.illustrated_style = true
 _coins.uniform_bar_height = true
 _coins.amount = EconomyManager.coins()
 JourneyArt.place(self, _coins, Rect2(.595, .020, .285, .0625))
 var settings := UIKit.button("", 30)
 settings.custom_minimum_size = Vector2.ZERO
 GameplaySkin.button(settings, "settings")
 JourneyArt.place(self, settings, Rect2(.895, .026, .085, .05))
 settings.pressed.connect(func() -> void: SceneManager.goto(SceneManager.SETTINGS))
 var sign := _painted_panel(Rect2(20,60,1495,355))
 JourneyArt.place(self,sign,Rect2(.17,.095,.66,.065))
 _place_label = JourneyArt.label(sign,"",Rect2(.16,.15,.68,.65),44,Palette.WOOD_DARK)
 _place_label.add_theme_constant_override("outline_size", 0)
 _place_label.add_theme_color_override("font_outline_color", Palette.WOOD_DARK)
 for i in 3:
  var chapter := UIKit.button(["1–10", "11–20", "21–30"][i], 25, Palette.WOOD_LIGHT)
  chapter.custom_minimum_size = Vector2.ZERO
  JourneyArt.place(self, chapter, Rect2(.035 + i * .325, .16, .31, .052))
  _chapters.append(chapter)
  chapter.pressed.connect(func() -> void: _scroll.scroll_vertical = maxi(0, int(_point(i * 10).y - _scroll.size.y * .56)))
 _scroll = ScrollContainer.new()
 _scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
 _scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_NEVER
 JourneyArt.place(self, _scroll, Rect2(0, .22, 1, .50))
 _grid = Control.new()
 _grid.custom_minimum_size = Vector2(0, _chapter_height*3)
 _grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 _grid.mouse_filter = Control.MOUSE_FILTER_PASS
 _scroll.add_child(_grid)
 _scroll.get_v_scroll_bar().value_changed.connect(_scroll_changed)
 move_child(_scroll,1)
 var character := TextureRect.new()
 character.name = "AinaCharacter"
 character.z_index = 8
 var source_aina: Texture2D = load("res://assets/ui/results_v1/aina_success.png")
 var aina_crop := AtlasTexture.new()
 aina_crop.atlas = source_aina
 aina_crop.region = Rect2(138, 53, 739, 740)
 character.texture = aina_crop
 character.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
 character.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
 character.mouse_filter = Control.MOUSE_FILTER_IGNORE
 JourneyArt.place(self, character, Rect2(.57, .45, .42, .32))
 # The painted dialogue bubble, the same art as story dialogue. Its right end sits
 # over Aina so the tail lands on her head.
 var speech := SpeechBubble.new()
 speech.name = "AinaSpeechBubble"
 speech.speaker_on_left = false
 speech.art_scale = .2
 speech.z_index = 9
 speech.mouse_filter = Control.MOUSE_FILTER_IGNORE
 JourneyArt.place(self,speech,Rect2(.65,.388,.20,.09))
 var welcome := UIKit.label(JourneyArt.localized("Jom\nsambung!", "Let's\ncontinue!"), 38, Palette.WOOD_DARK)
 welcome.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
 speech.add_child(welcome)
 # A dark pill keeps the progress line readable over the busy map and nodes.
 _unlock_note = JourneyArt.label(self, "", Rect2(.13, .681, .74, .036), 28, Palette.PAPER)
 _unlock_note.add_theme_stylebox_override("normal", UIKit.flat_box(Color(Palette.WOOD_DARK, .86), Palette.GOLD, 0, 2, 30))
 _unlock_note.add_theme_color_override("font_outline_color", Palette.WOOD_DARK)
 _unlock_note.add_theme_constant_override("outline_size", 4)
 _unlock_note.z_index = 5
 var footer := _painted_panel(Rect2(25,485,1490,445))
 footer.z_index = 10
 JourneyArt.place(self,footer,Rect2(.025,.72,.95,.175))
 # Keep the title clear of the painted frame's top rail.
 _stage_label = JourneyArt.label(footer,"",Rect2(.04,.075,.92,.18),52,Palette.LEAF_DEEP)
 _stage_subtitle = JourneyArt.label(footer,"",Rect2(.04,.255,.92,.11),28,Palette.WOOD_DARK)
 _targets = UIKit.hbox(12)
 JourneyArt.place(footer,_targets,Rect2(.045,.35,.47,.60))
 _start = GameButton.create(JourneyArt.localized("▶ Main","▶ Play"),"primary",62)
 _start.custom_minimum_size = Vector2.ZERO
 _start.name = "StartStageButton"
 JourneyArt.place(footer,_start,Rect2(.54,.40,.42,.48))
 var nav := Panel.new()
 nav.add_theme_stylebox_override("panel",UIKit.wood_box(Palette.WOOD,Palette.WOOD_DARK))
 JourneyArt.place(self,nav,Rect2(0,.90,1,.10))
 for index in 3:
  var button := Button.new()
  button.custom_minimum_size = Vector2.ZERO
  for state in ["normal","hover","pressed","focus"]:
   button.add_theme_stylebox_override(state,UIKit.flat_box(Color(1,.84,.35,.12) if index == 2 else Color.TRANSPARENT,Color.TRANSPARENT,0,0,12))
  JourneyArt.place(nav,button,Rect2(.02+index*.33,.02,.31,.96))
  var icon := preload("res://scripts/ui/journey_nav_icon.gd").new()
  icon.index = index
  JourneyArt.place(button,icon,Rect2(.25,.03,.50,.65))
  JourneyArt.label(button,[JourneyArt.localized("Gerai","Stall"),JourneyArt.localized("Kenangan","Memories"),JourneyArt.localized("Peta","Map")][index],Rect2(.05,.68,.90,.28),34,Palette.PAPER)
  if index == 0:
   button.name = "JourneyBackButton"
   button.pressed.connect(GameManager.go_home)
  elif index == 1:
   button.pressed.connect(func() -> void: _show_stop(ROUTE[0 if selected_stage < 11 else 1 if selected_stage < 21 else 2]))
 _start.pressed.connect(func() -> void:
  if has_node("StagePreview"):
   return
  var preview := StagePreview.new()
  preview.name = "StagePreview"
  add_child(preview)
  preview.show_stage(selected_stage)
 )

func _painted_panel(region: Rect2) -> Panel:
 var atlas := AtlasTexture.new()
 atlas.atlas = load(WORLD_ROOT+"panels.png")
 atlas.region = region
 var style := StyleBoxTexture.new()
 style.texture = atlas
 var panel := Panel.new()
 panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
 panel.add_theme_stylebox_override("panel",style)
 return panel

func _point(index: float) -> Vector2:
 var chapter := clampi(int(index)/10,0,2)
 var local := clampi(int(index)%10,0,9)
 var uv: Array = _centers[WORLD_NAMES[chapter]][local]
 return Vector2(_grid.size.x*float(uv[0]),(2-chapter+float(uv[1]))*_chapter_height)

func _scroll_changed(_value: float) -> void:
 _position_world_backgrounds()
 if not is_instance_valid(_grid) or not is_instance_valid(_place_label):
  return
 var visible_chapter := clampi(2-int((_scroll.scroll_vertical+_scroll.size.y*.5)/_chapter_height),0,2)
 if visible_chapter == _view_chapter:
  return
 _view_chapter = visible_chapter
 _place_label.text = [JourneyArt.localized("Gerai Keluarga","Family Stall"),JourneyArt.localized("Pasar Pagi","Morning Market"),JourneyArt.localized("Waterfront Kuching","Kuching Waterfront")][visible_chapter]
 for i in _chapters.size():
  _style_chapter(_chapters[i],i == visible_chapter)

func _style_chapter(button: Button, active: bool) -> void:
 if active:
  GameButton.apply(button,"primary",46)
  return
 for state in ["normal","hover","pressed","focus","disabled"]:
  button.add_theme_stylebox_override(state,UIKit.flat_box(Color("fff0cf"),Color("c18a37"),0,4,36))
 button.add_theme_font_size_override("font_size",46)
 for state in ["font_color","font_hover_color","font_pressed_color"]:
  button.add_theme_color_override(state,Palette.WOOD_DARK)

func _layout_nodes() -> void:
 if _grid == null:
  return
 _chapter_height = _scroll.size.x * 3.0
 _grid.custom_minimum_size = Vector2(0,_chapter_height*3.0)
 _position_world_backgrounds()
 for node in _nodes.values():
  node.queue_free()
 _nodes.clear()
 _place_label.text = JourneyArt.localized("Gerai Keluarga", "Family Stall")
 for i in LevelLibrary.count():
  var id := i + 1
  var unlocked := ProgressionManager.is_level_unlocked(id)
  var stars := ProgressionManager.stars_for(id)
  var fill := Color("e8d6b7") if not unlocked else Color("21c536") if id == selected_stage else Palette.LEAF if stars > 0 else Palette.GOLD
  var button := JourneyStageDisc.button(str(id), fill)
  button.name = "Stage%d" % id
  var milestone := not JourneyLibrary.milestone(id).is_empty()
  var diameter := 210.0 if id == selected_stage else 164.0
  button.position = _point(i) - Vector2.ONE * diameter*.5
  button.size = Vector2.ONE * diameter
  button.disabled = not unlocked
  button.add_theme_color_override("font_color", Palette.PAPER)
  button.add_theme_color_override("font_outline_color", Palette.WOOD_DARK)
  button.add_theme_constant_override("outline_size", 5)
  _grid.add_child(button)
  _nodes[id] = button
  button.pressed.connect(func() -> void: _select_stage(id))
  if milestone:
   var landmark := TextureRect.new()
   landmark.texture = load("res://assets/menu/nav_v4/shop.png")
   landmark.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
   landmark.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
   landmark.mouse_filter = Control.MOUSE_FILTER_IGNORE
   landmark.modulate = Color.WHITE if stars > 0 else Color(.65, .65, .65)
   JourneyArt.place(button, landmark, Rect2(-1.12 if i % 2 == 0 else 1.06, -.08, 1.06, 1.06))
  if stars > 0:
   for s in 3:
    var star := TextureRect.new()
    star.texture = GameplaySkin.texture("star")
    star.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    star.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
    star.modulate = Color.WHITE if s < stars else Color(.45, .45, .45)
    star.mouse_filter = Control.MOUSE_FILTER_IGNORE
    JourneyArt.place(button, star, Rect2(.10 + s * .27, .83, .26, .32))
  elif not unlocked:
   var lock := preload("res://scripts/ui/journey_nav_icon.gd").new()
   lock.index = 3
   JourneyArt.place(button,lock,Rect2(.68,.65,.36,.40))
  if id == selected_stage:
   button.z_index = 2
   button.pivot_offset = button.size*.5
   var pulse := button.create_tween().set_loops()
   pulse.tween_property(button,"modulate",Color(1.18,1.18,.85),.8)
   pulse.tween_property(button,"modulate",Color.WHITE,.8)
   var badge := Panel.new()
   badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
   badge.add_theme_stylebox_override("panel",UIKit.flat_box(Palette.LEAF_DEEP,Palette.GOLD,0,3,22))
   JourneyArt.place(button,badge,Rect2(-1.02,.12,1.12,.34))
   JourneyArt.label(badge,JourneyArt.localized("TAHAP SEMASA","CURRENT STAGE"),Rect2(.02,0,.96,1),25,Palette.PAPER)
 var destination := UIKit.label(JourneyArt.localized("Kantin Sekolah", "School Canteen") + " · " + JourneyArt.localized("Akan datang", "Coming soon"), 30, Palette.PAPER)
 destination.position = Vector2(20, 40)
 destination.size = Vector2(_grid.size.x - 40, 90)
 destination.add_theme_constant_override("outline_size", 5)
 _grid.add_child(destination)
 _nodes[31] = destination
 _grid.queue_redraw()
 _refresh()
 _scroll.set_deferred("scroll_vertical", maxi(0, int(_point(selected_stage - 1).y - _scroll.size.y * .56)))
 _view_chapter = -1
 _scroll_changed.call_deferred(0.0)

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
 _stage_label.text = "%s %d" % [MenuText.text("stage"), selected_stage]
 _stage_subtitle.text = LevelLibrary.display_title(LevelLibrary.get_level(selected_stage))
 _start.disabled = not ProgressionManager.is_level_unlocked(selected_stage)
 for index in _chapters.size():
  _style_chapter(_chapters[index],index == (selected_stage-1)/10)
 for child in _targets.get_children():
  _targets.remove_child(child)
  child.queue_free()
 var totals := {}
 for order in LevelLibrary.get_level(selected_stage).customer_orders:
  for item in order.items:
   totals[item.kuih.id] = int(totals.get(item.kuih.id,0))+item.count
 for id in totals.keys().slice(0,3):
  var column := UIKit.vbox(2)
  column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
  _targets.add_child(column)
  var icon := KuihIcon.new()
  icon.kuih = KuihLibrary.get_kuih(id)
  icon.custom_minimum_size = Vector2(96,96)
  column.add_child(icon)
  column.add_child(UIKit.label("×"+str(totals[id]),46,Palette.WOOD_DARK))

func _position_world_backgrounds() -> void:
 if _scroll == null:
  return
 for chapter in _world_layers.size():
  _world_layers[chapter].position = Vector2(0,size.y*.22-_scroll.scroll_vertical+(2-chapter)*_chapter_height)
  _world_layers[chapter].size = Vector2(size.x,_chapter_height)
 for index in _connectors.size():
  var height := _chapter_height*.16
  _connectors[index].position = Vector2(0,size.y*.22-_scroll.scroll_vertical+(index+1)*_chapter_height-height*.5)
  _connectors[index].size = Vector2(size.x,height)


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
    memories.append({"beat": beat_id, "stage": id, "label": "%s %d · %s" % [MenuText.text("stage"), id, LevelLibrary.display_title(level)]})
 return memories


func _show_stop(entry: Dictionary) -> void:
 if has_node("StopPopup"):
  return
 var overlay := Control.new()
 overlay.name = "StopPopup"
 overlay.z_index = 100
 overlay.mouse_filter = Control.MOUSE_FILTER_STOP
 overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 add_child(overlay)
 var dim := ColorRect.new()
 dim.color = Color(0, 0, 0, .65)
 dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 overlay.add_child(dim)
 var memories := memories_for(entry)
 # The window hugs its memories; the scroll list takes over once they outgrow it.
 var height := clampf(.46 + .07 * memories.size(), .55, .76)
 var top := .5 - height * .5
 var card := PanelContainer.new()
 card.add_theme_stylebox_override("panel", GeraiSkin.box("list_panel", .72, [74, 205, 74, 72]))
 JourneyArt.place(overlay, card, Rect2(.04, top, .92, height))
 var margin := UIKit.margin(10)
 card.add_child(margin)
 var stack := UIKit.vbox(22)
 margin.add_child(stack)
 var titles := [JourneyArt.localized("Gerai Keluarga · Mula Bangkit","Family Stall · A New Beginning"),JourneyArt.localized("Gerai Keluarga · Kemas & Cantikkan","Family Stall · A Fresh Look"),JourneyArt.localized("Gerai Keluarga · Kembangkan Bisnes","Family Stall · Growing Together")]
 var chapter := clampi((int(entry["id"])-1)/10,0,2)
 var banner := Panel.new()
 banner.name = "StopBanner"
 banner.add_theme_stylebox_override("panel", GeraiSkin.box("name_plate", .72))
 JourneyArt.place(overlay, banner, Rect2(.07, top + .015, .86, .085))
 var heading := JourneyArt.label(banner, titles[chapter], Rect2(.13, .12, .74, .74), 36, Palette.PAPER)
 heading.add_theme_color_override("font_outline_color", Palette.WOOD_DARK)
 heading.add_theme_constant_override("outline_size", 8)
 var progress := stop_progress(entry)
 stack.add_child(UIKit.label(MenuText.text("stop_progress") % [progress["cleared"], progress["total"], progress["stars"], progress["total"] * 3], 34, Palette.WOOD_DARK))
 var next := clampi(ProgressionManager.current_level(), progress["first"], progress["last"])
 var caption := MenuText.text("play") if ProgressionManager.needs_tutorial() else "%s · %s %d" % [MenuText.text("play"), MenuText.text("stage"), next]
 var play := GameButton.create(caption,"primary",40)
 play.pressed.connect(func() -> void:
  if ProgressionManager.needs_tutorial():
   GameManager.play_next()
  else:
   GameManager.play_level(next)
 )
 stack.add_child(play)
 stack.add_child(UIKit.label(MenuText.text("memories"), 36, Palette.WOOD_DARK))
 var scroll := ScrollContainer.new()
 scroll.name = "MemoriesScroll"
 scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
 scroll.custom_minimum_size.y = 160
 scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
 stack.add_child(scroll)
 var list := UIKit.vbox(16)
 list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 scroll.add_child(list)
 if memories.is_empty():
  list.add_child(UIKit.wrap_label(MenuText.text("no_memories"), 32))
 for memory in memories:
  var button := UIKit.button(String(memory["label"]), 36, Palette.CREAM_DEEP)
  GeraiSkin.skin_button(button, "tab_idle", .85, [56, 0, 56, 0])
  button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
  button.custom_minimum_size.y = 110
  button.add_theme_color_override("font_color", Palette.WOOD_DARK)
  button.add_theme_color_override("font_hover_color", Palette.WOOD_DARK)
  button.pressed.connect(func() -> void: _replay_memory(memory))
  list.add_child(button)
 var close := GameButton.create(MenuText.text("close"), "back")
 close.name = "CloseMemoriesButton"
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
