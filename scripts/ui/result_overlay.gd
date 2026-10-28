class_name ResultOverlay
extends Control

signal continue_pressed()
signal retry_pressed()
signal home_pressed()
signal watch_ad_for_moves()
signal booster_pressed()

const OFFER_COST := EconomyManager.EXTRA_MOVES_COST
# Keep results in the central reach area and leave room above Aina for notifications.
const RESULT_CARD_RECT := Rect2(.07, .34, .86, .51)
const SUCCESS_CHARACTER_RECT := Rect2(.05, .10, .90, .33)
const FAILED_CHARACTER_RECT := Rect2(.045, .105, .91, .32)
var stage_number := 1
var tutorial_stage := false
var tutorial_final := false
var is_win := false
var _title: Label
var _title_art: TextureRect
var _subtitle: Label
var _stage_label: Label
var _coins_label: Label
var _card: Control
var _character: TextureRect
var _stars: ResultStars
var _primary: Button
var _secondary: Button
var _home: Button
var _unlocks: Label
var _celebration: GameVfx
var _score_value: Label
var _new_best: Label
var _breakdown: Label
var _reward_box: Panel
var _score_heading: Control
var _coin_caption: Label
var _score_caption: Label
var _score_badge: TextureRect
var _offer_available := false
static var _art: Dictionary = {}
const BOUNDS := {
	"panel": Rect2(3, 6, 1233, 1215),
	"aina_success": Rect2(138, 53, 739, 1011),
	"aina_failed": Rect2(232, 76, 617, 981),
	"button_green": Rect2(25, 154, 2122, 411),
	"button_pink": Rect2(34, 183, 2105, 340),
}

class ResultStars extends Control:
	var filled := 0:
		set(value):
			filled = clampi(value, 0, 3)
			_update_stars()
	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		for i in 3:
			var icon := TextureRect.new()
			icon.texture = GameplaySkin.texture("star")
			icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
			add_child(icon)
		resized.connect(_update_stars)
		_update_stars()
	func _update_stars() -> void:
		var edge := minf(size.y, size.x / 3.2)
		var width := edge * 3.2
		for i in get_child_count():
			var icon: TextureRect = get_child(i)
			icon.position = Vector2((size.x - width) * .5 + i * edge * 1.1, (size.y - edge) * .5)
			icon.size = Vector2.ONE * edge
			icon.modulate = Color.WHITE if i < filled else Color(.75, .70, .65)
			if i < filled:
				icon.material = null
			else:
				var grey := ShaderMaterial.new()
				grey.shader = load("res://scripts/art/shaders/locked_booster.gdshader")
				icon.material = grey

static func artwork(id: String) -> Texture2D:
	if not _art.has(id):
		var source: Texture2D = load("res://assets/ui/results_v1/%s.png" % id)
		var atlas := AtlasTexture.new()
		atlas.atlas = source
		atlas.region = BOUNDS[id]
		_art[id] = atlas
	return _art[id]

static func success_portrait_artwork() -> Texture2D:
	if not _art.has("aina_success_heart"):
		var source: Texture2D = load("res://assets/ui/results_v3/aina_success_heart.png")
		var portrait := AtlasTexture.new()
		portrait.atlas = source
		# Native crop removes transparent margins; preserve the generated alpha.
		portrait.region = Rect2(source.get_image().get_used_rect())
		_art["aina_success_heart"] = portrait
	return _art["aina_success_heart"]

static func portrait_artwork(id: String) -> Texture2D:
	var key := id + "_bust"
	if not _art.has(key):
		var full := artwork(id) as AtlasTexture
		var bust := AtlasTexture.new()
		bust.atlas = full.atlas
		bust.region = Rect2(full.region.position, Vector2(full.region.size.x, full.region.size.y * .61))
		_art[key] = bust
	return _art[key]

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	# Cover raised board blockers and VFX as one complete modal layer.
	z_index = 200
	mouse_filter = Control.MOUSE_FILTER_STOP
	UIKit.apply_root_theme(self)
	_build()
	visibility_changed.connect(func() -> void: AudioManager.set_music_ducked(visible))

func _place(node: Control, rect: Rect2, parent: Control = self) -> void:
	parent.add_child(node)
	node.anchor_left = rect.position.x
	node.anchor_top = rect.position.y
	node.anchor_right = rect.end.x
	node.anchor_bottom = rect.end.y
	node.offset_left = 0
	node.offset_top = 0
	node.offset_right = 0
	node.offset_bottom = 0

func _set_character_rect(rect: Rect2) -> void:
	_character.anchor_left = rect.position.x
	_character.anchor_top = rect.position.y
	_character.anchor_right = rect.end.x
	_character.anchor_bottom = rect.end.y

