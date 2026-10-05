class_name RecipeBookScreen
extends Control

const PER_SPREAD := 4
var _grid: GridContainer
var _page := 0
var _page_label: Label
var _count_label: Label
var _previous: Button
var _next: Button

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	UIKit.apply_root_theme(self)
	_build()

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
	JourneyArt.label(self, "Recipe Book", Rect2(.25, .14, .50, .05), 52, Palette.WOOD_DARK)
	_grid = GridContainer.new()
	_grid.columns = 2
	_grid.add_theme_constant_override("h_separation", 76)
	_grid.add_theme_constant_override("v_separation", 42)
	JourneyArt.place(self, _grid, Rect2(.11, .255, .78, .48))
	_previous = GameButton.create("Previous", "back", 32)
	_next = GameButton.create("Next", "primary", 32)
	for button in [_previous, _next]:
		button.custom_minimum_size = Vector2.ZERO
	JourneyArt.place(self, _previous, Rect2(.11, .775, .29, .058))
	JourneyArt.place(self, _next, Rect2(.60, .775, .29, .058))
	_previous.pressed.connect(func() -> void: _turn_page(-1))
	_next.pressed.connect(func() -> void: _turn_page(1))
	_page_label = JourneyArt.label(self, "", Rect2(.41, .782, .18, .04), 34, Palette.WOOD_DARK)
	_count_label = JourneyArt.label(self, "", Rect2(.23, .865, .54, .04), 30, Palette.WOOD_DARK)
	refresh()

func _turn_page(direction: int) -> void:
	_page = clampi(_page + direction, 0, ceili(float(KuihLibrary.count()) / PER_SPREAD) - 1)
	AudioManager.play(AudioManager.Sfx.TAP)
	refresh()

func refresh() -> void:
	if _grid == null:
		return
	for child in _grid.get_children():
		_grid.remove_child(child)
		child.queue_free()
	var all_kuih := KuihLibrary.all()
	var unlocked := 0
	for kuih in all_kuih:
		if ProgressionManager.is_recipe_unlocked(kuih.recipe_id):
			unlocked += 1
	var first := _page * PER_SPREAD
	for i in range(first, mini(first + PER_SPREAD, all_kuih.size())):
		var kuih: KuihData = all_kuih[i]
		_grid.add_child(_make_card(kuih, ProgressionManager.is_recipe_unlocked(kuih.recipe_id)))
	var spreads := ceili(float(all_kuih.size()) / PER_SPREAD)
	_page_label.text = "%d / %d" % [_page + 1, spreads]
	_count_label.text = "Discovered %d / %d" % [unlocked, all_kuih.size()]
	_previous.disabled = _page == 0
	_next.disabled = _page == spreads - 1

func _make_card(kuih: KuihData, unlocked: bool) -> Control:
	var card := UIKit.vbox(10)
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var icon_holder := Control.new()
	icon_holder.custom_minimum_size = Vector2(170, 170)
	icon_holder.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	card.add_child(icon_holder)
	var icon := KuihIcon.new()
	icon.kuih = kuih
	icon.cell_ratio = .94
	icon.show_outline = unlocked
	icon.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	icon.modulate = Color.WHITE if unlocked else Color(.55, .50, .40, .65)
	icon_holder.add_child(icon)
	var title := UIKit.wrap_label(kuih.display_name if unlocked else "Undiscovered", 36, Palette.WOOD_DARK, HORIZONTAL_ALIGNMENT_CENTER)
	card.add_child(title)
	if unlocked:
		var mastery := StarDisplay.new()
		mastery.total = 5
		mastery.star_size = 30
		mastery.filled = ProgressionManager.mastery_stars(kuih.recipe_id)
		mastery.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		card.add_child(mastery)
	var caption := kuih.note if unlocked else "Keep serving to discover this kuih.\nChapter %d" % kuih.chapter
	var note := UIKit.wrap_label(caption, 30, Palette.WOOD_DARK, HORIZONTAL_ALIGNMENT_CENTER)
	card.add_child(note)
	return card
