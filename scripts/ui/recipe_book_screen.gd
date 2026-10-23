class_name RecipeBookScreen
extends Control

const PER_SPREAD := 4
const GUIDE_PER_SPREAD := 6
var _grid: GridContainer
var _page := 0
var _page_label: Label
var _count_label: Label
var _previous: Button
var _next: Button
var _mode := "guide"
var _tabs: Dictionary = {}
var _guide_hint: Label
var _filter := &""
var _filter_button: Button
var _collection_scroll: ScrollContainer
var _claim_status: Label

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	UIKit.apply_root_theme(self)
	PowerupRecipes.sync_seen_kuih()
	_build()
	RecipeBookManager.changed.connect(refresh)

func _build() -> void:
	var backdrop := GeraiBackdrop.new()
	backdrop.background_id = &"stall_dawn"
	backdrop.show_counter = false
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(backdrop)
	var back := GameButton.create(MenuText.text("back"), "back", 38)
	back.custom_minimum_size = Vector2.ZERO
	JourneyArt.place(self, back, Rect2(.035, .015, .23, .055))
	back.pressed.connect(func() -> void:
		AudioManager.play(AudioManager.Sfx.TAP)
		GameManager.go_home()
	)
	var book := TextureRect.new()
	var atlas := AtlasTexture.new()
	atlas.atlas = load("res://assets/ui/recipe_v1/open_book.png")
	atlas.region = Rect2(0, 63, 1024, 1404)
	book.texture = atlas
	book.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	book.stretch_mode = TextureRect.STRETCH_SCALE
	book.mouse_filter = Control.MOUSE_FILTER_IGNORE
	JourneyArt.place(self, book, Rect2(.025, .085, .95, .88))
	JourneyArt.label(self, JourneyArt.localized("Koleksi Kuih", "Kuih Collection"), Rect2(.20, .14, .60, .05), 48, Palette.WOOD_DARK)
	var tabs := HBoxContainer.new()
	JourneyArt.place(self, tabs, Rect2(.10, .20, .80, .047))
	for mode in ["guide", "collections"]:
		var button := GameButton.create(JourneyArt.localized("Resipi", "Recipes") if mode == "recipes" else JourneyArt.localized("Ganjaran", "Rewards") if mode == "collections" else JourneyArt.localized("Koleksi", "Collection"), "primary", 26)
		button.custom_minimum_size = Vector2.ZERO
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		tabs.add_child(button)
		_tabs[mode] = button
		var book_icon := preload("res://scripts/ui/book_tab_icon.gd").new()
		book_icon.notebook = mode == "collections"
		JourneyArt.place(button, book_icon, Rect2(.07,.12,.17,.76))
		button.pressed.connect(_select_mode.bind(mode))
	_guide_hint = JourneyArt.label(self, JourneyArt.localized("Kuih dalam permainan · Tap untuk lihat info", "Gameplay kuih · Tap to view info"), Rect2(.11,.253,.78,.04), 25, Palette.WOOD_DARK)
	_grid = GridContainer.new()
	_grid.columns = 2
	_grid.add_theme_constant_override("h_separation", 76)
	_grid.add_theme_constant_override("v_separation", 42)
	JourneyArt.place(self, _grid, Rect2(.11, .255, .78, .48))
	_collection_scroll = ScrollContainer.new()
	_collection_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	JourneyArt.place(self, _collection_scroll, Rect2(.11, .255, .78, .49))
	_filter_button = GameButton.create(RecipeText.text("collections"), "primary", 26)
	_filter_button.custom_minimum_size = Vector2.ZERO
	JourneyArt.place(self, _filter_button, Rect2(.20, .735, .60, .035))
	_filter_button.pressed.connect(func() -> void:
		var filters: Array[StringName] = [&""]
		for entry in RecipeCatalog.collections():
			filters.append(entry.id)
		_filter = filters[(filters.find(_filter) + 1) % filters.size()]
		_page = 0
		refresh()
	)
	_previous = GameButton.create(RecipeText.text("previous"), "back", 32)
	_next = GameButton.create(RecipeText.text("next"), "primary", 32)
	for button in [_previous, _next]:
		button.custom_minimum_size = Vector2.ZERO
	JourneyArt.place(self, _previous, Rect2(.11, .775, .29, .058))
	JourneyArt.place(self, _next, Rect2(.60, .775, .29, .058))
	_previous.pressed.connect(func() -> void: _turn_page(-1))
	_next.pressed.connect(func() -> void: _turn_page(1))
	_page_label = JourneyArt.label(self, "", Rect2(.41, .782, .18, .04), 34, Palette.WOOD_DARK)
	_count_label = JourneyArt.label(self, "", Rect2(.23, .865, .54, .04), 30, Palette.WOOD_DARK)
	_claim_status = JourneyArt.label(self, "", Rect2(.10, .91, .80, .04), 26, Palette.WOOD_DARK)
	refresh()

