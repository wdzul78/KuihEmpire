class_name JourneyMap
extends Control

## Malaysia journey map (Master Plan section 29).
##
## MVP only opens Chapter 1 - Kuching - plus the Season 1 finale node. The route
## is drawn as a dotted trail so later chapters can simply be appended.

const ROUTE := [
	{"id": 1, "title": "Prologue", "place": "Gerai Keluarga", "chapter": &"prologue", "bg": &"stall_dawn", "pos": Vector2(0.5, 0.86)},
	{"id": 11, "title": "Chapter 1", "place": "Kuching", "chapter": &"kuching", "bg": &"kuching_market", "pos": Vector2(0.5, 0.66)},
	{"id": 21, "title": "Chapter 2", "place": "Sarawak", "chapter": &"sarawak", "bg": &"weekend_market", "pos": Vector2(0.5, 0.48)},
	{"id": 31, "title": "Chapter 3", "place": "Sabah", "chapter": &"sabah", "bg": &"weekend_market", "pos": Vector2(0.5, 0.32)},
	{"id": 81, "title": "Chapter 4", "place": "Northern", "chapter": &"northern", "bg": &"stall_dawn", "pos": Vector2(0.5, 0.18)},
]

var _grid: Control
var _unlock_note: Label


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

	var top := UIKit.hbox(16)
	top.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	top.offset_top = 30
	top.offset_left = 30
	top.offset_right = -30
	add_child(top)
	var back := UIKit.button("Back", 28, Palette.WOOD_LIGHT)
	back.custom_minimum_size = Vector2(200, 88)
	back.pressed.connect(func() -> void:
		AudioManager.play(AudioManager.Sfx.TAP)
		GameManager.go_home()
	)
	top.add_child(back)
	var title := UIKit.title("Malaysia Journey", 52)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	top.add_child(title)
	var story := UIKit.button("Story", 26, Palette.PINK_DARK)
	story.custom_minimum_size = Vector2(180, 80)
	story.pressed.connect(_on_story)
	top.add_child(story)
	var coins := CoinDisplay.new()
	coins.icon_size = 66.0
	coins.amount = EconomyManager.coins()
	top.add_child(coins)

	_grid = Control.new()
	_grid.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_grid.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_grid.draw.connect(_draw_route)
	add_child(_grid)

	_unlock_note = UIKit.wrap_label(
		"Clear the Kuching chapter to reveal the next stop on the route.",
		26, Palette.WOOD_DARK
	)
	_unlock_note.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	_unlock_note.offset_top = -140
	_unlock_note.offset_bottom = -70
	_unlock_note.offset_left = 60
	_unlock_note.offset_right = -60
	add_child(_unlock_note)

	resized.connect(_grid.queue_redraw)
	_refresh()


func _refresh() -> void:
	var cleared := ProgressionManager.highest_cleared()
	_unlock_note.text = "Chapters unlock as you play  ·  %d / %d stages cleared" % [
		cleared, LevelLibrary.count()
	]


## Chapter intros live here, so the route always has a narrative entrance.
func _on_story() -> void:
	AudioManager.play(AudioManager.Sfx.TAP)
	var group := StoryLibrary.PROLOGUE
	if ProgressionManager.is_chapter_unlocked(StoryLibrary.KUCHING) or cleared_chapter_one():
		group = StoryLibrary.KUCHING
	SceneManager.goto_story(group, true, SceneManager.JOURNEY)


func cleared_chapter_one() -> bool:
	return ProgressionManager.highest_cleared() >= LevelLibrary.MORNING_RUSH


func _node_state(entry: Dictionary) -> String:
	var id := int(entry["id"])
	var chapter: StringName = entry["chapter"]
	if id > LevelLibrary.count():
		return "locked"
	if id == 1:
		return "open"
	if not ProgressionManager.is_level_unlocked(id):
		return "locked"
	if ProgressionManager.stars_for(id) > 0:
		return "done"
	if ProgressionManager.is_chapter_unlocked(chapter) or ProgressionManager.is_level_unlocked(id):
		return "open"
	return "locked"


func _draw_route() -> void:
	var trail_top := _grid.size.y * 0.12
	var trail_bottom := _grid.size.y * 0.88
	var points: Array[Vector2] = []
	for entry in ROUTE:
		var pos: Vector2 = entry["pos"]
		points.append(Vector2(
			_grid.size.x * pos.x + sin(float(entry["id"]) * 1.7) * _grid.size.x * 0.12,
			trail_top + (trail_bottom - trail_top) * (1.0 - pos.y)
		))

	# dotted trail
	for i in range(points.size() - 1):
		var a: Vector2 = points[i]
		var b: Vector2 = points[i + 1]
		var steps := int(a.distance_to(b) / 44.0)
		for s in steps:
			var t := float(s) / float(maxi(1, steps))
			_grid.draw_circle(a.lerp(b, t), 9.0, Color(1, 1, 1, 0.7))

	for i in ROUTE.size():
		_draw_node(ROUTE[i], points[i])


