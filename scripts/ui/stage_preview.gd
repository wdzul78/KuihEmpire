class_name StagePreview
extends Control
var stage: int
var picks: Array[int] = []
const PANEL := preload("res://assets/ui/stage_preview_v3/panel.png")
## Horizontal centres of the three baked-in count pills on panel.png.
const PILL_X := [.237,.5,.759]

func show_stage(id: int) -> void:
 stage = id
 set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 z_index = 100
 mouse_filter = Control.MOUSE_FILTER_STOP
 var dim := ColorRect.new()
 dim.color = Color(0,0,0,.84)
 JourneyArt.place(self,dim,Rect2(0,0,1,1))
 # Keep the painted panel at its native ratio on every screen shape;
 # stretching it made the pills and Play button look swollen.
 var frame := AspectRatioContainer.new()
 frame.ratio = float(PANEL.get_width())/PANEL.get_height()
 frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
 JourneyArt.place(self,frame,Rect2(.08,.12,.84,.76))
 var card := Control.new()
 frame.add_child(card)
 var art := TextureRect.new()
 art.texture = PANEL
 art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
 art.stretch_mode = TextureRect.STRETCH_SCALE
 art.mouse_filter = Control.MOUSE_FILTER_IGNORE
 JourneyArt.place(card,art,Rect2(0,0,1,1))
 JourneyArt.label(card,"%s %d" % [MenuText.text("stage"),id],Rect2(.25,.055,.50,.10),56,Palette.PAPER)
 JourneyArt.label(card,JourneyArt.localized("Pilih booster","Select boosters"),Rect2(.14,.25,.72,.08),50,Palette.WOOD_DARK)
 var kinds := [BoardCell.Special.DULANG,BoardCell.Special.ORDER,BoardCell.Special.HANTAR]
 var boosters := [EconomyManager.Booster.TRAY,EconomyManager.Booster.START_ORDER,EconomyManager.Booster.START_DELIVERY]
 for index in 3:
  var booster: int = boosters[index]
  var x: float = PILL_X[index]
  var button := Button.new()
  button.toggle_mode = true
  button.custom_minimum_size = Vector2.ZERO
  for state in ["normal","hover","pressed","disabled"]:
   button.add_theme_stylebox_override(state,StyleBoxEmpty.new())
  button.disabled = EconomyManager.booster_count(booster) <= 0
  JourneyArt.place(card,button,Rect2(x-.115,.355,.23,.19))
  var icon := KuihIcon.new()
  icon.kuih = KuihLibrary.get_kuih(&"onde_onde")
  icon.special_kind = kinds[index]
  JourneyArt.place(button,icon,Rect2(.04,.02,.92,.96))
  icon.modulate = Color(.6,.6,.6) if button.disabled else Color.WHITE
  var tick := SelectedTick.new()
  tick.name = "SelectedTick"
  # Sits on the lower-right edge of the booster, over the line above its count.
  JourneyArt.place(button,tick,Rect2(.48,.42,.66,.66))
  tick.hide()
  var count := JourneyArt.label(card,str(EconomyManager.booster_count(booster)),Rect2(x-.1,.562,.2,.06),50,Palette.WOOD_DARK)
  count.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
  var name_label := JourneyArt.label(card,["Badak","Kek Lapis","Kuih Sepit"][index],Rect2(x-.13,.64,.26,.06),36,Palette.WOOD_DARK)
  name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
  button.toggled.connect(func(on: bool) -> void:
   tick.visible = on
   if on:
    tick.pop()
   icon.pivot_offset = icon.size*.5
   icon.scale = Vector2.ONE*(1.08 if on else 1.0)
   if on:
    if not picks.has(booster):
     picks.append(booster)
   else:
    picks.erase(booster)
  )
 # The painted leaf button already carries a play arrow; no caption needed.
 var start := _hit(card,Rect2(.25,.75,.50,.16))
 start.name = "PlayButton"
 start.pressed.connect(func() -> void:
  GameManager.pending_level_id = stage
  GameManager.pending_start_specials.assign(picks)
  GameManager.start_selected_stage()
 )
 var close := _hit(card,Rect2(.83,.10,.13,.11))
 close.pressed.connect(queue_free)

## A big, bouncy tick over a chosen booster. Uses the painted tick when it
## exists and draws a chunky one otherwise.
class SelectedTick extends Control:
 const ART_PATH := "res://assets/ui/stage_preview_v5/selected_tick.png"
 var _art: Texture2D

 func _ready() -> void:
  mouse_filter = Control.MOUSE_FILTER_IGNORE
  z_index = 2
  if ResourceLoader.exists(ART_PATH):
   _art = load(ART_PATH)
  resized.connect(func() -> void: pivot_offset = size*.5)

 func pop() -> void:
  pivot_offset = size*.5
  scale = Vector2.ONE*.2
  rotation = -.5
  var tween := create_tween().set_parallel(true)
  tween.tween_property(self,"scale",Vector2.ONE,.42).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
  tween.tween_property(self,"rotation",0.0,.42).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

 func _draw() -> void:
  var edge := minf(size.x,size.y)
  var box := Rect2((size-Vector2.ONE*edge)*.5,Vector2.ONE*edge)
  if _art != null:
   BoardArt.draw_item_texture(self,box,_art)
   return
  var points := PackedVector2Array([box.position+Vector2(.14,.52)*edge,box.position+Vector2(.40,.78)*edge,box.position+Vector2(.88,.20)*edge])
  var shadow := PackedVector2Array()
  for point in points:
   shadow.append(point+Vector2(0,edge*.04))
  draw_polyline(shadow,Color(.16,.08,.02,.45),edge*.28,true)
  draw_polyline(points,Color("4a2c17"),edge*.28,true)
  draw_polyline(points,Color("fff7dd"),edge*.21,true)
  draw_polyline(points,Color("2f9a2a"),edge*.15,true)
  var shine := PackedVector2Array()
  for point in points:
   shine.append(point+Vector2(0,-edge*.025))
  draw_polyline(shine,Color("8ee86a"),edge*.05,true)
  for at in [Vector2(.86,.62),Vector2(.12,.24)]:
   BoardArt._draw_sparkle(self,box.position+at*edge,edge*.07)


func _hit(parent: Control, rect: Rect2) -> Button:
 var button := Button.new()
 button.custom_minimum_size = Vector2.ZERO
 for state in ["normal","hover","pressed","focus"]:
  button.add_theme_stylebox_override(state,StyleBoxEmpty.new())
 JourneyArt.place(parent,button,rect)
 return button
