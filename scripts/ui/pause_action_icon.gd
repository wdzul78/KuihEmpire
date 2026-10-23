extends Control
var stall := false
var icon_index := -1
const SHEET = preload("res://assets/ui/pause_icons_v1/icons.png")
func _ready() -> void:
 mouse_filter = Control.MOUSE_FILTER_IGNORE
 resized.connect(queue_redraw)
func _draw() -> void:
 var index := icon_index if icon_index >= 0 else (1 if stall else 0)
 var cell := SHEET.get_size()/2.0
 var edge := minf(size.x,size.y)
 draw_texture_rect_region(SHEET,Rect2((size-Vector2.ONE*edge)*.5,Vector2.ONE*edge),Rect2(Vector2(index % 2,index / 2)*cell,cell))
