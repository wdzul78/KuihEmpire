class_name ScoreProgress
extends Control

var number_font_size := 36
var score := 0
var two_star := 800
var three_star := 1400
var _number: Label
var _star_art: Texture2D
const METER_PATH := "res://assets/ui/score_meter_v1/score_meter_empty.png"
const ART_REGION := Rect2(18,180,1500,640)
var _meter_art: Texture2D
var fill_ratio := 0.0
var completed := false
var _fill_tween: Tween

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_number = JourneyArt.label(self, "0", Rect2(.08, .065, .84, .43), 36, Palette.WOOD_DARK)
	_number.name = "ScoreValue"
	_number.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_star_art = GameplaySkin.texture("star")
	var atlas := AtlasTexture.new()
	atlas.atlas = load(METER_PATH)
	atlas.region = ART_REGION
	_meter_art = atlas
	resized.connect(_refresh)
	_refresh()

func configure(level: LevelDefinition) -> void:
	completed = false
	fill_ratio = 0
	two_star = maxi(1, level.score_two_star)
	three_star = maxi(two_star + 1, level.score_three_star)
	_refresh()

func set_score(value: int) -> void:
	score = maxi(0, value)
	if is_instance_valid(_fill_tween):
		_fill_tween.kill()
	_fill_tween = create_tween()
	_fill_tween.tween_property(self,"fill_ratio",progress_for_score(score),.35).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_fill_tween.finished.connect(queue_redraw)
	_refresh()

func set_completed(value: bool) -> void:
	completed = value
	queue_redraw()

func progress_for_score(value: int) -> float:
	# Two-star target lines up with the middle star; the final target fills
	# the complete rail. The first star is awarded by completing the orders.
	if value <= two_star:
		return clampf(float(value)/two_star,0,1)*.54
	return .54+clampf(float(value-two_star)/(three_star-two_star),0,1)*.46

func lit_stars() -> int:
	if score >= three_star:
		return 3
	if score >= two_star:
		return 2
	# Preview progress at the first rail marker; final rewards still require
	# completing the orders in StageResultCalculator.
	return 1 if completed or progress_for_score(score) >= .26 else 0

func illustration_rect() -> Rect2:
	var extent := ART_REGION.size*minf(size.x/ART_REGION.size.x,size.y/ART_REGION.size.y)
	return Rect2((size-extent)*.5,extent)

func _process(_delta: float) -> void:
	if is_instance_valid(_fill_tween) and _fill_tween.is_running():
		queue_redraw()

func _refresh() -> void:
	if _number != null:
		var art := illustration_rect()
		_number.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
		_number.position = art.position+art.size*Vector2(.22,.66)
		_number.size = art.size*Vector2(.56,.28)
		_number.text = str(score)
		var px := number_font_size
		while px > 24 and _number.get_theme_font("font").get_string_size(_number.text, HORIZONTAL_ALIGNMENT_LEFT, -1, px).x > _number.size.x:
			px -= 1
		_number.add_theme_font_size_override("font_size", px)
	tooltip_text = "Complete orders to win. Targets: 2 stars %d; 3 stars %d." % [two_star, three_star]
	queue_redraw()

func _draw() -> void:
	if size.x <= 0 or size.y <= 0:
		return
	var art := illustration_rect()
	draw_texture_rect(_meter_art,art,false)
	var bar := Rect2(art.position+art.size*Vector2(.03,.208),art.size*Vector2(.94,.18))
	if fill_ratio > 0:
		# Clip the glossy fill to the pill silhouette, retaining round end caps
		# even when only a few pixels have been filled.
		var points := PackedVector2Array()
		var colors := PackedColorArray()
		for index in 80:
			var angle := TAU*float(index)/80.0
			var radius := bar.size.y*.5
			var center := Vector2(bar.position.x+(bar.size.x-radius if cos(angle)>=0 else radius),bar.get_center().y)
			var point := center+Vector2.from_angle(angle)*radius
			point.x = minf(point.x,bar.position.x+bar.size.x*fill_ratio)
			points.append(point)
			colors.append(Color("8cff19").lerp(Color("009b14"),clampf((point.y-bar.position.y)/bar.size.y,0,1)))
		draw_polygon(points,colors)
	if _star_art == null:
		return
	var side := art.size.y*.39
	var earned := lit_stars()
	for index in 3:
		var x: float = bar.position.x+bar.size.x*[.26,.54,.86][index]
		x = clampf(x,bar.position.x+side*.5,bar.end.x-side*.5)
		var tint := Color.WHITE if index < earned else Color(.50,.43,.32)
		draw_texture_rect(_star_art,Rect2(Vector2(x-side*.5,bar.get_center().y-side*.72),Vector2.ONE*side),false,tint)
