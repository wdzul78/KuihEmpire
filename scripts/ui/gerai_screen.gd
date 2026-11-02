class_name GeraiScreen
extends Control

var _location: StringName = &"family_stall"
var _preview: GeraiBackdrop
var _selector: OptionButton
var _coins: Label # Renovation-star wallet; kept for existing integrations.
var _progress: Label
var _active: Button
var _hotspots: Control
var _panel: PanelContainer
var _notice: Label
var _busy := false
var _variant := "classic"
var _panel_mode := ""
var _selected_task: RenovationTaskDefinition
var _confirm_button: Button
var _choice_buttons: Array[Button] = []
var _tasks_button: Button
var _design_button: Button
var _completion_count: int = 0
var _guide: Control
var _task_filter := "remaining"
var _next_hint: Button
var _progress_before := 0
const RenovationTransition := preload("res://scripts/ui/renovation_transition.gd")

## Opens on this location once, for callers that send the player to a specific stall.
static var requested_location: StringName = &""

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	UIKit.apply_root_theme(self)
	_location = requested_location if LocationManager.stall_unlocked(requested_location) else LocationManager.active_stall_id()
	requested_location = &""
	_build()
	MobileLayout.bind(self, ["StallScene", "BackgroundLayer"])
	LocationManager.location_state_changed.connect(func(_id: StringName) -> void: _refresh())
	LocationManager.active_stall_changed.connect(func(_id: StringName) -> void: _refresh())
	EconomyManager.stars_changed.connect(func(_amount: int) -> void: _refresh())
	EconomyManager.coins_changed.connect(func(_amount: int) -> void: _refresh_wallet())
	_refresh()
	_sync_navigation()
	resized.connect(func() -> void: _refresh.call_deferred())

func _build() -> void:
	var base := ColorRect.new()
	base.name = "BackgroundLayer"
	base.color = Color("f6e7c5")
	base.mouse_filter = Control.MOUSE_FILTER_IGNORE
	JourneyArt.place(self, base, Rect2(0,0,1,1))
	_preview = GeraiBackdrop.new()
	_preview.renovation_showcase = true
	_preview.name = "StallScene"
	_preview.clip_contents = true
	JourneyArt.place(self, _preview, Rect2(0,0,1,1))
	var header := Panel.new()
	header.mouse_filter = Control.MOUSE_FILTER_IGNORE
	header.add_theme_stylebox_override("panel", GeraiSkin.box("header_bar", .78))
	JourneyArt.place(self, header, Rect2(.012,.006,.976,.124))
	var back := GameButton.create(MenuText.text("back"), "back", 30)
	back.custom_minimum_size = Vector2.ZERO
	JourneyArt.place(self, back, Rect2(.045,.028,.165,.048))
	back.pressed.connect(func() -> void:
		if _busy:
			return
		if not _panel_mode.is_empty():
			_close_panel()
		else:
			GameManager.go_home()
	)
	var plate := TextureRect.new()
	plate.texture = GeraiSkin.texture("name_plate")
	plate.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	plate.stretch_mode = TextureRect.STRETCH_SCALE
	plate.mouse_filter = Control.MOUSE_FILTER_IGNORE
	JourneyArt.place(self, plate, Rect2(.22,.022,.50,.058))
	_selector = OptionButton.new()
	_selector.add_theme_font_size_override("font_size", 38)
	# The carved name plate is the backdrop; the selector itself stays flat.
	for state in ["normal", "hover", "pressed", "focus", "disabled"]:
		_selector.add_theme_stylebox_override(state, StyleBoxEmpty.new())
	for state in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		_selector.add_theme_color_override(state, Palette.PAPER)
	_selector.add_theme_color_override("font_outline_color", Palette.WOOD_DARK)
	_selector.add_theme_constant_override("outline_size", 8)
	_selector.alignment = HORIZONTAL_ALIGNMENT_CENTER
	# Size to the selected stall, not the longest locked name, so it never covers the stars.
	_selector.fit_to_longest_item = false
	_selector.clip_text = true
	for location in LocationDefinition.all():
		_selector.add_item(JourneyLibrary.location_name(location.id) + ("" if LocationManager.stall_unlocked(location.id) else " · " + RenovationText.text("locked")))
	JourneyArt.place(self, _selector, Rect2(.27,.026,.40,.05))
	_selector.item_selected.connect(func(index: int) -> void:
		if _busy:
			return
		_close_panel()
		_location = LocationDefinition.all()[index].id
		_refresh()
		_show_tasks()
	)
	# Star medallion pill; the number sits in its plain right-hand groove.
	var counter := GeraiSkin.icon("star_counter")
	JourneyArt.place(self, counter, Rect2(.73,.026,.245,.046))
	_coins = JourneyArt.label(self, "", Rect2(.82,.028,.145,.042), 46, Palette.WOOD_DARK)
	_progress = JourneyArt.label(self, "", Rect2(.06,.084,.88,.03), 32, Palette.WOOD_DARK)
	_guide = Control.new()
	_guide.hide()
	_guide.mouse_filter = Control.MOUSE_FILTER_IGNORE
	JourneyArt.place(self,_guide,Rect2(.73,.255,.25,.19))
	var aina := TextureRect.new()
	aina.texture = load("res://assets/characters/fullbody_v2/aina.png")
	aina.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	aina.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	aina.mouse_filter = Control.MOUSE_FILTER_IGNORE
	JourneyArt.place(_guide,aina,Rect2(0,0,1,1))
	_hotspots = Control.new()
	_hotspots.mouse_filter = Control.MOUSE_FILTER_IGNORE
	JourneyArt.place(self, _hotspots, Rect2(0,0,1,1))
	_next_hint = Button.new()
	_next_hint.name = "NextObjective"
	_next_hint.add_theme_font_size_override("font_size",36)
	_next_hint.add_theme_color_override("font_color",Palette.WOOD_DARK)
	GeraiSkin.skin_button(_next_hint, "next_hint", .56)
	UIKit.add_press_feedback(_next_hint)
	JourneyArt.place(self,_next_hint,Rect2(.08,.775,.84,.076))
	var hint_label := UIKit.wrap_label("",36,Palette.WOOD_DARK,HORIZONTAL_ALIGNMENT_LEFT)
	hint_label.name = "NextText"
	hint_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	hint_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	# Text starts right of the painted clipboard badge.
	JourneyArt.place(_next_hint,hint_label,Rect2(.235,.12,.72,.76))
	_next_hint.pressed.connect(func() -> void:
		var task := _next_task()
		if task != null:
			_inspect_task(task)
		else:
			_show_design()
	)
	var footer := Panel.new()
	footer.add_theme_stylebox_override("panel", GeraiSkin.box("footer_bar", .7))
	JourneyArt.place(self, footer, Rect2(.015,.884,.97,.098))
	var navigation := HBoxContainer.new()
	navigation.add_theme_constant_override("separation", 14)
	JourneyArt.place(self, navigation, Rect2(.05,.898,.90,.07))
	_tasks_button = _navigation_action(RenovationText.text("tasks"), 0)
	_design_button = _navigation_action(RenovationText.text("design"), 1)
	var play := GameButton.create("▶ " + RenovationText.text("play"), "primary", 46)
	play.size_flags_stretch_ratio = .85
	for button in [_tasks_button, _design_button, play]:
		button.custom_minimum_size = Vector2.ZERO
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		navigation.add_child(button)
	_tasks_button.pressed.connect(_toggle_tasks)
	_design_button.pressed.connect(_toggle_design)
	play.pressed.connect(func() -> void:
		if not _busy:
			GameManager.play_next()
	)
	_notice = JourneyArt.label(self, "", Rect2(.03,.975,.94,.021), 28, Palette.WOOD_DARK)
	_notice.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

