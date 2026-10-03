class_name GeraiScreen
extends Control

## My Gerai: visual meta progression with a simple coin upgrade
## (Master Plan sections 26 and 27).

var _stage_label: Label
var _cost_label: Label
var _upgrade_button: Button
var _preview: Control


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	UIKit.apply_root_theme(self)
	_build()
	_refresh()


func _build() -> void:
	var backdrop := GeraiBackdrop.new()
	backdrop.background_id = &"stall_dawn"
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(backdrop)

	var margin := UIKit.margin(30)
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(margin)

	var column := UIKit.vbox(16)
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
	var title := UIKit.title("My Gerai", 56)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	top.add_child(title)

	var preview_card := PanelContainer.new()
	preview_card.add_theme_stylebox_override("panel", UIKit.cream_box())
	preview_card.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(preview_card)
	_preview = Control.new()
	_preview.custom_minimum_size = Vector2(0, 620)
	preview_card.add_child(_preview)
	_preview.draw.connect(_draw_gerai)
	_preview.resized.connect(_preview.queue_redraw)

	var info_card := PanelContainer.new()
	info_card.add_theme_stylebox_override("panel", UIKit.cream_box())
	column.add_child(info_card)
	var info := UIKit.vbox(10)
	info_card.add_child(info)
	_stage_label = UIKit.label("", 34, Palette.WOOD_DARK)
	info.add_child(_stage_label)
	_cost_label = UIKit.label("", 26, Palette.INK_SOFT)
	info.add_child(_cost_label)
	_upgrade_button = UIKit.primary_button("Upgrade")
	_upgrade_button.pressed.connect(_on_upgrade)
	info.add_child(_upgrade_button)


func _refresh() -> void:
	var level := ProgressionManager.gerai_level()
	_stage_label.text = "Stage %d  ·  %s" % [level, ProgressionManager.gerai_stage_name(level)]
	var maxed := level >= 7
	var cost := ProgressionManager.gerai_upgrade_cost(level)
	if maxed:
		_cost_label.text = "Your gerai is the biggest in Kuching. Well done!"
		_upgrade_button.visible = false
	else:
		_cost_label.text = "Next: %s  ·  %d coins" % [
			ProgressionManager.gerai_stage_name(level + 1), cost
		]
		_upgrade_button.visible = true
		_upgrade_button.disabled = not EconomyManager.can_afford(cost)
	if _preview != null:
		_preview.queue_redraw()


func _on_upgrade() -> void:
	var level := ProgressionManager.gerai_level()
	if level >= 7:
		return
	if not ProgressionManager.upgrade_gerai(ProgressionManager.gerai_upgrade_cost(level)):
		AudioManager.play(AudioManager.Sfx.INVALID)
		return
	AudioManager.play(AudioManager.Sfx.REWARD)
	UIKit.sparkle_burst(_root_safe(), Vector2(size.x * 0.5, size.y * 0.5), Palette.GOLD_PALE, 18)
	_refresh()


func _root_safe() -> Control:
	return self


