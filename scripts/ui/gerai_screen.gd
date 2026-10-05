class_name GeraiScreen
extends Control

var _location: StringName = &"family_stall"
var _tab := "STALL"
var _tabs: Dictionary = {}
var _selector: OptionButton
var _preview: GeraiBackdrop
var _status: Label
var _content: VBoxContainer
var _coins: Label
var _preview_decor := ""
var _debug_state: OptionButton
var _notice: Label

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	UIKit.apply_root_theme(self)
	_build()
	LocationManager.location_state_changed.connect(func(_id: StringName) -> void: _refresh())
	LocationManager.stall_upgraded.connect(func(id: StringName, state: int) -> void:
		if id == _location:
			StallUpgradeCelebration.show_upgrade(self, id, state)
	)
	EconomyManager.coins_changed.connect(func(_amount: int) -> void: _refresh())
	_refresh()

func _build() -> void:
	var backdrop := GeraiBackdrop.new()
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(backdrop)
	var back := GameButton.create("Back", "back", 34)
	back.custom_minimum_size = Vector2.ZERO
	JourneyArt.place(self, back, Rect2(.03,.015,.22,.05))
	back.pressed.connect(GameManager.go_home)
	var heading := JourneyArt.label(self,"My Stalls",Rect2(.27,.015,.42,.05),46,Palette.PAPER)
	heading.add_theme_color_override("font_outline_color",Palette.WOOD_DARK)
	heading.add_theme_constant_override("outline_size",6)
	_coins = JourneyArt.label(self,"",Rect2(.71,.015,.26,.05),32,Palette.PAPER)
	_coins.add_theme_constant_override("outline_size",5)
	_coins.add_theme_color_override("font_outline_color",Palette.WOOD_DARK)
	var panel := Panel.new()
	panel.add_theme_stylebox_override("panel",UIKit.cream_box())
	JourneyArt.place(self,panel,Rect2(.025,.08,.95,.895))
	_selector = OptionButton.new()
	_selector.add_theme_font_size_override("font_size",34)
	for location in LocationDefinition.all():
		_selector.add_item(location.display_name + ("" if LocationManager.accessible(location.id) else " · Coming soon"))
	JourneyArt.place(self,_selector,Rect2(.06,.10,.88,.05))
	_selector.item_selected.connect(func(index: int) -> void:
		_location = LocationDefinition.all()[index].id
		_preview_decor = ""
		if _debug_state != null:
			_debug_state.select(0)
		_refresh()
	)
	for i in 4:
		var tab: String = ["STALL","DECOR","AINA","SUPPLIES"][i]
		var button := GameButton.create(tab.capitalize(),"secondary",29)
		button.custom_minimum_size = Vector2.ZERO
		button.name = "Tab" + tab.capitalize()
		_tabs[tab] = button
		JourneyArt.place(self,button,Rect2(.06+i*.225,.165,.205,.047))
		button.pressed.connect(func() -> void: _tab = tab; _preview_decor = ""; _refresh())
	var preview_panel := Panel.new()
	preview_panel.add_theme_stylebox_override("panel",UIKit.flat_box(Color("f4dfb3"),Palette.WOOD_LIGHT,0,3,18))
	JourneyArt.place(self,preview_panel,Rect2(.06,.23,.88,.38))
	_preview = GeraiBackdrop.new()
	_preview.clip_contents = true
	JourneyArt.place(self,_preview,Rect2(.30,.24,.40,.36))
	_status = JourneyArt.label(self,"",Rect2(.075,.622,.85,.09),32)
	_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	JourneyArt.place(self,scroll,Rect2(.06,.722,.88,.19))
	_content = UIKit.vbox(16)
	_content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(_content)
	_notice = JourneyArt.label(self,"",Rect2(.06,.922,.88,.04),26)
	_notice.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	if OS.has_feature("debug"):
		_debug_state = OptionButton.new()
		_debug_state.add_theme_font_size_override("font_size",24)
		for style in ["normal","hover","pressed","disabled","focus"]:
			_debug_state.add_theme_stylebox_override(style,StyleBoxEmpty.new())
		_debug_state.add_theme_color_override("font_color",Palette.WOOD_DARK)
		for text in ["Development: current state","Development: state 0","Development: state 1","Development: state 2","Development: state 3"]:
			_debug_state.add_item(text)
		JourneyArt.place(self,_debug_state,Rect2(.06,.951,.88,.021))
		_debug_state.item_selected.connect(func(_index: int) -> void: _refresh())