func _navigation_action(caption: String, icon_index: int) -> Button:
	var button := Button.new()
	button.text = caption
	button.add_theme_font_size_override("font_size",38)
	button.add_theme_color_override("font_color",Palette.WOOD_DARK)
	for state in ["font_hover_color","font_pressed_color","font_focus_color"]:
		button.add_theme_color_override(state,Palette.WOOD_DARK)
	# Painted dock button: the icon fills its round socket, the label sits right of it.
	GeraiSkin.skin_button(button, "nav_button", .67, [118, 0, 14, 0])
	UIKit.add_press_feedback(button)
	button.add_theme_constant_override("outline_size",0)
	button.clip_text = true
	var icon := GeraiSkin.icon("icon_tasks" if icon_index == 0 else "icon_design")
	icon.set_anchors_preset(Control.PRESET_LEFT_WIDE)
	icon.anchor_top = .5
	icon.anchor_bottom = .5
	icon.offset_left = 16
	icon.offset_right = 108
	icon.offset_top = -46
	icon.offset_bottom = 46
	button.add_child(icon)
	button.alignment = HORIZONTAL_ALIGNMENT_CENTER
	return button

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") and not _busy and not _panel_mode.is_empty():
		_close_panel()
		get_viewport().set_input_as_handled()

func _toggle_tasks() -> void:
	if _busy:
		return
	if _panel_mode == "tasks":
		_close_panel()
	else:
		_show_tasks()

func _toggle_design() -> void:
	if _busy:
		return
	if _panel_mode == "design":
		_close_panel()
	else:
		_show_design()

func _sync_navigation() -> void:
	if _tasks_button == null:
		return
	var remaining := 0
	for task in _tasks():
		if not task.complete():
			remaining += 1
	# The open panel already shows which tab is active, so the labels skip arrows to fit.
	_tasks_button.text = "%s %d" % [RenovationText.text("tasks"), remaining]
	_design_button.text = RenovationText.text("design")
	_refresh_markers()

func _next_task() -> RenovationTaskDefinition:
	for task in _tasks():
		if not task.complete() and task.available():
			return task
	for task in _tasks():
		if not task.complete():
			return task
	return null

