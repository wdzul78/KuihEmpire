class_name PauseOverlay
extends Control

signal resume_pressed()
signal restart_pressed()
signal extra_moves_pressed()
signal quit_pressed()

class ExitIcon extends Control:
	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		resized.connect(queue_redraw)
	func _draw() -> void:
		var edge := minf(size.x,size.y)
		var at := (size-Vector2.ONE*edge)*.5
		var color := Palette.WOOD_DARK
		var width := maxf(3.0,edge*.075)
		var door := PackedVector2Array([Vector2(.52,.20),Vector2(.18,.20),Vector2(.18,.80),Vector2(.52,.80)])
		for i in door.size():
			door[i] = at+door[i]*edge
		draw_polyline(door,color,width,true)
		draw_line(at+Vector2(.40,.50)*edge,at+Vector2(.89,.50)*edge,color,width,true)
		draw_polyline(PackedVector2Array([at+Vector2(.69,.31)*edge,at+Vector2(.89,.50)*edge,at+Vector2(.69,.69)*edge]),color,width,true)

const HEART = preload("res://assets/ui/hearts_v2/heart_full.png")
var stage_title := ""
var tutorial := false
var restart_available := true
var extra_available := false
var extra_count := 0
var extra_coin_purchase := false
var leave_costs_heart := true
var _leave_dialog: Control
var _pause_panel: Control
var _heart: TextureRect
var _confirming := false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	z_index = 200
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	UIKit.apply_root_theme(self)
	var dim := ColorRect.new()
	dim.color = Color(0,0,0,.86)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(dim)
	_pause_panel = Control.new()
	JourneyArt.place(self,_pause_panel,Rect2(.08,.18,.84,.59))
	var art := TextureRect.new()
	art.texture = load("res://assets/ui/pause_panel_v4/panel.png")
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode = TextureRect.STRETCH_SCALE
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	JourneyArt.place(_pause_panel,art,Rect2(0,0,1,1))
	var heading := TitleArt.create("paused","Paused")
	JourneyArt.place(_pause_panel,heading,Rect2(.24,.14,.52,.092))
	JourneyArt.label(_pause_panel,stage_title.replace(String.chr(194)+String.chr(183),String.chr(183)),Rect2(.17,.236,.66,.044),30,Palette.WOOD_DARK)
	var resume := _art_action(_pause_panel,JourneyArt.localized("Sambung","Resume"),Rect2(.40,.30,.40,.13),52,Color.WHITE)
	resume.pressed.connect(func() -> void: resume_pressed.emit())
	var resume_hit := _art_action(_pause_panel,"",Rect2(.10,.30,.29,.13))
	resume_hit.pressed.connect(func() -> void: resume_pressed.emit())
	var restart := _art_action(_pause_panel,JourneyArt.localized("Mula semula","Restart"),Rect2(.245,.464,.225,.12),44)
	restart.disabled = not restart_available
	restart.pressed.connect(func() -> void: restart_pressed.emit())
	var restart_hit := _art_action(_pause_panel,"",Rect2(.10,.464,.15,.12))
	restart_hit.disabled = not restart_available
	restart_hit.pressed.connect(func() -> void: restart_pressed.emit())
	var stall := _art_action(_pause_panel,JourneyArt.localized("Ke gerai","To stall"),Rect2(.65,.464,.24,.12),44)
	stall.pressed.connect(func() -> void: quit_pressed.emit())
	var stall_hit := _art_action(_pause_panel,"",Rect2(.52,.464,.13,.12))
	stall_hit.pressed.connect(func() -> void: quit_pressed.emit())
	var close := _art_action(_pause_panel,"",Rect2(.82,.07,.12,.09))
	close.pressed.connect(func() -> void: resume_pressed.emit())
	JourneyArt.label(_pause_panel,JourneyArt.localized("+5 langkah","+5 moves"),Rect2(.245,.669,.34,.055),46,Palette.WOOD_DARK)
	JourneyArt.label(_pause_panel,"%d coins" % EconomyManager.EXTRA_MOVES_COST if extra_coin_purchase else JourneyArt.localized("Stok: %d","Stock: %d") % extra_count,Rect2(.245,.727,.34,.045),34,Color("858578"))
	var use := _art_action(_pause_panel,JourneyArt.localized("Guna","Use"),Rect2(.645,.652,.24,.089),46,Color("23682b"))
	use.name = "UseExtraMovesButton"
	use.add_theme_color_override("font_disabled_color",Color("56634d"))
	use.disabled = tutorial or not extra_available
	use.pressed.connect(func() -> void: extra_moves_pressed.emit())

func _art_action(host: Control, caption: String, rect: Rect2, font_size: int = 30, color: Color = Palette.WOOD_DARK) -> Button:
	var button := Button.new()
	button.text = caption
	button.custom_minimum_size = Vector2.ZERO
	button.add_theme_font_override("font",UIKit.bold_font())
	button.add_theme_font_size_override("font_size",font_size)
	for state in ["normal","hover","pressed","disabled"]:
		button.add_theme_stylebox_override(state,StyleBoxEmpty.new())
	for state in ["font_color","font_hover_color","font_pressed_color"]:
		button.add_theme_color_override(state,color)
	JourneyArt.place(host,button,rect)
	return button
func _decorate_action(button: Button, stall: bool) -> void:
	var caption := button.text
	button.text = ""
	button.custom_minimum_size.y = 110
	var icon := preload("res://scripts/ui/pause_action_icon.gd").new()
	icon.stall = stall
	JourneyArt.place(button,icon,Rect2(.04,.13,.28,.74))
	JourneyArt.label(button,caption,Rect2(.33,.12,.64,.76),28,Palette.WOOD_DARK)

