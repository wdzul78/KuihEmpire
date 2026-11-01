class_name AchievementsScreen
extends Control

var _ranking := false
var _filter := "current_story"
var _category := "ALL"
var _content: VBoxContainer
var _status: Label
var _sticky: Label
var _scroll: ScrollContainer
var _options: OptionButton
var _notice: Label
var _sample_toggle: CheckButton
var _tabs: Array[Button] = []

## Hand-drawn dropdown arrow; the default theme arrow is lost on the painted frame.
class Chevron extends Control:
	func _draw() -> void:
		draw_colored_polygon(PackedVector2Array([Vector2.ZERO, Vector2(size.x, 0), Vector2(size.x * .5, size.y)]), Palette.WOOD_DARK)

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	UIKit.apply_root_theme(self)
	var backdrop := GeraiBackdrop.new()
	backdrop.background_id = &"stall_dawn"
	backdrop.show_counter = false
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(backdrop)
	var panel := Panel.new()
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_theme_stylebox_override("panel", GeraiSkin.box("list_panel", .72))
	JourneyArt.place(self, panel, Rect2(.02, .03, .96, .955))
	var back := GameButton.create(JourneyArt.localized("Kembali", "Back"), "back", 36)
	back.custom_minimum_size = Vector2.ZERO
	JourneyArt.place(self, back, Rect2(.03, .016, .22, .055))
	back.pressed.connect(func() -> void: SceneManager.goto(SceneManager.HOME))
	var plate := Panel.new()
	plate.mouse_filter = Control.MOUSE_FILTER_IGNORE
	plate.add_theme_stylebox_override("panel", GeraiSkin.box("name_plate", .6))
	JourneyArt.place(self, plate, Rect2(.26, .008, .71, .072))
	var heading := JourneyArt.label(plate, JourneyArt.localized("Pencapaian", "Achievements"), Rect2(0, 0, 1, 1), 48, Palette.PAPER)
	heading.add_theme_color_override("font_outline_color", Palette.WOOD_DARK)
	heading.add_theme_constant_override("outline_size", 8)
	var personal := _tab(JourneyArt.localized("Peribadi", "Personal"), "PersonalTab", Rect2(.07, .09, .43, .066))
	var ranking := _tab("Ranking", "RankingTab", Rect2(.50, .09, .43, .066))
	personal.pressed.connect(func() -> void: _ranking = false; _refresh_options())
	ranking.pressed.connect(func() -> void: _ranking = true; _refresh_options())
	_status = JourneyArt.label(self, "", Rect2(.08, .156, .84, .075), 34, Palette.WOOD_DARK)
	_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_options = OptionButton.new()
	_options.add_theme_font_size_override("font_size", 38)
	_options.alignment = HORIZONTAL_ALIGNMENT_CENTER
	_options.fit_to_longest_item = false
	_options.clip_text = true
	_options.add_theme_icon_override("arrow", ImageTexture.new())
	GeraiSkin.skin_button(_options, "tab_idle", .9)
	for state in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		_options.add_theme_color_override(state, Palette.WOOD_DARK)
	_style_popup(_options.get_popup())
	JourneyArt.place(self, _options, Rect2(.16, .232, .68, .066))
	var chevron := Chevron.new()
	chevron.mouse_filter = Control.MOUSE_FILTER_IGNORE
	JourneyArt.place(_options, chevron, Rect2(.84, .40, .04, .20))
	_options.item_selected.connect(_option_selected)
	_scroll = ScrollContainer.new()
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_scroll.get_v_scroll_bar().add_theme_stylebox_override("scroll", _bar_style(Palette.CREAM_DEEP))
	for state in ["grabber", "grabber_highlight", "grabber_pressed"]:
		_scroll.get_v_scroll_bar().add_theme_stylebox_override(state, _bar_style(Palette.WOOD_LIGHT))
	JourneyArt.place(self, _scroll, Rect2(.075, .305, .85, .525))
	_content = UIKit.vbox(16)
	_content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_scroll.add_child(_content)
	_sticky = JourneyArt.label(self, "", Rect2(.13, .832, .74, .08), 32, Palette.WOOD_DARK)
	_sticky.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_notice = JourneyArt.label(self, "", Rect2(.16, .912, .68, .024), 26, Palette.WOOD_DARK)
	if OS.has_feature("debug"):
		var sample := CheckButton.new()
		_sample_toggle = sample
		for style in ["normal", "hover", "pressed", "disabled", "focus"]:
			sample.add_theme_stylebox_override(style, StyleBoxEmpty.new())
		sample.text = "Show sample rankings (development)"
		sample.add_theme_font_size_override("font_size", 30)
		for color in ["font_color", "font_hover_color", "font_pressed_color"]:
			sample.add_theme_color_override(color, Palette.WOOD_DARK)
		JourneyArt.place(self, sample, Rect2(.18, .934, .64, .024))
		sample.toggled.connect(func(enabled: bool) -> void:
			RankingManager.refresh()
			if RankingManager.service is LocalLeaderboardService:
				RankingManager.service.set_samples(enabled)
			refresh()
		)
	AchievementManager.changed.connect(refresh)
	RankingManager.updated.connect(_rankings_ready)
	AchievementManager.refresh()
	_refresh_options()

