class_name WelcomeChest
extends Control

const SHEET := "res://assets/ui/onboarding_v1/reward_chest_sheet.png"
var _frames: Array[AtlasTexture] = []
var opening := 0.0:
	set(value):
		opening = value
		queue_redraw()

func _ready() -> void:
	mouse_filter = MOUSE_FILTER_IGNORE
	var sheet: Texture2D = load(SHEET)
	var width := sheet.get_width() / 2.0
	for i in 2:
		var frame := AtlasTexture.new()
		frame.atlas = sheet
		frame.region = Rect2(i*width,0,width,sheet.get_height())
		_frames.append(frame)
	resized.connect(queue_redraw)

func _draw() -> void:
	if _frames.is_empty():
		return
	var side := minf(size.x,size.y)
	var pulse := 1.0 + sin(opening*PI)*.045
	var rect := Rect2(size*.5-Vector2.ONE*side*pulse*.5,Vector2.ONE*side*pulse)
	var reveal := clampf((opening-.3)/.45,0,1)
	if reveal < 1:
		draw_texture_rect(_frames[0],rect,false,Color(1,1,1,1-reveal))
	if reveal > 0:
		draw_texture_rect(_frames[1],rect,false,Color(1,1,1,reveal))
