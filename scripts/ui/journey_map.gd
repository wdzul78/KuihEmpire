class_name JourneyMap
extends Control

const ROUTE := JourneyLibrary.SECTIONS
const WORLD_ROOT := "res://assets/ui/journey_world_v2/"
## Worlds are large, so only sections this close to the screen stay loaded.
const WINDOW_MARGIN := .25
var _sections: Array = JourneyLibrary.released_sections()
var _world_base: Control
var _connector_base: Control
var _world_textures: Dictionary = {}
var _world_requests: Dictionary = {}
var _world_layers: Dictionary = {}
var _connectors: Dictionary = {}
var _window: Array[int] = []
var _layout_pending := false
var _centers: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(WORLD_ROOT+"centers.json"))
var _chapter_height := 3240.0
var _view_section := -1
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
var _tab_sections: Array[int] = []
var _location_arrows: Array[Button] = []
var _destination: Label

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
 var base := Control.new()
 base.name = "ScrollingWorldBackground"
 base.mouse_filter = Control.MOUSE_FILTER_IGNORE
 JourneyArt.place(self,base,Rect2(0,0,1,1))
 _world_base = Control.new()
 _world_base.mouse_filter = Control.MOUSE_FILTER_IGNORE
 base.add_child(_world_base)
 _connector_base = Control.new()
 _connector_base.mouse_filter = Control.MOUSE_FILTER_IGNORE
 base.add_child(_connector_base)
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
  var chapter := UIKit.button("", 25, Palette.WOOD_LIGHT)
  chapter.custom_minimum_size = Vector2.ZERO
  JourneyArt.place(self, chapter, Rect2(.035 + i * .325, .16, .31, .052))
  _chapters.append(chapter)
  chapter.pressed.connect(func() -> void: _show_section(_tab_sections[i]))
 for step in [-1, 1]:
  var arrow := UIKit.button("◀" if step < 0 else "▶", 34, Palette.WOOD_LIGHT)
  arrow.custom_minimum_size = Vector2.ZERO
  arrow.visible = _location_ids().size() > 1
  JourneyArt.place(self, arrow, Rect2(.035 if step < 0 else .845, .10, .12, .052))
  _location_arrows.append(arrow)
  arrow.pressed.connect(func() -> void: _step_location(step))
 _scroll = ScrollContainer.new()
 _scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
 _scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_NEVER
 JourneyArt.place(self, _scroll, Rect2(0, .22, 1, .50))
 _grid = Control.new()
 _grid.custom_minimum_size = Vector2(0, _chapter_height*_sections.size())
 _grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 _grid.mouse_filter = Control.MOUSE_FILTER_PASS
 _scroll.add_child(_grid)
 _destination = UIKit.label("", 30, Palette.PAPER)
 _destination.position = Vector2(20, 40)
 _destination.add_theme_constant_override("outline_size", 5)
 _destination.visible = not JourneyLibrary.next_destination().is_empty()
 _destination.text = JourneyLibrary.next_destination() + " · " + JourneyArt.localized("Akan datang", "Coming soon")
 _grid.add_child(_destination)
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
   button.pressed.connect(func() -> void: _show_stop(JourneyLibrary.section_for(selected_stage)))
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
 var stage := int(index) + 1
 var section := mini(JourneyLibrary.section_index(stage), _sections.size() - 1)
 var entry: Dictionary = _sections[section]
 var uv: Array = _centers[entry["world"]][clampi(stage - int(entry["id"]), 0, 9)]
 return Vector2(_grid.size.x*float(uv[0]),(_sections.size()-1-section+float(uv[1]))*_chapter_height)

func _scroll_changed(_value: float) -> void:
 if _layout_pending or not is_instance_valid(_grid) or not is_instance_valid(_place_label):
  return
 _sync_window()
 _position_world_backgrounds()
 var last := _sections.size() - 1
 var visible_section := clampi(last-int((_scroll.scroll_vertical+_scroll.size.y*.5)/_chapter_height),0,last)
 if visible_section == _view_section:
  return
 _view_section = visible_section
 var entry: Dictionary = _sections[visible_section]
 _place_label.text = JourneyArt.localized(entry["place_ms"],entry["place_en"])
 _sync_tabs()

## The tabs always show the sections of the location in view.
func _sync_tabs() -> void:
 var location: StringName = _sections[_view_section]["location"]
 _tab_sections.clear()
 for index in _sections.size():
  if _sections[index]["location"] == location:
   _tab_sections.append(index)
 for i in _chapters.size():
  _chapters[i].visible = i < _tab_sections.size()
  if _chapters[i].visible:
   var entry: Dictionary = _sections[_tab_sections[i]]
   _chapters[i].text = "%d–%d" % [entry["id"], entry["last"]]
   _style_chapter(_chapters[i],_tab_sections[i] == _view_section)
 var locations := _location_ids()
 _location_arrows[0].disabled = locations.find(location) == 0
 _location_arrows[1].disabled = locations.find(location) == locations.size() - 1

func _location_ids() -> Array[StringName]:
 var out: Array[StringName] = []
 for entry in _sections:
  if not out.has(entry["location"]):
   out.append(entry["location"])
 return out