func _rankings_ready() -> void:
	if _ranking:
		_draw_rankings()

func _tab(caption: String, node_name: String, rect: Rect2) -> Button:
	var tab := Button.new()
	tab.name = node_name
	tab.text = caption
	tab.add_theme_font_size_override("font_size", 40)
	tab.add_theme_color_override("font_outline_color", Palette.LEAF_DEEP)
	UIKit.add_press_feedback(tab)
	JourneyArt.place(self, tab, rect)
	_tabs.append(tab)
	return tab

## The selected tab is the painted leaf green; the other stays cream.
func _update_tabs() -> void:
	for tab in _tabs:
		var selected: bool = (tab.name == "RankingTab") == _ranking
		for state in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
			tab.add_theme_color_override(state, Palette.PAPER if selected else Palette.WOOD_DARK)
		tab.add_theme_constant_override("outline_size", 8 if selected else 0)
		GeraiSkin.skin_button(tab, "tab_active" if selected else "tab_idle", .9)

func _bar_style(color: Color) -> StyleBoxFlat:
	var style := UIKit.flat_box(color, Color.TRANSPARENT, 0, 0, 6)
	style.content_margin_left = 6
	style.content_margin_right = 6
	return style

func _style_popup(popup: PopupMenu) -> void:
	for icon in ["radio_checked", "radio_unchecked"]:
		popup.add_theme_icon_override(icon, ImageTexture.new())
	popup.add_theme_stylebox_override("panel", UIKit.flat_box(Palette.PAPER, Palette.GOLD, 16, 4, 20))
	popup.add_theme_stylebox_override("hover", UIKit.flat_box(Color("f5dfaf"), Color("f5dfaf"), 6, 0, 12))
	popup.add_theme_font_size_override("font_size", 38)
	popup.add_theme_color_override("font_color", Palette.WOOD_DARK)
	popup.add_theme_color_override("font_hover_color", Palette.WOOD_DARK)
	popup.add_theme_color_override("font_disabled_color", Palette.WOOD_LIGHT)
	popup.add_theme_constant_override("v_separation", 18)

## Category heading on a small carved plate.
func _section(caption: String) -> Control:
	var heading := PanelContainer.new()
	heading.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	heading.custom_minimum_size = Vector2(560, 104)
	heading.add_theme_stylebox_override("panel", GeraiSkin.box("name_plate", .45))
	var label := UIKit.label(caption, 36, Palette.PAPER)
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_color_override("font_outline_color", Palette.WOOD_DARK)
	label.add_theme_constant_override("outline_size", 6)
	heading.add_child(label)
	return heading

func _refresh_options() -> void:
	_update_tabs()
	if _sample_toggle != null:
		_sample_toggle.visible = _ranking
	_options.clear()
	if _ranking:
		for text in [_t("Cerita Semasa", "Current Story"), _t("Semua Perjalanan", "All Journey"), _t("Pencapaian Semasa", "Current Milestone"), _t("Kawan (akan datang)", "Friends (coming later)")]:
			_options.add_item(text)
		_options.set_item_disabled(3, true)
		_options.select(["current_story", "all", "current_milestone"].find(_filter))
	else:
		_options.add_item(_category_name("ALL"))
		_options.set_item_metadata(0, "ALL")
		for definition in AchievementManager.definitions:
			var found := false
			for i in _options.item_count:
				if _options.get_item_metadata(i) == definition.category:
					found = true
			if not found:
				_options.add_item(_category_name(definition.category))
				_options.set_item_metadata(_options.item_count - 1, definition.category)
		for i in _options.item_count:
			if _options.get_item_metadata(i) == _category:
				_options.select(i)
	refresh()