func _inspect_task(task: RenovationTaskDefinition) -> void:
	if _busy:
		return
	if task.complete() and task.kind == RenovationTaskDefinition.Kind.STRUCTURE:
		var change := RenovationTaskDefinition.style_task(_location)
		change.state_index = task.state_index
		change.title_key = task.title_key
		_open_choices(change)
	elif task.available():
		_open_choices(task)
	else:
		var stack := _open_panel(RenovationText.text("locked"),.58,.88)
		_panel_mode = "locked"
		stack.add_child(UIKit.wrap_label(task.title(),38,Palette.WOOD_DARK))
		stack.add_child(UIKit.wrap_label(task.lock_reason(),32,Palette.WOOD_DARK))
		_action(stack,RenovationText.text("tasks"),_show_tasks)
		_sync_navigation()

func _refresh_markers() -> void:
	if _hotspots == null or _next_hint == null:
		return
	for child in _hotspots.get_children():
		_hotspots.remove_child(child)
		child.queue_free()
	var visible_scene := _panel_mode.is_empty() and not _busy
	_hotspots.visible = visible_scene and _location == &"family_stall"
	_next_hint.visible = visible_scene
	var next := _next_task()
	(_next_hint.get_node("NextText") as Label).text = RenovationText.text("all_done") if next == null else RenovationText.text("next_objective") + ": " + next.title() + (" · ★ %d" % next.cost() if next.available() else "")
	if not _hotspots.visible:
		return
	var grouped: Dictionary = {}
	for task in _tasks():
		var key := "structure_%d" % task.state_index if task.kind == RenovationTaskDefinition.Kind.STRUCTURE else DecorDefinition.find(task.decor_id).slot
		if not grouped.has(key) or (task.available() and not task.complete()):
			grouped[key] = task
	for task: RenovationTaskDefinition in grouped.values():
		if task.complete():
			continue
		var uv := _preview.component_rect(task.state_index) if task.kind == RenovationTaskDefinition.Kind.STRUCTURE else _preview.decor_rect(DecorDefinition.find(task.decor_id))
		var marker := Button.new()
		marker.name = "Marker_" + task.id.replace(":","_")
		for state in ["normal","hover","pressed","focus"]:
			marker.add_theme_stylebox_override(state,StyleBoxEmpty.new())
		UIKit.add_press_feedback(marker)
		_hotspots.add_child(marker)
		# Painted map-pin medallion: star when affordable work is ready, padlock otherwise.
		var pin := GeraiSkin.icon("hotspot_done" if task.complete() else "hotspot_ready" if task.available() else "hotspot_locked")
		pin.name = "HotspotIcon"
		JourneyArt.place(marker,pin,Rect2(0,0,1,1))
		marker.size = Vector2(104,104)
		var point := _preview.art_point(uv.get_center())
		if task.kind == RenovationTaskDefinition.Kind.STRUCTURE and task.state_index == 3:
			point = _preview.art_point(Vector2(.18,.38))
		elif task.kind == RenovationTaskDefinition.Kind.DECOR and DecorDefinition.find(task.decor_id).slot == "COUNTER_FRONT":
			point = _preview.art_point(Vector2(.84,.69))
		elif task.kind == RenovationTaskDefinition.Kind.DECOR and DecorDefinition.find(task.decor_id).slot == "SIGN_BOARD":
			point = _preview.art_point(Vector2(.69,.37))
		marker.position = Vector2(clampf(point.x-52,8,size.x-112),clampf(point.y-52,size.y*.135,size.y*.70))
		marker.tooltip_text = task.title() + ("\n" + task.lock_reason() if not task.available() and not task.complete() else "")
		marker.pressed.connect(_inspect_task.bind(task))

func _tasks() -> Array[RenovationTaskDefinition]:
	return RenovationTaskDefinition.for_location(_location)

func _refresh_wallet() -> void:
	_coins.text = str(EconomyManager.stars())

func _refresh() -> void:
	if _preview == null:
		return
	_refresh_wallet()
	if _busy:
		return
	var done := 0
	var remaining := 0
	for task in _tasks():
		if task.complete():
			done += 1
		else:
			remaining += 1
	_progress.text = RenovationText.text("progress") % [done, _tasks().size()]
	# Markers read the preview's location, so it must match the selected stall first.
	if _panel_mode != "choices":
		_preview.apply_environment(_location)
	_sync_navigation()
	_design_button.disabled = not LocationManager.stall_unlocked(_location)
	for index in LocationDefinition.all().size():
		if LocationDefinition.all()[index].id == _location:
			_selector.select(index)
	if _panel_mode == "choices":
		_update_choice_state()
		return
	if _panel_mode in ["tasks", "design"]:
		_rebuild_tasks(_panel_mode == "design")