func _draw_node(entry: Dictionary, at: Vector2) -> void:
	var state := _node_state(entry)
	var id := int(entry["id"])
	var radius := 74.0
	var fill := Palette.PINK
	var ring := Palette.PINK_DARK
	match state:
		"done":
			fill = Palette.GOLD_PALE
			ring = Palette.GOLD_DARK
		"locked":
			fill = Color(0.78, 0.74, 0.68, 0.65)
			ring = Color(0.55, 0.50, 0.45, 0.7)

	_grid.draw_circle(at + Vector2(0, 8), radius, Palette.SHADOW)
	_grid.draw_circle(at, radius, ring)
	_grid.draw_circle(at, radius - 10.0, fill)

	if state != "locked":
		var stars := ProgressionManager.stars_for(id)
		_grid.draw_string(
			UIKit.bold_font(), at + Vector2(-radius + 12.0, -radius * 0.36),
			str(id), HORIZONTAL_ALIGNMENT_LEFT, -1, 32, Palette.WOOD_DARK
		)
		for s in 3:
			var c := at + Vector2((float(s) - 1.0) * 38.0, 12.0)
			_draw_star(c, 17.0, Palette.STAR if s < stars else Color(1, 1, 1, 0.55))
	else:
		_draw_padlock(at)

	var label := String(entry["place"])
	var font := UIKit.bold_font()
	var text_w := font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, 26).x
	var pill := Rect2(at.x - text_w * 0.5 - 18.0, at.y + radius + 12.0, text_w + 36.0, 44.0)
	_grid.draw_rect(pill, Color(1, 1, 1, 0.78))
	_grid.draw_rect(pill, Palette.WOOD_LIGHT, false, 3.0)
	_grid.draw_string(
		font, Vector2(at.x - text_w * 0.5, at.y + radius + 44.0), label,
		HORIZONTAL_ALIGNMENT_LEFT, -1, 26, Palette.WOOD_DARK
	)


func _draw_padlock(at: Vector2) -> void:
	_grid.draw_arc(at + Vector2(0, -14.0), 20.0, PI, TAU, 20, Palette.WOOD_DARK, 9.0, true)
	_grid.draw_rect(Rect2(at.x - 32.0, at.y - 14.0, 64.0, 54.0), Palette.WOOD_DARK)
	_grid.draw_rect(Rect2(at.x - 24.0, at.y - 6.0, 48.0, 38.0), Color(0.55, 0.50, 0.45, 0.95))
	_grid.draw_circle(at + Vector2(0, 8.0), 6.0, Palette.WOOD_DARK)


func _draw_star(center: Vector2, radius: float, color: Color) -> void:
	var pts := PackedVector2Array()
	for i in 10:
		var a := -PI * 0.5 + float(i) * PI / 5.0
		var r := radius if i % 2 == 0 else radius * 0.46
		pts.append(center + Vector2(cos(a), sin(a)) * r)
	_grid.draw_colored_polygon(pts, color)


func _gui_input(event: InputEvent) -> void:
	var released := false
	var at := Vector2.ZERO
	if event is InputEventScreenTouch:
		released = not (event as InputEventScreenTouch).pressed
		at = (event as InputEventScreenTouch).position
	elif event is InputEventMouseButton:
		released = not (event as InputEventMouseButton).pressed
		at = (event as InputEventMouseButton).position
	if not released:
		return
	var trail_top := _grid.size.y * 0.12
	var trail_bottom := _grid.size.y * 0.88
	for i in ROUTE.size():
		var entry: Dictionary = ROUTE[i]
		var pos: Vector2 = entry["pos"]
		var node_pos := Vector2(
			_grid.size.x * pos.x + sin(float(entry["id"]) * 1.7) * _grid.size.x * 0.12,
			trail_top + (trail_bottom - trail_top) * (1.0 - pos.y)
		)
		if at.distance_to(node_pos) > 110.0:
			continue
		var id := int(entry["id"])
		if _node_state(entry) == "locked":
			AudioManager.play(AudioManager.Sfx.INVALID)
			_unlock_note.text = "That stop is still locked. Keep serving customers!"
			return
		AudioManager.play(AudioManager.Sfx.TAP)
		GameManager.play_level(id)
		return