func _label(text: String, rect: Rect2, font_size: int, parent: Control) -> Label:
	var label := UIKit.label(text, font_size, Palette.WOOD_DARK)
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_place(label, rect, parent)
	return label

func _button(id: String, rect: Rect2) -> Button:
	var button := UIKit.button("", 42)
	button.custom_minimum_size = Vector2.ZERO
	ButtonArt.apply(button, artwork(id))
	button.add_theme_stylebox_override("focus", UIKit.flat_box(Color.TRANSPARENT, Palette.GOLD, 0, 4, 24))
	button.add_theme_color_override("font_color", Palette.PAPER)
	button.add_theme_color_override("font_outline_color", Palette.LEAF_DEEP if id == "button_green" else Palette.PINK_DARK)
	button.add_theme_constant_override("outline_size", 3)
	_place(button, rect, _card)
	return button

func _build() -> void:
	var dim := ColorRect.new()
	dim.color = Color(.12, .07, .03, .58)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_place(dim, Rect2(0, 0, 1, 1))
	_character = TextureRect.new()
	_character.name = "ResultAina"
	_character.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_character.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_character.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_place(_character, SUCCESS_CHARACTER_RECT)
	_card = Control.new()
	_card.name = "ResultCard"
	_place(_card, RESULT_CARD_RECT)
	var panel := TextureRect.new()
	panel.name = "ResultPanelArtwork"
	panel.texture = artwork("panel")
	panel.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	panel.stretch_mode = TextureRect.STRETCH_SCALE
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_place(panel, Rect2(0, 0, 1, 1), _card)
	_stage_label = _label("", Rect2(.25, .118, .50, .075), 34, _card)
	_title = _label("", Rect2(.10, .245, .80, .095), 64, _card)
	_title.add_theme_color_override("font_color", Palette.GOLD_PALE)
	_title.add_theme_color_override("font_outline_color", Palette.WOOD_DARK)
	_title.add_theme_constant_override("outline_size", 10)
	_title.add_theme_font_override("font", UIKit.title_font())
	_title_art = TitleArt.create("order_served", "Order served!")
	_place(_title_art, Rect2(.10, .228, .80, .088), _card)
	_subtitle = _label("", Rect2(.10, .316, .80, .048), 34, _card)
	_stars = ResultStars.new()
	_place(_stars, Rect2(.23, .370, .54, .096), _card)
	var reward := Panel.new()
	_reward_box = reward
	reward.add_theme_stylebox_override("panel", UIKit.flat_box(Palette.CREAM_DEEP, Palette.WOOD_LIGHT, 0, 3, 35))
	_place(reward, Rect2(.27, .50, .46, .105), _card)
	var coin := TextureRect.new()
	coin.texture = TutorialArt.texture("gold_coin")
	coin.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	coin.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	coin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_place(coin, Rect2(.08, .07, .24, .86), reward)
	_coins_label = _label("+0", Rect2(.34, .05, .59, .9), 66, reward)
	_unlocks = _label("", Rect2(.15, .657, .7, .033), 28, _card)
	_score_value = _label("", Rect2(.49, .636, .28, .064), 48, _card)
	_score_heading = TitleArt.create("score", "Score")
	_place(_score_heading, Rect2(.24, .638, .24, .055), _card)
	_coin_caption = _label(JourneyArt.localized("Syiling","Coins"),Rect2(.20,.508,.22,.04),30,_card)
	_score_caption = _label(JourneyArt.localized("Skor","Score"),Rect2(.59,.508,.23,.04),30,_card)
	_score_badge = TextureRect.new()
	_score_badge.texture = GameplaySkin.texture("star")
	_score_badge.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_score_badge.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_score_badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_place(_score_badge,Rect2(.49,.25,.16,.55),reward)
	_new_best = _label("", Rect2(.14, .522, .72, .048), 36, _card)
	_breakdown = _label("", Rect2(.13, .573, .74, .183), 34, _card)
	_primary = _button("button_green", Rect2(.095, .705, .81, .09))
	_secondary = _button("button_pink", Rect2(.095, .802, .81, .09))
	_home = GameButton.create("", "back", 42)
	_home.custom_minimum_size = Vector2.ZERO
	_place(_home, Rect2(.095, .899, .81, .09), _card)
	for button in [_secondary,_home]:
		var icon := preload("res://scripts/ui/pause_action_icon.gd").new()
		icon.stall = button == _home
		icon.set_meta("win_icon",true)
		_place(icon,Rect2(.03,.04,.30,.92),button)
	_primary.pressed.connect(func() -> void:
		AudioManager.play(AudioManager.Sfx.TAP)
		if is_win:
			continue_pressed.emit()
		else:
			retry_pressed.emit()
	)
	_secondary.pressed.connect(func() -> void:
		if is_win:
			retry_pressed.emit()
		else:
			_show_recovery()
	)
	_home.pressed.connect(func() -> void: home_pressed.emit())

