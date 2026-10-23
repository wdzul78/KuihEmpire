class_name StagePreview
extends Control
var stage: int
var picks: Array[int] = []

func show_stage(id: int) -> void:
 stage = id
 set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 z_index = 100
 mouse_filter = Control.MOUSE_FILTER_STOP
 var dim := ColorRect.new()
 dim.color = Color(0,0,0,.84)
 JourneyArt.place(self,dim,Rect2(0,0,1,1))
 var card := Control.new()
 JourneyArt.place(self,card,Rect2(.08,.18,.84,.59))
 var art := TextureRect.new()
 art.texture = load("res://assets/ui/stage_preview_v3/panel.png")
 art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
 art.stretch_mode = TextureRect.STRETCH_SCALE
 art.mouse_filter = Control.MOUSE_FILTER_IGNORE
 JourneyArt.place(card,art,Rect2(0,0,1,1))
 JourneyArt.label(card,"%s %d" % [MenuText.text("stage"),id],Rect2(.23,.05,.54,.10),56,Palette.PAPER)
 JourneyArt.label(card,JourneyArt.localized("Pilih booster","Select boosters"),Rect2(.14,.24,.72,.08),50,Palette.WOOD_DARK)
 var kinds := [BoardCell.Special.DULANG,BoardCell.Special.ORDER,BoardCell.Special.HANTAR]
 var boosters := [EconomyManager.Booster.TRAY,EconomyManager.Booster.START_ORDER,EconomyManager.Booster.START_DELIVERY]
 for index in 3:
  var booster: int = boosters[index]
  var button := Button.new()
  button.toggle_mode = true
  button.custom_minimum_size = Vector2.ZERO
  for state in ["normal","hover","pressed","disabled"]:
   button.add_theme_stylebox_override(state,StyleBoxEmpty.new())
  button.disabled = EconomyManager.booster_count(booster) <= 0
  JourneyArt.place(card,button,Rect2(.115+index*.262,.378,.23,.245))
  var icon := KuihIcon.new()
  icon.kuih = KuihLibrary.get_kuih(&"onde_onde")
  icon.special_kind = kinds[index]
  JourneyArt.place(button,icon,Rect2(.04,0,.92,.76))
  icon.modulate = Color(.6,.6,.6) if button.disabled else Color.WHITE
  var tick := JourneyArt.label(button,"✓",Rect2(.70,0,.3,.3),46,Color("3b8628"))
  tick.hide()
  JourneyArt.label(card,str(EconomyManager.booster_count(booster)),Rect2(.13+index*.262,.57,.20,.055),50,Palette.WOOD_DARK)
  JourneyArt.label(card,["Badak","Kek Lapis","Kuih Sepit"][index],Rect2(.10+index*.262,.65,.26,.065),36,Palette.WOOD_DARK)
  button.toggled.connect(func(on: bool) -> void:
   tick.visible = on
   if on:
    if not picks.has(booster):
     picks.append(booster)
   else:
    picks.erase(booster)
  )
 var start := _hit(card,Rect2(.25,.77,.50,.15))
 JourneyArt.label(start,JourneyArt.localized("Main","Play"),Rect2(.53,.1,.44,.8),54,Color.WHITE)
 start.pressed.connect(func() -> void:
  GameManager.pending_level_id = stage
  GameManager.pending_start_specials.assign(picks)
  GameManager.start_selected_stage()
 )
 var close := _hit(card,Rect2(.83,.11,.13,.11))
 close.pressed.connect(queue_free)

func _hit(parent: Control, rect: Rect2) -> Button:
 var button := Button.new()
 button.custom_minimum_size = Vector2.ZERO
 for state in ["normal","hover","pressed","focus"]:
  button.add_theme_stylebox_override(state,StyleBoxEmpty.new())
 JourneyArt.place(parent,button,rect)
 return button
