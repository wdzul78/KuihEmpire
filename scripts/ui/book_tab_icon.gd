class_name BookTabIcon
extends Control

var notebook := false

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func _draw() -> void:
	var bounds := Rect2(size*.12,size*.76)
	draw_style_box(UIKit.flat_box(Color("fff6df"),Color("864b24"),0,2,5),bounds)
	draw_rect(Rect2(bounds.position,Vector2(size.x*.12,bounds.size.y)),Color("55a332"))
	if notebook:
		draw_line(size*Vector2(.36,.22),size*Vector2(.36,.80),Color("de7b75"),1.5,true)
		for line in 4:
			var y := size.y*(.30+line*.13)
			draw_line(Vector2(size.x*.29,y),Vector2(size.x*.78,y),Color("a4bed1"),1.5,true)
	else:
		draw_circle(size*Vector2(.56,.48),size.x*.17,Color("79b535"))
		draw_arc(size*Vector2(.56,.48),size.x*.12,0,TAU,20,Color("fff8da"),2,true)
		draw_line(size*Vector2(.38,.74),size*Vector2(.74,.74),Color("ad7844"),2,true)