func _close_panel() -> void:
	if is_instance_valid(_panel):
		remove_child(_panel)
		_panel.queue_free()
	_panel = null
	_panel_mode = ""
	_choice_buttons.clear()
	_selected_task = null
	_confirm_button = null
	_preview.renovation_focus = Vector2(.5,0)
	_preview.component_preview.clear()
	_preview.showcase_focus = Rect2()
	_preview.showcase_pan = Vector2.ZERO
	_guide.hide()
	_preview.anchor_bottom = 1.0
	_preview.apply_environment(_location)
	_selector.disabled = false
	_sync_navigation()

func _open_panel(title: String, top: float = .55, bottom: float = .89, celebration: bool = false) -> VBoxContainer:
	_close_panel()
	# The celebration frame keeps its painted aspect so the ribbon never stretches;
	# the list frame stretches freely because its title plaque is a fixed overlay.
	var width := .84 if celebration else .95
	var dialog := GeraiSkin.dialog(title, celebration, width)
	_panel = dialog.panel
	_panel.name = "StallUpgradePanel"
	_panel.z_index = 200
	JourneyArt.place(self, _panel, Rect2((1.0-width)*.5,top,width,bottom-top))
	_panel.modulate.a = 0
	_panel.create_tween().tween_property(_panel,"modulate:a",1.0,.16)
	_hotspots.hide()
	_next_hint.hide()
	var safe := MobileLayout.safe_rect(self)
	var inset := MobileLayout.inset_offsets(size, safe, Vector4(_panel.anchor_left,_panel.anchor_top,_panel.anchor_right,_panel.anchor_bottom))
	_panel.offset_left += inset.x
	_panel.offset_top += inset.y
	_panel.offset_right += inset.z
	_panel.offset_bottom += inset.w
	var stack: VBoxContainer = dialog.stack
	var chrome: Control = dialog.chrome
	var content_top: float = dialog.content_top
	var close := UIKit.close_button()
	close.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	close.offset_left = -36
	close.offset_right = 64
	close.offset_top = (110 if celebration else 70) - content_top
	close.offset_bottom = close.offset_top + 100
	chrome.add_child(close)
	close.pressed.connect(func() -> void:
		if not _busy:
			_close_panel()
	)
	return stack

func _show_tasks() -> void:
	if _busy:
		return
	_rebuild_tasks(false)

func _show_design() -> void:
	if _busy:
		return
	_rebuild_tasks(true)

func _rebuild_tasks(design: bool) -> void:
	var stack := _open_panel(RenovationText.text("design_mode" if design else "todo"), .44, .88)
	_guide.hide()
	_panel_mode = "design" if design else "tasks"
	_sync_navigation()
	var done := 0
	for task in _tasks():
		if task.complete():
			done += 1
	var meter := ProgressBar.new()
	meter.max_value = _tasks().size()
	meter.value = done
	meter.show_percentage = false
	GeraiSkin.style_progress(meter, 40)
	stack.add_child(meter)
	stack.add_child(UIKit.wrap_label(RenovationText.text("progress") % [done,_tasks().size()], 34, Palette.WOOD_DARK))
	if not design:
		var filters := HBoxContainer.new()
		filters.add_theme_constant_override("separation",10)
		stack.add_child(filters)
		for key in ["remaining","all","done"]:
			var tab := Button.new()
			tab.text = RenovationText.text(key + "_tab")
			tab.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			tab.custom_minimum_size.y = 78
			tab.add_theme_font_size_override("font_size",34)
			var selected: bool = _task_filter == key
			for state in ["font_color","font_hover_color","font_pressed_color","font_focus_color"]:
				tab.add_theme_color_override(state,Palette.PAPER if selected else Palette.WOOD_DARK)
			tab.add_theme_color_override("font_outline_color",Palette.LEAF_DEEP)
			tab.add_theme_constant_override("outline_size",8 if selected else 0)
			GeraiSkin.skin_button(tab, "tab_active" if selected else "tab_idle", .65)
			UIKit.add_press_feedback(tab)
			filters.add_child(tab)
			tab.pressed.connect(func() -> void:
				_task_filter = key
				_show_tasks()
			)
	if not LocationManager.stall_unlocked(_location):
		stack.add_child(UIKit.wrap_label(RenovationText.text("locked_stall"), 30, Palette.WOOD_DARK))
		return
	if done == _tasks().size() and not design:
		stack.add_child(UIKit.wrap_label(RenovationText.text("all_done"), 32, Palette.WOOD_DARK))
	var scroll := ScrollContainer.new()
	scroll.name = "TaskList"
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_ALWAYS
	scroll.get_v_scroll_bar().custom_minimum_size.x = 24
	scroll.scroll_deadzone = 12
	stack.add_child(scroll)
	var list := UIKit.vbox(14)
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(list)
	if design and _location != &"family_stall" and LocationManager.structural_level(_location) > 0:
		_add_task_card(list,RenovationTaskDefinition.style_task(_location),true)
	var ordered: Array[RenovationTaskDefinition] = []
	# Actionable work leads the list; locked and completed work stays inspectable.
	for task in _tasks():
		if not task.complete() and task.available():
			ordered.append(task)
	for task in _tasks():
		if not task.complete() and not task.available():
			ordered.append(task)
	for task in _tasks():
		if task.complete():
			ordered.append(task)
	for task in ordered:
		if design and not task.complete():
			continue
		if not design and ((_task_filter == "remaining" and task.complete()) or (_task_filter == "done" and not task.complete())):
			continue
		_add_task_card(list, task, design)
	if list.get_child_count() == 0:
		list.add_child(UIKit.wrap_label(RenovationText.text("empty_design" if design else "no_tasks"),32,Palette.WOOD_DARK))
	_active = GameButton.create(RenovationText.text("active") if LocationManager.active_stall_id() == _location else RenovationText.text("activate"), "back", 26)
	_active.custom_minimum_size.y = 82
	_active.disabled = LocationManager.active_stall_id() == _location
	_active.visible = design and not _active.disabled
	stack.add_child(_active)
	_active.pressed.connect(func() -> void:
		if not _busy:
			LocationManager.set_active_stall(_location)
	)
	var supplies := GameButton.create(RenovationText.text("supplies"), "secondary", 26)
	supplies.custom_minimum_size.y = 72
	supplies.visible = design
	stack.add_child(supplies)
	supplies.pressed.connect(_show_supplies)