func _panel(rect: Rect2) -> PanelContainer:
	var panel := preload("res://scripts/ui/pause_paper_panel.gd").new() as PanelContainer
	panel.add_theme_stylebox_override("panel",StyleBoxEmpty.new())
	JourneyArt.place(self,panel,rect)
	return panel

func _column(panel: Control) -> VBoxContainer:
	var margin := UIKit.margin(48)
	panel.add_child(margin)
	var column := UIKit.vbox(24)
	column.alignment = BoxContainer.ALIGNMENT_CENTER
	margin.add_child(column)
	return column

func _action(caption: String, primary: bool) -> Button:
	var button := GameButton.create(caption,"primary",34) if primary else Button.new()
	button.text = caption
	button.custom_minimum_size = Vector2(0,100 if primary else 82)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	if not primary:
		for state in ["normal","hover","pressed","focus"]:
			button.add_theme_stylebox_override(state,UIKit.flat_box(Color("fff4dc"),Palette.WOOD_LIGHT,0,2,20))
		button.add_theme_font_override("font",UIKit.bold_font())
		button.add_theme_font_size_override("font_size",28)
		button.add_theme_color_override("font_color",Palette.WOOD_DARK)
	return button

func confirm_leave(message: String, confirmed: Callable) -> void:
	if is_instance_valid(_leave_dialog):
		return
	_pause_panel.hide()
	_leave_dialog = Control.new()
	JourneyArt.place(self,_leave_dialog,Rect2(.15,.18,.70,.55))
	_leave_dialog.name = "LeaveStageConfirmation"
	var art := TextureRect.new()
	art.texture = load("res://assets/ui/leave_panel_v3/panel.png")
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode = TextureRect.STRETCH_SCALE
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	JourneyArt.place(_leave_dialog,art,Rect2(0,0,1,1))
	JourneyArt.label(_leave_dialog,JourneyArt.localized("Kembali ke gerai?","Return to stall?"),Rect2(.12,.29,.76,.06),40,Palette.WOOD_DARK)
	_heart = TextureRect.new()
	_heart.texture = HEART
	_heart.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_heart.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	JourneyArt.place(_leave_dialog,_heart,Rect2(.34,.37,.32,.20))
	var heart_count := JourneyArt.label(_heart,str(HeartManager.current()),Rect2(.15,.18,.70,.58),64,Color.WHITE)
	heart_count.name = "CurrentHeartCount"
	heart_count.add_theme_color_override("font_outline_color",Color("a31a36"))
	heart_count.add_theme_constant_override("outline_size",3)
	if leave_costs_heart:
		var badge := Panel.new()
		badge.add_theme_stylebox_override("panel",UIKit.flat_box(Color("fff3d4"),Color("b27a2c"),0,3,50))
		JourneyArt.place(_leave_dialog,badge,Rect2(.57,.48,.12,.08))
		JourneyArt.label(badge,"−1",Rect2(0,0,1,1),36,Palette.WOOD_DARK)

	var leave_message := message if leave_costs_heart else JourneyArt.localized("Tiada nyawa ditolak. Kembali ke gerai?","No heart will be lost. Return to the stall?")
	var explanation := JourneyArt.label(_leave_dialog,leave_message,Rect2(.11,.575,.78,.095),34,Palette.WOOD_DARK)
	explanation.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var keep := GameButton.create(JourneyArt.localized("Terus bermain","Keep playing"),"primary",46)
	keep.custom_minimum_size = Vector2.ZERO
	JourneyArt.place(_leave_dialog,keep,Rect2(.17,.685,.66,.106))
	keep.pressed.connect(_cancel_leave)
	var leave := _art_action(_leave_dialog,"",Rect2(.23,.815,.54,.075))
	JourneyArt.label(leave,JourneyArt.localized("Ya, keluar","Yes, leave"),Rect2(.02,0,.76,1),38,Palette.WOOD_DARK)
	var exit_icon := ExitIcon.new()
	exit_icon.name = "ExitIcon"
	JourneyArt.place(leave,exit_icon,Rect2(.79,.05,.21,.90))
	leave.pressed.connect(func() -> void:
		if _confirming:
			return
		_confirming = true
		keep.disabled = true
		leave.disabled = true
		confirmed.call()
	)
func _cancel_leave() -> void:
	if _confirming:
		return
	_leave_dialog.queue_free()
	_leave_dialog = null
	_pause_panel.show()

func play_heart_loss(before: int, after: int) -> void:
	if not is_instance_valid(_heart) or after >= before:
		return
	_heart.pivot_offset = _heart.size*.5
	for index in 10:
		var sparkle := UIKit.label("✦",28,Color("ffd577") if index % 2 == 0 else Color("ff8aae"))
		_heart.get_parent().add_child(sparkle)
		sparkle.position = _heart.position+_heart.size*.5
		var particles := create_tween().set_parallel(true)
		particles.tween_property(sparkle,"position",sparkle.position+Vector2.from_angle(float(index)*TAU/10.0)*90,.55).set_trans(Tween.TRANS_QUAD)
		particles.tween_property(sparkle,"modulate:a",0.0,.55)
		particles.chain().tween_callback(sparkle.queue_free)
	var count := UIKit.label("%d → %d" % [before,after],34,Palette.WOOD_DARK)
	add_child(count)
	count.position = Vector2(size.x*.72,size.y*.06)
	var tw := create_tween()
	tw.tween_property(_heart,"scale",Vector2.ONE*1.12,.12)
	tw.tween_property(_heart,"scale",Vector2.ONE*.1,.65).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	tw.parallel().tween_property(_heart,"modulate:a",0.0,.65)
	tw.parallel().tween_property(_heart,"position",_leave_dialog.get_global_transform().affine_inverse()*Vector2(size.x*.84,size.y*.06),.65).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	await tw.finished