func _option_selected(index: int) -> void:
	if _ranking:
		_filter = ["current_story", "all", "current_milestone"][index]
	else:
		_category = str(_options.get_item_metadata(index))
	_scroll.scroll_vertical = 0
	refresh()

func _clear() -> void:
	for child in _content.get_children():
		_content.remove_child(child)
		child.queue_free()

func refresh() -> void:
	if _content == null:
		return
	if _ranking:
		RankingManager.refresh()
		_draw_rankings()
		return
	_clear()
	var metrics := AchievementManager.metrics()
	_status.text = JourneyArt.localized("%d / %d pencapaian selesai\n★ %d  ·  Resipi %d  ·  Pesanan %d  ·  Cerita %d", "%d / %d achievements completed\n★ %d  ·  Recipes %d  ·  Orders %d  ·  Stories %d") % [AchievementManager.completed_count(), AchievementManager.definitions.size(), metrics["stars"], metrics["recipes"], metrics.get("orders_served", 0), metrics["stories"]]
	_sticky.text = JourneyArt.localized("Raikan setiap langkah kecil.\nGanjaran ditambah automatik sebaik dibuka.", "Celebrate every small step.\nRewards are added automatically once unlocked.")
	_notice.text = JourneyArt.localized("Pencapaian peribadi · disimpan dalam peranti ini", "Personal accomplishments · saved on this device")
	var groups: Dictionary = {}
	for definition in AchievementManager.definitions:
		if _category != "ALL" and definition.category != _category:
			continue
		if definition.hidden and not AchievementManager.state(definition.id).get("unlocked", false):
			continue
		if not groups.has(definition.category):
			groups[definition.category] = []
		groups[definition.category].append(definition)
	for category in groups:
		var complete := 0
		for definition in groups[category]:
			if AchievementManager.state(definition.id).get("unlocked", false):
				complete += 1
		_content.add_child(_section("%s  ·  %d / %d" % [_category_name(category), complete, groups[category].size()]))
		for definition in groups[category]:
			var state := AchievementManager.state(definition.id)
			var unlocked: bool = state.get("unlocked", false)
			var box := _card(unlocked)
			var line := HBoxContainer.new()
			line.add_theme_constant_override("separation", 56)
			box.add_child(line)
			line.add_child(_badge(definition.category, unlocked))
			var column := UIKit.vbox(12)
			column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			line.add_child(column)
			column.add_child(_text(_title(definition), 40))
			column.add_child(_text(_description(definition), 32))
			var progress := ProgressBar.new()
			progress.max_value = definition.target
			progress.value = state.get("progress", 0)
			progress.show_percentage = false
			GeraiSkin.style_progress(progress, 30)
			column.add_child(progress)
			column.add_child(_text("%d / %d  ·  +%d %s%s" % [state.get("progress", 0), definition.target, definition.reward_coins, JourneyArt.localized("syiling", "coins"), JourneyArt.localized("  ·  Ganjaran diterima", "  ·  Reward received") if unlocked else ""], 30))
			if not definition.tier.is_empty():
				column.add_child(_text(_tier_name(definition.tier), 28))