func _add_task_card(list: VBoxContainer, task: RenovationTaskDefinition, design: bool) -> void:
	var card := PanelContainer.new()
	card.name = "Task_" + task.id.replace(":", "_")
	card.custom_minimum_size.y = 180
	# The row's round socket sits at the left; the icon is centred inside it.
	card.add_theme_stylebox_override("panel", GeraiSkin.box("task_row", .82, [58, 18, 34, 18]))
	list.add_child(card)
	var margin := UIKit.margin(14)
	card.add_child(margin)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 30)
	margin.add_child(row)
	var task_icon := RenovationArt.icon(task.icon_key, 112)
	if task.kind == RenovationTaskDefinition.Kind.DECOR:
		task_icon.texture = RenovationArt.design_texture(task.decor_id, str(LocationManager.decor_styles(_location).get(DecorDefinition.find(task.decor_id).slot, "original")))
	elif _location == &"family_stall":
		task_icon.texture = RenovationArt.component_texture(maxi(1,task.state_index),LocationManager.variant_for(_location,maxi(1,task.state_index)))
	row.add_child(task_icon)
	var text := UIKit.vbox(6)
	text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(text)
	text.add_child(UIKit.wrap_label(task.title(), 40, Palette.WOOD_DARK, HORIZONTAL_ALIGNMENT_LEFT))
	var complete := task.complete()
	var available := task.available()
	var status := RenovationText.text("done" if complete else "ready" if available else "locked")
	if task.kind == RenovationTaskDefinition.Kind.STYLE:
		status = RenovationText.text("owned")
	elif not complete and available:
		status += " · ★ %d" % task.cost()
	elif not complete:
		status += " · " + task.lock_reason()
	if complete and task.kind == RenovationTaskDefinition.Kind.DECOR:
		var item := DecorDefinition.find(task.decor_id)
		status = RenovationText.text("installed" if str(LocationManager.equipped(_location).get(item.slot,"")) == item.id else "stored")
	elif available and not complete and not EconomyManager.can_afford_stars(task.cost()):
		status = RenovationText.text("need_stars") % (task.cost() - EconomyManager.stars())
	text.add_child(UIKit.wrap_label(status, 34, Palette.WOOD_DARK, HORIZONTAL_ALIGNMENT_LEFT))
	var can_change := task.kind != RenovationTaskDefinition.Kind.STRUCTURE or (complete and _location == &"family_stall")
	var priced := available and not complete and task.kind != RenovationTaskDefinition.Kind.STYLE
	var caption := RenovationText.text("redesign") if complete or task.kind == RenovationTaskDefinition.Kind.STYLE else "★ %d" % task.cost() if available else RenovationText.text("inspect")
	var button := GameButton.create(caption, "primary" if available or complete else "back", 32)
	button.custom_minimum_size = Vector2(190,96)
	if priced:
		# Painted star-price pill; its gold star badge replaces the ★ glyph.
		button.text = str(task.cost())
		button.custom_minimum_size = Vector2(236,96)
		GeraiSkin.skin_button(button, "price_button", .64, [96, 0, 30, 6])
		button.add_theme_font_size_override("font_size", 40)
		for state in ["font_color","font_hover_color","font_pressed_color","font_focus_color"]:
			button.add_theme_color_override(state, Palette.PAPER)
		button.add_theme_color_override("font_outline_color", Palette.LEAF_DEEP)
		button.add_theme_constant_override("outline_size", 10)
	button.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	button.disabled = complete and not can_change
	row.add_child(button)
	button.pressed.connect(_inspect_task.bind(task))