func _draw_gerai() -> void:
	var level := ProgressionManager.gerai_level()
	var tier := float(mini(level, 7))
	# Draw inside a fixed art box so the stall never stretches with the panel.
	var box := Rect2(Vector2.ZERO, Vector2(980, 700))
	box.position = ((_preview.size - box.size) * 0.5).round()
	box.position.y = maxf(box.position.y, 10.0)

	var canopy_w := box.size.x * (0.46 + 0.05 * (tier - 1.0))
	var counter_w := box.size.x * (0.50 + 0.04 * (tier - 1.0))
	var cx := box.get_center().x
	var canopy_top := box.position.y + box.size.y * 0.16
	var canopy_h := box.size.y * 0.14
	var counter_top := box.position.y + box.size.y * 0.60
	var counter_h := box.size.y * 0.30

	# shadow on the ground
	_preview.draw_rect(
		Rect2(cx - counter_w * 0.62, counter_top + counter_h - 14.0, counter_w * 1.24, 28.0),
		Palette.SHADOW
	)

	# posts
	_preview.draw_rect(Rect2(cx - canopy_w * 0.5 - 14.0, canopy_top + canopy_h, 28.0, counter_top - canopy_top - canopy_h + 10.0), Palette.WOOD)
	_preview.draw_rect(Rect2(cx + canopy_w * 0.5 - 14.0, canopy_top + canopy_h, 28.0, counter_top - canopy_top - canopy_h + 10.0), Palette.WOOD)

	# canopy
	var stripes := 8
	var stripe_w := canopy_w / float(stripes)
	for i in stripes:
		var c := Palette.PINK if i % 2 == 0 else Palette.CREAM
		_preview.draw_rect(Rect2(cx - canopy_w * 0.5 + stripe_w * float(i), canopy_top, stripe_w, canopy_h), c)
	_preview.draw_rect(Rect2(cx - canopy_w * 0.5, canopy_top, canopy_w, canopy_h * 0.16), Palette.PINK_DARK)
	for i in stripes:
		_preview.draw_circle(
			Vector2(cx - canopy_w * 0.5 + stripe_w * (float(i) + 0.5), canopy_top + canopy_h),
			stripe_w * 0.5,
			Palette.PINK if i % 2 == 0 else Palette.CREAM
		)

	# signage
	var sign_w := canopy_w * 0.72
	var sign_h := box.size.y * 0.12
	var sign_rect := Rect2(cx - sign_w * 0.5, canopy_top - sign_h - 14.0, sign_w, sign_h)
	_preview.draw_rect(sign_rect, Palette.WOOD_DARK)
	_preview.draw_rect(sign_rect.grow(-6.0), Palette.WOOD)
	var sign_text := "KUIH EMPIRE"
	var sign_size := UIKit.fit_font_size(sign_text, sign_w - 40.0, int(sign_h * 0.56))
	_preview.draw_string(
		UIKit.bold_font(),
		Vector2(sign_rect.position.x + 20.0, sign_rect.position.y + sign_h * 0.5 + sign_size * 0.36),
		sign_text,
		HORIZONTAL_ALIGNMENT_LEFT,
		sign_w - 40.0,
		sign_size,
		Palette.PAPER
	)

	# counter
	_preview.draw_rect(Rect2(cx - counter_w * 0.5, counter_top, counter_w, counter_h), Palette.WOOD_LIGHT)
	_preview.draw_rect(Rect2(cx - counter_w * 0.5, counter_top, counter_w, counter_h * 0.12), Palette.WOOD_PALE)
	_preview.draw_rect(Rect2(cx - counter_w * 0.5, counter_top + counter_h * 0.72, counter_w, counter_h * 0.28), Palette.WOOD)

	# kuih on display grows with the gerai
	var slots := mini(level + 1, 5)
	var radius := 22.0 + 4.0 * tier
	for i in slots:
		var t := float(i) / float(maxi(1, slots - 1))
		var x := cx - counter_w * 0.36 + counter_w * 0.72 * t
		var y := counter_top + radius * 0.55
		_preview.draw_circle(Vector2(x, y), radius * 1.14, Color("4a2c17"))
		_preview.draw_circle(Vector2(x, y), radius, Palette.PINK if i % 2 == 0 else Palette.LEAF_LIGHT)

	# extra decorations appear as the stall levels up
	if level >= 3:
		var sides: Array[float] = [-1.0, 1.0]
		for side in sides:
			var px: float = cx + side * canopy_w * 0.60
			var py := counter_top + counter_h * 0.30
			_preview.draw_circle(Vector2(px, py), 34.0, Palette.WOOD_DARK)
			_preview.draw_circle(Vector2(px, py), 30.0, Palette.WOOD_PALE)
			for f in 4:
				var a := -PI * 0.5 + (float(f) - 1.5) * 0.42
				_preview.draw_line(
					Vector2(px, py),
					Vector2(px, py) + Vector2(cos(a), sin(a)) * 76.0,
					Palette.LEAF, 9.0
				)
	if level >= 4:
		for i in 3:
			var lx := cx + (float(i) - 1.0) * 210.0
			_preview.draw_line(Vector2(lx, canopy_top + canopy_h), Vector2(lx, canopy_top + canopy_h + 42.0), Palette.WOOD_DARK, 5.0)
			_preview.draw_circle(Vector2(lx, canopy_top + canopy_h + 62.0), 22.0, Palette.PINK_LIGHT)
			_preview.draw_circle(Vector2(lx, canopy_top + canopy_h + 62.0), 11.0, Palette.GOLD_PALE)