func _step_location(step: int) -> void:
 var locations := _location_ids()
 var target: StringName = locations[clampi(locations.find(_sections[_view_section]["location"])+step,0,locations.size()-1)]
 for index in _sections.size():
  if _sections[index]["location"] == target:
   _show_section(index)
   return

func _show_section(index: int) -> void:
 _scroll.scroll_vertical = maxi(0, int(_point(int(_sections[index]["id"]) - 1).y - _scroll.size.y * .56))

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
 _grid.custom_minimum_size = Vector2(0,_chapter_height*_sections.size())
 _destination.size = Vector2(_scroll.size.x - 40, 90)
 for id in _nodes.keys():
  _remove_stage_node(id)
 _window = []
 _layout_pending = true
 _refresh()
 _finish_layout.call_deferred()

func _finish_layout() -> void:
 # A new height reaches the scroll bar a frame later, and it would clamp the position.
 if _scroll.get_v_scroll_bar().max_value < _grid.custom_minimum_size.y:
  await get_tree().process_frame
 _layout_pending = false
 _center_on_selected()
 _view_section = -1
 _scroll_changed(0.0)

func _center_on_selected() -> void:
 _scroll.scroll_vertical = maxi(0, int(_point(selected_stage - 1).y - _scroll.size.y * .56))

## Keeps worlds and stage buttons only for sections near the screen.
func _sync_window() -> void:
 var top := _scroll.scroll_vertical - size.y * (.22 + WINDOW_MARGIN)
 var bottom := top + size.y * (1.0 + WINDOW_MARGIN * 2.0)
 var last := _sections.size() - 1
 var wanted: Array[int] = []
 for section in _sections.size():
  var section_top := (last - section) * _chapter_height
  if section_top < bottom and section_top + _chapter_height > top:
   wanted.append(section)
 if wanted == _window:
  return
 _window = wanted
 _sync_worlds()
 _sync_stage_nodes()

func _sync_stage_nodes() -> void:
 for id in _nodes.keys():
  if not _window.has(JourneyLibrary.section_index(id)):
   _remove_stage_node(id)
 for section in _window:
  var entry: Dictionary = _sections[section]
  for id in range(int(entry["id"]), mini(int(entry["last"]), LevelLibrary.count()) + 1):
   if not _nodes.has(id):
    _nodes[id] = _make_stage_node(id)

func _remove_stage_node(id: int) -> void:
 var old: Control = _nodes[id]
 _nodes.erase(id)
 # Hidden and renamed at once, because the pressed button may be the one replaced.
 old.name = "Removed%s" % old.get_instance_id()
 old.hide()
 old.queue_free()

func _make_stage_node(id: int) -> Button:
 var unlocked := ProgressionManager.is_level_unlocked(id)
 var stars := ProgressionManager.stars_for(id)
 var fill := Color("e8d6b7") if not unlocked else Color("21c536") if id == selected_stage else Palette.LEAF if stars > 0 else Palette.GOLD
 var button := JourneyStageDisc.button(str(id), fill)
 button.name = "Stage%d" % id
 var milestone := not JourneyLibrary.milestone(id).is_empty()
 var diameter := 210.0 if id == selected_stage else 164.0
 button.position = _point(id - 1) - Vector2.ONE * diameter*.5
 button.size = Vector2.ONE * diameter
 button.disabled = not unlocked
 button.add_theme_color_override("font_color", Palette.PAPER)
 button.add_theme_color_override("font_outline_color", Palette.WOOD_DARK)
 button.add_theme_constant_override("outline_size", 5)
 _grid.add_child(button)
 button.pressed.connect(func() -> void: _select_stage(id))
 if milestone:
  var landmark := TextureRect.new()
  landmark.texture = load("res://assets/menu/nav_v4/shop.png")
  landmark.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
  landmark.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
  landmark.mouse_filter = Control.MOUSE_FILTER_IGNORE
  landmark.modulate = Color.WHITE if stars > 0 else Color(.65, .65, .65)
  JourneyArt.place(button, landmark, Rect2(-1.12 if (id - 1) % 2 == 0 else 1.06, -.08, 1.06, 1.06))
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
 return button

func _select_stage(id: int) -> void:
 if not ProgressionManager.is_level_unlocked(id):
  return
 var previous := selected_stage
 selected_stage = id
 GameManager.pending_level_id = id
 GameManager.pending_tutorial_index = 0
 for changed in [previous, id]:
  if _nodes.has(changed):
   _remove_stage_node(changed)
   _nodes[changed] = _make_stage_node(changed)
 _refresh()
 _center_on_selected()