func _select_mode(mode: String) -> void:
	if mode == "recipes":
		mode = "guide" # Keep unfinished recipe pages hidden for MVP.
	_mode = mode
	_page = 0
	_claim_status.text = ""
	refresh()

func _filtered_recipes() -> Array[RecipeDefinition]:
	var entries: Array[RecipeDefinition] = []
	for recipe in RecipeCatalog.all():
		if _filter == &"" or String(_filter) in recipe.collection_tags:
			entries.append(recipe)
	return entries

func _turn_page(direction: int) -> void:
	var total := KuihLibrary.count() + PowerupRecipes.ENTRIES.size() if _mode == "guide" else _filtered_recipes().size()
	_page = clampi(_page + direction, 0, maxi(0, ceili(float(total) / (GUIDE_PER_SPREAD if _mode == "guide" else PER_SPREAD)) - 1))
	AudioManager.play(AudioManager.Sfx.TAP)
	refresh()

func refresh() -> void:
	if _grid == null:
		return
	for mode in _tabs:
		var tab: Button = _tabs[mode]
		tab.modulate = Color(1.12,1.12,.8) if mode == _mode else Color(.85,.85,.85)
	_guide_hint.visible = _mode in ["guide","collections"]
	_guide_hint.text = JourneyArt.localized("Tugasan resipi · Buka resipi melalui stage","Recipe tasks · Discover recipes by completing stages") if _mode == "collections" else JourneyArt.localized("Kuih dalam permainan · Tap untuk lihat info","Gameplay kuih · Tap to view info")
	_collection_scroll.anchor_top = .30
	_collection_scroll.anchor_bottom = .79
	_grid.add_theme_constant_override("h_separation",18 if _mode == "guide" else 76)
	_grid.add_theme_constant_override("v_separation",18 if _mode == "guide" else 42)
	_grid.anchor_top = .30 if _mode == "guide" else .255
	for child in _grid.get_children():
		_grid.remove_child(child)
		child.queue_free()
	_grid.visible = _mode != "collections"
	_collection_scroll.visible = _mode == "collections"
	_filter_button.visible = _mode == "recipes"
	_previous.visible = _mode != "collections"
	_next.visible = _mode != "collections"
	_page_label.visible = _mode != "collections"
	if _mode == "collections":
		_refresh_collections()
		return
	if _mode == "recipes":
		_refresh_recipes()
		return
	var all_kuih := KuihLibrary.all()
	var unlocked := 0
	for kuih in all_kuih:
		if ProgressionManager.is_recipe_unlocked(kuih.recipe_id):
			unlocked += 1
	for entry in PowerupRecipes.ENTRIES:
		if ProgressionManager.is_recipe_unlocked(PowerupRecipes.key(int(entry[0]))):
			unlocked += 1
	var total := all_kuih.size() + PowerupRecipes.ENTRIES.size()
	_page = clampi(_page, 0, maxi(0, ceili(float(total) / (GUIDE_PER_SPREAD if _mode == "guide" else PER_SPREAD)) - 1))
	var first := _page * GUIDE_PER_SPREAD
	for i in range(first, mini(first + GUIDE_PER_SPREAD, total)):
		if i < all_kuih.size():
			var kuih: KuihData = all_kuih[i]
			_grid.add_child(_make_card(kuih, ProgressionManager.is_recipe_unlocked(kuih.recipe_id)))
		else:
			_grid.add_child(_make_powerup_card(PowerupRecipes.ENTRIES[i - all_kuih.size()]))
	var spreads := ceili(float(total) / (GUIDE_PER_SPREAD if _mode == "guide" else PER_SPREAD))
	_page_label.text = "%d / %d" % [_page + 1, spreads]
	_count_label.text = "Discovered %d / %d" % [unlocked, total]
	_previous.disabled = _page == 0
	_next.disabled = _page == spreads - 1