func _show_upgrade() -> void:
	for task in _tasks():
		if task.kind == RenovationTaskDefinition.Kind.STRUCTURE and not task.complete():
			_open_choices(task)
			return

func _show_style() -> void:
	if LocationManager.structural_level(_location) > 0:
		_open_choices(RenovationTaskDefinition.style_task(_location))

func _show_decor(item: DecorDefinition) -> void:
	for task in _tasks():
		if task.decor_id == item.id:
			_open_choices(task)
			return

func _open_choices(task: RenovationTaskDefinition) -> void:
	if _busy or not task.available():
		return
	var stack := _open_panel(RenovationText.text("choose_design"), .44, .88)
	_panel_mode = "choices"
	_selected_task = task
	_variant = LocationManager.variant_for(_location,task.state_index) if task.kind == RenovationTaskDefinition.Kind.STYLE else "classic"
	if task.kind == RenovationTaskDefinition.Kind.DECOR:
		var item := DecorDefinition.find(task.decor_id)
		_variant = str(LocationManager.decor_styles(_location).get(item.slot,"original"))
	_selector.disabled = true
	_preview.renovation_focus = Vector2(.5,.65) if task.kind == RenovationTaskDefinition.Kind.DECOR and DecorDefinition.find(task.decor_id).slot == "COUNTER_DECOR" else Vector2(.5,0)
	stack.add_child(UIKit.wrap_label(task.title(), 38, Palette.WOOD_DARK))
	stack.add_child(UIKit.wrap_label(task.description(),32,Palette.WOOD_DARK))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 14)
	stack.add_child(row)
	for choice in task.choices():
		var button := Button.new()
		button.name = "Choice_" + choice
		button.custom_minimum_size = Vector2(0,235)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
		row.add_child(button)
		_choice_buttons.append(button)
		var content := UIKit.vbox(6)
		content.mouse_filter = Control.MOUSE_FILTER_IGNORE
		JourneyArt.place(button, content, Rect2(.035,.04,.93,.92))
		var icon := RenovationArt.icon(task.icon_key, 144)
		icon.custom_minimum_size.x = 0
		icon.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		icon.name = "AccessoryPreview" if task.kind == RenovationTaskDefinition.Kind.DECOR and choice == task.choices()[0] else "DesignPreview"
		if task.kind == RenovationTaskDefinition.Kind.DECOR:
			icon.texture = RenovationArt.design_texture(task.decor_id, choice)
			content.add_child(icon)
		else:
			icon.free()
			if _location == &"family_stall":
				var thumbnail := TextureRect.new()
				thumbnail.name = "DesignPreview"
				thumbnail.texture = RenovationArt.component_texture(task.state_index,choice)
				thumbnail.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
				thumbnail.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
				thumbnail.custom_minimum_size = Vector2(0,144)
				content.add_child(thumbnail)
			else:
				var thumbnail := GeraiBackdrop.new()
				thumbnail.name = "DesignPreview"
				thumbnail.custom_minimum_size = Vector2(0,144)
				thumbnail.size_flags_horizontal = Control.SIZE_EXPAND_FILL
				content.add_child(thumbnail)
				thumbnail.preview_design(_location,task.state_index,choice,LocationManager.equipped(_location),LocationManager.decor_styles(_location))
		var name_label := UIKit.wrap_label(task.choice_label(choice), 36, Palette.WOOD_DARK)
		name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		content.add_child(name_label)
		var mark := UIKit.label("", 30, Palette.LEAF_DEEP)
		mark.name = "SelectedMark"
		mark.hide() # Selection is shown by the clear green outline, without an overflowing caption.
		mark.mouse_filter = Control.MOUSE_FILTER_IGNORE
		content.add_child(mark)
		button.pressed.connect(_select_choice.bind(choice))
	_notice = UIKit.wrap_label("", 32, Palette.WOOD_DARK)
	stack.add_child(_notice)
	var actions := HBoxContainer.new()
	actions.add_theme_constant_override("separation", 18)
	stack.add_child(actions)
	var cancel := GameButton.create(RenovationText.text("cancel"), "secondary", 34)
	cancel.custom_minimum_size = Vector2(0,96)
	cancel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	actions.add_child(cancel)
	cancel.pressed.connect(_show_tasks)
	_confirm_button = GameButton.create("", "primary", 36)
	_confirm_button.custom_minimum_size = Vector2(0,96)
	_confirm_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	actions.add_child(_confirm_button)
	_confirm_button.pressed.connect(_confirm_selection)
	if task.kind == RenovationTaskDefinition.Kind.DECOR and task.complete():
		var remove := GameButton.create(RenovationText.text("remove"), "back", 26)
		remove.custom_minimum_size.y = 54
		stack.add_child(remove)
		remove.pressed.connect(func() -> void: _select_choice("none"))
	_select_choice(_variant)

