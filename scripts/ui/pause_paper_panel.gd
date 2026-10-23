extends PanelContainer

func _ready() -> void:
	resized.connect(queue_redraw)

func _draw() -> void:
	var outer := Rect2(Vector2.ZERO,size)
	draw_style_box(UIKit.flat_box(Color("9f632c"),Color("653813"),0,3,42),outer)
	draw_style_box(UIKit.flat_box(Color("eabd64"),Color("ffe4a0"),0,3,36),outer.grow(-7))
	draw_style_box(UIKit.flat_box(Color("fff5de"),Color("b87c37"),0,2,30),outer.grow(-15))
	for bottom in [false,true]:
		for right in [false,true]:
			var at := Vector2(size.x-34 if right else 34,size.y-34 if bottom else 34)
			var sign_x := -1.0 if right else 1.0
			var sign_y := -1.0 if bottom else 1.0
			for index in 3:
				var leaf := PackedVector2Array()
				var base := at+Vector2(sign_x*index*11,sign_y*index*13)
				for point in 20:
					var angle := float(point)*TAU/20
					leaf.append(base+Vector2(sign_x*(12*cos(angle)+7*sin(angle)),sign_y*23*sin(angle)))
				draw_colored_polygon(leaf,Color("7aaf42"))
				draw_line(base-Vector2(sign_x*7,sign_y*18),base+Vector2(sign_x*7,sign_y*18),Color("d1df83"),1.5,true)