func _rect(node: Control, rect: Rect2) -> void:
	node.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	node.anchor_left = rect.position.x
	node.anchor_top = rect.position.y
	node.anchor_right = rect.end.x
	node.anchor_bottom = rect.end.y
	node.offset_left = 0
	node.offset_top = 0
	node.offset_right = 0
	node.offset_bottom = 0

func _apply_result_layout() -> void:
	_coin_caption.visible = is_win
	_score_caption.visible = is_win
	_score_heading.visible = not is_win
	_score_badge.visible = is_win
	_rect(_reward_box.get_child(0),Rect2(.035,.15,.16,.70) if is_win else Rect2(.08,.07,.24,.86))
	_rect(_card,Rect2(.07,.34,.86,.57) if is_win else RESULT_CARD_RECT)
	_rect(_title,Rect2(.10,.235,.80,.08) if is_win else Rect2(.10,.245,.80,.095))
	_title.add_theme_color_override("font_color",Palette.WOOD_DARK if is_win else Palette.GOLD_PALE)
	_title.add_theme_constant_override("outline_size",0 if is_win else 10)
	_rect(_subtitle,Rect2(.10,.325,.80,.055) if is_win else Rect2(.10,.316,.80,.052))
	_rect(_stars,Rect2(.20,.375,.60,.12) if is_win else Rect2(.23,.370,.54,.096))
	_rect(_reward_box,Rect2(.13,.51,.74,.145) if is_win else Rect2(.27,.50,.46,.105))
	_rect(_coins_label,Rect2(.17,.28,.33,.64) if is_win else Rect2(.34,.05,.59,.9))
	_coins_label.add_theme_font_size_override("font_size",48 if is_win else 66)
	_rect(_score_value,Rect2(.59,.555,.25,.085) if is_win else Rect2(.49,.636,.28,.064))
	_rect(_primary,Rect2(.095,.690,.81,.11) if is_win else Rect2(.095,.705,.81,.09))
	_rect(_secondary,Rect2(.16,.815,.33,.09) if is_win else Rect2(.095,.802,.81,.09))
	_rect(_home,Rect2(.51,.815,.33,.09) if is_win else Rect2(.095,.899,.81,.09))
	for button in [_secondary,_home]:
		for child in button.get_children():
			if child is ButtonArt:
				child.visible = not is_win
			elif child.has_meta("win_icon"):
				child.visible = is_win
		if is_win:
			for state in ["normal","hover","pressed","focus"]:
				button.add_theme_stylebox_override(state,UIKit.flat_box(Color("fff4dc"),Palette.WOOD_LIGHT,0,2,18))
			button.add_theme_color_override("font_color",Palette.WOOD_DARK)
			button.add_theme_color_override("font_hover_color",Palette.WOOD_DARK)
			button.add_theme_color_override("font_pressed_color",Palette.WOOD_DARK)
			button.add_theme_constant_override("outline_size",0)
			button.add_theme_font_size_override("font_size",36)
			button.alignment = HORIZONTAL_ALIGNMENT_RIGHT
		else:
			button.add_theme_color_override("font_color",Palette.PAPER)
			button.alignment = HORIZONTAL_ALIGNMENT_CENTER