func _select_choice(choice: String) -> void:
	if _busy or _selected_task == null:
		return
	_variant = choice
	var task := _selected_task
	var decor := LocationManager.equipped(_location).duplicate()
	var styles := LocationManager.decor_styles(_location)
	var state := LocationManager.structural_level(_location)
	var variant := LocationManager.variant_for(_location)
	if task.kind == RenovationTaskDefinition.Kind.DECOR:
		var item := DecorDefinition.find(task.decor_id)
		if choice == "none":
			decor.erase(item.slot)
		else:
			decor[item.slot] = item.id
			styles[item.slot] = choice
	else:
		if task.kind == RenovationTaskDefinition.Kind.STRUCTURE:
			state = task.state_index
			variant = choice
		elif not _preview.showcase_active():
			variant = choice
	_preview.preview_design(_location,state,variant,decor,styles)
	_preview.showcase_focus = _preview.decor_rect(DecorDefinition.find(task.decor_id)) if task.kind == RenovationTaskDefinition.Kind.DECOR else _preview.component_rect(task.state_index)
	if task.kind == RenovationTaskDefinition.Kind.STYLE:
		_preview.component_preview[task.state_index] = choice
		_preview.queue_redraw()
	_focus_choice_preview()
	_update_choice_state()

func _focus_choice_preview() -> void:
	if _preview.showcase_active():
		_preview.showcase_pan = Vector2.ZERO
		var target := _preview.art_point(_preview.showcase_focus.get_center())
		_preview.showcase_pan.y = minf(0,size.y * .29 - target.y)
		_preview.queue_redraw()
		return
	if _selected_task == null or _preview._background == null:
		return
	# Frame the edited object in the free part of the scene above the choices.
	var point := Vector2(.5,.55)
	if _selected_task.kind == RenovationTaskDefinition.Kind.DECOR:
		point = DecorDefinition.find(_selected_task.decor_id).art_rect(_location).get_center()
	elif _selected_task.kind == RenovationTaskDefinition.Kind.STRUCTURE:
		point = StallDefinition.find(_location).state(_selected_task.state_index).hotspot
	else:
		point = Vector2(.5,.12)
	var pixels := _preview._background.get_size()
	var scaled := pixels * maxf(_preview.size.x / pixels.x, _preview.size.y / pixels.y)
	if scaled.y > _preview.size.y:
		_preview.renovation_focus = Vector2(.5,clampf((scaled.y * point.y - _preview.size.y * .5) / (scaled.y - _preview.size.y),0,1))
	_preview.queue_redraw()

func _update_choice_state() -> void:
	if _selected_task == null or _confirm_button == null:
		return
	for button in _choice_buttons:
		var selected := button.name == "Choice_" + _variant
		for state in ["normal","hover","pressed","disabled"]:
			button.add_theme_stylebox_override(state, UIKit.flat_box(Color("e8f4cf") if selected else Color("fffaf0"), Palette.LEAF_DEEP if selected else Color("ddc492"), 14, 5 if selected else 2, 18))
		var mark := button.find_child("SelectedMark",true,false) as Label
		mark.text = RenovationText.text("selected") if selected else ""
	var price := 0 if _variant == "none" else _selected_task.cost()
	_confirm_button.text = RenovationText.text("confirm") % price if price > 0 else RenovationText.text("apply")
	_confirm_button.disabled = not EconomyManager.can_afford_stars(price) or not _selected_task.available()
	_notice.text = RenovationText.text("need_stars") % (price - EconomyManager.stars()) if price > EconomyManager.stars() else RenovationText.text("owned") if price == 0 else RenovationText.text("preview")