func _draw_rankings() -> void:
	if _content == null:
		return
	_clear()
	var rows := RankingManager.service.get_rankings(_filter)
	var own := RankingManager.service.get_player_rank(_filter)
	var samples := false
	for entry in rows:
		samples = samples or entry.is_sample
	_status.text = _t("Ranking Perjalanan\nPerjalanan → Cerita → Stage → Bintang → Skor", "Journey Ranking\nJourney → Story → Stage → Stars → Score")
	_notice.text = "SAMPLE DATA · development only" if samples else _t("Rekod setempat · ranking dalam talian belum disambung", "Local snapshot · online ranking is not connected")
	if own == null:
		_sticky.text = _t("Rekod perjalanan anda sedang dimuat…", "Your Journey snapshot is loading…")
		return
	var own_index := rows.find(own)
	# Around-player window, with the full rank retained and a permanent own card.
	var first := maxi(0, own_index - 3)
	var last := mini(rows.size(), first + 10)
	for i in range(first, last):
		var entry := rows[i]
		var is_own := entry.player_id == own.player_id
		var box := _card(is_own)
		var line := HBoxContainer.new()
		line.add_theme_constant_override("separation", 62)
		box.add_child(line)
		var avatar := AvatarLibrary.icon(entry.avatar_id)
		avatar.custom_minimum_size = Vector2(100, 100)
		line.add_child(avatar)
		var column := UIKit.vbox(8)
		column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		line.add_child(column)
		column.add_child(_text("#%d  %s%s" % [entry.rank, entry.nickname, _t(" · ANDA", " · YOU") if is_own else ""], 38))
		column.add_child(_text(entry.title, 28))
		column.add_child(_text(_t("Cerita %d  ·  Stage %d  ·  ★ %d", "Story %d  ·  Stage %d  ·  ★ %d") % [entry.story_index, entry.highest_stage_completed, entry.total_stars], 32))
	_sticky.text = _t("KEDUDUKAN ANDA  #%d  ·  Cerita %d / Pencapaian %d\nStage %d  ·  ★ %d  ·  Skor terbaik %d", "YOUR RANK  #%d  ·  Story %d / Milestone %d\nStage %d  ·  ★ %d  ·  Best relevant score %d") % [own.rank, own.story_index, own.milestone_index, own.highest_stage_completed, own.total_stars, own.tie_break_score]
	if own_index > 0:
		var next := rows[own_index - 1]
		if next.highest_stage_completed > own.highest_stage_completed:
			_sticky.text += _t("\n%d stage lagi untuk naik satu kedudukan.", "\n%d more stage(s) to reach the next position.") % (next.highest_stage_completed - own.highest_stage_completed)
		elif next.total_stars > own.total_stars:
			_sticky.text += _t("\n%d bintang lagi untuk berkongsi kedudukan seterusnya.", "\n%d more stars to share the next position.") % (next.total_stars - own.total_stars)
		elif next.tie_break_score > own.tie_break_score:
			_sticky.text += _t("\nCuba skor terbaik baharu di Stage %d.", "\nTry for a new best on Stage %d.") % own.highest_stage_completed

func _card(highlight: bool) -> PanelContainer:
	var box := PanelContainer.new()
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	# The row's round socket sits at the left; icons are centred inside it.
	var style := GeraiSkin.box("task_row", .95, [94, 28, 46, 28])
	if highlight:
		style.modulate_color = Color(1, .93, .76)
	box.add_theme_stylebox_override("panel", style)
	_content.add_child(box)
	return box

const MS_CATEGORIES := {"ALL": "Semua", "GERAI": "Gerai", "JOURNEY": "Perjalanan", "STARS": "Bintang", "PUZZLE": "Teka-teki", "RECIPES": "Resipi", "ORDERS": "Pesanan", "SPECIALS": "Istimewa", "STREAK": "Rentetan", "SCORE": "Skor"}
const MS_TIERS := {"BRONZE": "Gangsa", "SILVER": "Perak", "GOLD": "Emas", "MASTER": "Pakar"}
## id -> [Malay title, Malay description]
const MS_TEXT := {
	"first_renovation": ["Ubah Suai Pertama", "Beli naik taraf struktur gerai yang pertama."],
	"first_steps": ["Langkah Pertama", "Selesaikan stage pertama anda."],
	"stars_30": ["Pengumpul Bintang I", "Kumpul 30 bintang kekal."],
	"stars_60": ["Pengumpul Bintang II", "Kumpul 60 bintang kekal."],
	"stars_90": ["Pengumpul Bintang III", "Kumpul 90 bintang kekal."],
	"stars_120": ["Pengumpul Bintang IV", "Kumpul 120 bintang kekal."],
	"stars_180": ["Pengumpul Bintang V", "Kumpul 180 bintang kekal."],
	"perfect_server": ["Hidangan Sempurna", "Dapatkan tiga bintang di 10 stage berbeza."],
	"recipes_10": ["Peneroka Kuih", "Temui 10 resipi."],
	"malaysian_kuih_master": ["Pakar Kuih Malaysia", "Temui kesemua 200 resipi warisan."],
	"recipe_master": ["Pakar Kuih", "Lengkapkan buku resipi."],
	"serve_100": ["Gerai Sibuk", "Hidangkan 100 pesanan pelanggan."],
	"combo_25": ["Tukang Kombo", "Aktifkan 25 gabungan istimewa."],
	"no_help": ["Tak Perlu Bantuan", "Menang satu stage tanpa guna booster."],
	"streak_5": ["Rentetan Manis", "Menang lima stage berturut-turut."],
	"story_1": ["Gerai Keluarga Selesai", "Selesaikan kesemua 30 stage gerai keluarga."],
	"next_story": ["Perjalanan Diteruskan", "Buka cerita kantin sekolah."],
	"story_2": ["Kantin Sekolah Selesai", "Selesaikan kesemua 30 stage kantin sekolah."],
	"score_3000": ["Skor Manis", "Capai skor terbaik 3,000 dalam satu stage."],
	"gerai_2": ["Gerai Berkembang", "Naik taraf gerai ke tahap dua."],
}