func _set_copy() -> void:
	_apply_result_layout()
	_stage_label.text = (MenuText.text("lesson_complete") if is_win and tutorial_stage else MenuText.text("stage_complete") if is_win else MenuText.text("stage_failed")) % stage_number
	_title.text = MenuText.text("order_served" if is_win else "almost_there")
	_title_art.visible = SaveManager.get_setting("language", "en") == "en"
	_title.visible = not _title_art.visible
	_title_art.texture = TitleArt.texture("order_served" if is_win else "stage_failed")
	_title_art.accessibility_name = "Order served!" if is_win else "Stage failed"
	var font_size := 84
	while font_size > 48 and _title.get_theme_font("font").get_string_size(_title.text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x > _card.size.x * .79:
		font_size -= 2
	_title.add_theme_font_size_override("font_size", font_size)
	_primary.text = MenuText.text("next_stage" if is_win else "try_again") + "  ›"
	if is_win and tutorial_stage:
		_primary.text = MenuText.text(("open_gift" if OnboardingProgress.pending() or not ProgressionManager.tutorial_done() else "start_journey") if tutorial_final else "next_lesson") + "  ›"
	if is_win and not tutorial_stage and stage_number >= LevelLibrary.count():
		_primary.text = MenuText.text("map") + "  ›"
	_secondary.text = MenuText.text("play_again" if is_win else "use_booster")
	_home.text = MenuText.text("back_stall")
	if is_win:
		_secondary.text = JourneyArt.localized("Main semula","Replay")
		_home.text = JourneyArt.localized("Ke gerai","To stall")

func show_win(_title_text: String, stars: int, coins: int, unlocks: Array, is_new_best: bool, details: StageResult = null, animate: bool = true) -> void:
	visible = true
	is_win = true
	_character.texture = success_portrait_artwork()
	_set_character_rect(SUCCESS_CHARACTER_RECT)
	_set_copy()
	# The painted title is English artwork; Malay players get the live label.
	_title_art.visible = SaveManager.get_setting("language", "en") == "en"
	_title.visible = not _title_art.visible
	_title.text = JourneyArt.localized("Pesanan siap!","Order served!")
	_title.add_theme_font_size_override("font_size",62)
	_subtitle.text = MenuText.text("served_perfectly")
	_stars.filled = clampi(stars, 0, 3)
	_stars.queue_redraw()
	_coins_label.text = "+%d" % coins
	var names := PackedStringArray()
	for id in unlocks:
		names.append(KuihLibrary.get_display_name(id))
	_unlocks.text = ", ".join(names) if not names.is_empty() else MenuText.text("new_best") if is_new_best else ""
	_show_score_details(details, is_new_best)
	if not animate:
		hide()
		return
	AudioManager.play_result_jingle(true)
	_animate_in()
	if _celebration == null:
		_celebration = GameVfx.new()
		_celebration.z_index = 20
		add_child(_celebration)
	_celebration.celebrate(Rect2(Vector2.ZERO, size))

func show_fail(missing: String, can_afford_offer: bool, details: StageResult = null) -> void:
	if _celebration != null:
		_celebration.reset()
	visible = true
	is_win = false
	_offer_available = can_afford_offer
	_character.texture = portrait_artwork("aina_failed")
	_set_character_rect(FAILED_CHARACTER_RECT)
	_set_copy()
	_subtitle.text = MenuText.text("few_more_kuih")
	_subtitle.tooltip_text = missing
	_stars.filled = 0
	_stars.queue_redraw()
	_coins_label.text = "+0"
	_unlocks.text = ""
	_show_score_details(details, false)
	AudioManager.play_result_jingle(false)
	_animate_in()

func _show_recovery() -> void:
	if has_node("RecoveryOptions"):
		return
	var overlay := Control.new()
	overlay.name = "RecoveryOptions"
	_place(overlay, Rect2(0, 0, 1, 1))
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, .6)
	_place(dim, Rect2(0, 0, 1, 1), overlay)
	var card := PanelContainer.new()
	card.add_theme_stylebox_override("panel", UIKit.cream_box())
	_place(card, Rect2(.12, .36, .76, .28), overlay)
	var stack := UIKit.vbox(16)
	card.add_child(stack)
	stack.add_child(UIKit.title(MenuText.text("use_booster"), 38))
	var extra := UIKit.button(MenuText.text("inventory_moves") % EconomyManager.booster_count(EconomyManager.Booster.EXTRA_MOVES), 28, Palette.LEAF)
	extra.name = "InventoryMoves"
	extra.disabled = not EconomyManager.has_booster(EconomyManager.Booster.EXTRA_MOVES)
	extra.pressed.connect(func() -> void:
		overlay.queue_free()
		booster_pressed.emit()
	)
	stack.add_child(extra)
	if _offer_available:
		var buy := UIKit.button(MenuText.text("coin_moves") % OFFER_COST, 26, Palette.GOLD)
		buy.disabled = not EconomyManager.can_afford(OFFER_COST)
		buy.pressed.connect(func() -> void:
			if EconomyManager.spend_coins(OFFER_COST):
				overlay.queue_free()
				continue_pressed.emit()
		)
		stack.add_child(buy)
	if GameManager.setting("rewarded_ads", false) and HeartManager.rewarded_ad_provider.is_valid():
		var ad := UIKit.button(MenuText.text("ad_moves"), 26, Palette.LEAF_LIGHT)
		ad.pressed.connect(func() -> void:
			overlay.queue_free()
			watch_ad_for_moves.emit()
		)
		stack.add_child(ad)
	var close := UIKit.button(MenuText.text("close"), 26)
	close.pressed.connect(func() -> void: overlay.queue_free())
	stack.add_child(close)

func _animate_in() -> void:
	modulate.a = 0
	_card.pivot_offset = _card.size * .5
	_card.scale = Vector2(.86, .86)
	var tween := create_tween().set_parallel(true)
	tween.tween_property(self, "modulate:a", 1, .24)
	tween.tween_property(_card, "scale", Vector2.ONE, .42).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _show_score_details(details: StageResult, _is_new_best: bool) -> void:
	_reward_box.show()
	_score_value.text = str(details.final_score) if details != null else "0"
	_new_best.text = ""
	_new_best.hide()
	_breakdown.text = ""
	_breakdown.hide()
	_unlocks.hide()