func _refresh_recipes() -> void:
	var entries := _filtered_recipes()
	var spreads := maxi(1, ceili(float(entries.size()) / PER_SPREAD))
	_page = clampi(_page, 0, spreads - 1)
	for index in range(_page * PER_SPREAD, mini((_page + 1) * PER_SPREAD, entries.size())):
		var recipe := entries[index]
		var unlocked := RecipeBookManager.is_recipe_discovered(recipe.id)
		var card := UIKit.vbox(8)
		card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		card.size_flags_vertical = Control.SIZE_EXPAND_FILL
		card.add_child(RecipePresentation.artwork_control(recipe, unlocked, 170))
		card.add_child(UIKit.wrap_label("#%03d" % recipe.collection_number, 26, Palette.WOOD_DARK, HORIZONTAL_ALIGNMENT_CENTER))
		var title := GameButton.create(recipe.text("name") if unlocked else RecipeText.text("locked"), "primary", 28)
		title.custom_minimum_size = Vector2(0, 88)
		title.clip_text = true
		title.disabled = not unlocked
		card.add_child(title)
		title.pressed.connect(RecipePresentation.show_detail.bind(self, recipe))
		var caption := RecipeText.text("card_stage" if recipe.discovery_stage <= LevelLibrary.count() else "future") % recipe.discovery_stage
		card.add_child(UIKit.wrap_label(caption, 26, Palette.WOOD_DARK, HORIZONTAL_ALIGNMENT_CENTER))
		_grid.add_child(card)
	_page_label.text = "%d / %d" % [_page + 1, spreads]
	_count_label.text = RecipeText.text("progress") % [RecipeBookManager.get_discovered_count(), RecipeBookManager.get_total_recipe_count()]
	_filter_button.text = RecipeCatalog.collection(_filter).display_name() if _filter != &"" else RecipeText.text("all")
	_previous.disabled = _page == 0
	_next.disabled = _page == spreads - 1

func _refresh_collections() -> void:
	for child in _collection_scroll.get_children():
		_collection_scroll.remove_child(child)
		child.queue_free()
	var list := UIKit.vbox(18)
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_collection_scroll.add_child(list)
	for entry in RecipeCatalog.collections():
		var progress := RecipeBookManager.get_collection_progress(entry.id)
		list.add_child(_task_card(entry.display_name().replace(" (sample)",""),progress.discovered,progress.total,progress.claimed,RecipeCatalog.reward(entry.completion_reward_id),func() -> void: _show_claim(RecipeBookManager.claim_collection_reward(entry.id))))
	for milestone in RecipeCatalog.milestones:
		if int(milestone.threshold) > RecipeBookManager.get_total_recipe_count():
			continue
		var claimed: bool = str(milestone.id) in SaveManager.data["claimed_recipe_milestone_rewards"]
		list.add_child(_task_card(RecipeText.text("milestone") % int(milestone.threshold),RecipeBookManager.get_discovered_count(),int(milestone.threshold),claimed,RecipeCatalog.reward(str(milestone.reward_id)),func() -> void: _show_claim(RecipeBookManager.claim_milestone_reward(str(milestone.id)))))
	_count_label.text = JourneyArt.localized("%d / %d resipi ditemui","%d / %d recipes discovered") % [RecipeBookManager.get_discovered_count(), RecipeBookManager.get_total_recipe_count()]

func _task_card(title: String, current: int, goal: int, claimed: bool, reward: Dictionary, claim_action: Callable) -> Control:
	var card := PanelContainer.new()
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.add_theme_stylebox_override("panel",UIKit.flat_box(Color("fff7e5"),Palette.WOOD_LIGHT,0,2,20))
	var margin := UIKit.margin(18)
	card.add_child(margin)
	var column := UIKit.vbox(10)
	margin.add_child(column)
	var header := UIKit.hbox(12)
	column.add_child(header)
	var complete := current >= goal and goal > 0
	header.add_child(UIKit.label("✓" if complete else "○",34,Color("518f32") if complete else Palette.WOOD_DARK))
	var heading := UIKit.wrap_label(title,29,Palette.WOOD_DARK,HORIZONTAL_ALIGNMENT_LEFT)
	heading.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(heading)
	var progress := ProgressBar.new()
	progress.max_value = maxi(1,goal)
	progress.value = mini(current,goal)
	progress.show_percentage = false
	progress.custom_minimum_size.y = 18
	progress.add_theme_stylebox_override("background",UIKit.flat_box(Color("e9ddc3"),Color.TRANSPARENT,0,0,9))
	progress.add_theme_stylebox_override("fill",UIKit.flat_box(Color("71b548"),Color.TRANSPARENT,0,0,9))
	column.add_child(progress)
	column.add_child(UIKit.label("%d / %d" % [mini(current,goal),goal],24,Palette.WOOD_DARK,HORIZONTAL_ALIGNMENT_LEFT))
	var footer := UIKit.hbox(12)
	column.add_child(footer)
	var prizes := PackedStringArray()
	if int(reward.get("coins",0)) > 0:
		prizes.append("● %d coins" % int(reward.coins))
	if int(reward.get("renovation_stars",0)) > 0:
		prizes.append("★ %d" % int(reward.renovation_stars))
	for id in reward.get("boosters",{}):
		var label := str(id)
		for kind in EconomyManager.BOOSTER_IDS:
			if EconomyManager.BOOSTER_IDS[kind] == id:
				label = EconomyManager.BOOSTER_NAMES[kind]
		prizes.append("%s ×%d" % [label,int(reward.boosters[id])])
	var summary := UIKit.wrap_label(" · ".join(prizes),25,Palette.WOOD_DARK,HORIZONTAL_ALIGNMENT_LEFT)
	summary.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	footer.add_child(summary)
	if complete and not claimed:
		var claim := GameButton.create(JourneyArt.localized("Tuntut","Claim"),"primary",26)
		claim.custom_minimum_size = Vector2(150,64)
		footer.add_child(claim)
		claim.pressed.connect(claim_action)
	else:
		footer.add_child(UIKit.label(JourneyArt.localized("Dituntut","Claimed") if claimed else JourneyArt.localized("Dalam progress","In progress"),23,Palette.WOOD_DARK))
	return card