static func _is_ms() -> bool:
	return SaveManager.get_setting("language", "en") != "en"

static func _t(ms: String, en: String) -> String:
	return ms if _is_ms() else en

static func _category_name(category: String) -> String:
	return MS_CATEGORIES.get(category, category.capitalize()) if _is_ms() else category.capitalize()

static func _tier_name(tier: String) -> String:
	return MS_TIERS.get(tier, tier.capitalize()) if _is_ms() else tier.capitalize()

static func _title(definition: AchievementDefinition) -> String:
	return MS_TEXT[definition.id][0] if _is_ms() and MS_TEXT.has(definition.id) else definition.title

static func _description(definition: AchievementDefinition) -> String:
	return MS_TEXT[definition.id][1] if _is_ms() and MS_TEXT.has(definition.id) else definition.description

## Painted category art in the row's socket; locked goals stay muted until earned.
func _badge(category: String, unlocked: bool) -> Control:
	var disc := Control.new()
	disc.custom_minimum_size = Vector2(112, 112)
	disc.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	disc.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var art := TextureRect.new()
	art.texture = _category_icon(category)
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	art.modulate = Color.WHITE if unlocked else Color(.62, .6, .58, .8)
	JourneyArt.place(disc, art, Rect2(.04, .04, .92, .92))
	if unlocked:
		var tick := JourneyStageDisc.CompletedBadge.new()
		JourneyArt.place(disc, tick, Rect2(.64, .64, .42, .42))
	return disc

static func _category_icon(category: String) -> Texture2D:
	match category:
		"GERAI":
			return _trimmed(load("res://assets/ui/journey_icons_v2/icons.png"), 0)
		"RECIPES":
			return _trimmed(load("res://assets/ui/journey_icons_v2/icons.png"), 1)
		"JOURNEY":
			return _trimmed(load("res://assets/ui/journey_icons_v2/icons.png"), 2)
		"STARS":
			return GameplaySkin.texture("star")
		"STREAK":
			return load("res://assets/ui/hearts_v2/heart_full.png")
		"SPECIALS":
			return _trimmed(load("res://assets/specials/kek_lapis_diraja_v1/kek_lapis_diraja.png"))
		"SCORE":
			return load("res://assets/menu/nav_v4/records.png")
		"ORDERS":
			return KuihLibrary.get_kuih(&"kuih_lapis").texture
	return KuihLibrary.get_kuih(&"onde_onde").texture

## Crops a 2x2 sheet quadrant (or the whole image when quadrant < 0) to its painted pixels.
static func _trimmed(source: Texture2D, quadrant: int = -1) -> Texture2D:
	var area := Rect2i(Vector2i.ZERO, source.get_size())
	if quadrant >= 0:
		area.size /= 2
		area.position = Vector2i(quadrant % 2, quadrant / 2) * area.size
	var used := source.get_image().get_region(area).get_used_rect()
	var atlas := AtlasTexture.new()
	atlas.atlas = source
	atlas.region = Rect2(area.position + used.position, used.size)
	return atlas

func _text(value: String, font_size: int) -> Label:
	var label := UIKit.label(value, font_size, Palette.WOOD_DARK)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	return label