func _confirm_selection() -> void:
	if _busy or _selected_task == null:
		return
	var task := _selected_task
	var chosen := _variant
	var redesign := task.complete() or task.kind == RenovationTaskDefinition.Kind.STYLE
	_progress_before = 0
	for entry in _tasks():
		if entry.complete():
			_progress_before += 1
	_busy = true
	# Capture the saved design, not the uncommitted preview, for the replacement.
	var old_decor := LocationManager.equipped(_location).duplicate()
	var old_styles := LocationManager.decor_styles(_location).duplicate()
	var old_variant := LocationManager.variant_for(_location)
	var old_component_variant := LocationManager.variant_for(_location,maxi(1,task.state_index))
	var outcome := LocationManager.confirm_task(task,chosen)
	if not outcome.ok:
		_busy = false
		_notice.text = RenovationText.text("save_failed") if outcome.error == "save_failed" else (RenovationText.text("need_stars") % maxi(0,task.cost() - EconomyManager.stars())) if outcome.error == "insufficient_stars" else RenovationText.text("task_changed")
		return
	AudioManager.play(AudioManager.Sfx.REWARD)
	_completion_count += 1
	_refresh_wallet()
	_close_panel()
	_selector.disabled = true
	_panel_mode = "animating"
	_preview.apply_environment(_location)
	var transition := RenovationTransition.new()
	transition.name = "RenovationTransition"
	add_child(transition)
	if task.kind == RenovationTaskDefinition.Kind.DECOR:
		var item := DecorDefinition.find(task.decor_id)
		transition.stretch_to_fit = item.kind in ["sign","counter"]
		_preview.hidden_decor_slot = item.slot
		_preview.queue_redraw()
		var uv := _preview.decor_rect(item)
		var target := Rect2(_preview.position + _preview.art_point(uv.position), _preview.art_point(uv.end) - _preview.art_point(uv.position))
		var old_texture: Texture2D = null
		if old_decor.has(item.slot):
			old_texture = RenovationArt.design_texture(str(old_decor[item.slot]),str(old_styles.get(item.slot,"original")))
		await transition.play(old_texture,RenovationArt.design_texture(item.id,chosen),target,chosen == "none")
		_preview.hidden_decor_slot = ""
		_preview.queue_redraw()
	elif _preview.showcase_active():
		_preview.hidden_structure = task.state_index
		_preview.queue_redraw()
		var uv := _preview.component_rect(task.state_index)
		var target := Rect2(_preview.position + _preview.art_point(uv.position),_preview.art_point(uv.end) - _preview.art_point(uv.position))
		if task.state_index == 3:
			var left := _preview.lantern_rect(0)
			var right := _preview.lantern_rect(1)
			target = Rect2(_preview.position + _preview.art_point(left.position),_preview.art_point(left.end)-_preview.art_point(left.position))
			transition.paired_lamps = true
			transition.paired_offset = _preview.art_point(right.position)-_preview.art_point(left.position)
		var old_texture: Texture2D = RenovationArt.component_texture(task.state_index,old_component_variant) if redesign else null
		await transition.play(old_texture,RenovationArt.component_texture(task.state_index,chosen),target,false)
		_preview.hidden_structure = 0
		_preview.queue_redraw()
	else:
		# Keep scenery stationary while revealing the restored structure from top to bottom.
		var old_visual := StallDefinition.find(_location).state(maxi(0,task.state_index - 1) if not redesign else task.state_index)
		var previous := old_visual.background_path("renovation", old_variant)
		var texture: Texture2D = load(previous) if ResourceLoader.exists(previous) else _preview._background
		await transition.play_structure(texture, _preview.get_rect())
	transition.queue_free()
	_busy = false
	_selector.disabled = false
	_show_completion(task,redesign)

func _renovate() -> void:
	await _confirm_selection()

func _show_completion(task: RenovationTaskDefinition, redesign: bool = false) -> void:
	# Height matches the celebration frame's painted aspect at .84 screen width.
	var stack := _open_panel(RenovationText.text("design_saved" if redesign else "complete"), .548, .548 + .84 * 1080.0 / 1920.0 * 900.0 / 1280.0, true)
	_panel_mode = "complete"
	stack.add_child(UIKit.wrap_label(task.title(),42,Palette.WOOD_DARK))
	var done := 0
	for entry in _tasks():
		if entry.complete():
			done += 1
	var progress := ProgressBar.new()
	progress.name = "CompletionProgress"
	progress.max_value = _tasks().size()
	progress.value = _progress_before
	progress.show_percentage = false
	GeraiSkin.style_progress(progress, 44)
	stack.add_child(progress)
	progress.create_tween().tween_property(progress,"value",float(done),.55).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	stack.add_child(UIKit.wrap_label(RenovationText.text("progress") % [done,_tasks().size()],36,Palette.LEAF_DEEP))
	_action(stack,RenovationText.text("next_task"),_show_tasks)
	_refresh()

func _show_supplies() -> void:
	if _busy:
		return
	var stack := _open_panel("%s · %d coins" % [RenovationText.text("supplies"), EconomyManager.coins()], .44,.88)
	_panel_mode = "supplies"
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	stack.add_child(scroll)
	var items := UIKit.vbox(12)
	items.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(items)
	for booster in [EconomyManager.Booster.SPATULA,EconomyManager.Booster.TRAY,EconomyManager.Booster.SHUFFLE,EconomyManager.Booster.GIFT,EconomyManager.Booster.EXTRA_MOVES,EconomyManager.Booster.HAND,EconomyManager.Booster.ROYAL,EconomyManager.Booster.START_ORDER,EconomyManager.Booster.START_DELIVERY]:
		var key := EconomyManager.booster_id(booster)
		var price: int = {"start_order":180,"start_delivery":140,"hand":90,"royal":300,"spatula":90,"tray":150,"shuffle":100,"gift":180,"extra_moves":EconomyManager.EXTRA_MOVES_COST}[key]
		var button := _action(items,"%s · %d coins" % [EconomyManager.booster_name(booster),price],func() -> void:
			if EconomyManager.spend_coins(price):
				EconomyManager.grant_booster(booster)
				SaveManager.save_game()
				_show_supplies()
		)
		button.disabled = not EconomyManager.can_afford(price)

func _action(stack: VBoxContainer, text: String, action: Callable) -> Button:
	var button := GameButton.create(text,"primary",36)
	button.custom_minimum_size = Vector2(0,94)
	stack.add_child(button)
	button.pressed.connect(action)
	return button