func _refresh() -> void:
	if _content == null:
		return
	for tab in _tabs:
		GameButton.apply(_tabs[tab], "primary" if tab == _tab else "secondary", 29)
		_tabs[tab].custom_minimum_size = Vector2.ZERO
	_coins.text = "%d coins" % EconomyManager.coins()
	var location := LocationDefinition.find(_location)
	for i in LocationDefinition.all().size():
		if LocationDefinition.all()[i].id == _location:
			_selector.select(i)
	var level := LocationManager.structural_level(_location)
	var decor := LocationManager.equipped(_location).duplicate()
	if not _preview_decor.is_empty():
		var item := DecorDefinition.find(_preview_decor)
		decor[item.slot] = item.id
	_preview.apply_environment(_location,decor)
	if _debug_state != null and _debug_state.selected > 0:
		_preview.debug_preview(_location,_debug_state.selected-1,decor)
	_status.text = "%s · %s\nStructure %d / 3 (%d%%) · Story %d / 30" % [location.display_name,location.state_name(level),level,roundi(level*100.0/3),LocationManager.completed_stages(_location)]
	_notice.text = "Preview only · purchases and equip save your changes" if not _preview_decor.is_empty() else "Milestones unlock upgrades. Buy them with coins."
	for child in _content.get_children():
		_content.remove_child(child)
		child.queue_free()
	if not LocationManager.accessible(_location):
		_content.add_child(UIKit.wrap_label("Coming soon · Stages %d–%d\nLocation concept preview. Playable stages are not released yet." % [location.stage_start,location.stage_end],32))
		return
	match _tab:
		"STALL": _stall(location,level)
		"DECOR": _decor_shop()
		"AINA":
			_content.add_child(UIKit.wrap_label("Choose your player avatar in Settings. Aina outfits are coming later.",32))
			_add_button("Choose Avatar", "back",func() -> void: SceneManager.goto(SceneManager.SETTINGS))
		"SUPPLIES":
			for booster in [EconomyManager.Booster.SPATULA,EconomyManager.Booster.TRAY,EconomyManager.Booster.SHUFFLE,EconomyManager.Booster.GIFT]:
				var key := EconomyManager.booster_id(booster)
				var price: int = {"spatula":90,"tray":150,"shuffle":100,"gift":180}[key]
				var button := _add_button("%s · %d owned · Buy %d coins" % [key.capitalize(),EconomyManager.booster_count(booster),price],"primary",func() -> void:
					if EconomyManager.spend_coins(price):
						EconomyManager.grant_booster(booster)
						_refresh()
				)
				button.disabled = not EconomyManager.can_afford(price)

func _stall(location: LocationDefinition, level: int) -> void:
	if _location == &"family_stall" and not OnboardingProgress.restored():
		var restore := _add_button("Restore family stall · %d coins" % OnboardingProgress.RESTORE_COST,"primary",func() -> void: OnboardingProgress.restore_stall(); _refresh())
		restore.disabled = not EconomyManager.can_afford(OnboardingProgress.RESTORE_COST)
	if level >= 3:
		_content.add_child(UIKit.wrap_label("Your stall structure is complete! Personalise it in Decor.",34))
		return
	var requirement := location.requirement(level+1)
	var unlocked := LocationManager.available_level(_location) > level
	_content.add_child(UIKit.wrap_label("Next: %s\n%s Stage %d complete · %d coins" % [location.state_name(level+1),"✓" if unlocked else "Required:",requirement.stage,requirement.coins],32))
	var upgrade := _add_button("Upgrade · %d coins" % requirement.coins,"primary",func() -> void:
		if not LocationManager.upgrade(_location):
			AudioManager.play(AudioManager.Sfx.INVALID)
		_refresh()
	)
	upgrade.disabled = not unlocked or not EconomyManager.can_afford(requirement.coins)
	_content.add_child(UIKit.wrap_label("Stage progress continues even if you save your coins for later.",28))

func _decor_shop() -> void:
	for item in DecorDefinition.all():
		var owned := LocationManager.owned(item.id)
		var equipped: bool = LocationManager.equipped(_location).get(item.slot, "") == item.id
		_content.add_child(UIKit.label("%s · %s" % [item.title,"Equipped" if equipped else "Owned" if owned else "%d coins" % item.cost],34))
		_add_button("Preview " + item.title,"secondary",func() -> void: _preview_decor = item.id; _refresh())
		var action := _add_button("Unequip" if equipped else "Equip" if owned else "Buy", "back" if equipped else "primary",func() -> void:
			if equipped:
				LocationManager.unequip(_location,item.slot)
			elif owned:
				LocationManager.equip(_location,item.id)
			else:
				LocationManager.buy(item.id)
			_preview_decor = ""
			_refresh()
		)
		action.disabled = not owned and not EconomyManager.can_afford(item.cost)
	if not _preview_decor.is_empty():
		_add_button("Cancel preview","back",func() -> void: _preview_decor = ""; _refresh())

func _add_button(text: String, style: String, action: Callable) -> Button:
	var button := GameButton.create(text,style,32)
	button.custom_minimum_size = Vector2(0,100)
	_content.add_child(button)
	button.pressed.connect(action)
	return button
