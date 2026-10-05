class_name StagePreview
extends Control

var stage: int
var picks: Array[int] = []

func show_stage(id: int) -> void:
	stage = id
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	z_index = 100
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, .65)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(dim)
	var card := PanelContainer.new()
	card.add_theme_stylebox_override("panel", UIKit.cream_box())
	JourneyArt.place(self, card, Rect2(.08, .20, .84, .53))
	var stack := UIKit.vbox(16)
	card.add_child(stack)
	var level := LevelLibrary.get_level(id)
	stack.add_child(UIKit.title("%s %d" % [MenuText.text("stage"), id], 42))
	stack.add_child(UIKit.wrap_label(level.title, 30))
	var location := LocationDefinition.for_stage(id)
	stack.add_child(UIKit.wrap_label("%s · %s" % [location.display_name, location.state_name(LocationManager.structural_level(location.id))], 26))
	stack.add_child(UIKit.label("%s · %d %s" % [JourneyLibrary.name_for(id), level.moves, JourneyArt.localized("langkah", "moves")], 25))
	var orders := GridContainer.new()
	orders.columns = 3
	orders.add_theme_constant_override("separation", 18)
	stack.add_child(orders)
	var totals: Dictionary = {}
	for order in level.customer_orders:
		for item in order.items:
			totals[item.kuih.id] = int(totals.get(item.kuih.id, 0)) + item.count
	for food in totals:
		var column := UIKit.vbox(4)
		column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		orders.add_child(column)
		var icon := KuihIcon.new()
		icon.kuih = KuihLibrary.get_kuih(food)
		icon.custom_minimum_size = Vector2(80, 80)
		column.add_child(icon)
		column.add_child(UIKit.wrap_label("%s × %d" % [KuihLibrary.get_display_name(food), totals[food]], 23))
	if not level.blockers.is_empty():
		stack.add_child(UIKit.wrap_label(JourneyArt.localized("Halangan: ", "Obstacles: ") + str(level.blockers.size()) + (JourneyArt.localized(" · Bersihkan semua", " · Clear all") if level.require_blockers_cleared else ""), 24))
	stack.add_child(UIKit.wrap_label(JourneyArt.localized("Special permulaan (pilihan)", "Starting specials (optional)"), 27))
	for booster in [EconomyManager.Booster.TRAY, EconomyManager.Booster.GIFT]:
		var toggle := UIKit.button("%s · %d" % ["Dulang" if booster == EconomyManager.Booster.TRAY else "Tapau", EconomyManager.booster_count(booster)], 28, Palette.CREAM_DEEP)
		toggle.toggle_mode = true
		toggle.disabled = EconomyManager.booster_count(booster) <= 0
		toggle.add_theme_color_override("font_color", Palette.WOOD_DARK)
		stack.add_child(toggle)
		var special := KuihIcon.new()
		special.kuih = KuihLibrary.get_kuih(&"onde_onde")
		special.special_kind = BoardCell.Special.DULANG if booster == EconomyManager.Booster.TRAY else BoardCell.Special.TAPAU
		special.custom_minimum_size = Vector2.ZERO
		JourneyArt.place(toggle, special, Rect2(.05, .08, .17, .84))
		toggle.toggled.connect(func(on: bool) -> void:
			if on:
				picks.append(booster)
			else:
				picks.erase(booster)
		)
	stack.add_child(UIKit.wrap_label("Score targets: 2 stars %d / 3 stars %d" % [level.score_two_star, level.score_three_star], 25))
	var source: Texture2D = load("res://assets/ui/results_v1/button_green.png")
	var art := AtlasTexture.new()
	art.atlas = source
	art.region = source.get_image().get_used_rect()
	var start := JourneyArt.painted_button(art, JourneyArt.localized("MULA", "START"), 38)
	start.custom_minimum_size = Vector2(0, 100)
	stack.add_child(start)
	start.pressed.connect(func() -> void:
		GameManager.pending_level_id = stage
		GameManager.pending_start_specials.assign(picks)
		GameManager.start_selected_stage()
	)
	var cancel := GameButton.create(MenuText.text("close"), "back")
	stack.add_child(cancel)
	cancel.pressed.connect(queue_free)
