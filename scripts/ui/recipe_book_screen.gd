class_name RecipeBookScreen
extends Control

## Recipe Book: a collection and discovery screen, never a stat screen
## (Master Plan section 24).

var _grid: GridContainer
var _count_label: Label


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

	var margin := UIKit.margin(30)
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(margin)

	var column := UIKit.vbox(14)
	margin.add_child(column)

	var top := UIKit.hbox(16)
	column.add_child(top)
	var back := UIKit.button("Back", 28, Palette.WOOD_LIGHT)
	back.custom_minimum_size = Vector2(190, 84)
	back.pressed.connect(func() -> void:
		AudioManager.play(AudioManager.Sfx.TAP)
		GameManager.go_home()
	)
	top.add_child(back)
	_count_label = UIKit.title("Recipe Book", 56)
	_count_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_count_label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	top.add_child(_count_label)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	column.add_child(scroll)

	_grid = GridContainer.new()
	_grid.columns = 2
	_grid.add_theme_constant_override("h_separation", 18)
	_grid.add_theme_constant_override("v_separation", 18)
	_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(_grid)

	refresh()


func refresh() -> void:
	if _grid == null:
		return
	for child in _grid.get_children():
		child.queue_free()
	var unlocked := 0
	for kuih in KuihLibrary.all():
		var is_unlocked := ProgressionManager.is_recipe_unlocked(kuih.recipe_id)
		if is_unlocked:
			unlocked += 1
		_grid.add_child(_make_card(kuih, is_unlocked))
	_count_label.text = "Recipe Book   %d / %d" % [unlocked, KuihLibrary.count()]


func _make_card(kuih: KuihData, unlocked: bool) -> Control:
	var data: KuihData = kuih
	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(470, 0)
	card.add_theme_stylebox_override(
		"panel",
		UIKit.cream_box() if unlocked else UIKit.flat_box(Color(0.88, 0.85, 0.80, 0.55), Color(0.7, 0.66, 0.6, 0.6), 0, 3, 18)
	)

	var row := UIKit.hbox(14)
	card.add_child(row)

	var icon_holder := Control.new()
	icon_holder.custom_minimum_size = Vector2(150, 150)
	row.add_child(icon_holder)

	var icon := KuihIcon.new()
	icon.kuih = data
	icon.cell_ratio = 0.94
	icon.show_outline = unlocked
	icon.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	icon.modulate = Color.WHITE if unlocked else Color(0.35, 0.33, 0.30, 0.5)
	icon_holder.add_child(icon)

	var col := UIKit.vbox(4)
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(col)

	if unlocked:
		col.add_child(UIKit.label(kuih.display_name, 30, Palette.WOOD_DARK, HORIZONTAL_ALIGNMENT_LEFT))
		var mastery := StarDisplay.new()
		mastery.total = 5
		mastery.star_size = 26.0
		mastery.filled = ProgressionManager.mastery_stars(kuih.recipe_id)
		mastery.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
		col.add_child(mastery)
		var note := UIKit.wrap_label(kuih.note, 22, Palette.INK_SOFT, HORIZONTAL_ALIGNMENT_LEFT)
		note.custom_minimum_size = Vector2(0, 96)
		col.add_child(note)
	else:
		col.add_child(UIKit.label("???", 30, Palette.INK_SOFT, HORIZONTAL_ALIGNMENT_LEFT))
		var hint := UIKit.wrap_label(
			"Keep serving to discover this kuih. Found in Chapter %d." % kuih.chapter,
			22, Palette.INK_SOFT, HORIZONTAL_ALIGNMENT_LEFT
		)
		hint.custom_minimum_size = Vector2(0, 96)
		col.add_child(hint)
	return card