func _refresh() -> void:
 var cleared := 0
 for id in range(1, LevelLibrary.count() + 1):
  if ProgressionManager.stars_for(id) > 0:
   cleared += 1
 _unlock_note.text = (MenuText.text("route_progress") % [cleared, LevelLibrary.count(), ProgressionManager.total_stars()]) + " · " + JourneyArt.localized("Gerai", "Stall") + " %d/3" % LocationManager.structural_level(LocationDefinition.for_stage(selected_stage).id)
 _stage_label.text = "%s %d" % [MenuText.text("stage"), selected_stage]
 _stage_subtitle.text = LevelLibrary.display_title(LevelLibrary.get_level(selected_stage))
 _start.disabled = not ProgressionManager.is_level_unlocked(selected_stage)
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
 var origin := size.y*.22-_scroll.scroll_vertical
 var last := _sections.size() - 1
 for section in _world_layers:
  _world_layers[section].position = Vector2(0,origin+(last-section)*_chapter_height)
  _world_layers[section].size = Vector2(size.x,_chapter_height)
 for section in _connectors:
  var height := _chapter_height*.16
  _connectors[section].position = Vector2(0,origin+(last-section+1)*_chapter_height-height*.5)
  _connectors[section].size = Vector2(size.x,height)

func _world_path(section: int) -> String:
 return WORLD_ROOT + String(_sections[section]["world"]) + ".png"

func _world_texture(section: int) -> Texture2D:
 var path := _world_path(section)
 if not _world_textures.has(path):
  if _world_requests.has(path):
   _world_requests.erase(path)
   _world_textures[path] = ResourceLoader.load_threaded_get(path)
  else:
   _world_textures[path] = load(path)
 return _world_textures[path]

func _sync_worlds() -> void:
 var nearby: Array[int] = []
 for section in _window:
  for neighbour in [section - 1, section, section + 1]:
   if neighbour >= 0 and neighbour < _sections.size() and not nearby.has(neighbour):
    nearby.append(neighbour)
 var keep := nearby.map(_world_path)
 for path in _world_textures.keys():
  if not keep.has(path):
   _world_textures.erase(path)
 for section in _world_layers.keys():
  if not _window.has(section):
   _world_layers[section].queue_free()
   _world_layers.erase(section)
 for section in _window:
  if not _world_layers.has(section):
   var layer := TextureRect.new()
   layer.texture = _world_texture(section)
   layer.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
   layer.stretch_mode = TextureRect.STRETCH_SCALE
   layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
   var blend := ShaderMaterial.new()
   blend.shader = preload("res://shaders/journey_chapter_blend.gdshader")
   layer.material = blend
   _world_base.add_child(layer)
   _world_layers[section] = layer
  # A neighbour outside the window is too far away for its seam to show.
  var material: ShaderMaterial = _world_layers[section].material
  material.set_shader_parameter("has_above",_window.has(section + 1))
  material.set_shader_parameter("has_below",_window.has(section - 1))
  if _window.has(section + 1):
   material.set_shader_parameter("above_map",_world_texture(section + 1))
  if _window.has(section - 1):
   material.set_shader_parameter("below_map",_world_texture(section - 1))
 # Start loading the next world early so crossing into it does not stall the scroll.
 for section in nearby:
  var path := _world_path(section)
  if not _window.has(section) and not _world_textures.has(path) and not _world_requests.has(path):
   _world_requests[path] = true
   ResourceLoader.load_threaded_request(path)
 _sync_connectors()

## A connector sits on the seam below its section.
func _sync_connectors() -> void:
 var seams: Array[int] = []
 for section in _window:
  for seam in [section, section + 1]:
   if seam >= 1 and seam < _sections.size() and not seams.has(seam):
    seams.append(seam)
 for seam in _connectors.keys():
  if not seams.has(seam):
   _connectors[seam].queue_free()
   _connectors.erase(seam)
 for seam in seams:
  if _connectors.has(seam):
   continue
  var connector := TextureRect.new()
  connector.texture = preload("res://assets/ui/journey_transitions_v1/connectors.png")
  connector.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
  connector.mouse_filter = Control.MOUSE_FILTER_IGNORE
  var blend := ShaderMaterial.new()
  blend.shader = preload("res://shaders/journey_connector.gdshader")
  blend.set_shader_parameter("frame",float(_sections[seam]["connector"]))
  connector.material = blend
  _connector_base.add_child(connector)
  _connectors[seam] = connector


func cleared_chapter_one() -> bool:
 return ProgressionManager.highest_cleared() >= FamilyStallChapter.MORNING_RUSH

func _node_state(entry: Dictionary) -> String:
 var id := int(entry["id"])
 if id > LevelLibrary.count() or not ProgressionManager.is_level_unlocked(id):
  return "locked"
 var progress := stop_progress(entry)
 return "done" if progress["total"] > 0 and progress["cleared"] == progress["total"] else "open"



func stop_progress(entry: Dictionary) -> Dictionary:
 var first := int(entry["id"])
 var last := mini(int(entry["last"]), LevelLibrary.count())
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
 var last := mini(int(entry["last"]), LevelLibrary.count())
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
 var banner := Panel.new()
 banner.name = "StopBanner"
 banner.add_theme_stylebox_override("panel", GeraiSkin.box("name_plate", .72))
 JourneyArt.place(overlay, banner, Rect2(.07, top + .015, .86, .085))
 var heading := JourneyArt.label(banner, JourneyArt.localized(entry["title_ms"],entry["title_en"]), Rect2(.13, .12, .74, .74), 36, Palette.PAPER)
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