func _show_claim(outcome: Dictionary) -> void:
	_claim_status.text = RecipeText.text("reward") % RecipeText.reward_summary(outcome.reward) if outcome.get("ok", false) else RecipeText.text("save_failed")
	refresh()

func _make_card(kuih: KuihData, unlocked: bool) -> Control:
	var column := UIKit.vbox(12)
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var icon := KuihIcon.new()
	icon.kuih = kuih
	icon.custom_minimum_size = Vector2(170,170)
	icon.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	icon.modulate = Color.WHITE
	column.add_child(icon)
	column.add_child(UIKit.wrap_label(KuihLibrary.get_display_name(kuih.id) if unlocked else JourneyArt.localized("Belum ditemui","Undiscovered"),32,Palette.WOOD_DARK))
	_bind_info_icon(icon,unlocked,_show_kuih_info.bind(kuih))
	return column

func _bind_info_icon(icon: Control, unlocked: bool, action: Callable) -> void:
	if not icon.is_node_ready():
		icon.ready.connect(func() -> void: icon.mouse_filter = Control.MOUSE_FILTER_STOP,CONNECT_ONE_SHOT)
	icon.mouse_filter = Control.MOUSE_FILTER_STOP
	icon.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND if unlocked else Control.CURSOR_ARROW
	icon.focus_mode = Control.FOCUS_ALL if unlocked else Control.FOCUS_NONE
	icon.gui_input.connect(func(event: InputEvent) -> void:
		if not unlocked:
			return
		if (event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed) or (event is InputEventScreenTouch and event.pressed) or event.is_action_pressed("ui_accept"):
			icon.accept_event()
			action.call()
	)
func _show_kuih_info(kuih: KuihData) -> void:
	if has_node("KuihInfoPopup"):
		return
	AudioManager.play(AudioManager.Sfx.TAP)
	var popup := KuihInfoPopup.new()
	popup.kuih = kuih
	add_child(popup)
func _make_powerup_card(entry: Array) -> Control:
	var unlocked := ProgressionManager.is_recipe_unlocked(PowerupRecipes.key(int(entry[0])))
	var column := UIKit.vbox(12)
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var icon := TextureRect.new()
	icon.texture = BoardArt.special_texture(int(entry[0]))
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.custom_minimum_size = Vector2(170,170)
	icon.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	icon.modulate = Color.WHITE if unlocked else Color(.55,.50,.40,.65)
	column.add_child(icon)
	column.add_child(UIKit.wrap_label(str(entry[1]) if unlocked else JourneyArt.localized("Belum ditemui","Undiscovered"),32,Palette.WOOD_DARK))
	_bind_info_icon(icon,unlocked,_show_special_info.bind(entry))
	return column
func _show_special_info(entry: Array) -> void:
	if has_node("KuihInfoPopup"):
		return
	var popup := KuihInfoPopup.new()
	popup.kuih = KuihLibrary.get_kuih(&"onde_onde")
	popup.special_kind = int(entry[0])
	popup.special_name = str(entry[1])
	popup.special_note = str(entry[2])
	add_child(popup)
